# Remote Exercise Media Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `image_url`, `duo_image_url`, and `video_url` fields to the exercise data pipeline so professional content (hosted in Supabase Storage) flows into the app without code changes.

**Architecture:** Add nullable URL columns to both Supabase and the local Drift cache. A shared `ExerciseImageWidget` resolves URL-or-asset so all 6+ image display sites change in one place. `ExerciseVideoWidget` tries network URL first, falls back to bundled asset. After the Drift v8 migration the exercises table is dropped+recreated to force a clean sync that fetches the new URL columns.

**Tech Stack:** Flutter/Dart, Drift (SQLite), Supabase Postgres + Storage, `video_player ^2.9.1`, `cached_network_image ^3.3.1` (new dep), `flutter_cache_manager ^3.4.1` (already present)

---

## File Map

| Action | Path |
|--------|------|
| Create | `supabase/migrations/20260530_exercise_media_urls.sql` |
| Modify | `lib/core/database/tables/exercises_table.dart` |
| Modify | `lib/core/database/app_database.dart` |
| Modify | `lib/features/training/domain/models/exercise.dart` |
| Modify | `lib/core/sync/exercises_sync_service.dart` |
| Modify | `pubspec.yaml` |
| Create | `lib/features/training/presentation/widgets/exercise_image_widget.dart` |
| Modify | `lib/features/training/presentation/widgets/exercise_video_widget.dart` |
| Modify | `lib/features/training/presentation/widgets/exercise_position_widget.dart` |
| Modify | `lib/features/training/presentation/widgets/training_intro_widget.dart` |
| Modify | `lib/features/training/presentation/widgets/exercise_transition_widget.dart` |
| Modify | `lib/features/training/presentation/screens/training_movement_screen.dart` |
| Modify | `lib/features/training/presentation/screens/training_position_screen.dart` |
| Modify | `lib/features/training/presentation/screens/training_exercise_screen.dart` |

---

## Task 1: Supabase migration — columns + storage bucket

**Files:**
- Create: `supabase/migrations/20260530_exercise_media_urls.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260530_exercise_media_urls.sql
-- Add remote media URL columns to exercises table.
-- Also adds duo_image_path which was modelled in Dart but missing from DB.
-- Creates the exercise-media storage bucket for uploaded professional content.

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS duo_image_path  TEXT;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS image_url       TEXT;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS duo_image_url   TEXT;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS video_url       TEXT;

-- Public read-only storage bucket for exercise media (images + videos).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'exercise-media',
  'exercise-media',
  true,
  524288000,  -- 500 MB per file
  ARRAY['image/jpeg','image/png','image/webp','video/mp4','video/quicktime','video/webm']
)
ON CONFLICT (id) DO NOTHING;

-- Allow anyone (anon + authenticated) to read from the bucket.
DROP POLICY IF EXISTS "exercise-media public read" ON storage.objects;
CREATE POLICY "exercise-media public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'exercise-media');

-- Verification
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'exercises'
  AND column_name IN ('duo_image_path', 'image_url', 'duo_image_url', 'video_url')
ORDER BY column_name;
```

- [ ] **Step 2: Run the migration against the live Supabase project**

Go to the Supabase dashboard → SQL Editor, paste and run the migration. Verify the output shows 4 rows (one per new column).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260530_exercise_media_urls.sql
git commit -m "feat: add remote media URL columns and exercise-media storage bucket"
```

---

## Task 2: Drift table — add new columns

**Files:**
- Modify: `lib/core/database/tables/exercises_table.dart`

- [ ] **Step 1: Add the four new columns to ExercisesTable**

In `lib/core/database/tables/exercises_table.dart`, replace the `// ── Assets` section:

```dart
  // ── Assets ──────────────────────────────────────────────────────────────────
  TextColumn get imagePath => text()();
  TextColumn get duoImagePath => text().nullable()();
  TextColumn get videoPath => text().nullable()();
  TextColumn get audioCuePath => text().nullable()();

  // Remote media (Supabase Storage). Null = use bundled asset above.
  TextColumn get imageUrl => text().nullable()();
  TextColumn get duoImageUrl => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
```

- [ ] **Step 2: Bump schemaVersion and add migration in app_database.dart**

In `lib/core/database/app_database.dart`, change `schemaVersion` from `7` to `8`, then add this block inside `onUpgrade`:

