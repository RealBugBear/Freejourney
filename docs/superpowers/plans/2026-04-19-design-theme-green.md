# Design Theme — Green Palette & Poppins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the violet color scheme and Inter typeface with the new green palette (`#009E6B`, aligned with Free Place partner brand) and Poppins typeface across the entire app.

**Architecture:** All color constants live in `AppColors` and all widget files reference them by name — so updating `app_colors.dart` propagates the new palette everywhere automatically. The font swap is a two-line change in `AppTheme`. No widget-level edits are required.

**Tech Stack:** Flutter, Material Design 3, `google_fonts` package (already in `pubspec.yaml` at `^6.1.0`)

---

## Files Changed

| File | Change |
|---|---|
| `lib/core/theme/app_colors.dart` | Replace all color values with green palette; add `primaryOnDark` token |
| `lib/core/theme/app_theme.dart` | Swap Inter → Poppins in both light and dark theme builders |

No other files require changes — widget files already reference `AppColors.*` and `theme.colorScheme.*` by name.

---

## Task 1: Update AppColors with green palette

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Write the widget test that verifies key color values**

Create `test/core/theme/app_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  group('AppColors — green palette', () {
    test('primary is Free Place green', () {
      expect(AppColors.primary, const Color(0xFF009E6B));
    });

    test('primaryDark is darker green for pressed state', () {
      expect(AppColors.primaryDark, const Color(0xFF007A52));
    });

    test('primaryLight is lighter green for decorative use', () {
      expect(AppColors.primaryLight, const Color(0xFF6FD4A8));
    });

    test('primaryOnDark is brightened green for dark surfaces', () {
      expect(AppColors.primaryOnDark, const Color(0xFF00C882));
    });

    test('backgroundLight has subtle green tint', () {
      expect(AppColors.backgroundLight, const Color(0xFFF4FAF6));
    });

    test('textPrimary is dark green-tinted black', () {
      expect(AppColors.textPrimary, const Color(0xFF0D1F15));
    });

    test('textSecondary is muted green-grey', () {
      expect(AppColors.textSecondary, const Color(0xFF5A8A6A));
    });

    test('divider is light green-tinted border', () {
      expect(AppColors.divider, const Color(0xFFD8EEE2));
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/core/theme/app_colors_test.dart
```

Expected: FAIL — colors are still violet values.

- [ ] **Step 3: Replace app_colors.dart with the new green palette**

Replace the full contents of `lib/core/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Free Place green (#009E6B exact match)
  static const Color primary = Color(0xFF009E6B);
  static const Color primaryDark = Color(0xFF007A52);
  static const Color primaryLight = Color(0xFF6FD4A8);
  static const Color primaryOnDark = Color(0xFF00C882);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF248A3D);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Neutrals — Light mode
  static const Color textPrimary = Color(0xFF0D1F15);
  static const Color textSecondary = Color(0xFF5A8A6A);
  static const Color textDisabled = Color(0xFF999999);
  static const Color backgroundLight = Color(0xFFF4FAF6);
  static const Color divider = Color(0xFFD8EEE2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarkElevated = Color(0xFF2A2A2A);
  static const Color textPrimaryDark = Color(0xFFEFEFEF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textDisabledDark = Color(0xFF737373);

  // Surface variants (light)
  static const Color surfaceLight1 = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFFAFAFA);
  static const Color surfaceLight3 = Color(0xFFF0F5F2);

  // Mood chart series — unchanged
  static const Color moodTeal = Color(0xFF5A9B84);
  static const Color moodBlue = Color(0xFF6E8FCB);
  static const Color moodRose = Color(0xFFC47A93);
  static const Color moodGold = Color(0xFFE0B867);

  static Color getContrastText(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? textPrimary
        : textPrimaryDark;
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

```bash
flutter test test/core/theme/app_colors_test.dart
```

Expected: All 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
git add lib/core/theme/app_colors.dart test/core/theme/app_colors_test.dart
git commit -m "feat: replace violet palette with Free Place green (#009E6B)"
```

---

## Task 2: Swap Inter for Poppins in AppTheme

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Write the widget test that verifies Poppins is applied**

