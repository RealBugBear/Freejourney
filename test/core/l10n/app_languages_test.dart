import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/l10n/app_languages.dart';

void main() {
  test('registry lists German first and English second', () {
    expect(AppLanguages.all.map((l) => l.code).toList(), ['de', 'en']);
    expect(AppLanguages.sourceCode, 'de');
  });

  test('locales derive from the registry', () {
    expect(AppLanguages.locales, const [Locale('de'), Locale('en')]);
  });

  test('isSupported accepts registry codes only', () {
    expect(AppLanguages.isSupported('de'), isTrue);
    expect(AppLanguages.isSupported('en'), isTrue);
    expect(AppLanguages.isSupported('fr'), isFalse);
    expect(AppLanguages.isSupported(null), isFalse);
  });

  test('resolveInitial: supported device language wins, otherwise English', () {
    expect(AppLanguages.resolveInitial('de'), 'de');
    expect(AppLanguages.resolveInitial('en'), 'en');
    expect(AppLanguages.resolveInitial('fr'), 'en');
    expect(AppLanguages.resolveInitial(''), 'en');
  });

  test('normalize falls back to the source language', () {
    expect(AppLanguages.normalize('en'), 'en');
    expect(AppLanguages.normalize('xx'), 'de');
    expect(AppLanguages.normalize(null), 'de');
  });

  test('byCode returns the registry entry', () {
    expect(AppLanguages.byCode('en').autonym, 'English');
    expect(AppLanguages.byCode('de').flagEmoji, '🇩🇪');
  });
}
