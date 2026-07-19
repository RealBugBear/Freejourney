import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/l10n/localized_content.dart';

void main() {
  test('German picks the German variant', () {
    expect(pickLocalized('de', de: 'Halten', en: 'Hold'), 'Halten');
  });
  test('English picks the English variant', () {
    expect(pickLocalized('en', de: 'Halten', en: 'Hold'), 'Hold');
  });
  test('unknown locales resolve like the international default (English)', () {
    expect(pickLocalized('fr', de: 'Halten', en: 'Hold'), 'Hold');
  });
  test('works for non-string content', () {
    expect(pickLocalized<List<String>>('de', de: ['a'], en: ['b']), ['a']);
  });
}