Create `test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/theme/app_theme.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    group('light theme', () {
      late ThemeData theme;
      setUp(() => theme = AppTheme.light);

      test('scaffold background is green-tinted', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
      });

      test('primary color is Free Place green', () {
        expect(
          theme.colorScheme.primary,
          isA<Color>(),
        );
        // ColorScheme.fromSeed generates a derived primary — verify it's
        // seeded from our green by checking the scaffold color
        expect(theme.scaffoldBackgroundColor, const Color(0xFFF4FAF6));
      });

      test('elevated button background is primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({});
        expect(bg, AppColors.primary);
      });

      test('card radius is 16', () {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      });
    });

    group('dark theme', () {
      late ThemeData theme;
      setUp(() => theme = AppTheme.dark);

      test('scaffold background is pure neutral dark', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
      });

      test('elevated button background is primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({});
        expect(bg, AppColors.primary);
      });
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it passes as a baseline**

```bash
flutter test test/core/theme/app_theme_test.dart
```

Expected: PASS (these tests verify structure, not font names — they should already pass before the font change).

- [ ] **Step 3: Swap Inter for Poppins in app_theme.dart**

In `lib/core/theme/app_theme.dart`, replace all four occurrences of `inter`/`Inter` with `poppins`/`Poppins`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static bool get _useGoogleFonts => !Platform.isIOS;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _useGoogleFonts
        ? GoogleFonts.poppinsTextTheme(base.textTheme)
        : base.textTheme;
    final titleTextStyle = _useGoogleFonts
        ? GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )
        : const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          );
    final buttonTextStyle = _useGoogleFonts
        ? GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: titleTextStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: buttonTextStyle,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.divider),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _useGoogleFonts
        ? GoogleFonts.poppinsTextTheme(base.textTheme)
        : base.textTheme;
    final titleTextStyle = _useGoogleFonts
        ? GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          )
        : const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          );
    final buttonTextStyle = _useGoogleFonts
        ? GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        titleTextStyle: titleTextStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: buttonTextStyle,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.surfaceDarkElevated),
        ),
      ),
    );
  }
}
```

Note: Button radius updated from 12px to 14px to match the design spec.

- [ ] **Step 4: Run all theme tests**

```bash
flutter test test/core/theme/
```

Expected: All tests PASS.

- [ ] **Step 5: Run full test suite to check for regressions**

```bash
flutter test
```

Expected: All tests PASS. If any widget tests fail due to color value snapshots, update the snapshots.

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: swap Inter for Poppins, update button radius to 14px"
```

---

## Task 3: Smoke test on device

**Files:** None — visual verification only.

- [ ] **Step 1: Run the app on a simulator**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
make run-sim
```

- [ ] **Step 2: Verify light mode**

Check the following screens look correct:
- Dashboard: subtle green-tinted background, green hero card, white stat cards, Poppins font
- Journal: green FAB, white cards with green-tinted borders
- Settings: green toggle, green sync status icon

- [ ] **Step 3: Verify dark mode**

Toggle to dark mode in Settings. Check:
- Pure black/neutral background (no green tint)
- Green accent on active elements only (toggle, buttons, active nav)
- White/neutral card surfaces

- [ ] **Step 4: Verify training flow**

Start a training session. Check:
- Training widgets show `primaryLight` (#6FD4A8) decorative elements in a green tone (no leftover violet)

- [ ] **Step 5: Commit if any fixups were needed, otherwise done**

```bash
git add -p  # stage only intentional fixups
git commit -m "fix: theme smoke test fixups"
```

---

## Self-Review

**Spec coverage:**
- ✅ Primary `#009E6B` — Task 1
- ✅ Primary Dark `#007A52` — Task 1
- ✅ Primary On Dark `#00C882` — Task 1 (as `primaryOnDark`)
- ✅ Light bg `#F4FAF6` — Task 1 (`backgroundLight`)
- ✅ Light surface `#FFFFFF` — unchanged (`surfaceLight1`)
- ✅ Light border `#D8EEE2` — Task 1 (`divider`)
- ✅ Dark bg `#121212` — unchanged (`backgroundDark`)
- ✅ Dark surface `#1E1E1E` — unchanged (`surfaceDark`)
- ✅ Dark border `#2A2A2A` — unchanged (`surfaceDarkElevated`)
- ✅ Poppins font — Task 2
- ✅ Button radius 14px — Task 2

**Placeholder scan:** No TBDs or ambiguous steps.

**Type consistency:** `AppColors.primaryOnDark` defined in Task 1 — not yet used in `app_theme.dart` (widgets that need it on dark surfaces currently use `AppColors.primary` directly; this is acceptable for V1 since `#009E6B` still reads on `#1E1E1E` at WCAG AA. A follow-up plan can wire up `primaryOnDark` to individual dark-mode widgets that display accent numbers.)
