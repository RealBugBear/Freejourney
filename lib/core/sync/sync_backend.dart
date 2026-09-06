import 'package:supabase_flutter/supabase_flutter.dart';

/// Narrow transport boundary for deterministic offline/session/concurrency tests.
abstract interface class SyncBackend {
  String? get userId;
  Future<void> upsert(String table, Map<String, dynamic> payload);
  Future<void> delete(String table, String id);
  Future<List<Map<String, dynamic>>> fetch(
    String table,
    String userId, {
    List<String>? enrollmentIds,
  });
}

class SupabaseSyncBackend implements SyncBackend {
  SupabaseSyncBackend({SupabaseClient? client}) : _clientOverride = client;
  final SupabaseClient? _clientOverride;
  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> upsert(String table, Map<String, dynamic> payload) async {
    // Postgres checks required INSERT columns before applying ON CONFLICT.
    // Status-only changes therefore need UPDATE, with an explicit missing-row
    // failure instead of silently acknowledging a zero-row update.
    const requiredFields = {
      'enrollments': [
        'user_id',
        'package_id',
        'assigned_duration_weeks',
        'start_date',
        'target_completion_date'
      ],
      'progress_entries': ['user_id', 'enrollment_id'],
      'training_sessions': [
        'user_id',
        'enrollment_id',
        'session_date',
        'day_number',
        'completed_exercise_ids'
      ],
      'mood_checkins': ['user_id', 'enrollment_id', 'day_key', 'source'],
      'journal_entries': ['user_id', 'content', 'day_key'],
      'intake_assessments': [
        'enrollment_id',
        'had_isometric_with_trainer',
        'final_duration_weeks',
        'recommended_duration_weeks',
        'user_accepted_recommendation'
      ],
      'completion_questionnaires': ['enrollment_id', 'response', 'result'],
    };
    final required = requiredFields[table];
    if (required != null &&
        required.any((field) => !payload.containsKey(field))) {
      final row = await _client
          .from(table)
          .update(payload)
          .eq('id', payload['id'] as String)
          .select('id')
          .maybeSingle();
      if (row == null) {
        throw const PostgrestException(
            message: 'Sync target unavailable', code: 'sync_target_missing');
      }
      return;
    }
    await _client.from(table).upsert(payload);
  }

  @override
  Future<void> delete(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(
    String table,
    String userId, {
    List<String>? enrollmentIds,
  }) async {
    final rows = <Map<String, dynamic>>[];
    // Keyset pagination avoids PostgREST's default 1,000-row truncation.
    // Limit IN filters so a long-lived account cannot exceed URL limits.
    final groups = <List<String>?>[];
    if (enrollmentIds == null) {
      groups.add(null);
    } else {
      for (var offset = 0; offset < enrollmentIds.length; offset += 100) {
        groups.add(enrollmentIds.skip(offset).take(100).toList());
      }
    }
    for (final ids in groups) {
      String? after;
      while (true) {
        if (this.userId != userId) throw const SyncSessionChanged();
        var query = _client.from(table).select();
        query = ids == null
            ? query.eq('user_id', userId)
            : query.inFilter('enrollment_id', ids);
        if (after != null) query = query.gt('id', after);
        final page = await query
            .order('id')
            .limit(250)
            .timeout(const Duration(seconds: 20));
        rows.addAll(page);
        if (page.length < 250) break;
        after = page.last['id'] as String;
      }
    }
    return rows;
  }
}

class SyncSessionChanged implements Exception {
  const SyncSessionChanged();
}
