import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/training/domain/content/training_content_snapshot.dart';
import '../../features/training/domain/models/exercise.dart';
import '../../features/training/domain/services/training_content_resolver.dart';
import '../database/app_database.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';

/// Syncs static exercise content from Supabase into the local Drift cache.
///
/// Exercises are static content — they don't change per user and must be
/// available offline. This service fetches them once after app start and
/// whenever the local cache is empty. The server is authoritative; local rows
/// are always overwritten.
///
/// Call [syncIfNeeded] once after the database is ready. It is idempotent and
/// no-ops if the local cache already contains rows (avoids redundant fetches
/// on every cold start). Call [forceSync] to refresh unconditionally.
class ExercisesSyncService {
  final AppDatabase _db;
  final Future<bool> Function() _isConnected;
  final Future<List<dynamic>> Function() _loadRemoteRows;
  Future<void>? _inFlight;

  ExercisesSyncService(
    this._db, {
    Future<bool> Function()? isConnected,
    Future<List<dynamic>> Function()? loadRemoteRows,
  })  : _isConnected = isConnected ?? ConnectivityService.isConnected,
        _loadRemoteRows = loadRemoteRows ?? _defaultRemoteRowsLoader;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetches exercises unless the local Moro cache satisfies the full contract.
  Future<void> syncIfNeeded() async {
    final rows = await (_db.select(_db.exercisesTable)
          ..orderBy([
            (table) => OrderingTerm.asc(table.packageId),
            (table) => OrderingTerm.asc(table.sequenceNumber),
          ]))
        .get();
    if (_isValidMoroCache(rows)) {
      appLogger.d(
        'ExercisesSyncService: validated ${rows.length} cached rows — skipping',
      );
      return;
    }
    await _synchronize();
  }

