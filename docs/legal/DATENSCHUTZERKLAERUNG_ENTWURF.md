# Datenschutzerklärung — ENTWURF zur anwaltlichen Prüfung

> **⚠️ ENTWURF (Anlage 4 zum Anwalts-Briefing) — NICHT VERÖFFENTLICHEN.**
> Stand: 19.07.2026. Dieser Text wurde technisch vorbereitet, damit die
> Kanzlei redigieren kann statt neu zu entwerfen. Jede Tatsachenbehauptung
> ist im Beleg-Anhang (Teil D) auf Code/Infrastruktur rückführbar. Er ist
> keine Rechtsberatung und wird erst nach anwaltlicher Freigabe unter
> `reflexjourney.app/datenschutz` veröffentlicht und in der App verlinkt.
>
> **Markierungen im Text:**
> `[FOUNDER: …]` = Angabe, die Alexander einsetzt (keine Rechtsfrage).
> `[⚖️ ANWALT: …]` = juristische Einordnung/Formulierung durch die Kanzlei.
> **Tonalität:** „du“ wie die gesamte App- und Website-Copy — bei Bedarf
> gern auf „Sie“ umstellen (eine Vorgabe genügt, wir passen alles an).

---

## Datenschutzerklärung

Gültig für die Website `reflexjourney.app` und die Mobile-App
**Reflex Journey** (iOS und Android). Stand: `[Datum der Veröffentlichung]`.

### 1. Verantwortlicher

Verantwortlicher im Sinne der Datenschutz-Grundverordnung (DSGVO):

> `[FOUNDER: Name/Firmierung, z. B. „Alexander Messinger (Einzelunternehmer)“]`
> `[FOUNDER: ladungsfähige Anschrift — siehe Impressums-Frage im Briefing, Abschnitt 3]`
> E-Mail: `[FOUNDER: support@reflexjourney.app — Postfach aus R5, sobald eingerichtet]`

Ein Datenschutzbeauftragter ist nicht benannt. `[⚖️ ANWALT: bitte bestätigen,
dass bei einem Solo-Betreiber ohne umfangreiche Kernverarbeitungstätigkeit
keine Benennungspflicht nach Art. 37 DSGVO / § 38 BDSG besteht — Hinweis:
Kern der App ist die Verarbeitung gesundheitsnaher Daten, siehe Abschnitt 5;
falls doch erforderlich oder empfehlenswert, bitte kurz begründen.]`

### 2. Das Wichtigste in Kürze

- Reflex Journey ist ein Übungs- und Begleitprogramm. **Die App ist kein
  Medizinprodukt** und stellt keine Diagnosen.
- Deine Daten werden **in der EU gespeichert** (Supabase, Region Irland).
- **Kein Tracking, keine Werbung, keine Analyse-SDKs, kein Verkauf von
  Daten.** Die Website setzt keine Cookies.
- Trainings-, Befindlichkeits- und Journaldaten verarbeiten wir **nur mit
  deiner ausdrücklichen Einwilligung**, die du in der App erteilst und
  jederzeit widerrufen kannst.
- **Konto und Daten kannst du jederzeit direkt in der App löschen.**

### 3. Website (reflexjourney.app)

#### 3.1 Hosting und Server-Logfiles

Die Website wird bei Vercel Inc. (USA) gehostet. Beim Aufruf verarbeitet
Vercel technisch notwendig: IP-Adresse, Datum und Uhrzeit des Zugriffs,
aufgerufene Seite, Browsertyp/-version und Betriebssystem (Server-Logs).
Zweck ist die technische Bereitstellung, Stabilität und Sicherheit der
Website; Rechtsgrundlage ist unser berechtigtes Interesse an einem sicheren
und funktionsfähigen Webauftritt (Art. 6 Abs. 1 lit. f DSGVO).
`[⚖️ ANWALT: Log-Aufbewahrungsdauer bei Vercel — Standardangabe der
Vercel-DPA übernehmen oder neutral „kurzfristig“ formulieren?]`

