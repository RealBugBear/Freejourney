# I18N-EN — visuelle Sprachwechsel- und Screen-Evidenz

Stand: 2026-07-15

Die sechs PNGs werden reproduzierbar durch
`test/evidence/i18n_en_evidence_test.dart` erzeugt:

```bash
flutter test --no-pub test/evidence/i18n_en_evidence_test.dart
```

Letzter Lauf: **5/5 Tests grün**. Jeder Screenshot ist 780 × 1688 px
(390 × 844 logische Pixel bei 2× Rasterung). Der Test prüft außerdem sichtbare
englische Copy, den Sprachzustand, die Persistenz beziehungsweise Navigation,
fehlende Flutter-/Overflow-Exceptions, vorhandene PNG-Dateien sowie opake,
nicht schwarze Eckpixel.

## Aufnahmen

| Datei | Beleg |
|---|---|
| `01_first_launch_choose_english.png` | Echter `LanguageSelectionScreen` auf einem simulierten Erststart ohne gespeicherte Sprache. Ausgangssprache ist Deutsch; `English` wird getappt. Titel, Untertitel und `Continue` wechseln schon in der Vorschau auf Englisch, während noch nichts gespeichert ist. |
| `02_first_launch_login_english.png` | Im selben Test wird anschließend der echte `Continue`-Button getappt. `settings.languageCode=en` wird gespeichert und der echte `LoginScreen` erscheint auf Englisch. Damit ist der Pfad **Erststart-Sprachwahl vor Login → English → Login** interaktiv belegt. |
| `03_settings_after_switch_english.png` | Echter `SettingsScreen`, initial mit gespeicherter Sprache `de`. `English` wird im Sprachsegment getappt; App-Locale, Titel und restliche Settings-Copy wechseln im selben Frame auf Englisch, und der Wert wird als `en` persistiert. Der aktuelle Produktionsscreen platziert den Sprachselektor unter `APPEARANCE`; es gibt dort keine separate sichtbare `LANGUAGE`-Überschrift. |
| `04_onboarding_english.png` | Echter `EntryPointsScreen` in Englisch; die Karte `Body & Tension` wird interaktiv aufgeklappt. |
| `05_dashboard_english.png` | Echter `DashboardScreen` in einem deterministischen lokalen Zustand: Profil `Sam` vorhanden, kein aktives Paket, keine Sessions/Nachrichten/Terminvorschläge, feste Uhrzeit 2026-07-15 12:00. Belegt den ehrlichen, lokal möglichen Hauptflächenzustand `No Active Package Yet`. |
| `06_training_english.png` | Echter `TrainingIntroScreen` mit englischem Titel, Beschreibung, Eckdaten und `Start Session`. |

## Was im Harness simuliert ist

- Kein Produktionskonto, keine Produktionsdaten und kein Netzwerkzugriff. Der
  Auth-Repository-Stub liefert einen ausgeloggten Zustand; der für
  `Supabase.instance` nötige Client verwendet nur eine ungültige lokale
  Evidence-URL und führt keine Anfrage aus.
- `SharedPreferences` ist ein In-Memory-Mock. Die Tests führen aber die echten
  `SettingsNotifier.setLanguage`-Aufrufe aus und prüfen den geschriebenen Wert.
- Settings erhalten eine lokale In-Memory-Datenbank, einen lokalen
  `SyncService`, den Zustand `All synced` und kein aktives Enrollment.
- Dashboard-Provider liefern ausschließlich die oben genannten lokalen
  Evidence-Daten. Produktions-Repositories und Supabase werden nicht gelesen.
- Navigation Erststart → Login verwendet einen kleinen `GoRouter`, aber beide
  Zielseiten sind die echten Produktionsscreens.

Onboarding und Training benötigen für diese Zustände keine Daten-Stubs.

## Fonts und Rasterung

Wie bei T04/T13 lädt der Test Fonts lokal mit `FontLoader` aus dem
Flutter-SDK-Cache. `Roboto-Regular.ttf` wird für den Screenshot als `Poppins`,
`Roboto` und `.SF Pro Text` registriert; `MaterialIcons-Regular.otf` liefert
die Icons. Dadurch gibt es weder Google-Fonts- noch sonstige Netzabrufe.

`flutter test` startet die Engine zwangsweise mit dem Ahem-Testfont. Einzelne
Produktwidgets setzen in ihrem `ButtonStyle` absichtlich keine `fontFamily`;
ohne Korrektur würden deren Buchstaben als schwarze Ahem-Balken erscheinen.
Unmittelbar vor der Rasterung setzt der Evidence-Harness deshalb nur bei
solchen `RenderParagraph`s die bereits geladene lokale Font-Family. Der
Widgetzustand und die Copy werden dadurch nicht geändert.

Vier rein dekorative Unicode-Glyphen lassen sich im headless Flutter-Tester
nicht zuverlässig rendern: die Flaggen vor `Deutsch`/`English` sowie die
Pfeile hinter `More`/`Less`. Der Test assertiert zuerst ausdrücklich die echten
Produktstrings `🇩🇪 Deutsch`, `🇬🇧 English`, `More ↓` und `Less ↑`; ausschließlich
in der danach erzeugten PNG-Rasterung werden Flaggen und Pfeile ausgelassen.
Die Wörter, Auswahlzustände und Abstände bleiben sichtbar. Auf einem echten
iOS-/Android-Gerät rendert das System diese Glyphen normal.

Die Screenshots selbst haben keine schwarzen oder transparenten Randflächen:
Der Test liest die RGBA-Eckpixel vor dem Schreiben und verlangt Alpha 255 sowie
eine nicht schwarze Farbe. Schwarze Flächen außerhalb des Bildes in einzelnen
Preview-Ansichten sind Letterboxing des Viewers.

## Grenzen

- Dies ist visuelle Widget-Evidenz, kein Simulator-/Geräte-End-to-End-Test.
  Native Safe Areas, Systemfont-Metriken, Tastatur, echte Apple-/Google-Anmeldung
  und ein App-Neustart nach Persistenz sind nicht enthalten.
- Der Dashboard-Screenshot zeigt bewusst den echten No-Package-Zustand. Ein
  produktionsnah befülltes Konto würde Produktion/Netz oder deutlich mehr
  fingierte Gesundheits-/Fortschrittsdaten erfordern und wurde nicht erfunden.
- Die Screenshots belegen die aktuell bereits lokalisierten Hauptflächen, nicht
  die Vollständigkeit aller App-Routen und nicht die Store-Screenshot-Freigabe.
- Das separate `ASSET_INVENTORY.md` im selben Ordner dokumentiert den
  Sprachcheck der Raster-/Audio-Assets; es wird vom Screenshot-Test nicht
  erzeugt oder verändert.
