import 'dart:convert';
import 'dart:io';

import 'package:corejourney/features/training/domain/content/training_content_snapshot.dart';
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regenerate only source fields with UPDATE_EXERCISE_VIDEO_INVENTORY=1.
/// Delivery statuses, approvals and file records are deliberately preserved.
void main() {
  test('video delivery inventory covers the complete local exercise catalog',
      () {
    final file = File('docs/media/exercise_video_manifest.v1.json');
    final all = [
      ...moroExercises,
      ...spinalGalantExercises,
      ...tlrExercises,
      ...vorrundeExercises,
    ];
    final existing = file.existsSync()
        ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
        : <String, dynamic>{};
    final oldEntries = {
      for (final entry in existing['videos'] as List? ?? [])
        entry['exercise_id'] as String: entry as Map<String, dynamic>,
    };
    final expected = [
      for (final exercise in all) _source(exercise),
    ];
    if (Platform.environment['UPDATE_EXERCISE_VIDEO_INVENTORY'] == '1') {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert({
            'schema_version': 1,
            'contract': 'docs/media/EXERCISE_VIDEO_DELIVERY.md',
            'videos': [
              for (final source in expected)
                {
                  'video_id': '${source['exercise_id']}_demonstration',
                  'revision': 1,
                  'status': 'awaiting_production',
                  'owner':
                      'Founder (commissioning); exercise professional (content approval); editor (delivery)',
                  'approval_refs': <String, String>{},
                  'files': <String, dynamic>{},
                  ...?oldEntries[source['exercise_id']],
                  ...source,
                },
            ],
          })}\n');
    }
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entries = (manifest['videos'] as List).cast<Map<String, dynamic>>();
    expect(entries.map((e) => e['exercise_id']), all.map((e) => e.id));
    expect(entries.map((e) => e['video_id']).toSet().length, all.length);
    for (var i = 0; i < all.length; i++) {
      for (final field in expected[i].entries) {
        expect(entries[i][field.key], field.value,
            reason: '${all[i].id}: stale ${field.key}');
      }
      expect(File(all[i].imagePath).existsSync(), isTrue);
    }
  });
}

Map<String, dynamic> _source(Exercise e) => {
      'exercise_id': e.id,
      'package_id': e.packageId,
      'sequence_number': e.sequenceNumber,
      'content_version': e.packageId == 'moro'
          ? moroContentVersion
          : '${e.packageId}-legacy-v1',
      'content_review_required': true,
      'title': {'de': e.titleDe, 'en': e.titleEn},
      'instructions': {
        'de': {
          'position': e.positionInstructionsDe,
          'movement': e.movementInstructionsDe,
          'guide': e.executionGuideDe,
          'orientation': e.orientationDe,
        },
        'en': {
          'position': e.positionInstructionsEn,
          'movement': e.movementInstructionsEn,
          'guide': e.executionGuideEn,
          'orientation': e.orientationEn,
        },
      },
      'instruction_status': e.executionGuideDe.contains('TBD')
          ? 'blocked_missing_instructions'
          : 'requires_filming_review',
      'exercise_duration_seconds': e.durationSeconds,
      'target_clip_seconds': {'min': 15, 'max': 90},
      'bundled_poster_path': e.imagePath,
      'duo_instructions_present': e.positionInstructionsDuoDe != null,
      'delivery_profile': 'silent-neutral-landscape-v1',
    };