#### 3.2 Keine Cookies, kein Tracking

Die Website ist eine statische Seite ohne Cookies, ohne Analyse- und ohne
Marketing-Werkzeuge. Ein Cookie-Banner ist deshalb nicht erforderlich.
`[⚖️ ANWALT: kurze Bestätigung mit Blick auf § 25 TDDDG.]`

#### 3.3 Konto-Hilfeseiten (Passwort zurücksetzen, E-Mail-Bestätigung)

Die Seiten `reflexjourney.app/auth/…` verarbeiten die Bestätigungs-Codes
aus unseren System-E-Mails (z. B. beim Zurücksetzen des Passworts) und
leiten sie an unser Backend (Supabase, EU) weiter. Zweck ist die sichere
Verwaltung deines Kontos; Rechtsgrundlage ist die Durchführung des
Nutzungsverhältnisses (Art. 6 Abs. 1 lit. b DSGVO).

#### 3.4 Trainer-Bewerbungsformular

*(Geht mit der Trainer-Bewerbungsseite live — Formular ohne Datei-Upload.)*

Wenn du dich als Trainer bewirbst, verarbeiten wir die von dir im Formular
angegebenen Daten: Name, Kontaktdaten, Angaben zu deiner Zertifizierung und
deine Selbstauskunft zum erweiterten Führungszeugnis. Die Angaben werden
per E-Mail (Versanddienstleister: Resend) an unser Support-Postfach
übermittelt und für die Prüfung deiner Bewerbung verwendet.
Rechtsgrundlage ist die Durchführung vorvertraglicher Maßnahmen auf deine
Anfrage (Art. 6 Abs. 1 lit. b DSGVO). Dokumente (Ausweis, Zertifikat,
Führungszeugnis) werden **nicht hochgeladen**, sondern ausschließlich in
einem Video-Termin gezeigt und niemals kopiert, gespeichert oder
aufgezeichnet; gespeichert wird nur ein Prüfvermerk (geprüft ja/nein,
Vorlagedatum, Wiedervorlage). `[⚖️ ANWALT: Aufbewahrungsdauer für
abgelehnte Bewerbungen (AGG-Frist?) und Formulierung zum Prüfvermerk beim
erweiterten Führungszeugnis (Art. 10 DSGVO) — siehe Briefing Leistung 7.]`

### 4. App — Konto und Anmeldung

#### 4.1 Registrierung mit E-Mail

Für die Nutzung der App benötigst du ein Konto. Dabei verarbeiten wir deine
E-Mail-Adresse und dein Passwort (gespeichert wird nur ein kryptografischer
Hash, nie das Passwort selbst; Authentifizierung über Supabase Auth).
Nach der Registrierung bestätigst du deine E-Mail-Adresse über einen
Bestätigungslink. Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO
(Bereitstellung der App).

#### 4.2 Anmeldung mit Apple oder Google (optional)

`[Hinweis für die Kanzlei: technisch vorbereitet (T26); ob die Anmeldewege
zum Launch aktiv sind, hängt von der Portal-Konfiguration ab. Absatz bitte
mitprüfen; er entfällt, falls Social Login beim Launch deaktiviert bleibt.]`

Alternativ kannst du dich mit deinem Apple- oder Google-Konto anmelden.
Dabei erhalten wir vom jeweiligen Anbieter deine E-Mail-Adresse (bei Apple
auf Wunsch eine Weiterleitungs-Adresse) und ggf. deinen Namen — weitere
Daten aus deinem Apple-/Google-Konto erhalten wir nicht. Rechtsgrundlage:
Art. 6 Abs. 1 lit. b DSGVO. Für die Anmeldung gelten ergänzend die
Datenschutzhinweise von Apple bzw. Google.

#### 4.3 System-E-Mails

Konto-bezogene E-Mails (Registrierungs-Bestätigung, Passwort-Zurücksetzen)
versenden wir über den Dienstleister Resend (Absende-Domain
`send.reflexjourney.de`). Es werden keine Werbe-E-Mails versendet.
Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO.

