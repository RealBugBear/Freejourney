import 'package:corejourney/core/training/training_announcement_manifest.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled manifest is the exact 48-event DE/EN recording contract',
      () async {
    final manifest = await TrainingAnnouncementManifest.loadBundled();
    final expectedIds = _fullRuntimeEventIds();

    expect(manifest.schemaVersion, 1);
    expect(manifest.contentVersion, 'moro-2026.07.23-v1');
    expect(manifest.defaultLocale, 'de');
    expect(manifest.locales.keys, unorderedEquals(['de', 'en']));
    expect(_recordingScript, hasLength(48));
    expect(expectedIds, hasLength(48));
    expect(_recordingScript.keys, unorderedEquals(expectedIds));

    for (final locale in const ['de', 'en']) {
      final entries = manifest.catalogFor(locale).entries;
      expect(entries, hasLength(48), reason: '$locale entry count');
      expect(entries.keys, unorderedEquals(expectedIds));

      for (final MapEntry(key: id, value: script) in _recordingScript.entries) {
        final entry = entries[id];
        expect(entry, isNotNull, reason: '$locale missing $id');
        expect(
          entry!.spokenText,
          locale == 'de' ? script.de : script.en,
          reason: '$locale spokenText drift for $id',
        );
        expect(
          entry.spokenText.trim(),
          entry.spokenText,
          reason: '$locale surrounding whitespace for $id',
        );
        expect(
          entry.assetKey,
          isNull,
          reason: '$locale $id must stay gated until recorded and approved',
        );
      }
    }
  });

  test('locale resolution is exact, base-language aware, and deterministic',
      () async {
    final manifest = await TrainingAnnouncementManifest.loadBundled();

    expect(manifest.resolveLocale('de-AT'), 'de');
    expect(manifest.resolveLocale('EN_us'), 'en');
    expect(manifest.resolveLocale('fr-FR'), 'de');
    expect(manifest.resolveLocale(null), 'de');
  });

  test('full-catalog preflight reports all 48 entries unassigned per locale',
      () async {
    final manifest = await TrainingAnnouncementManifest.loadBundled();

    for (final locale in const ['de', 'en']) {
      var probes = 0;
      final report = await manifest.preflight(
        requestedLocale: locale,
        assetExists: (_) async {
          probes += 1;
          return true;
        },
      );

      expect(report.locale, locale);
      expect(report.isReady, isFalse);
      expect(report.unassignedEntryIds, hasLength(48));
      expect(
        report.unassignedEntryIds,
        unorderedEquals(_recordingScript.keys),
      );
      expect(report.availableAssetKeys, isEmpty);
      expect(report.invalidAssetKeys, isEmpty);
      expect(report.missingAssetKeys, isEmpty);
      expect(report.missingEntryIds, isEmpty);
      expect(probes, 0, reason: 'null assetKey must never probe a fake file');
    }
  });

  test('solo and duo runtime scopes each require exactly 41 gated events',
      () async {
    final manifest = await TrainingAnnouncementManifest.loadBundled();

    for (final isDuo in [false, true]) {
      final requiredIds = _sessionRuntimeEventIds(isDuo: isDuo);
      expect(requiredIds, hasLength(41));
      expect(_recordingScript.keys, containsAll(requiredIds));

      for (final locale in const ['de', 'en']) {
        final report = await manifest.preflight(
          requestedLocale: locale,
          requiredEntryIds: requiredIds,
          assetExists: (_) async => true,
        );
        expect(report.isReady, isFalse);
        expect(report.unassignedEntryIds, hasLength(41));
        expect(report.unassignedEntryIds, unorderedEquals(requiredIds));
        expect(report.missingEntryIds, isEmpty);
      }
    }
  });

  test('preflight separates missing entries, invalid keys, and absent files',
      () async {
    final manifest = TrainingAnnouncementManifest.fromJsonString(r'''
      {
        "schemaVersion": 1,
        "contentVersion": "test.1",
        "defaultLocale": "en",
        "locales": {
          "en": {
            "entries": {
              "available": {
                "spokenText": "Available.",
                "assetKey": "sounds/announcements/en/available.mp3"
              },
              "absent": {
                "spokenText": "Absent.",
                "assetKey": "sounds/announcements/en/absent.mp3"
              },
              "wrongLocale": {
                "spokenText": "Wrong.",
                "assetKey": "sounds/announcements/de/wrong.mp3"
              },
              "unassigned": {
                "spokenText": "Unassigned.",
                "assetKey": null
              }
            }
          }
        }
      }
    ''');

    final report = await manifest.preflight(
      requestedLocale: 'en-US',
      requiredEntryIds: const [
        'available',
        'absent',
        'wrongLocale',
        'unassigned',
        'unknown',
      ],
      assetExists: (bundleKey) async =>
          bundleKey == 'assets/sounds/announcements/en/available.mp3',
    );

    expect(report.isReady, isFalse);
    expect(
      report.availableAssetKeys,
      ['sounds/announcements/en/available.mp3'],
    );
    expect(
      report.missingAssetKeys,
      ['sounds/announcements/en/absent.mp3'],
    );
    expect(
      report.invalidAssetKeys,
      ['sounds/announcements/de/wrong.mp3'],
    );
    expect(report.unassignedEntryIds, ['unassigned']);
    expect(report.missingEntryIds, ['unknown']);
  });

  test('bundle probe reports the manifest and rejects an absent MP3', () async {
    expect(
      await TrainingAnnouncementManifest.assetExistsInBundle(
        rootBundle,
        TrainingAnnouncementManifest.bundledAssetPath,
      ),
      isTrue,
    );
    expect(
      await TrainingAnnouncementManifest.assetExistsInBundle(
        rootBundle,
        'assets/sounds/announcements/not_recorded.mp3',
      ),
      isFalse,
    );
  });

  test('parser rejects unsupported schema versions', () {
    expect(
      () => TrainingAnnouncementManifest.fromJsonString(
        '{"schemaVersion":2,"contentVersion":"x","defaultLocale":"en",'
        '"locales":{"en":{"entries":{"a":{"spokenText":"A",'
        '"assetKey":null}}}}}',
      ),
      throwsFormatException,
    );
  });
}

