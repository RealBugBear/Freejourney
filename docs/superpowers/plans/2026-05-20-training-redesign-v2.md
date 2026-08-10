# Training Redesign v2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver hands-free, audio-driven training sessions with a proper mode toggle, plus the Vorrunde optional entry package.

**Architecture:** New `AudioAnnouncementService` singleton plays pre-recorded MP3 announcement files with audio ducking via `InAppMusicService`. The existing `ImmersiveSessionScreen` + `ExerciseTransitionWidget` are updated to fire announcements and reduce transition time. Mode toggle moves from Settings to the Session intro screen inline. Vorrunde is a new package with an interstitial screen gating package selection.

**Tech Stack:** Flutter/Dart, Riverpod 2.5, audioplayers 6.5, SharedPreferences, GoRouter

**Spec:** `docs/superpowers/specs/2026-05-20-training-redesign-v2.md`

---

## File Map

### New files
- `lib/features/training/domain/services/audio_announcement_service.dart` — singleton, plays queued MP3 assets, triggers music ducking
- `lib/core/training/vorrunde_status_settings.dart` — SharedPrefs key for vorrunde_status
- `lib/core/training/first_run_settings.dart` — per-package first-run flag
- `lib/core/training/routine_tip_settings.dart` — tracks session count + tip shown
- `lib/features/training/presentation/screens/vorrunde_interstitial_screen.dart` — "Bevor du startest" one-shot screen
- `test/features/training/audio_announcement_service_test.dart`
- `test/features/training/vorrunde_status_settings_test.dart`

### Modified files
- `lib/features/training/domain/models/exercise.dart` — add `positionInstructionsDuoDe`, `movementInstructionsDuoDe`, 6 Vorrunde exercises
- `lib/features/training/presentation/services/in_app_music_service.dart` — add `duck()` / `unduck()` 
- `lib/features/training/presentation/widgets/training_intro_widget.dart` — inline Tutorial/Routine toggle (replaces "go to settings" hint)
- `lib/features/training/presentation/screens/immersive_session_screen.dart` — fire AudioAnnouncementService on exercise transition
- `lib/features/training/presentation/widgets/exercise_transition_widget.dart` — 5 s default, video button, first-run video
- `lib/features/packages/presentation/screens/packages_screen.dart` — inject Vorrunde interstitial
- `lib/features/home/presentation/screens/*.dart` (dashboard) — routine tip bottom sheet
- `pubspec.yaml` — register `assets/sounds/announcements/de/` directory

---

## Task 1: Exercise model — Vorrunde duo fields

**Files:**
- Modify: `lib/features/training/domain/models/exercise.dart`

- [ ] **Step 1: Add duo instruction fields to `Exercise` constructor**

Open `lib/features/training/domain/models/exercise.dart`. Find the constructor and add two nullable fields after the existing `positionInstructions` / `movementInstructions` parameters:

```dart
final List<String>? positionInstructionsDuoDe;
final List<String>? movementInstructionsDuoDe;
```

Add them to the constructor, `copyWith`, and any `fromJson`/`toJson` if present. Mark them `final` with default `null`.

- [ ] **Step 2: Add 6 Vorrunde exercises to the hardcoded list**

Find the `allExercises` (or equivalent) static list in `exercise.dart`. Append the 6 Vorrunde exercises below the existing TLR exercises:

```dart
// ── VORRUNDE ─────────────────────────────────────────────
Exercise(
  id: 'vorrunde_ex1',
  packageId: 'vorrunde',
  sequenceNumber: 1,
  titleDe: 'Schaukeln 1',
  titleEn: 'Rocking 1',
  positionInstructions: ['TBD — solo Ausgangsposition'],
  movementInstructions: ['TBD — solo Bewegung'],
  positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
  movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
  repetitions: 6,
  imagePath: 'assets/images/trainings/vorrunde/vorrunde1.png',
  videoPath: null,
  audioCuePath: null,
  rhythmType: RhythmType.holdRest,
  holdSeconds: 7,
  restSeconds: 3,
  hasRepSwitch: false,
  halfwaySwitch: false,
),
Exercise(
  id: 'vorrunde_ex2',
  packageId: 'vorrunde',
  sequenceNumber: 2,
  titleDe: 'Schaukeln 2',
  titleEn: 'Rocking 2',
  positionInstructions: ['TBD — solo Ausgangsposition'],
  movementInstructions: ['TBD — solo Bewegung'],
  positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
  movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
  repetitions: 6,
  imagePath: 'assets/images/trainings/vorrunde/vorrunde2.png',
  videoPath: null,
  audioCuePath: null,
  rhythmType: RhythmType.holdRest,
  holdSeconds: 7,
  restSeconds: 3,
  hasRepSwitch: false,
  halfwaySwitch: false,
),
// Repeat pattern for vorrunde_ex3 … vorrunde_ex6 with sequenceNumber 3–6
// and imagePath vorrunde3.png … vorrunde6.png
```

> **Content note:** All `TBD` strings must be replaced by the domain expert before shipping. Placeholder exercises are intentional — the code structure is complete.

- [ ] **Step 3: Create placeholder image directory**

```bash
mkdir -p /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/images/trainings/vorrunde
touch /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/images/trainings/vorrunde/.gitkeep
mkdir -p /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/sounds/announcements/de/exercises
touch /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/sounds/announcements/de/.gitkeep
touch /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/sounds/announcements/de/exercises/.gitkeep
```

- [ ] **Step 4: Register asset paths in pubspec.yaml**

In `pubspec.yaml`, under `flutter: assets:`, add:

```yaml
    - assets/images/trainings/vorrunde/
    - assets/sounds/announcements/de/
    - assets/sounds/announcements/de/exercises/
```

- [ ] **Step 5: Verify app compiles**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

Expected: no new errors related to `Exercise`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/training/domain/models/exercise.dart assets/images/trainings/vorrunde/ assets/sounds/announcements/ pubspec.yaml
git commit -m "feat: add Vorrunde exercise data structure and asset directories"
```

---

## Task 2: AudioAnnouncementService

**Files:**
- Create: `lib/features/training/domain/services/audio_announcement_service.dart`
- Create: `test/features/training/audio_announcement_service_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/training/audio_announcement_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/training/domain/services/audio_announcement_service.dart';