### 5. App — Trainings- und Gesundheitsdaten

#### 5.1 Welche Daten das sind

Kern der App sind Übungsprogramme zur Integration frühkindlicher Reflexe.
Dabei verarbeiten wir — je nachdem, was du nutzt:

- **Einstiegs- und Reflex-Fragebögen** (deine Antworten und die daraus
  berechneten Auswertungen),
- **Trainingsfortschritt** (absolvierte Einheiten, Übungsstand, Paketverlauf),
- **Stimmungs-Check-ins** (Befinden, Energie, Stress; optionale Notiz),
- **Journal-Einträge** (Freitext),
- deine optionale Angabe zum Einstiegsbereich.

Diese Angaben können Rückschlüsse auf deine Gesundheit zulassen. Wir
behandeln sie deshalb als **besondere Kategorien personenbezogener Daten**
(Art. 9 DSGVO) und verarbeiten sie nur auf Grundlage deiner
**ausdrücklichen Einwilligung** (Art. 9 Abs. 2 lit. a in Verbindung mit
Art. 6 Abs. 1 lit. a DSGVO), die du beim ersten Start der App erteilst.
`[⚖️ ANWALT: finale Einordnung als Gesundheitsdaten + Konstruktion der
Einwilligung über den In-App-Consent (Anlage 1, inkl. Re-Consent-Mechanik
über Versions-Bump) bitte prüfen/schärfen.]`

#### 5.2 Widerruf

Du kannst deine Einwilligung jederzeit mit Wirkung für die Zukunft
widerrufen, indem du dein Konto in der App löschst (Profil → Konto löschen)
oder uns kontaktierst. Die Rechtmäßigkeit der bis zum Widerruf erfolgten
Verarbeitung bleibt unberührt. `[⚖️ ANWALT: reicht die Kombination
„Kontolöschung oder formlose Kontaktaufnahme“ als Widerrufsweg, oder soll
ein separater In-App-Widerruf beschrieben werden? Technischer Ist-Stand:
Widerruf ohne Kontolöschung würde die App unbenutzbar machen, da die
Verarbeitung der Trainingsdaten ihr Kern ist.]`

### 6. App — Profile für Kinder

Erwachsene Kontoinhaber können Profile für ihre Kinder anlegen (Name,
Geburtsdatum, Fragebogen-Antworten, Trainingsfortschritt). Es gilt:

- Kinderprofile werden **ausschließlich durch den erziehungsberechtigten
  Kontoinhaber** angelegt und verwaltet; es gibt **keinen eigenen
  Kinder-Login** und keine Ansprache von Kindern durch die App.
- Die Daten des Kindes gehören zu deinem Konto, werden wie deine eigenen
  Daten geschützt und mit deinem Konto gelöscht.
- Die Einwilligung nach Abschnitt 5 erteilst du dabei auch in Ausübung
  deiner elterlichen Sorge für die Daten des Kindes. `[⚖️ ANWALT:
  Formulierung der Eltern-Einwilligung (Art. 6/8/9 DSGVO) und ggf.
  ergänzende Transparenzanforderungen gegenüber dem Kind bitte festlegen.]`

### 7. App — Trainer-Funktionen

#### 7.1 Trainer-Suche und Karte (Standort)

Die Trainer-Suche zeigt zertifizierte Trainer als Liste und auf einer Karte.

- **Dein Standort wird nur auf deine Anfrage verwendet:** Erst wenn du in
  der Trainer-Suche aktiv „Standort verwenden“ antippst und die
  Systemberechtigung erteilst, fragt die App deinen Gerätestandort ab. Die
  Koordinaten werden einmalig für die Umkreis-Suche an unsere Datenbank
  (Supabase, EU) übermittelt und **nicht gespeichert** — weder auf deinem
  Gerät noch auf dem Server. Ohne Standortfreigabe ist die Trainer-Suche
  voll nutzbar (Liste aller Trainer).