Set<String> _fullRuntimeEventIds() {
  final ids = _sessionRuntimeEventIds(isDuo: false)
    ..addAll(_sessionRuntimeEventIds(isDuo: true));
  return ids;
}

Set<String> _sessionRuntimeEventIds({required bool isDuo}) {
  const phaseCounts = [3, 2, 2, 4, 4, 1, 1];
  final ids = <String>{
    'session.pause',
    'session.resume',
    'session.complete',
    'session.safety',
    'session.countdown.3',
    'session.countdown.2',
    'session.countdown.1',
    'exercise.repetition.complete',
    'exercise.switch_side',
    'exercise.rest',
  };

  for (var exercise = 1; exercise <= phaseCounts.length; exercise++) {
    ids
      ..add('exercise.moro_ex$exercise.name')
      ..add(
        'exercise.moro_ex$exercise.position.${isDuo ? 'duo' : 'solo'}',
      );
    for (var phase = 1; phase <= phaseCounts[exercise - 1]; phase++) {
      ids.add('exercise.moro_ex$exercise.phase.$phase');
    }
  }
  return ids;
}

const Map<String, ({String de, String en})> _recordingScript = {
  'session.pause': (de: 'Pause.', en: 'Pause.'),
  'session.resume': (de: 'Weiter.', en: 'Continue.'),
  'session.complete': (
    de: 'Einheit abgeschlossen.',
    en: 'Session complete.',
  ),
  'session.safety': (
    de: 'Stoppe bei Schmerzen, Schwindel, Übelkeit oder deutlichem '
        'Unwohlsein. Lass anhaltende Beschwerden fachlich abklären.',
    en: 'Stop if you feel pain, dizziness, nausea, or significant discomfort. '
        'Seek professional advice if symptoms persist.',
  ),
  'session.countdown.3': (de: 'Drei.', en: 'Three.'),
  'session.countdown.2': (de: 'Zwei.', en: 'Two.'),
  'session.countdown.1': (de: 'Eins.', en: 'One.'),
  'exercise.repetition.complete': (
    de: 'Wiederholung abgeschlossen.',
    en: 'Repetition complete.',
  ),
  'exercise.switch_side': (de: 'Wechsel.', en: 'Switch sides.'),
  'exercise.rest': (de: 'Pause.', en: 'Rest.'),
  'exercise.moro_ex1.name': (de: 'Moro fünf.', en: 'Moro five.'),
  'exercise.moro_ex1.position.solo': (
    de: 'Lege dich auf den Rücken und strecke beide Beine aus. '
        'Lege die Arme lang neben den Körper. '
        'Die Handflächen zeigen zum Boden. Du hebst abwechselnd ein Bein an. '
        'Bein hoch, halten, zurück, Seite wechseln.',
    en: 'Lie on your back with both legs extended. '
        'Rest your arms alongside your body with your palms facing down. '
        'You alternately raise one leg. Leg up, hold, return, switch sides.',
  ),
  'exercise.moro_ex1.position.duo': (
    de: 'Lege dich auf den Rücken und strecke beide Beine aus. '
        'Lege die Arme lang neben den Körper. '
        'Die Handflächen zeigen zum Boden. Du hebst abwechselnd ein Bein an. '
        'Bein hoch, halten, zurück, Seite wechseln.',
    en: 'Lie on your back with both legs extended. '
        'Rest your arms alongside your body with your palms facing down. '
        'You alternately raise one leg. Leg up, hold, return, switch sides.',
  ),
  'exercise.moro_ex1.phase.1': (de: 'Hoch.', en: 'Up.'),
  'exercise.moro_ex1.phase.2': (de: 'Halten.', en: 'Hold.'),
  'exercise.moro_ex1.phase.3': (de: 'Runter.', en: 'Down.'),
  'exercise.moro_ex2.name': (
    de: 'Moro drei. Halber Frosch.',
    en: 'Moro three. Half frog.',
  ),
  'exercise.moro_ex2.position.solo': (
    de: 'Lege dich auf den Rücken und strecke beide Beine aus. '
        'Lass beide Beine gerade und entspannt nebeneinander liegen. '
        'Du lässt abwechselnd einen Fuß am anderen Bein entlanggleiten. '
        'Fuß hochgleiten, zurück, Seite wechseln.',
    en: 'Lie on your back with both legs extended. '
        'Let both legs rest straight and relaxed beside each other. '
        'You alternately slide one foot along the opposite leg. '
        'Slide foot up, return, switch sides.',
  ),
  'exercise.moro_ex2.position.duo': (
    de: 'Lege dich auf den Rücken und strecke beide Beine aus. '
        'Lass beide Beine gerade und entspannt nebeneinander liegen. '
        'Du lässt abwechselnd einen Fuß am anderen Bein entlanggleiten. '
        'Fuß hochgleiten, zurück, Seite wechseln.',
    en: 'Lie on your back with both legs extended. '
        'Let both legs rest straight and relaxed beside each other. '
        'You alternately slide one foot along the opposite leg. '
        'Slide foot up, return, switch sides.',
  ),
  'exercise.moro_ex2.phase.1': (de: 'Hoch.', en: 'Up.'),
  'exercise.moro_ex2.phase.2': (de: 'Runter.', en: 'Down.'),
  'exercise.moro_ex3.name': (
    de: 'Moro vier. Frosch.',
    en: 'Moro four. Frog.',
  ),
  'exercise.moro_ex3.position.solo': (
    de: 'Lege dich auf den Rücken und strecke beide Beine aus. '
        'Führe die Fußsohlen zusammen. Du bewegst beide Füße gemeinsam. '
        'Füße heran, Knie öffnen, Füße zurück.',
    en: 'Lie on your back with both legs extended. '
        'Bring the soles of your feet together. You move both feet together. '
        'Feet in, knees open, feet back.',
  ),
  'exercise.moro_ex3.position.duo': (
    de: 'Lege dich auf den Rücken und strecke beide Beine aus. '
        'Führe die Fußsohlen zusammen. Du bewegst beide Füße gemeinsam. '
        'Füße heran, Knie öffnen, Füße zurück.',
    en: 'Lie on your back with both legs extended. '
        'Bring the soles of your feet together. You move both feet together. '
        'Feet in, knees open, feet back.',
  ),
  'exercise.moro_ex3.phase.1': (de: 'Ran.', en: 'In.'),
  'exercise.moro_ex3.phase.2': (de: 'Zurück.', en: 'Back.'),
  'exercise.moro_ex4.name': (de: 'Moro eins.', en: 'Moro one.'),
  'exercise.moro_ex4.position.solo': (
    de: 'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie '
        'zusammen. Lege die Arme lang neben den Körper. '
        'Die Handflächen zeigen zum Boden. Du bewegst beide Knie zu jeder '
        'Seite. Rechts, Mitte, links, Mitte.',
    en: 'Lie on your back. Place your feet on the floor and keep your knees '
        'together. Rest your arms alongside your body with your palms facing '
        'down. You move both knees to each side. Right, centre, left, centre.',
  ),
  'exercise.moro_ex4.position.duo': (
    de: 'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie '
        'zusammen. Lege die Arme lang neben den Körper. '
        'Die Handflächen zeigen zum Boden. Du bewegst beide Knie zu jeder '
        'Seite. Rechts, Mitte, links, Mitte.',
    en: 'Lie on your back. Place your feet on the floor and keep your knees '
        'together. Rest your arms alongside your body with your palms facing '
        'down. You move both knees to each side. Right, centre, left, centre.',
  ),
  'exercise.moro_ex4.phase.1': (de: 'Rechts.', en: 'Right.'),
  'exercise.moro_ex4.phase.2': (de: 'Mitte.', en: 'Centre.'),
  'exercise.moro_ex4.phase.3': (de: 'Links.', en: 'Left.'),
  'exercise.moro_ex4.phase.4': (de: 'Mitte.', en: 'Centre.'),
  'exercise.moro_ex5.name': (de: 'Moro zwei.', en: 'Moro two.'),
  'exercise.moro_ex5.position.solo': (
    de: 'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie '
        'zusammen. Lege die Arme lang neben den Körper. '
        'Die Handflächen zeigen zum Boden. Du rollst Kopf und Oberkörper mit '
        'der Ausatmung an. Ausatmen, hochrollen, halten, ablegen.',
    en: 'Lie on your back. Place your feet on the floor and keep your knees '
        'together. Rest your arms alongside your body with your palms facing '
        'down. You curl your head and upper body as you exhale. '
        'Exhale, roll up, hold, lower.',
  ),
  'exercise.moro_ex5.position.duo': (
    de: 'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie '
        'zusammen. Lege die Arme lang neben den Körper. '
        'Die Handflächen zeigen zum Boden. Du rollst Kopf und Oberkörper mit '
        'der Ausatmung an. Ausatmen, hochrollen, halten, ablegen.',
    en: 'Lie on your back. Place your feet on the floor and keep your knees '
        'together. Rest your arms alongside your body with your palms facing '
        'down. You curl your head and upper body as you exhale. '
        'Exhale, roll up, hold, lower.',
  ),
  'exercise.moro_ex5.phase.1': (de: 'Ausatmen.', en: 'Exhale.'),
  'exercise.moro_ex5.phase.2': (de: 'Hochrollen.', en: 'Roll up.'),
  'exercise.moro_ex5.phase.3': (de: 'Halten.', en: 'Hold.'),
  'exercise.moro_ex5.phase.4': (de: 'Ablegen.', en: 'Lower.'),
  'exercise.moro_ex6.name': (
    de: 'Moro sechs. Isometrischer Gegendruck.',
    en: 'Moro six. Isometric counterpressure.',
  ),
  'exercise.moro_ex6.position.solo': (
    de: 'Lege dich auf den Rücken und winkle beide Beine an. '
        'Lege die überkreuzten Hände auf Knie oder Schienbeine. Baue leichten '
        'Gegendruck auf. Halte sieben Sekunden. Löse drei Sekunden. '
        'Wechsle nach drei Wiederholungen das Armkreuz.',
    en: 'Lie on your back with both legs bent. '
        'Place your crossed hands on your knees or shins. Build gentle '
        'counterpressure. Hold for seven seconds. Release for three seconds. '
        'Switch the arm cross after three repetitions.',
  ),
  'exercise.moro_ex6.position.duo': (
    de: 'Lege dich auf den Rücken und winkle beide Beine an. '
        'Lege die überkreuzten Hände auf Knie oder Schienbeine. Baue leichten '
        'Gegendruck auf. Halte sieben Sekunden. Löse drei Sekunden. '
        'Wechsle nach drei Wiederholungen das Armkreuz.',
    en: 'Lie on your back with both legs bent. '
        'Place your crossed hands on your knees or shins. Build gentle '
        'counterpressure. Hold for seven seconds. Release for three seconds. '
        'Switch the arm cross after three repetitions.',
  ),
  'exercise.moro_ex6.phase.1': (de: 'Spannung.', en: 'Tension.'),
  'exercise.moro_ex7.name': (
    de: 'Moro sieben. Überkreuzter Gegendruck.',
    en: 'Moro seven. Crossed counterpressure.',
  ),
  'exercise.moro_ex7.position.solo': (
    de: 'Lege dich auf den Rücken und winkle beide Beine an. '
        'Lege die überkreuzten Hände auf Oberschenkel oder Knie. Lass Beine '
        'und Hände kontrolliert gegeneinander arbeiten. Halte sieben Sekunden. '
        'Löse drei Sekunden. Wechsle nach drei Wiederholungen das Armkreuz.',
    en: 'Lie on your back with both legs bent. '
        'Place your crossed hands on your thighs or knees. Let your legs and '
        'hands work against each other with control. Hold for seven seconds. '
        'Release for three seconds. Switch the arm cross after three '
        'repetitions.',
  ),
  'exercise.moro_ex7.position.duo': (
    de: 'Lege dich auf den Rücken und winkle beide Beine an. '
        'Lege die überkreuzten Hände auf Oberschenkel oder Knie. Lass Beine '
        'und Hände kontrolliert gegeneinander arbeiten. Halte sieben Sekunden. '
        'Löse drei Sekunden. Wechsle nach drei Wiederholungen das Armkreuz.',
    en: 'Lie on your back with both legs bent. '
        'Place your crossed hands on your thighs or knees. Let your legs and '
        'hands work against each other with control. Hold for seven seconds. '
        'Release for three seconds. Switch the arm cross after three '
        'repetitions.',
  ),
  'exercise.moro_ex7.phase.1': (de: 'Spannung.', en: 'Tension.'),
};
