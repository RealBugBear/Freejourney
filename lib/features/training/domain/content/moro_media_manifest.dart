/// Local media contract for the released Moro exercise sequence.
///
/// Videos are intentionally absent: `pubspec.yaml` does not bundle the legacy
/// video folders. A validated HTTPS URL may be added as a runtime overlay by
/// the content resolver, but must never replace this offline contract.
class MoroExerciseMedia {
  const MoroExerciseMedia({
    required this.exerciseId,
    required this.bundledImagePath,
  });

  final String exerciseId;
  final String? bundledImagePath;

  /// No Moro video is currently bundled with the app.
  String? get bundledVideoPath => null;
}

const moroExercise1ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_05.png';
const moroExercise2ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_03.png';
const moroExercise3ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_04.png';
const moroExercise4ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_01.png';
const moroExercise5ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_02.png';
const moroExercise6ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_06.png';
const moroExercise7ImagePath =
    'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_07.png';

const List<MoroExerciseMedia> moroMediaManifest = [
  MoroExerciseMedia(
    exerciseId: 'moro_ex1',
    bundledImagePath: moroExercise1ImagePath,
  ),
  MoroExerciseMedia(
    exerciseId: 'moro_ex2',
    bundledImagePath: moroExercise2ImagePath,
  ),
  MoroExerciseMedia(
    exerciseId: 'moro_ex3',
    bundledImagePath: moroExercise3ImagePath,
  ),
  MoroExerciseMedia(
    exerciseId: 'moro_ex4',
    bundledImagePath: moroExercise4ImagePath,
  ),
  MoroExerciseMedia(
    exerciseId: 'moro_ex5',
    bundledImagePath: moroExercise5ImagePath,
  ),
  MoroExerciseMedia(
    exerciseId: 'moro_ex6',
    bundledImagePath: moroExercise6ImagePath,
  ),
  MoroExerciseMedia(
    exerciseId: 'moro_ex7',
    bundledImagePath: moroExercise7ImagePath,
  ),
];

MoroExerciseMedia? moroMediaForExercise(String exerciseId) {
  for (final media in moroMediaManifest) {
    if (media.exerciseId == exerciseId) return media;
  }
  return null;
}