- **Kartenkacheln:** Beim Anzeigen der Karte werden Kartenkacheln von
  Servern der OpenStreetMap Foundation (UK) geladen. Diese erhält dabei
  technisch bedingt deine IP-Adresse und das angezeigte Kartengebiet
  (nicht deinen präzisen Standort) sowie die App-Kennung.
- **Trainer-Standorte** werden nur in verrauschter Form (~1 km Umkreis)
  veröffentlicht; die präzise Adresse eines Trainers ist für Nutzer nicht
  sichtbar.

Rechtsgrundlage der Standortverwendung: `[⚖️ ANWALT: Einwilligung
(Art. 6 Abs. 1 lit. a — nutzerinitiierter Tap + Systemberechtigung) oder
Art. 6 Abs. 1 lit. b (angeforderte Funktion)? Bitte festlegen; die
Nutzerführung ist auf aktive, informierte Auslösung ausgelegt.]`

#### 7.2 Verbindung mit einem Trainer

Du kannst dich in der App mit einem Trainer verbinden (z. B. über einen
Einladungscode). Mit einer aktiven Verbindung kann dein Trainer sehen:

- die Inhalte, die du ausdrücklich mit ihm teilst (z. B. freigegebene
  Reflexprofil-Auswertungen),
- deine geteilten Befindlichkeitswerte (Stimmung, Energie, Stress)
  einschließlich optionaler Notiztexte,
- eure gemeinsamen Termine und den 1:1-Chat (Abschnitt 7.3).

Zusätzlich kann dein Trainer zu eurer Zusammenarbeit ein eigenes
Notizfeld führen. `[⚖️ ANWALT — WICHTIGSTE OFFENE STELLE DIESES ENTWURFS
(Briefing Abschnitt 3 + Zusatzfrage): Rollenverteilung für die
Trainer-Datenflüsse (Verantwortlicher / Auftragsverarbeiter des Trainers /
gemeinsame Verantwortlichkeit), erforderliche Verträge (AVV mit Trainern?),
Transparenz gegenüber Klienten und Eltern, Umfang der wirksamen Freigabe,
Zugriffsende bei Beziehungsende und Aufbewahrung der Trainer-Notizen.
Diesen Abschnitt bitte auf Basis Ihrer Einordnung formulieren — wir haben
bewusst nur den technischen Ist-Zustand beschrieben und keine
Rollenzuweisung vorweggenommen.]`

**Wichtige Abgrenzung:** Die Plattform vermittelt ausschließlich den
Kontakt und stellt Werkzeuge bereit (Chat, Termine, Teilen von
Fortschritten). Verträge über Trainer-Sitzungen und deren Bezahlung kommen
ausschließlich direkt zwischen dir und dem Trainer zustande — wir sind
nicht Vertragspartei, verarbeiten keine Zahlungen und kennen keine Beträge.

#### 7.3 1:1-Chat mit deinem Trainer

Nachrichten zwischen dir und deinem verbundenen Trainer werden auf unseren
Servern (Supabase, EU) gespeichert und sind nur für euch beide einsehbar.
Einen öffentlichen Feed oder Community-Bereich gibt es zum Start der App
nicht. Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO; soweit Chat-Inhalte
gesundheitsbezogene Angaben enthalten, deine Einwilligung nach Abschnitt 5.

#### 7.4 Termine

Vereinbarte Termine mit deinem Trainer (Zeitpunkt, Teilnehmer, optional
betroffenes Profil) speichern wir zur Bereitstellung der Terminfunktion.
Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO.

### 8. App — Mitteilungen (Push) und Erinnerungen

- **Lokale Erinnerungen** (z. B. Trainings-Erinnerungen) werden auf deinem
  Gerät geplant und benötigen keine Übertragung an uns.
