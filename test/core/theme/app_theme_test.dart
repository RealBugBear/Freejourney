import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corejourney/core/theme/app_theme.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme', () {
    group('light theme', () {
      late ThemeData theme;

      setUpAll(() async {
        // GoogleFonts raises async exceptions when fonts aren't found and
        // allowRuntimeFetching is false. We suppress them since we're testing
        // theme structure, not font loading.
        await runZonedGuarded(
          () async {
            theme = AppTheme.light;
            // Yield to allow async errors to surface
            await Future.delayed(Duration.zero);
          },
          (Object e, StackTrace st) {},
        );
        // If there was an error, we still have the theme, so we ignore it.
      });

      test('scaffold background is green-tinted', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
      });

      test('scaffold background hex matches design spec', () {
        expect(theme.scaffoldBackgroundColor, const Color(0xFFF4FAF6));
      });

      test('elevated button background is primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({});
        expect(bg, AppColors.primary);
      });

      test('elevated button foreground is contrast-safe on primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final fg = style.foregroundColor?.resolve({});
        expect(fg, AppColors.textPrimary);
      });

      test('filled button foreground is contrast-safe on primary green', () {
        final style = theme.filledButtonTheme.style!;
        final fg = style.foregroundColor?.resolve({});
        expect(fg, AppColors.textPrimary);
      });

      test('color scheme onPrimary is contrast-safe on primary green', () {
        expect(theme.colorScheme.onPrimary, AppColors.textPrimary);
      });

      test('elevated button radius is 14', () {
        final style = theme.elevatedButtonTheme.style!;
        final shape = style.shape?.resolve({}) as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(14));
      });

      test('card radius is 16', () {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      });

      test('app bar background is green-tinted', () {
        expect(theme.appBarTheme.backgroundColor, AppColors.backgroundLight);
      });
    });

    group('dark theme', () {
      late ThemeData theme;

      setUpAll(() async {
        // GoogleFonts raises async exceptions when fonts aren't found and
        // allowRuntimeFetching is false. We suppress them since we're testing
        // theme structure, not font loading.
        await runZonedGuarded(
          () async {
            theme = AppTheme.dark;
            // Yield to allow async errors to surface
            await Future.delayed(Duration.zero);
          },
          (Object e, StackTrace st) {},
        );
        // If there was an error, we still have the theme, so we ignore it.
      });

      test('scaffold background is pure neutral dark', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
      });

      test('elevated button background is primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({});
        expect(bg, AppColors.primary);
      });

      test('elevated button foreground is contrast-safe on primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final fg = style.foregroundColor?.resolve({});
        expect(fg, AppColors.textPrimary);
      });

      test('filled button foreground is contrast-safe on primary green', () {
        final style = theme.filledButtonTheme.style!;
        final fg = style.foregroundColor?.resolve({});
        expect(fg, AppColors.textPrimary);
      });

      test('color scheme onPrimary is contrast-safe on primary green', () {
        expect(theme.colorScheme.onPrimary, AppColors.textPrimary);
      });

      test('elevated button radius is 14', () {
        final style = theme.elevatedButtonTheme.style!;
        final shape = style.shape?.resolve({}) as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(14));
      });

      test('app bar background is dark', () {
        expect(theme.appBarTheme.backgroundColor, AppColors.backgroundDark);
      });

      test('card surface is dark', () {
        expect(theme.cardTheme.color, AppColors.surfaceDark);
      });
    });
  });
}
