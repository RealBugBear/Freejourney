# Anwalts-Briefing: Reflex Journey — Datenschutz- und Launch-Rechtstexte

**Anfrage für ein Festpreis-Angebot** · Stand: 07.07.2026

> **[VOR VERSAND EINSETZEN — 3 Angaben von Alexander:]**
> - Rechtsform/Firmierung: `[z. B. Einzelunternehmer Alexander Messinger]`
> - Rückruf-Kontakt: `[E-Mail + ggf. Telefonnummer]`
> - Wunsch-Zeitrahmen: `[z. B. Entwürfe innerhalb von 2–3 Wochen]`

---

## 1. Worum es geht (Kurzfassung)

- **Produkt:** „Reflex Journey“ — eine Mobile-App (iOS zuerst, Android
  folgt) mit strukturierten Übungsprogrammen zur Integration frühkindlicher
  Reflexe. Übungs- und Begleitprogramm, **bewusst kein Medizinprodukt**:
  keine Diagnose, keine Heil- oder Therapieversprechen; alle Nutzertexte
  sind bereits entsprechend formuliert und ein Disclaimer ist Teil der
  Store-Beschreibung.
- **Betreiber:** Solo-Gründer (Deutschland), `[Rechtsform einsetzen]`.
- **Zielgruppe:** Erwachsene (Selbstanwender). Eltern können zusätzlich
  **Profile für ihre Kinder** anlegen (Name, Geburtsdatum,
  Trainingsfortschritt). Kinderprofile existieren nur unter dem
  Eltern-Account — es gibt keinen Kinder-Login und keine Kinder-Zielgruppe
  im Sinne der App-Store-Kids-Kategorie.
- **Trainer-Komponente:** Zertifizierte Reflexintegrations-Trainer können
  sich bewerben, werden manuell geprüft (Ablauf s. Abschnitt 6) und sind
  danach in einer Trainer-Suche (Liste + Karte) sichtbar; Nutzer können
  sich mit einem Trainer verbinden (1:1-Chat). **Wichtige Abgrenzung:**
  Die Plattform vermittelt ausschließlich den Kontakt und stellt
  Werkzeuge (Chat, Termine, Fortschritts-Teilen). Verträge über und die
  Bezahlung von Trainer-Sitzungen kommen **ausschließlich direkt zwischen
  Trainer und Klient** zustande — die Plattform ist nicht Vertragspartei,
  verarbeitet keine Zahlungen, erhält keine Provision und kennt keine
  Beträge. Bitte diese Abgrenzung in Datenschutzerklärung/Haftungs-
  passagen entsprechend abbilden.
- **Vertrieb:** Apple App Store, EU-Verteilung, Start in Deutschland.
  **Launch kostenlos**, keine In-App-Käufe zum Start.
- **Website:** `reflexjourney.app` (Hosting: Vercel) — bekommt Impressum,
  Datenschutzerklärung, Support-Seite und eine Trainer-Bewerbungsseite.
- **Geplantes Marketing:** Erstansprache von ca. 20 Trainer-Praxen
  (B2B-Kaltakquise per Kontaktformular/E-Mail) für ein
  „Gründungs-Trainer“-Angebot.

## 2. Gewünschte Leistungen (bitte je Baustein bepreisen)

1. **Datenschutzerklärung für die App** (DSGVO; Deutsch; Englisch gern als
   Prüfung/Freigabe unserer Übersetzung). Wird im App Store als
   Pflicht-URL verlinkt (`reflexjourney.app/datenschutz`).
2. **Datenschutzerklärung/-abschnitte für die Website** — inkl. des
   Trainer-Bewerbungsformulars (Formular-Daten gehen per E-Mail-Versand
   über unseren bestehenden Dienstleister Resend an unser Support-Postfach;
   kein Datei-Upload).
3. **Impressum** (Website; dieselben Angaben erscheinen als
   „Trader-Status“ nach dem EU Digital Services Act öffentlich auf der
   App-Store-Produktseite: Adresse, Telefonnummer, E-Mail). **Konkrete
   Beratungsfrage:** Solo-Gründer arbeitet von der Privatadresse — welche
   Adresse/Telefonnummer muss bzw. darf öffentlich stehen, und welche
   Gestaltungen (separate Nummer, c/o-/Büroservice-Adresse) sind zulässig?