- **Push-Mitteilungen** (z. B. eine neue Nachricht deines Trainers): Wenn du
  Mitteilungen auf Systemebene erlaubst, wird ein Geräte-Token über Google
  Firebase Cloud Messaging (FCM) verarbeitet und bei uns gespeichert, um
  Mitteilungen an dein Gerät zuzustellen; auf Apple-Geräten läuft die
  Zustellung zusätzlich über den Apple-Push-Dienst (APNs). Das Token lässt
  keinen direkten Rückschluss auf deine Identität durch Dritte zu, ist bei
  uns aber deinem Konto zugeordnet.
- Du kannst Mitteilungen jederzeit in den Systemeinstellungen deines
  Geräts deaktivieren; mit der Kontolöschung werden gespeicherte
  Geräte-Tokens gelöscht.

Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO (angeforderte Funktion)
`[⚖️ ANWALT: oder lit. a über die System-Permission? Bitte festlegen.]`

### 9. App — Absturzberichte (Sentry)

Zur Stabilität der App verarbeiten wir bei technischen Fehlern anonymisierte
Absturzberichte über Sentry (EU-Datenhaltung): Fehlertyp, technischer
Programmablauf (Stacktrace), Gerätemodell und Betriebssystem-Version.
**Keine Inhalte** (keine Journal-, Chat- oder Trainingsdaten), keine
E-Mail-Adresse, kein Nutzerprofil; Request-Daten werden vor dem Versand
technisch entfernt. Rechtsgrundlage: berechtigtes Interesse an einer
stabilen, fehlerfreien App (Art. 6 Abs. 1 lit. f DSGVO).

### 10. Lokale Daten auf deinem Gerät

Für die Offline-Nutzung hält die App deine Daten zusätzlich in einer
app-eigenen Datenbank auf deinem Gerät. Diese kann nur von der App gelesen
werden, ist durch die Geräteverschlüsselung deines Betriebssystems
geschützt und **von Geräte-Backups ausgeschlossen**. Beim Abmelden und bei
der Kontolöschung werden die lokalen Nutzerdaten gelöscht.

### 11. Empfänger und Auftragsverarbeiter

Deine Daten werden nicht verkauft und nur im beschriebenen Umfang an
folgende Dienstleister übermittelt (Auftragsverarbeitung nach Art. 28
DSGVO, soweit nicht anders angegeben):

| Dienstleister | Zweck | Sitz/Verarbeitungsort |
|---|---|---|
| Supabase, Inc. | Datenbank, Authentifizierung, Backend | Hosting EU (Irland); US-Anbieter |
| Google (Firebase Cloud Messaging) | Zustellung von Push-Mitteilungen | Google Ireland Ltd.; Konzern-Transfers möglich |
| Apple (APNs) | Push-Transport auf Apple-Geräten | — |
| Resend | Versand von System-E-Mails | US-Anbieter |
| Sentry | Absturzberichte (anonymisiert) | EU-Datenhaltung gewählt; US-Anbieter |
| Vercel Inc. | Hosting der Website | US-Anbieter |
| OpenStreetMap Foundation | Kartenkacheln in der Trainer-Suche (**externer Empfänger**, kein Auftragsverarbeiter: erhält IP-Adresse + Kartengebiet) | UK |

`[⚖️ ANWALT: Einordnung OSMF als Empfänger/Dritter sowie AVV-/
Vertragslage je Anbieter bitte prüfen (Briefing Leistung 5); Hinweis fürs
Verzeichnis von Verarbeitungstätigkeiten erbeten.]`

### 12. Übermittlung in Drittländer

Die inhaltlichen Daten liegen in der EU (Supabase, Region Irland). Einzelne
Dienstleister sind US-Unternehmen bzw. haben Konzernstandorte außerhalb der
EU; mit ihnen bestehen Auftragsverarbeitungsverträge mit
EU-Standardvertragsklauseln und/oder sie sind nach dem EU-U.S. Data
Privacy Framework zertifiziert. Kartenkacheln bezieht die App von der
OpenStreetMap Foundation im Vereinigten Königreich, für das ein
Angemessenheitsbeschluss der EU-Kommission besteht.
`[⚖️ ANWALT: bitte je Anbieter den aktuellen Transfermechanismus
verifizieren (DPF-Status Google/Vercel/Sentry/Resend/Supabase) und den
UK-Angemessenheitsbeschluss-Stand prüfen; Formulierung entsprechend
präzisieren.]`

