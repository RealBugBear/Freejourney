# Local media pipeline verification — 2026-09-06

Observed commands in the app repository:

| Command | Observed result |
|---|---|
| `python3 -m unittest discover -s scripts -p 'test_*exercise_video*.py'` | 18 tests passed, 0.082 seconds |
| `python3 scripts/validate_exercise_videos.py` | Valid inventory, 22 entries; explicitly does not certify footage |
| `python3 scripts/validate_exercise_videos.py --release-package moro` | Exit 1, seven required videos are not approved — expected external-dependency gate |
| `flutter test --no-pub test/features/training/domain/content/exercise_video_inventory_test.dart` | 1 test passed; complete inventory matches Dart source fields and every bundled poster exists |
| `git diff --check` | Exit 0 |

The Python suite includes file/checksum corruption, missing rights, stale content
approval, path traversal/symlink escape, duplicate IDs, malformed records,
unsupported encoding/audio, missing fast-start, pending-public URL rejection,
exact prior mapping, guarded reversal, revision reuse rejection, unsafe origin,
and SQL quote/dollar-delimiter escaping. Video metadata in unit tests is an
injected fixture, not measured real footage. No final videos were fabricated,
uploaded, downloaded, transcoded, or approved. No database operation was executed
by these tools. No throughput, CDN reliability or device footage result is claimed.

Runtime error/timeout and secure session-storage improvements were implemented
and tested by the coordinating engineer separately. This evidence covers only
the local media inventory, delivery validation and release preparation tools.

A supplementary `py_compile` invocation could not write the macOS Python cache
outside the sandbox. The scripts were imported and executed successfully by the
18-test suite above; that redundant cache-writing check is not counted as passed.

Remaining acceptance is external: actual content production, professional and
rights approvals, DE/EN accessible-equivalence review, valid delivered files,
real-device playback checks and authorized public storage/database publication.
See `EXERCISE_VIDEO_DELIVERY.md` for the complete delivery and rollback workflow.