4. **In-App-Einwilligung (Consent-Screen):** Juristische Prüfung/
   Überarbeitung unserer vorbereiteten Entwurfsfassung (Anlage 1). Die App
   hat eine funktionierende Re-Consent-Mechanik (Versions-Bump).
5. **Verarbeiter-/AVV-Check:** Kurzprüfung der Liste in Abschnitt 5
   (Standard-DPAs der Anbieter; Drittlandtransfers/SCCs wo relevant) +
   Hinweis, was ins Verarbeitungsverzeichnis gehört.
6. **Trainer-Akquise:** Kurzprüfung der Zulässigkeit der B2B-Erstansprache
   (UWG § 7) und der Informationspflichten (Art. 14 DSGVO) für unser
   Vorgehen (max. ~20 Praxen, individuelle Ansprache über öffentlich
   angegebene Kontaktwege, keine Massenmails, kein Tracking).
7. **Trainer-Vetting:** Kurzbestätigung unseres Sichtprüfungs-Ablaufs
   (Abschnitt 6) — insbesondere der Grundsatz „ansehen, nie speichern“
   beim erweiterten Führungszeugnis (Art. 10 DSGVO) und der geplante
   Prüfvermerk. Bitte dabei auch die Abgrenzungs-Formulierung aus
   Abschnitt 1 mitdenken (reine Kontaktvermittlung; Sitzungsverträge und
   -zahlungen ausschließlich direkt Trainer↔Klient — keine
   Zahlungsvermittlung durch die Plattform).
8. **OPTIONAL — bitte nur Angebotspreis:** AGB + Widerrufsbelehrung für
   spätere In-App-Abos (Apple In-App-Purchase, „Phase 2“ nach dem Launch;
   jetzt noch nicht beauftragt). Ebenfalls optional: Datenschutz-Passage
   für eine mögliche spätere E-Mail-Warteliste (aktuell nicht geplant).

## 3. Verarbeitete Daten (Ist-Zustand, technisch belegt)

| Datenart | Inhalt | Anmerkung |
|---|---|---|
| Konto | E-Mail, Passwort | Supabase Auth; E-Mail-Bestätigung aktiv |
| Gesundheitsnahe Daten | Trainingsfortschritt, Einstiegs-/Reflexfragebogen, Stimmungs-Check-ins, Journal-Freitexte | Kern der App; besondere Sensibilität bekannt |
| Kinderprofile | Name, Geburtsdatum, Fortschritt | nur durch erziehungsberechtigten Kontoinhaber angelegt/verwaltet |
| Kommunikation | 1:1-Chat Nutzer ↔ Trainer | kein öffentlicher Feed zum Launch (Community-Funktionen deaktiviert) |
| Push | FCM-Geräte-Token | für Erinnerungen/Trainer-Nachrichten |
| Standort (Nutzer) | nur auf aktive Nutzer-Anfrage in der Trainer-Suche; **transient, wird nicht gespeichert** | technischer Nachweis: Anlage 2 |
| Standort (Trainer) | vom Trainer selbst gesetzter Praxis-Standort; veröffentlicht nur serverseitig verrauscht (~1 km) | B2B-Daten |
| Trainer-Bewerbung | Name, Kontakt, Zertifizierungsangaben, Selbstauskunft Führungszeugnis | kein Dokumenten-Upload |
| Gerätedaten | OS, App-Version | — |

Weitere Fakten: Hosting der Nutzerdaten in der **EU (Supabase, Region
Irland)**; lokale Offline-Datenbank app-privat, von Geräte-Backups
ausgeschlossen; **In-App-Kontolöschung** löscht Server- und lokale Daten;
**kein Tracking, keine Werbung, keine Analytics-SDKs**; Absturzberichte
(Sentry) anonymisiert und ohne Inhaltsdaten, EU-Datenhaltung.

## 4. Bekannte Abweichung (bitte im Zuge von Leistung 4 heilen)

Die aktuell ausgelieferte In-App-Einwilligung ist eine Testphasen-Fassung:
Sie nennt als Verarbeiter nur Supabase und behauptet, Push-Daten verließen
das Gerät nicht (seit Einführung der FCM-Push-Funktion unzutreffend).
Die korrigierte Entwurfsfassung (Anlage 1) liegt fertig im Code und wartet
auf Ihre Prüfung; danach wird per Re-Consent neu eingewilligt.

## 5. Auftragsverarbeiter / Empfänger