### 13. Speicherdauer

- **Konto- und Inhaltsdaten:** bis zur Löschung deines Kontos. Die
  Kontolöschung ist jederzeit direkt in der App möglich und löscht deine
  Daten auf unseren Servern und auf deinem Gerät.
- **Server-Logfiles (Website):** kurzfristig zu Sicherheitszwecken
  `[⚖️ ANWALT: Frist gemäß 3.1]`.
- **Trainer-Bewerbungen:** bis zum Abschluss des Bewerbungsverfahrens
  `[⚖️ ANWALT: + Frist für abgelehnte Bewerbungen]`.
- `[⚖️ ANWALT: Aufbewahrung von Einwilligungsnachweisen (Art. 7 Abs. 1
  DSGVO) im Verhältnis zur vollständigen Kontolöschung sowie etwaige
  gesetzliche Aufbewahrungspflichten bitte einordnen.]`

### 14. Deine Rechte

Du hast gegenüber uns folgende Rechte hinsichtlich deiner
personenbezogenen Daten:

- **Auskunft** (Art. 15 DSGVO),
- **Berichtigung** (Art. 16 DSGVO),
- **Löschung** (Art. 17 DSGVO) — am schnellsten direkt in der App
  (Profil → Konto löschen),
- **Einschränkung der Verarbeitung** (Art. 18 DSGVO),
- **Datenübertragbarkeit** (Art. 20 DSGVO) — auf Anfrage stellen wir dir
  eine Kopie deiner Daten in einem gängigen, maschinenlesbaren Format
  bereit; wende dich dazu an `[FOUNDER: Support-Adresse]`,
- **Widerruf erteilter Einwilligungen** (Art. 7 Abs. 3 DSGVO) mit Wirkung
  für die Zukunft (Abschnitt 5.2).

> **Widerspruchsrecht (Art. 21 DSGVO):** Soweit wir Daten auf Grundlage
> unseres berechtigten Interesses verarbeiten (Art. 6 Abs. 1 lit. f DSGVO
> — z. B. Server-Logs, Absturzberichte), kannst du aus Gründen, die sich
> aus deiner besonderen Situation ergeben, jederzeit Widerspruch einlegen.
> Wir verarbeiten die Daten dann nicht mehr, es sei denn, es liegen
> zwingende schutzwürdige Gründe vor.

Außerdem hast du das Recht, dich bei einer Datenschutz-Aufsichtsbehörde zu
beschweren (Art. 77 DSGVO), z. B. bei der für uns zuständigen Behörde:
`[⚖️ ANWALT/FOUNDER: zuständige Landesbehörde nach Sitz einsetzen]`.

### 15. Keine automatisierte Entscheidungsfindung

Eine automatisierte Entscheidungsfindung einschließlich Profiling im Sinne
von Art. 22 DSGVO findet nicht statt. Die Auswertung deiner
Fragebogen-Antworten dient ausschließlich der Anzeige deines eigenen
Reflexprofils in der App und entfaltet keine rechtliche oder ähnlich
erhebliche Wirkung.
`[⚖️ ANWALT: Einordnung der Fragebogen-Auswertung bitte gegenprüfen.]`

### 16. Datensicherheit

Alle Verbindungen sind transportverschlüsselt (TLS). Serverseitig gelten
Zugriffskontrollen auf Zeilenebene (Row Level Security), sodass jedes
Konto nur die eigenen Daten erreicht; Rollen- und Berechtigungsänderungen
sind nur serverseitig möglich. Lokale Daten sind wie in Abschnitt 10
beschrieben geschützt.

### 17. Pflicht zur Bereitstellung

