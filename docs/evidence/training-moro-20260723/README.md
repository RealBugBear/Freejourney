# Training Moro – Responsive & Accessibility Evidence

Deterministic widget screenshots for the redesigned training flow.

- Surface sizes: 390 × 844 portrait and 844 × 390 landscape
- Text scaling: screenshots at 200%; operability/overflow assertions at 100%,
  150%, and 200%
- Motion settings: animations disabled and accessible navigation enabled
- Locales/states: DE learning intro, EN routine preparation, DE active
  movement, EN paused routine
- Captures: intro top, transition top and preparation action/exit area, active
  movement top and full-width control area, paused landscape cue
- Large-text reflow: immersive landscape switches to the vertical flow and
  tempo controls stack instead of splitting German labels across lines
- Voluntary controls: repeat guidance and exit session remain explicit,
  full-width, single-line, and at least 48 px high at large text sizes;
  transition and paused-state exit controls receive the same operability checks
- Source test:
  `test/features/training/presentation/widgets/training_responsive_accessibility_test.dart`

The evidence harness loads Roboto and Material Icons from the active Flutter
SDK so text and controls remain readable in screenshots. It also waits for
bundled exercise images to decode before capture.

Generate or refresh the screenshots:

```sh
flutter test \
  test/features/training/presentation/widgets/training_responsive_accessibility_test.dart \
  --plain-name "deterministic screenshot evidence" \
  --update-goldens
```

The screenshots are regression baselines, not a replacement for the semantic,
interaction, minimum-target-size, reduced-motion, and overflow assertions in
the same test file.