void main() {
  group('AudioAnnouncementService', () {
    test('is a singleton', () {
      expect(
        AudioAnnouncementService.instance,
        same(AudioAnnouncementService.instance),
      );
    });

    test('stop() does not throw when nothing is playing', () {
      expect(() => AudioAnnouncementService.instance.stop(), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter test test/features/training/audio_announcement_service_test.dart 2>&1 | tail -10
```

Expected: compilation error (class doesn't exist yet).

- [ ] **Step 3: Implement AudioAnnouncementService**

Create `lib/features/training/domain/services/audio_announcement_service.dart`:

```dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../presentation/services/in_app_music_service.dart';

class AudioAnnouncementService {
  AudioAnnouncementService._();

  static final AudioAnnouncementService instance =
      AudioAnnouncementService._();

  AudioPlayer? _player;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    _player = AudioPlayer();
    final ctx = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    await _player!.setAudioContext(ctx);
    await _player!.setReleaseMode(ReleaseMode.stop);
  }

  /// Plays a single asset key (relative to assets/, e.g.
  /// 'sounds/announcements/de/wechsel.mp3').
  /// Ducks music while playing, then restores it.
  Future<void> play(String assetKey) async {
    try {
      await _init();
      await InAppMusicService.instance.duck();
      await _player!.play(AssetSource(assetKey));
      await _player!.onPlayerComplete.first;
    } catch (e) {
      debugPrint('[AudioAnnouncementService] play error: $e');
    } finally {
      await InAppMusicService.instance.unduck();
    }
  }

  /// Plays a sequence of asset keys one after another.
  Future<void> queue(List<String> assetKeys) async {
    for (final key in assetKeys) {
      await play(key);
    }
  }

  void stop() {
    _player?.stop();
    InAppMusicService.instance.unduck();
  }

  Future<void> dispose() async {
    _initialized = false;
    await _player?.dispose();
    _player = null;
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter test test/features/training/audio_announcement_service_test.dart 2>&1 | tail -10
```

Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/training/domain/services/audio_announcement_service.dart test/features/training/audio_announcement_service_test.dart
git commit -m "feat: add AudioAnnouncementService with audio ducking"
```

---

## Task 3: InAppMusicService — duck / unduck

**Files:**
- Modify: `lib/features/training/presentation/services/in_app_music_service.dart`

- [ ] **Step 1: Add `_normalVolume`, `_isDucked`, `duck()`, `unduck()` to InAppMusicService**

In `in_app_music_service.dart`, find `final _player = AudioPlayer();` and add below it:

```dart
double _normalVolume = 0.7;
bool _isDucked = false;
```

Then after `setVolume()`, add:

```dart
Future<void> duck() async {
  if (_isDucked || _currentTrack == null) return;
  _isDucked = true;
  await _player.setVolume(0.2);
}

Future<void> unduck() async {
  if (!_isDucked) return;
  _isDucked = false;
  await _player.setVolume(_normalVolume);
}
```

Also update `play()` to capture `_normalVolume`:

```dart
Future<void> play(String assetKey, {double volume = 0.7}) async {
  try {
    await init();
    _currentTrack = assetKey;
    _normalVolume = volume.clamp(0.0, 1.0);   // ← add this line
    await _player.setVolume(_normalVolume);
    await _player.play(AssetSource(assetKey));
  } catch (error) {
    debugPrint('[InAppMusicService] play error: $error');
  }
}
```

And update `setVolume()`:

```dart
Future<void> setVolume(double volume) async {
  await init();
  _normalVolume = volume.clamp(0.0, 1.0);   // ← add this line
  if (!_isDucked) await _player.setVolume(_normalVolume);
}
```

- [ ] **Step 2: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/features/training/presentation/services/in_app_music_service.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/training/presentation/services/in_app_music_service.dart
git commit -m "feat: add duck/unduck to InAppMusicService for audio announcements"
```

---

## Task 4: Mode toggle inline in TrainingIntroWidget

**Files:**
- Modify: `lib/features/training/presentation/widgets/training_intro_widget.dart`

The widget currently shows mode as read-only with "Ändere den Modus in den Einstellungen." It needs to become an interactive toggle that calls `settingsProvider.notifier.setTrainingMode()`.

- [ ] **Step 1: Convert TrainingIntroWidget from StatelessWidget to ConsumerWidget**

Change the class signature:

```dart
class TrainingIntroWidget extends ConsumerWidget {
```

Add the import for Riverpod at the top:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/settings/settings_provider.dart';
```

Change `build(BuildContext context)` to `build(BuildContext context, WidgetRef ref)`.

- [ ] **Step 2: Replace the read-only mode card with an interactive toggle**

Find the `Container` block that currently shows mode + "Ändere den Modus in den Einstellungen." and replace the entire block with:

```dart
Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () => ref
            .read(settingsProvider.notifier)
            .setTrainingMode(TrainingSessionMode.tutorial),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: mode == TrainingSessionMode.tutorial
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10)),
            border: Border.all(
              color: mode == TrainingSessionMode.tutorial
                  ? AppColors.primary
                  : AppColors.surfaceDarkElevated,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Tutorial',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mode == TrainingSessionMode.tutorial
                      ? Colors.white
                      : AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mit Anleitung',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mode == TrainingSessionMode.tutorial
                      ? Colors.white70
                      : AppColors.textDisabledDark,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    Expanded(
      child: GestureDetector(
        onTap: () => ref
            .read(settingsProvider.notifier)
            .setTrainingMode(TrainingSessionMode.routine),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: mode == TrainingSessionMode.routine
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10)),
            border: Border.all(
              color: mode == TrainingSessionMode.routine
                  ? AppColors.primary
                  : AppColors.surfaceDarkElevated,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Routine',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mode == TrainingSessionMode.routine
                      ? Colors.white
                      : AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Hands-free',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mode == TrainingSessionMode.routine
                      ? Colors.white70
                      : AppColors.textDisabledDark,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
```

- [ ] **Step 3: Check that `settingsProvider.notifier` has `setTrainingMode`**

```bash
grep -n "setTrainingMode\|trainingMode" /Users/alexandermessinger/dev/claudvibes/reflexjourney/lib/core/settings/settings_provider.dart | head -10
```

Expected: `setTrainingMode` method exists. If not, add it (copy pattern from any other setter in that file).

- [ ] **Step 4: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/features/training/presentation/widgets/training_intro_widget.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/training/presentation/widgets/training_intro_widget.dart
git commit -m "feat: add inline Tutorial/Routine toggle to session intro screen"
```

---

## Task 5: Wire AudioAnnouncementService into ImmersiveSessionScreen

**Files:**
- Modify: `lib/features/training/presentation/screens/immersive_session_screen.dart`

In Routine mode, before showing the transition screen for the NEXT exercise, play the exercise name + position announcement.

- [ ] **Step 1: Import AudioAnnouncementService**

Add at top of `immersive_session_screen.dart`:

```dart
import '../../domain/services/audio_announcement_service.dart';
```

- [ ] **Step 2: Fire announcements in `_onExerciseComplete()`**

In `_onExerciseComplete()`, after incrementing `_exerciseIndex` and before calling `setState`, add the audio announcement for the NEXT exercise. Replace the existing `setState` block at the end of `_onExerciseComplete()` with:

```dart
final nextIndex = _exerciseIndex + 1;
final nextExercise = widget.exercises[nextIndex];
final nextId = nextExercise.id;
final isDuo = widget.companionSubjectProfileIds.isNotEmpty;

// Fire announcement asynchronously — don't await (transition screen
// shows immediately while audio plays over it).
if (widget.isRoutineMode) {
  unawaited(AudioAnnouncementService.instance.queue([
    'sounds/announcements/de/exercises/${nextId}_name.mp3',
    'sounds/announcements/de/exercises/${nextId}_position${isDuo ? '_duo' : ''}.mp3',
  ]));
}

if (!mounted) return;
setState(() {
  _exerciseIndex = nextIndex;
  _phase = _Phase.transition;
});
```

Add `import 'dart:async';` at the top if not already present (needed for `unawaited`).

Also add `companionSubjectProfileIds` parameter to `ImmersiveSessionScreen`:

```dart
final List<String> companionSubjectProfileIds;
```

And pass it from `TrainingSessionScreen` where `ImmersiveSessionScreen` is constructed:

```dart
ImmersiveSessionScreen(
  exercises: state.exercises,
  isRoutineMode: state.mode == TrainingSessionMode.routine,
  companionSubjectProfileIds: widget.companionSubjectProfileIds,
  onComplete: ...,
)
```

- [ ] **Step 3: Also announce the FIRST exercise when the session starts**

In `ImmersiveSessionScreen`, override `initState` (or add to existing `initState`) to fire announcement for exercise 0 in Routine mode:

```dart
@override
void initState() {
  super.initState();
  _loadTransitionDuration();
  if (widget.isRoutineMode && widget.exercises.isNotEmpty) {
    final first = widget.exercises.first;
    final isDuo = widget.companionSubjectProfileIds.isNotEmpty;
    unawaited(AudioAnnouncementService.instance.queue([
      'sounds/announcements/de/exercises/${first.id}_name.mp3',
      'sounds/announcements/de/exercises/${first.id}_position${isDuo ? '_duo' : ''}.mp3',
    ]));
  }
}
```

- [ ] **Step 4: Stop announcements when session is cancelled**

In `dispose()` of `_ImmersiveSessionScreenState`, add:

```dart
@override
void dispose() {
  AudioAnnouncementService.instance.stop();
  super.dispose();
}
```

- [ ] **Step 5: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/features/training/presentation/screens/immersive_session_screen.dart 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/training/presentation/screens/immersive_session_screen.dart
git commit -m "feat: fire audio announcements between exercises in Routine mode"
```

---

## Task 6: ExerciseTransitionWidget — 5 s default + video button

**Files:**
- Modify: `lib/features/training/presentation/widgets/exercise_transition_widget.dart`
- Create: `lib/core/training/first_run_settings.dart`

- [ ] **Step 1: Create FirstRunSettings**

Create `lib/core/training/first_run_settings.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class FirstRunSettings {
  static String _key(String packageId) => 'first_run_complete_$packageId';

  static bool isFirstRun(SharedPreferences prefs, String packageId) =>
      !(prefs.getBool(_key(packageId)) ?? false);

  static Future<void> markComplete(
          SharedPreferences prefs, String packageId) =>
      prefs.setBool(_key(packageId), true);
}
```

- [ ] **Step 2: Add `packageId` and `isFirstRun` params to ExerciseTransitionWidget**

In `exercise_transition_widget.dart`, add to the widget's constructor:

```dart
final String packageId;
final bool isFirstRun;
```

All callers pass `packageId: widget.packageId` and `isFirstRun: _isFirstRun` (a state variable loaded from `FirstRunSettings`).

- [ ] **Step 3: Load first-run flag in ImmersiveSessionScreen**

In `_ImmersiveSessionScreenState`, add:

```dart
bool _isFirstRun = false;

@override
void initState() {
  super.initState();
  _loadTransitionDuration();
  _loadFirstRun();
  // ... existing routine announcement code
}

Future<void> _loadFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  if (!mounted) return;
  setState(() {
    _isFirstRun = FirstRunSettings.isFirstRun(prefs, widget.packageId);
  });
}
```

Add `packageId` param to `ImmersiveSessionScreen`:

```dart
final String packageId;
```

Pass from `TrainingSessionScreen`:

```dart
ImmersiveSessionScreen(
  exercises: state.exercises,
  packageId: widget.packageId,
  isRoutineMode: ...,
  companionSubjectProfileIds: ...,
  onComplete: ...,
)
```

Mark first run complete after the session ends — in `_onExerciseComplete()`, when the last exercise completes:

```dart
if (_isFirstRun) {
  final prefs = await SharedPreferences.getInstance();
  await FirstRunSettings.markComplete(prefs, widget.packageId);
}
```

- [ ] **Step 4: Change routine default countdown to 5 s**

In `ExerciseTransitionWidget`, the constructor currently takes `transitionDurationSeconds`. Keep the parameter but change the default passed from `ImmersiveSessionScreen` from `_transitionDuration` (SharedPrefs, default 10) to `5` for Routine mode:

In `ImmersiveSessionScreen.build()`, where `ExerciseTransitionWidget` is constructed:

```dart
ExerciseTransitionWidget(
  key: ValueKey('transition_$_exerciseIndex'),
  exercise: exercise,
  exerciseIndex: _exerciseIndex,
  totalExercises: widget.exercises.length,
  isRoutineMode: widget.isRoutineMode,
  transitionDurationSeconds: widget.isRoutineMode ? 5 : _transitionDuration,
  packageId: widget.packageId,
  isFirstRun: _isFirstRun,
  locale: locale,
  onStart: _onTransitionComplete,
)
```

- [ ] **Step 5: Add video button overlay to ExerciseTransitionWidget**

In `ExerciseTransitionWidget.build()`, find where the exercise image is shown (the `AspectRatio` / `Image.asset` block). Wrap it in a `Stack` and add the video button:

```dart
Stack(
  children: [
    AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          ex.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    ),
    // Show video button if: tutorial mode AND exercise has a video
    // AND it's not the first run (first run shows video prominently below)
    if (!widget.isFirstRun &&
        ex.videoPath != null &&
        !widget.isRoutineMode)
      Positioned(
        bottom: 8,
        right: 8,
        child: GestureDetector(
          onTap: () => _showVideo(context, ex.videoPath!),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: Colors.white70, size: 14),
                SizedBox(width: 4),
                Text(
                  'Video',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
  ],
),
```

Add the `_showVideo` helper method to `_ExerciseTransitionWidgetState`:

```dart
void _showVideo(BuildContext context, String videoPath) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: ExerciseVideoWidget(videoPath: videoPath),
    ),
  );
}
```

Add import for `ExerciseVideoWidget` at the top:

```dart
import 'exercise_video_widget.dart';
```

- [ ] **Step 6: Show video prominently on first run (Tutorial only)**

In the `Column` of `ExerciseTransitionWidget.build()`, after the Stack with the image, add conditionally for first run + tutorial:

```dart
if (widget.isFirstRun && ex.videoPath != null && !widget.isRoutineMode) ...[
  const SizedBox(height: 12),
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: ExerciseVideoWidget(videoPath: ex.videoPath!),
  ),
],
```

- [ ] **Step 7: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/features/training/ lib/core/training/first_run_settings.dart 2>&1 | tail -10
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/training/presentation/widgets/exercise_transition_widget.dart lib/features/training/presentation/screens/immersive_session_screen.dart lib/core/training/first_run_settings.dart
git commit -m "feat: 5s routine countdown, video button, first-run video for Tutorial mode"
```

---

## Task 7: VorrundeStatusSettings + interstitial screen

**Files:**
- Create: `lib/core/training/vorrunde_status_settings.dart`
- Create: `lib/features/training/presentation/screens/vorrunde_interstitial_screen.dart`
- Create: `test/features/training/vorrunde_status_settings_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/training/vorrunde_status_settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corejourney/core/training/vorrunde_status_settings.dart';

void main() {
  group('VorrundeStatusSettings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default status is unseen', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(VorrundeStatusSettings.status(prefs), 'unseen');
    });

    test('setStatus persists value', () async {
      final prefs = await SharedPreferences.getInstance();
      await VorrundeStatusSettings.setStatus(prefs, 'skipped');
      expect(VorrundeStatusSettings.status(prefs), 'skipped');
    });

    test('isUnseen returns true only for unseen', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(VorrundeStatusSettings.isUnseen(prefs), isTrue);
      await VorrundeStatusSettings.setStatus(prefs, 'skipped');
      expect(VorrundeStatusSettings.isUnseen(prefs), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter test test/features/training/vorrunde_status_settings_test.dart 2>&1 | tail -5
```

Expected: compilation error.

- [ ] **Step 3: Implement VorrundeStatusSettings**

Create `lib/core/training/vorrunde_status_settings.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has seen / acted on the Vorrunde interstitial.
/// Values: 'unseen' | 'started' | 'skipped' | 'completed'
class VorrundeStatusSettings {
  static const _key = 'vorrunde_status';

  static String status(SharedPreferences prefs) =>
      prefs.getString(_key) ?? 'unseen';

  static bool isUnseen(SharedPreferences prefs) => status(prefs) == 'unseen';

  static Future<void> setStatus(
          SharedPreferences prefs, String value) =>
      prefs.setString(_key, value);
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter test test/features/training/vorrunde_status_settings_test.dart 2>&1 | tail -5
```

Expected: PASS (3 tests).

- [ ] **Step 5: Implement VorrundeInterstitialScreen**

Create `lib/features/training/presentation/screens/vorrunde_interstitial_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/vorrunde_status_settings.dart';

class VorrundeInterstitialScreen extends StatelessWidget {
  /// Called when the user chooses to start Vorrunde.
  final VoidCallback onStartVorrunde;

  /// Called when the user skips Vorrunde (proceed to package list).
  final VoidCallback onSkip;

  const VorrundeInterstitialScreen({
    super.key,
    required this.onStartVorrunde,
    required this.onSkip,
  });

  Future<void> _handleStart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await VorrundeStatusSettings.setStatus(prefs, 'started');
    onStartVorrunde();
  }

  Future<void> _handleSkip(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await VorrundeStatusSettings.setStatus(prefs, 'skipped');
    onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Bevor du startest',
                style: TextStyle(
                  color: AppColors.textDisabledDark,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vorrunde',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Die Vorrunde bereitet deinen Körper auf das Reflex-Training vor. '
                'Viele Nutzer erleben deutlich stärkere Ergebnisse.',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Primary: start Vorrunde
              GestureDetector(
                onTap: () => _handleStart(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Vorrunde jetzt starten',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'empfohlen',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '4 Wochen · 6 Übungen täglich · ca. 8 Min.',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary: skip
              GestureDetector(
                onTap: () => _handleSkip(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceDarkElevated),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Direkt mit erstem Paket starten',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vorrunde kann jederzeit nachgeholt werden.',
                        style: TextStyle(
                          color: AppColors.textDisabledDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/training/vorrunde_status_settings.dart lib/features/training/presentation/screens/vorrunde_interstitial_screen.dart test/features/training/vorrunde_status_settings_test.dart
git commit -m "feat: Vorrunde status settings + interstitial screen"
```

---

## Task 8: Wire Vorrunde interstitial into packages screen

**Files:**
- Modify: `lib/features/packages/presentation/screens/packages_screen.dart`

The interstitial appears once when the user opens the packages screen and `vorrunde_status == 'unseen'`.

- [ ] **Step 1: Convert PackagesScreen to ConsumerStatefulWidget + load Vorrunde status**

`PackagesScreen` is currently a `ConsumerWidget`. Change the class declaration:

```dart
// Before:
class PackagesScreen extends ConsumerWidget { ... }

// After:
class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});
  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
```

Move the existing `build` body into `_PackagesScreenState.build(BuildContext context, WidgetRef ref)`.

Add state variable and loader:

```dart
class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  bool _vorrundeChecked = false;
  bool _showInterstitial = false;

  @override
  void initState() {
    super.initState();
    _checkVorrunde();
  }

  Future<void> _checkVorrunde() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showInterstitial = VorrundeStatusSettings.isUnseen(prefs);
      _vorrundeChecked = true;
    });
  }
```

Add the necessary imports:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../../training/presentation/screens/vorrunde_interstitial_screen.dart';
import '../../../../core/training/vorrunde_status_settings.dart';
```

- [ ] **Step 2: Show interstitial or package list based on state**

In `build()`, before rendering the package list, add:

```dart
if (!_vorrundeChecked) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

if (_showInterstitial) {
  return VorrundeInterstitialScreen(
    onStartVorrunde: () {
      setState(() => _showInterstitial = false);
      // Navigate to Vorrunde training session
      context.push(Routes.trainingSession,
          extra: const TrainingSessionLaunchArgs(packageId: 'vorrunde'));
    },
    onSkip: () => setState(() => _showInterstitial = false),
  );
}
```

- [ ] **Step 3: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/features/packages/ 2>&1 | tail -10
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/packages/presentation/screens/packages_screen.dart
git commit -m "feat: show Vorrunde interstitial once on first package screen visit"
```

---

## Task 9: Routine tip after 2nd session

**Files:**
- Create: `lib/core/training/routine_tip_settings.dart`
- Modify: `lib/features/training/presentation/screens/training_session_screen.dart`
- Modify: dashboard screen (find via `grep -r "dashboard\|Dashboard" lib/features/home --include="*.dart" -l`)

- [ ] **Step 1: Create RoutineTipSettings**

Create `lib/core/training/routine_tip_settings.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class RoutineTipSettings {
  static const _keyShown = 'routine_tip_shown';
  static const _keyCount = 'completed_session_count';

  static bool tipShown(SharedPreferences prefs) =>
      prefs.getBool(_keyShown) ?? false;

  static int sessionCount(SharedPreferences prefs) =>
      prefs.getInt(_keyCount) ?? 0;

  static Future<void> incrementSessionCount(SharedPreferences prefs) =>
      prefs.setInt(_keyCount, sessionCount(prefs) + 1);

  static Future<void> markTipShown(SharedPreferences prefs) =>
      prefs.setBool(_keyShown, true);

  /// True if tip should be shown: not yet shown + at least 2 sessions done.
  static bool shouldShowTip(SharedPreferences prefs) =>
      !tipShown(prefs) && sessionCount(prefs) >= 2;
}
```

- [ ] **Step 2: Increment session count on session completion**

In `TrainingSessionScreen._handleOutroContinue()`, after the session is saved successfully, add:

```dart
final prefs = await SharedPreferences.getInstance();
await RoutineTipSettings.incrementSessionCount(prefs);
```

Add import:

```dart
import '../../../../core/training/routine_tip_settings.dart';
```

- [ ] **Step 3: Show tip bottom sheet on dashboard**

Find the dashboard screen file:

```bash
grep -rl "dashboard\|Dashboard" /Users/alexandermessinger/dev/claudvibes/reflexjourney/lib/features/home --include="*.dart" | head -3
```

In the dashboard `StatefulWidget`'s `initState`, add a one-shot check after first frame:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoutineTip());
}

Future<void> _checkRoutineTip() async {
  final prefs = await SharedPreferences.getInstance();
  if (!mounted) return;
  if (RoutineTipSettings.shouldShowTip(prefs)) {
    await RoutineTipSettings.markTipShown(prefs);
    if (!mounted) return;
    _showRoutineTip();
  }
}

void _showRoutineTip() {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Du kennst die Übungen jetzt',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Probiere den Routine-Modus — er führt dich komplett '
            'hands-free per Audio durch das Training.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    ),
  );
}
```

Add imports:

```dart
import '../../../../core/training/routine_tip_settings.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 4: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze 2>&1 | grep -E "error|warning" | grep -v "info" | head -20
```

Expected: no new errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/training/routine_tip_settings.dart lib/features/training/presentation/screens/training_session_screen.dart
git add lib/features/home/  # add dashboard file
git commit -m "feat: show Routine-mode tip after 2nd completed session"
```

---

## Task 10: Run all tests + final check

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter test 2>&1 | tail -20
```

Expected: all tests pass.

- [ ] **Step 2: Full flutter analyze**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze --no-fatal-infos 2>&1 | tail -10
```

Expected: "No issues found!" or only pre-existing warnings.

- [ ] **Step 3: Final commit**

```bash
git add -p  # review any remaining unstaged changes
git commit -m "chore: training redesign v2 complete"
```

---

## Content Tasks (out of code scope — must be done before shipping)

These are not code tasks but blockers before the feature is user-facing:

1. **Vorrunde exercise content** — fill in all 6 exercise names, solo and duo instructions in `exercise.dart`
2. **Vorrunde images** — add 6 PNG files to `assets/images/trainings/vorrunde/`
3. **Audio announcement files** — generate ~80–90 MP3 files with ElevenLabs (or equivalent) and place in `assets/sounds/announcements/de/` and `assets/sounds/announcements/de/exercises/`
4. **Binaural music tracks** — source 3 binaural stereo MP3 tracks, replace files in `assets/sounds/music/`, update track names in `in_app_music_service.dart`