  /// Forces a full refresh from Supabase regardless of cache state.
  Future<void> forceSync() => _synchronize();

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _synchronize() {
    final active = _inFlight;
    if (active != null) return active;

    final operation = _fetchAndCache();
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<void> _fetchAndCache() async {
    if (!await _isConnected()) {
      appLogger.d('ExercisesSyncService: offline — using hardcoded fallback');
      return;
    }

    try {
      final rows = await _loadRemoteRows();

      await replaceCacheWithValidatedSnapshot(rows);

      appLogger.i(
          'ExercisesSyncService: cached ${rows.length} exercises from Supabase');
    } on AuthException {
      appLogger.w('ExercisesSyncService: auth error — using fallback');
    } catch (e, st) {
      appLogger.e('ExercisesSyncService: fetch failed',
          error: e, stackTrace: st);
    }
  }

  static Future<List<dynamic>> _defaultRemoteRowsLoader() async {
    final client = Supabase.instance.client;
    return await client
        .from('exercises')
        .select()
        .order('package_id')
        .order('sequence_number') as List<dynamic>;
  }

  bool _isValidMoroCache(List<ExercisesTableData> rows) {
    try {
      final exercises = rows
          .where((row) => row.packageId == moroContentSnapshot.packageId)
          .map(_exerciseFromCacheRow)
          .toList()
        ..sort(
          (left, right) => left.sequenceNumber.compareTo(right.sequenceNumber),
        );
      return const TrainingContentValidator()
          .validateSnapshotCache(
            snapshot: moroContentSnapshot,
            cachedExercises: exercises,
          )
          .isValid;
    } on Object catch (error) {
      appLogger.w(
        'ExercisesSyncService: corrupt cached snapshot — refreshing ($error)',
      );
      return false;
    }
  }

  /// Atomically replaces cached content after validating the full response.
  ///
  /// Exposed for deterministic database tests; production calls it only with
  /// the complete ordered Supabase response.
  Future<void> replaceCacheWithValidatedSnapshot(List<dynamic> rows) async {
    validateRemoteSnapshotForCache(rows);
    await _db.transaction(() async {
      await _db.delete(_db.exercisesTable).go();
      for (final raw in rows) {
        final row = raw as Map<String, dynamic>;
        final companion = ExercisesTableCompanion.insert(
          id: row['id'] as String,
          packageId: row['package_id'] as String,
          sequenceNumber: row['sequence_number'] as int,
          titleDe: row['title_de'] as String,
          titleEn: row['title_en'] as String,
          positionInstructionsDe: _encodeList(row['position_instructions_de']),
          positionInstructionsEn: _encodeList(row['position_instructions_en']),
          movementInstructionsDe: _encodeList(row['movement_instructions_de']),
          movementInstructionsEn: _encodeList(row['movement_instructions_en']),
          hintsDe: Value(_encodeNullableList(row['hints_de'])),
          hintsEn: Value(_encodeNullableList(row['hints_en'])),
          executionGuideDe: row['execution_guide_de'] as String,
          executionGuideEn: row['execution_guide_en'] as String,
          durationSeconds: row['duration_seconds'] as int,
          repetitions: row['repetitions'] as int,
          imagePath: row['image_path'] as String,
          videoPath: Value(row['video_path'] as String?),
          duoImagePath: Value(row['duo_image_path'] as String?),
          imageUrl: Value(row['image_url'] as String?),
          duoImageUrl: Value(row['duo_image_url'] as String?),
          videoUrl: Value(row['video_url'] as String?),
          audioCuePath: Value(row['audio_cue_path'] as String?),
          rhythmType: Value(row['rhythm_type'] as String? ?? 'holdRest'),
          phasesJson: Value(_encodePhasesJson(row['phases_json'])),
          hasRepSwitch: Value(row['has_rep_switch'] as bool? ?? false),
          holdCueDe: Value(row['hold_cue_de'] as String? ?? 'Halten'),
          holdCueEn: Value(row['hold_cue_en'] as String? ?? 'Hold'),
          holdSeconds: Value(row['hold_seconds'] as int? ?? 7),
          restSeconds: Value(row['rest_seconds'] as int? ?? 3),
          halfwaySwitch: Value(row['halfway_switch'] as bool? ?? false),
        );
        await _db.into(_db.exercisesTable).insert(companion);
      }
    });
  }

  /// Validates the full response before any cached row is replaced.
  static void validateRemoteSnapshotForCache(List<dynamic> rows) {
    if (rows.isEmpty) {
      throw StateError('The remote exercise snapshot is empty.');
    }
    final moroRows = rows
        .cast<Map<String, dynamic>>()
        .where((row) => row['package_id'] == 'moro')
        .map(Exercise.fromRow)
        .toList();
    final result = const TrainingContentValidator().validateSnapshotCache(
      snapshot: moroContentSnapshot,
      cachedExercises: moroRows,
    );
    if (!result.isValid) {
      final details = result.issues
          .map((issue) => '${issue.code.name}:${issue.exerciseId ?? '-'}')
          .join(',');
      throw StateError(
        'Remote Moro content does not match $moroContentVersion ($details).',
      );
    }
  }

  // ── Encoding helpers ────────────────────────────────────────────────────────

  /// Supabase returns text[] as List<dynamic>. Drift stores as JSON string.
  static String _encodeList(dynamic value) {
    if (value == null) return '[]';
    if (value is String) return value; // already JSON
    return jsonEncode((value as List).cast<String>());
  }

  static String? _encodeNullableList(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    final list = (value as List).cast<String>();
    if (list.isEmpty) return null;
    return jsonEncode(list);
  }

  /// phases_json is already jsonb on the server — encode to string for SQLite.
  static String _encodePhasesJson(dynamic value) {
    if (value == null) return '[]';
    if (value is String) return value;
    return jsonEncode(value); // List<Map<String, dynamic>>
  }

  static Exercise _exerciseFromCacheRow(ExercisesTableData row) {
    return Exercise.fromRow({
      'id': row.id,
      'package_id': row.packageId,
      'sequence_number': row.sequenceNumber,
      'title_de': row.titleDe,
      'title_en': row.titleEn,
      'position_instructions_de': row.positionInstructionsDe,
      'position_instructions_en': row.positionInstructionsEn,
      'movement_instructions_de': row.movementInstructionsDe,
      'movement_instructions_en': row.movementInstructionsEn,
      'hints_de': row.hintsDe,
      'hints_en': row.hintsEn,
      'execution_guide_de': row.executionGuideDe,
      'execution_guide_en': row.executionGuideEn,
      'duration_seconds': row.durationSeconds,
      'repetitions': row.repetitions,
      'image_path': row.imagePath,
      'video_path': row.videoPath,
      'duo_image_path': row.duoImagePath,
      'image_url': row.imageUrl,
      'duo_image_url': row.duoImageUrl,
      'video_url': row.videoUrl,
      'audio_cue_path': row.audioCuePath,
      'rhythm_type': row.rhythmType,
      'phases_json': row.phasesJson,
      'has_rep_switch': row.hasRepSwitch,
      'hold_cue_de': row.holdCueDe,
      'hold_cue_en': row.holdCueEn,
      'hold_seconds': row.holdSeconds,
      'rest_seconds': row.restSeconds,
      'halfway_switch': row.halfwaySwitch,
    });
  }
}