Die Angabe von E-Mail-Adresse und Passwort ist für die Kontoerstellung
erforderlich; ohne sie kann die App nicht genutzt werden. Alle weiteren
Angaben (z. B. Journal, Stimmungs-Check-ins, Kinderprofile,
Trainer-Verbindung, Standort) sind freiwillig.

### 18. Änderungen dieser Datenschutzerklärung

Wir passen diese Erklärung an, wenn sich die App oder die Rechtslage
ändert. Bei wesentlichen Änderungen der Verarbeitung holen wir deine
Einwilligung in der App erneut ein (Re-Consent). Die jeweils aktuelle
Fassung findest du unter `reflexjourney.app/datenschutz`.

---

## Teil B — Hinweise für die Kanzlei (nicht Teil des Veröffentlichungstextes)

1. **Bewusst NICHT genannt:** Agora (Video-Calls) — Funktion ist im
   Launch-Build deaktiviert, es fließen keine Daten; vor einer
   Reaktivierung wird die Erklärung erweitert (interner Merkposten R9).
   Ebenso nicht genannt: Community/Feed (deaktiviert), In-App-Käufe
   (Launch kostenlos).
2. **Konsistenzanker:** Dieser Entwurf ist deckungsgleich mit dem
   In-App-Consent-Entwurf (Anlage 1), der Standort-Dokumentation
   (Anlage 2) und den Privacy-Nutrition-Labels (Anlage 3) gehalten —
   Änderungen bitte in allen vier Texten spiegeln (machen wir nach Ihrer
   Freigabe).
3. **Englische Fassung:** erstellen wir nach Freigabe der deutschen
   Fassung als Übersetzung und legen sie Ihnen zur Freigabe vor
   (Briefing Leistung 1).
4. **„du“-Ansprache** entspricht der gesamten Produkt-Copy; auf Wunsch
   stellen wir auf „Sie“ um.

## Teil C — Offene Punkte (Sammelliste der ⚖️-Marker)

| # | Abschnitt | Frage |
|---|---|---|
| 1 | 1 | DSB-Benennungspflicht (Art. 37 DSGVO / § 38 BDSG) bei Solo-Betreiber mit gesundheitsnahen Daten |
| 2 | 3.1/13 | Log-Aufbewahrung Vercel |
| 3 | 3.2 | Cookie-/TDDDG-Bestätigung (statische Seite) |
| 4 | 3.4/13 | Aufbewahrung Trainer-Bewerbungen; Prüfvermerk-Formulierung (Art. 10 DSGVO) |
| 5 | 5.1 | Einordnung als Gesundheitsdaten + Einwilligungs-Konstruktion inkl. Re-Consent |
| 6 | 5.2 | Widerrufsweg (Kontolöschung/Kontakt) ausreichend? |
| 7 | 6 | Eltern-Einwilligung für Kinderprofile (Art. 6/8/9), Kind-Transparenz |
| 8 | 7.1 | Rechtsgrundlage Standort (lit. a vs. lit. b) — plus Labels-Frage „linked vs. not linked“ (Anlage 3) |
| 9 | 7.2 | **Trainer-Datenflüsse: Rollen, AVV, Transparenz, Zugriffsende, Notizen-Aufbewahrung** (zentrale Frage) |
| 10 | 8 | Rechtsgrundlage Push |
| 11 | 11/12 | AVV-/Transfermechanismen je Anbieter; OSMF-Einordnung; UK-Angemessenheit |
| 12 | 13 | Einwilligungsnachweise vs. vollständige Löschung; gesetzliche Fristen |
| 13 | 15 | Art.-22-Einordnung der Fragebogen-Auswertung |
| 14 | 14 | Zuständige Aufsichtsbehörde einsetzen |

## Teil D — Beleg-Anhang (Behauptung → Nachweis; vor Veröffentlichung löschen)

Jede Tatsachenbehauptung dieses Entwurfs ist technisch belegt; die Belege
liegen als Code, Migrationen oder dokumentierte Prüfungen vor und können
der Kanzlei auf Wunsch im Detail gezeigt werden.

