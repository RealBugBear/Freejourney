import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _uuid = Uuid();

enum VorrundePhaseStatus {
  started,
  skipped,
  completed;

  static VorrundePhaseStatus fromJson(String value) => switch (value) {
        'skipped' => skipped,
        'completed' => completed,
        _ => started,
      };
}

class VorrundePhase {
  const VorrundePhase({
    required this.id,
    required this.userId,
    required this.subjectProfileId,
    required this.status,
    required this.firstStartedAt,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? subjectProfileId;
  final VorrundePhaseStatus status;
  final DateTime? firstStartedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isReadyForMoro(DateTime now) {
    final start = firstStartedAt;
    if (status == VorrundePhaseStatus.completed) return true;
    if (start == null) return false;
    return !now.isBefore(start.add(const Duration(days: 28)));
  }

  VorrundePhase deriveCompletion(DateTime now) {
    if (status != VorrundePhaseStatus.started || !isReadyForMoro(now)) {
      return this;
    }
    return copyWith(
      status: VorrundePhaseStatus.completed,
      completedAt: completedAt ?? now,
      updatedAt: now,
    );
  }

  VorrundePhase copyWith({
    VorrundePhaseStatus? status,
    DateTime? firstStartedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return VorrundePhase(
      id: id,
      userId: userId,
      subjectProfileId: subjectProfileId,
      status: status ?? this.status,
      firstStartedAt: firstStartedAt ?? this.firstStartedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory VorrundePhase.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullable(String key) => json[key] == null
        ? null
        : DateTime.parse(json[key] as String).toLocal();

    return VorrundePhase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectProfileId: json['subject_profile_id'] as String?,
      status: VorrundePhaseStatus.fromJson(json['status'] as String? ?? ''),
      firstStartedAt: parseNullable('first_started_at'),
      completedAt: parseNullable('completed_at'),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
        'status': status.name,
        if (firstStartedAt != null)
          'first_started_at': firstStartedAt!.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

abstract interface class VorrundePhaseRepository {
  Future<VorrundePhase?> fetch({
    required String userId,
    required String? subjectProfileId,
  });

  Future<VorrundePhase> start({
    required String userId,
    required String? subjectProfileId,
    DateTime? now,
  });

  Future<VorrundePhase> skip({
    required String userId,
    required String? subjectProfileId,
    DateTime? now,
  });

  Future<VorrundePhase> complete({
    required String userId,
    required String? subjectProfileId,
    DateTime? now,
  });
}

class SupabaseVorrundePhaseRepository implements VorrundePhaseRepository {
  const SupabaseVorrundePhaseRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  @override
  Future<VorrundePhase?> fetch({
    required String userId,
    required String? subjectProfileId,
  }) async {
    try {
      final query =
          _client.from('vorrunde_phases').select().eq('user_id', userId);
      final row = subjectProfileId == null
          ? await query.isFilter('subject_profile_id', null).maybeSingle()
          : await query
              .eq('subject_profile_id', subjectProfileId)
              .maybeSingle();
      if (row == null) return _cached(userId, subjectProfileId);
      final phase = VorrundePhase.fromJson(row);
      await _cache(phase);
      return phase.deriveCompletion(DateTime.now());
    } catch (_) {
      return _cached(userId, subjectProfileId);
    }
  }

  @override
  Future<VorrundePhase> start({
    required String userId,
    required String? subjectProfileId,
    DateTime? now,
  }) {
    return _upsert(
      userId: userId,
      subjectProfileId: subjectProfileId,
      status: VorrundePhaseStatus.started,
      now: now ?? DateTime.now(),
      keepSkipped: true,
    );
  }

  @override
  Future<VorrundePhase> skip({
    required String userId,
    required String? subjectProfileId,
    DateTime? now,
  }) {
    return _upsert(
      userId: userId,
      subjectProfileId: subjectProfileId,
      status: VorrundePhaseStatus.skipped,
      now: now ?? DateTime.now(),
    );
  }

  @override
  Future<VorrundePhase> complete({
    required String userId,
    required String? subjectProfileId,
    DateTime? now,
  }) {
    return _upsert(
      userId: userId,
      subjectProfileId: subjectProfileId,
      status: VorrundePhaseStatus.completed,
      now: now ?? DateTime.now(),
    );
  }

  Future<VorrundePhase> _upsert({
    required String userId,
    required String? subjectProfileId,
    required VorrundePhaseStatus status,
    required DateTime now,
    bool keepSkipped = false,
  }) async {
    final existing =
        await fetch(userId: userId, subjectProfileId: subjectProfileId);
    if (keepSkipped && existing?.status == VorrundePhaseStatus.skipped) {
      return existing!;
    }

    final phase = VorrundePhase(
      id: existing?.id ?? _uuid.v4(),
      userId: userId,
      subjectProfileId: subjectProfileId,
      status: status,
      firstStartedAt: existing?.firstStartedAt ??
          (status == VorrundePhaseStatus.started ? now : null),
      completedAt: status == VorrundePhaseStatus.completed
          ? existing?.completedAt ?? now
          : existing?.completedAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _cache(phase);
    try {
      await _client.from('vorrunde_phases').upsert(
            phase.toJson(),
            onConflict: 'user_id,subject_profile_id',
          );
    } catch (_) {
      // Local cache keeps the UI deterministic until sync is available again.
    }
    return phase;
  }

  VorrundePhase? _cached(String userId, String? subjectProfileId) {
    final raw = _prefs.getString(_cacheKey(userId, subjectProfileId));
    if (raw == null) return null;
    return VorrundePhase.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _cache(VorrundePhase phase) async {
    await _prefs.setString(
      _cacheKey(phase.userId, phase.subjectProfileId),
      jsonEncode(phase.toJson()),
    );
  }

  String _cacheKey(String userId, String? subjectProfileId) =>
      'vorrunde_phase_${userId}_${subjectProfileId ?? 'self'}';
}

final vorrundePhaseRepositoryProvider =
    Provider<VorrundePhaseRepository>((ref) {
  return SupabaseVorrundePhaseRepository(
    Supabase.instance.client,
    ref.watch(sharedPreferencesProvider),
  );
});

final vorrundePhaseProvider = FutureProvider.family<VorrundePhase?, String?>(
    (ref, subjectProfileId) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return ref.read(vorrundePhaseRepositoryProvider).fetch(
        userId: userId,
        subjectProfileId: subjectProfileId,
      );
});

final selectedVorrundePhaseProvider = FutureProvider<VorrundePhase?>((ref) {
  final profile = ref.watch(selectedSubjectProfileProvider);
  return ref.watch(vorrundePhaseProvider(profile?.id).future);
});