| Dienst | Zweck | Region/Transfer |
|---|---|---|
| Supabase Inc. | Datenbank, Authentifizierung, Backend | EU-Hosting (Irland); US-Anbieter → DPA/SCCs |
| Google (Firebase Cloud Messaging) | Zustellung von Push-Nachrichten (Geräte-Token) | Google Ireland Ltd. |
| Resend | Versand von System-E-Mails (Domain `send.reflexjourney.de`) | US-Anbieter → DPA/SCCs |
| Sentry | Absturzberichte (anonymisiert, ohne Inhalte) | EU-Data-Residency gewählt; US-Anbieter → DPA |
| Vercel | Hosting der Website `reflexjourney.app` | US-Anbieter → DPA/SCCs |
| OpenStreetMap Foundation | Karten-Kacheln in der Trainer-Suche (erhält IP + Kartenausschnitt) | UK; **kein AVV** — externer Empfänger, bitte einordnen |
| Apple | App-Vertrieb, Push-Transport (APNs) | — |

## 6. Trainer-Vetting-Ablauf (zur Kurzbestätigung, Leistung 7)

Bewerbung über Web-Formular (nur Daten, kein Upload) → Plausibilitätsprüfung
→ **Sichttermin per Video:** Lichtbildausweis, Ausbildungszertifikat und
erweitertes Führungszeugnis (nicht älter als 3 Monate) werden **gezeigt,
niemals kopiert/gespeichert/aufgezeichnet**. Gespeichert wird nur ein
Prüfvermerk (Name, „geprüft ja/nein“, Vorlagedatum, Wiedervorlage nach
24 Monaten). Ablehnungen: Minimalvermerk ohne Begründungsdetails.

## 7. Anlagen

1. **In-App-Consent-Entwurf (DE+EN)** mit Beleg-Liste — jede
   Tatsachenbehauptung ist auf Code/Infrastruktur rückführbar.
2. **Standort-Datenfluss-Dokumentation** (nutzerinitiierter Abruf,
   transiente Verarbeitung, OSM-Empfängerdetails).
3. **Entwurf Privacy Nutrition Labels** (Apple) / Data Safety (Google) —
   zur Konsistenzprüfung mit der Datenschutzerklärung. Enthält eine
   offene Einordnungsfrage („Standort: linked vs. not linked“).

*(Die Anlagen werden als PDF/Markdown mitgesendet; auf Wunsch stellen wir
weitere technische Detail-Dokumentation bereit — alles ist schriftlich
belegt, Rückfragen können schnell beantwortet werden.)*

## 8. Rahmen

- **Kritischer Pfad:** Datenschutzerklärung + Impressumsfrage blockieren
  die App-Store-Einreichung. Wunsch-Zeitrahmen: `[einsetzen]`.
- **Angebot:** Festpreis je Leistungsbaustein (1–7; 8 optional) erbeten.
- **Zusammenarbeit:** gern vollständig per E-Mail/Video.

---

## Anschreiben-Vorlage (E-Mail an die Kanzlei)

> Betreff: Festpreis-Anfrage: Datenschutzerklärung + Launch-Rechtstexte
> für Gesundheits-App (Solo-Gründer, DSGVO/Kinderdaten)
>
> Sehr geehrte Damen und Herren,
>
> ich bin Solo-Gründer und stehe kurz vor dem App-Store-Launch einer
> Mobile-App im gesundheitsnahen Bereich (Übungsprogramm zur
> Reflexintegration; ausdrücklich kein Medizinprodukt). Verarbeitet werden
> u. a. gesundheitsnahe Einträge und — durch Eltern angelegte —
> Kinderprofile; die Infrastruktur liegt in der EU.
>
> Ich benötige die im beigefügten Briefing beschriebenen Leistungen —
> im Kern: Datenschutzerklärung (App + Website), Impressum inkl. einer
> Beratungsfrage zur öffentlichen Adresse/Telefonnummer (EU-DSA-
> Trader-Status im App Store), Prüfung unseres In-App-Einwilligungstexts
> sowie zwei Kurzprüfungen (B2B-Erstansprache, Prüfablauf mit erweitertem
> Führungszeugnis).
>
> Das Briefing enthält eine vollständige, technisch belegte Übersicht der
> Datenverarbeitung samt Anlagen — Sie finden dort alles für ein
> Festpreis-Angebot je Baustein. Über eine kurze Rückmeldung, ob Sie das
> Mandat übernehmen können, und Ihr Angebot freue ich mich.
>
> Mit freundlichen Grüßen
> `[Name, Kontakt]`