```dart
          if (from < 8) {
            // Drop and recreate exercises table so the next syncIfNeeded()
            // fetches fresh rows including the new URL columns.
            await m.deleteTable('exercises');
            await m.createTable(exercisesTable);
          }
```

- [ ] **Step 3: Rebuild Drift generated code**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
dart run build_runner build --delete-conflicting-outputs
```

Expected: no errors, `app_database.g.dart` regenerated.

- [ ] **Step 4: Commit**

```bash
git add lib/core/database/tables/exercises_table.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart
git commit -m "feat: drift v8 — add remote media URL columns to exercises table"
```

---

## Task 3: Exercise model — add URL fields + helpers

**Files:**
- Modify: `lib/features/training/domain/models/exercise.dart`

- [ ] **Step 1: Add three new fields to the Exercise class**

After `final String? duoImagePath;` (line 43), add:

```dart
  final String? imageUrl;
  final String? duoImageUrl;
  final String? videoUrl;
```

- [ ] **Step 2: Add the three fields to the constructor**

After `this.duoImagePath,` in the constructor, add:

```dart
    this.imageUrl,
    this.duoImageUrl,
    this.videoUrl,
```

- [ ] **Step 3: Add URL-aware helper methods**

After the existing `imagePathFor` method, add:

```dart
  /// Returns the remote image URL for this exercise.
  /// Prefers duo URL when [duo] is true and one is available.
  String? imageUrlFor({bool duo = false}) {
    if (duo && duoImageUrl != null && duoImageUrl!.isNotEmpty) {
      return duoImageUrl;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    return null;
  }
```

- [ ] **Step 4: Update Exercise.fromRow() to read the new columns**

After `duoImagePath: row['duo_image_path'] as String?,` in `fromRow`, add:

```dart
      imageUrl: row['image_url'] as String?,
      duoImageUrl: row['duo_image_url'] as String?,
      videoUrl: row['video_url'] as String?,
```

- [ ] **Step 5: Verify the app compiles**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/training/domain/models/exercise.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/training/domain/models/exercise.dart
git commit -m "feat: add imageUrl, duoImageUrl, videoUrl fields to Exercise model"
```

---

## Task 4: ExercisesSyncService — cache new fields

**Files:**
- Modify: `lib/core/sync/exercises_sync_service.dart`

- [ ] **Step 1: Add four new fields to the ExercisesTableCompanion.insert call**

In `_fetchAndCache()`, after `videoPath: Value(row['video_path'] as String?),`, add:

```dart
            duoImagePath: Value(row['duo_image_path'] as String?),
            imageUrl: Value(row['image_url'] as String?),
            duoImageUrl: Value(row['duo_image_url'] as String?),
            videoUrl: Value(row['video_url'] as String?),
```

- [ ] **Step 2: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/core/sync/exercises_sync_service.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/sync/exercises_sync_service.dart
git commit -m "feat: sync remote media URL columns from Supabase into Drift cache"
```

---

## Task 5: Add cached_network_image dep + create ExerciseImageWidget

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/training/presentation/widgets/exercise_image_widget.dart`

- [ ] **Step 1: Add cached_network_image to pubspec.yaml**

In `pubspec.yaml`, under the `video_player` line, add:

```yaml
  cached_network_image: ^3.3.1
```

Then run:

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter pub get
```

Expected: resolves without conflicts.

- [ ] **Step 2: Create ExerciseImageWidget**

Create `lib/features/training/presentation/widgets/exercise_image_widget.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/models/exercise.dart';

/// Resolves the correct image source for an exercise:
/// prefers the remote Supabase Storage URL when available,
/// falls back to the bundled local asset otherwise.
class ExerciseImageWidget extends StatelessWidget {
  final Exercise exercise;
  final bool isDuo;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ExerciseImageWidget({
    super.key,
    required this.exercise,
    this.isDuo = false,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final url = exercise.imageUrlFor(duo: isDuo);
    final localPath = exercise.imagePathFor(duo: isDuo);

    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => Image.asset(localPath, fit: fit,
            width: width, height: height),
        errorWidget: (_, __, ___) => Image.asset(localPath, fit: fit,
            width: width, height: height),
      );
    }

    return Image.asset(localPath, fit: fit, width: width, height: height);
  }
}
```

- [ ] **Step 3: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/training/presentation/widgets/exercise_image_widget.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/training/presentation/widgets/exercise_image_widget.dart
git commit -m "feat: add ExerciseImageWidget with URL-or-asset resolution"
```