| Behauptung | Nachweis |
|---|---|
| EU-Hosting (Supabase, Irland) | Projekt-Region verifiziert 2026-07-02 (Backlog P0.4) |
| Kein Tracking / keine Analytics- oder Werbe-SDKs; Website ohne Cookies/Analytics | Abhängigkeits-Review pubspec 2026-07-07 (keine Ads/Analytics-SDKs); Website-Repo-Grep 2026-07-19 (analytics/gtag/cookie → 0 Treffer; statisches HTML) |
| Passwort nur als Hash | Supabase Auth (Standardverfahren; kein Klartext-Speicherpfad im Code) |
| E-Mail-Bestätigung aktiv | Supabase-Auth-Konfiguration seit 2026-07-04; On-Device-Test 2026-07-04 |
| Standort nur nutzerinitiiert, transient, nicht gespeichert; „Alle“-Modus sendet nichts | `docs/STANDORT_DATENFLUSS_T13.md` (RPC `find_trainers_nearby` ist `STABLE`; kein Persistenzpfad; Grep-Beleg) |
| OSMF erhält IP + Kartengebiet + App-Kennung | ebd., Punkt 6 |
| Trainer-Standorte nur verrauscht (~1 km) veröffentlicht | ebd., Punkt 7 (`_jitter_location`, getrennte Spalten privat/öffentlich) |
| Push über FCM-Geräte-Token, kontoverknüpft, mit Konto löschbar | `lib/core/push/`, Live-Tabelle `device_tokens` (RLS-Policies verifiziert) |
| Sentry ohne PII: nur Fehlertyp/Stacktrace/Gerät, Request-Daten entfernt, EU-Datenhaltung | `lib/core/monitoring/sentry_service.dart` (T15: `sendDefaultPii=false`, beforeSend-Stripping); EU-Region per Founder-Setup-Anleitung (P3) |
| Lokale DB app-privat, geräteverschlüsselt, von Backups ausgeschlossen; Löschung bei Abmeldung/Kontolöschung | Commit `c654998` (iOS backup-excluded Verzeichnis, Android `allowBackup=false`); `clearUserData()` wischt alle 8 lokalen Nutzertabellen |
| In-App-Kontolöschung löscht Server- und Lokaldaten | `profile_screen.dart` → `rpc('delete_user')` + Sign-out-Wipe (P0.5-Verifikation 2026-07-02) |
| Row Level Security auf allen Nutzertabellen; Rollen-/Premium-Änderung nur serverseitig | RLS-Verifikation aller 37 Tabellen 2026-07-02 (P0.1) + Baseline-Migration; DB-Trigger `trg_prevent_direct_role_change` / `trg_prevent_direct_premium_change` (live verifiziert) |
| Chat nur 1:1, kein öffentlicher Feed zum Launch | Launch-Flags `kCommunityEnabled=false` (T04), Membership-Policies |
| Kinderprofile nur unter Eltern-Konto, kein Kinder-Login | Tabelle `reflex_subject_profiles` mit owner-scoped RLS |
| Keine Zahlungsabwicklung Trainer↔Klient über die Plattform | Founder-Entscheidung D5 2026-07-07; kein Zahlungscode im Repo |
| System-E-Mails über Resend (`send.reflexjourney.de`) | Custom-SMTP-Konfiguration (P1.4, verifiziert 2026-06-22) |
| Trainer-Vetting „zeigen, nie speichern“, nur Prüfvermerk | Ablaufbeschreibung Briefing Abschnitt 6 (Prozess-Zusage des Betreibers) |

**Vor Veröffentlichung zusätzlich intern zu verifizieren (Merkliste für uns,
nicht für die Kanzlei):** (a) ob Social Login (4.2) zum Launch aktiv ist;
(b) ob das Beenden einer Trainer-Verbindung in der App durch den Nutzer
selbst möglich ist — falls nein, Formulierung in 7.2 anpassen oder
Support-Weg nennen; (c) endgültige Support-Adresse (R5) einsetzen.