---

## Task 6: Update ExerciseVideoWidget for network video

**Files:**
- Modify: `lib/features/training/presentation/widgets/exercise_video_widget.dart`

- [ ] **Step 1: Add import for ExerciseImageWidget at the top**

After the existing imports, add:

```dart
import 'exercise_image_widget.dart';
```

- [ ] **Step 2: Replace _initVideo() to try network URL first**

Replace the entire `_initVideo()` method with:

```dart
  Future<void> _initVideo() async {
    final videoUrl = widget.exercise.videoUrl;
    final videoPath = widget.exercise.videoPath;

    if (videoUrl == null && videoPath == null) {
      setState(() => _videoFailed = true);
      return;
    }

    try {
      final controller = videoUrl != null
          ? VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          : VideoPlayerController.asset(videoPath!);
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initialized = true;
      });

      controller.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }
```

- [ ] **Step 3: Update _buildVideoArea() condition and fallback images**

Replace the `_buildVideoArea()` method with:

```dart
  Widget _buildVideoArea() {
    final hasVideo = widget.exercise.videoUrl != null ||
        widget.exercise.videoPath != null;

    if (_videoFailed || !hasVideo) {
      return _FallbackImage(exercise: widget.exercise);
    }

    if (!_initialized || _controller == null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ExerciseImageWidget(exercise: widget.exercise, fit: BoxFit.cover),
          Container(color: Colors.black54),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          AnimatedOpacity(
            opacity: _isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                backgroundColor: Colors.white24,
                bufferedColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Update _FallbackImage to use ExerciseImageWidget**

Replace the `_FallbackImage` class with:

```dart
class _FallbackImage extends StatelessWidget {
  final Exercise exercise;
  const _FallbackImage({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ExerciseImageWidget(exercise: exercise, fit: BoxFit.contain),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
        const Positioned(
          bottom: 16,
          child: Text(
            'Video wird vorbereitet...',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Verify compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/training/presentation/widgets/exercise_video_widget.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/training/presentation/widgets/exercise_video_widget.dart
git commit -m "feat: ExerciseVideoWidget loads video from network URL with local asset fallback"
```

---

## Task 7: Update remaining 6 image display sites

**Files:**
- Modify: `lib/features/training/presentation/widgets/exercise_position_widget.dart`
- Modify: `lib/features/training/presentation/widgets/training_intro_widget.dart`
- Modify: `lib/features/training/presentation/widgets/exercise_transition_widget.dart`
- Modify: `lib/features/training/presentation/screens/training_movement_screen.dart`
- Modify: `lib/features/training/presentation/screens/training_position_screen.dart`
- Modify: `lib/features/training/presentation/screens/training_exercise_screen.dart`

### exercise_position_widget.dart (line 43)

- [ ] **Step 1: Add import + replace Image.asset**

Add import at top:
```dart
import 'exercise_image_widget.dart';
```

Replace `Image.asset(exercise.imagePath, fit: BoxFit.contain)` at line 43 with:
```dart
ExerciseImageWidget(exercise: exercise, fit: BoxFit.contain)
```

### training_intro_widget.dart (line 65–68)

- [ ] **Step 2: Add import + replace Image.asset**

Add import:
```dart
import 'exercise_image_widget.dart';
```

Replace:
```dart
Image.asset(
  exercise.imagePathFor(duo: isDuo),
  fit: BoxFit.contain,
)
```
with:
```dart
ExerciseImageWidget(
  exercise: exercise,
  isDuo: isDuo,
  fit: BoxFit.contain,
)
```

### exercise_transition_widget.dart (lines 110–119 and line 122)

- [ ] **Step 3: Add import + replace Image.asset + fix video button condition**

Add import:
```dart
import 'exercise_image_widget.dart';
```

Replace the `Image.asset(ex.imagePathFor(duo: widget.isDuo), fit: BoxFit.cover, errorBuilder: ...)` block (lines 110–119) with:
```dart
ExerciseImageWidget(
  exercise: ex,
  isDuo: widget.isDuo,
  fit: BoxFit.cover,
)
```

On the video button visibility condition (line 122), update:
```dart
// Before:
if (!widget.isFirstRun && ex.videoPath != null && !widget.isRoutineMode)
// After:
if (!widget.isFirstRun &&
    (ex.videoPath != null || ex.videoUrl != null) &&
    !widget.isRoutineMode)
```

### training_movement_screen.dart (line 94–101)

- [ ] **Step 4: Add import + replace Image.asset**

Add import:
```dart
import '../widgets/exercise_image_widget.dart';
```

Replace:
```dart
Image.asset(
  exercise.imagePath,
  width: 140,
  height: 140,
  fit: BoxFit.contain,
  semanticLabel: 'Referenzbild für Übung ${exercise.exerciseNumber}',
  errorBuilder: (context, error, stackTrace) {
    return Container(
      width: 140,
      height: 140,
      ...
    );
  },
)
```
with:
```dart
ExerciseImageWidget(
  exercise: exercise,
  width: 140,
  height: 140,
  fit: BoxFit.contain,
)
```

(The `errorBuilder` is not needed — `ExerciseImageWidget` already falls back to the local asset on network error.)

### training_position_screen.dart (lines 91–108)

- [ ] **Step 5: Add import + replace Image.asset**

Add import:
```dart
import '../widgets/exercise_image_widget.dart';
```

Replace:
```dart
Image.asset(
  exercise.imagePath,
  width: 260,
  height: 260,
  fit: BoxFit.contain,
  semanticLabel: 'Übungsbild für Übung ${exercise.exerciseNumber}',
  errorBuilder: (context, error, stackTrace) {
    return Container(
      width: 260,
      height: 260,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported, ...),
    );
  },
)
```
with:
```dart
ExerciseImageWidget(
  exercise: exercise,
  width: 260,
  height: 260,
  fit: BoxFit.contain,
)
```

### training_exercise_screen.dart (lines 335–348)

- [ ] **Step 6: Add import + replace Image.asset**

Add import (near other widget imports):
```dart
import '../widgets/exercise_image_widget.dart';
```

Replace:
```dart
Image.asset(
  exercise.imagePath,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(Icons.image_not_supported_outlined, ...),
  ),
)
```
with:
```dart
ExerciseImageWidget(exercise: exercise, fit: BoxFit.cover)
```

- [ ] **Step 7: Verify all 6 files compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze \
  lib/features/training/presentation/widgets/exercise_position_widget.dart \
  lib/features/training/presentation/widgets/training_intro_widget.dart \
  lib/features/training/presentation/widgets/exercise_transition_widget.dart \
  lib/features/training/presentation/screens/training_movement_screen.dart \
  lib/features/training/presentation/screens/training_position_screen.dart \
  lib/features/training/presentation/screens/training_exercise_screen.dart
```

Expected: no errors.

- [ ] **Step 8: Full analyze pass**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/
```

Expected: no new errors introduced.

- [ ] **Step 9: Commit**

```bash
git add \
  lib/features/training/presentation/widgets/exercise_position_widget.dart \
  lib/features/training/presentation/widgets/training_intro_widget.dart \
  lib/features/training/presentation/widgets/exercise_transition_widget.dart \
  lib/features/training/presentation/screens/training_movement_screen.dart \
  lib/features/training/presentation/screens/training_position_screen.dart \
  lib/features/training/presentation/screens/training_exercise_screen.dart
git commit -m "feat: all exercise image displays use ExerciseImageWidget (URL-or-asset)"
```

---

## How to populate content once the professional delivers

After the professional delivers files:

1. Upload images/videos to Supabase Storage → bucket `exercise-media`
   - Path convention: `exercises/{exercise_id}/image.jpg`, `exercises/{exercise_id}/duo_image.jpg`, `exercises/{exercise_id}/video.mp4`
   - The public URL will be: `https://sxvpiggednbftfqeokyd.supabase.co/storage/v1/object/public/exercise-media/exercises/{exercise_id}/image.jpg`

2. Update the exercises rows in Supabase:
   ```sql
   UPDATE exercises SET
     image_url = 'https://sxvpiggednbftfqeokyd.supabase.co/storage/v1/object/public/exercise-media/exercises/vorrunde_ex1/image.jpg',
     video_url  = 'https://sxvpiggednbftfqeokyd.supabase.co/storage/v1/object/public/exercise-media/exercises/vorrunde_ex1/video.mp4'
   WHERE id = 'vorrunde_ex1';
   -- repeat for each exercise
   ```

3. On next app start, `syncIfNeeded()` will fetch fresh exercises (the Drift v8 migration dropped the cache) and the URLs will appear automatically — no app update required.

For vorrunde exercises, also fill in the text content (positionInstructions, movementInstructions, executionGuide) in the same UPDATE statement.
