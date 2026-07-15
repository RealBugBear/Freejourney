// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Reflex Journey';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get languageSelectionTitle => 'Sprache wählen';

  @override
  String get languageSelectionSubtitle =>
      'Du kannst sie später in den Einstellungen ändern.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageContinue => 'Weiter';

  @override
  String get tryShortAssessment => 'Kurztest ohne Konto ausprobieren';

  @override
  String get signInWithAlternativeDivider => 'oder';

  @override
  String get signInWithApple => 'Mit Apple fortfahren';

  @override
  String get signInWithGoogle => 'Mit Google fortfahren';

  @override
  String get authErrorSocialConfiguration =>
      'Social Login ist noch nicht korrekt konfiguriert. Bitte Support kontaktieren.';

  @override
  String get authErrorSocialCancelled => 'Anmeldung wurde abgebrochen.';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get passwordResetSent =>
      'Wir haben dir eine E-Mail zum Zurücksetzen des Passworts gesendet.';

  @override
  String get signUpConfirmEmailSent =>
      'Fast geschafft! Wir haben dir eine E-Mail zur Bestätigung deines Kontos gesendet. Bitte tippe auf den Link darin, dann kannst du dich anmelden.';

  @override
  String get authErrorInvalidCredentials => 'E-Mail oder Passwort ist falsch.';

  @override
  String get authErrorEmailInUse =>
      'Diese E-Mail-Adresse ist bereits registriert.';

  @override
  String get authErrorWeakPassword =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get startTraining => 'Einheit beginnen';

  @override
  String currentDay(int day, int total) {
    return 'Tag $day von $total';
  }

  @override
  String get dailyStreak => 'Regelmäßigkeit';

  @override
  String weeklyProgress(int count, int goal) {
    return '$count von $goal diese Woche';
  }

  @override
  String get goldenDay => 'Golden Day';

  @override
  String daysRemaining(int days) {
    return '$days Tage verbleibend';
  }

  @override
  String get trainingMode => 'Einheitsmodus';

  @override
  String get tutorialMode => 'Tutorial';

  @override
  String get routineMode => 'Routine';

  @override
  String get silentMode => 'Silent';

  @override
  String get hapticMode => 'Haptisch';

  @override
  String get voiceCuesMode => 'Stimme & Cues';

  @override
  String get exercisePosition => 'Ausgangsposition';

  @override
  String get exerciseMovement => 'Bewegung';

  @override
  String get exerciseHints => 'Hinweise';

  @override
  String exerciseReps(int count) {
    return '$count Wiederholungen';
  }

  @override
  String get sessionComplete => 'Einheit abgeschlossen';

  @override
  String get sessionCompleteSubtitle =>
      'Du hast deine heutige Einheit abgeschlossen.';

  @override
  String get moodCheckIn => 'Wie geht es dir?';

  @override
  String get moodLabel => 'Stimmung';

  @override
  String get energyLabel => 'Energie';

  @override
  String get stressLabel => 'Stress';

  @override
  String get moodSkip => 'Überspringen';

  @override
  String get moodSubmit => 'Speichern';

  @override
  String get moodChartEmpty =>
      'Trage eine Einheit ein, um dein Befinden im Verlauf zu sehen.';

  @override
  String get intakeAssessmentTitle => 'Programmstart';

  @override
  String get intakeWelcomeTitle =>
      'Willkommen in deinem Reflexintegrations-Programm';

  @override
  String get intakeWelcomeBody =>
      'Reflex Journey begleitet dich bei der Integration pränataler Reflexe — ein Prozess, der dabei helfen kann, tief verwurzelte körperliche und emotionale Muster zu transformieren.';

  @override
  String get intakeTrainerTitle => 'Empfehlung: Mit Trainer starten';

  @override
  String get intakeTrainerBody =>
      'Wir empfehlen, das Programm mit einem zertifizierten Trainer zu beginnen und begleiten zu lassen. Ein Trainer führt isometrische Partnerübungen durch, die klares Spüren von Richtung, Bewegung und Widerstand unterstützen. Ohne diese Begleitung braucht der Körper in der Regel mehr ruhige Wiederholung.';

  @override
  String get intakeQuestionLabel => 'Eine Frage zu deinem Start';

  @override
  String get questionIsometricWithTrainer =>
      'Hast du bereits isometrische Partnerübungen mit einem Trainer durchgeführt?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String durationRecommendation(int weeks) {
    return 'Empfohlene Dauer: $weeks Wochen';
  }

  @override
  String get adjustDuration => 'Dauer anpassen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get durationWithoutTrainerInfo =>
      'Ohne begleitenden Trainer empfehlen wir etwa 8 Wochen, damit der Körper mehr Zeit für die Integration hat.';

  @override
  String get durationTrainerMinimumInfo =>
      'Mit begleitendem Trainer empfehlen wir mindestens 4 Wochen. Du kannst die Dauer verlängern, wenn du mehr Integrationszeit möchtest.';

  @override
  String get trainerOnboardingTitle => 'Trainer-Begleitung';

  @override
  String get trainerOnboardingFindTitle =>
      'Starte mit einem Trainer in deiner Nähe';

  @override
  String get trainerOnboardingFindBody =>
      'Da du die isometrische Aktivierung noch nicht mit einem Trainer gemacht hast, empfehlen wir dir, zuerst einen passenden Trainer zu finden. Du kannst trotzdem direkt starten, wenn du das möchtest.';

  @override
  String get trainerOnboardingConnectTitle =>
      'Verknüpfe dich mit deinem Trainer';

  @override
  String get trainerOnboardingConnectBody =>
      'Wenn du bereits mit einem Trainer gearbeitet hast, kannst du dich jetzt verbinden. So kann dein Trainer deinen Fortschritt begleiten und bei Bedarf Termine abstimmen.';

  @override
  String get trainerOnboardingSearchCta => 'Trainer in meiner Nähe suchen';

  @override
  String get trainerOnboardingInviteCta => 'Einladungscode eingeben';

  @override
  String get trainerOnboardingSkipCta => 'Später machen';

  @override
  String get trainerOnboardingInviteTitle => 'Mit Trainer verbinden';

  @override
  String get trainerOnboardingInviteBody =>
      'Gib den 6-stelligen Einladungscode ein, den du von deinem Trainer erhalten hast.';

  @override
  String get trainerOnboardingInviteInvalid =>
      'Bitte 6-stelligen Code eingeben.';

  @override
  String get trainerOnboardingInviteFailed =>
      'Fehler beim Verbinden mit dem Trainer.';

  @override
  String get trainerOnboardingContinueAfterRequest =>
      'Weiter zur Dauerempfehlung';

  @override
  String get completionQuestionnaireTitle => 'Abschlussreflexion';

  @override
  String get completionCelebrationTitle => 'Paket abgeschlossen';

  @override
  String get completionCelebrationSubtitle =>
      'Du hast dieses Paket über die geplante Zeit begleitet.';

  @override
  String get completionNextPackage => 'Weiter zum nächsten Paket';

  @override
  String get completionBackToDashboard => 'Zum Dashboard';

  @override
  String get completionReachedTitle => 'Paketdauer erreicht';

  @override
  String get completionReachedBody =>
      'Du hast die geplante Paketdauer erreicht. In Heute findest du jetzt oben eine kurze Einschätzung, mit der du das Paket abschließen oder um 7 Tage verlängern kannst.';

  @override
  String get completionPlaceholderQuestion =>
      'Platzhalter-Einschätzung: Fühlt sich dieses Paket stimmig abgeschlossen an?';

  @override
  String get completionPass => 'Paket abschließen';

  @override
  String get completionInsufficient => 'Noch 7 Tage wiederholen';

  @override
  String get completionMoroReturnSubtitle =>
      'Der erneute Moro-Durchlauf ist abgeschlossen. Du kehrst jetzt zu deinem unterbrochenen Paket zurück und startest dort wieder bei Tag 1.';

  @override
  String get completionBackToInterruptedPackage =>
      'Zurück zum unterbrochenen Paket';

  @override
  String get completionExtendedTitle => 'Noch eine Woche';

  @override
  String get completionExtendedSubtitle =>
      'Du hast 7 weitere Tage in diesem Paket.';

  @override
  String get completionQuestion =>
      'Hast du seit Beginn dieses Pakets stärkere emotionale oder stressbezogene Reaktionen bemerkt und konntest du sie etwas besser einordnen oder regulieren?';

  @override
  String get completionYes => 'Ja, ich bin bereit';

  @override
  String get completionNotYet => 'Noch nicht';

  @override
  String get packages => 'Programm';

  @override
  String get packageLocked => 'Gesperrt';

  @override
  String get packageCurrent => 'Aktuell';

  @override
  String get packageCompleted => 'Abgeschlossen';

  @override
  String get paywallTitle => 'Alle Pakete freischalten';

  @override
  String get paywallSubtitle =>
      'Paket 1 bleibt für immer kostenlos. Mit Premium schaltest du alle weiteren Reflexpakete frei — für dich und deine Familienprofile.';

  @override
  String get paywallDurationNote =>
      'Das gesamte Programm dauert typischerweise 10–12 Monate — in deinem Tempo, Pausen inklusive.';

  @override
  String get paywallMonthlyTitle => 'Monatlich';

  @override
  String get paywallPerMonth => 'pro Monat';

  @override
  String get paywallYearlyTitle => 'Jährlich';

  @override
  String get paywallPerYear => 'pro Jahr';

  @override
  String get paywallYearlyBadge => '2 Monate geschenkt';

  @override
  String get paywallLifetimeTitle => 'Einmalig';

  @override
  String get paywallOnce => 'einmalig, dauerhaft';

  @override
  String get paywallUnlock => 'Freischalten';

  @override
  String get paywallRestore => 'Käufe wiederherstellen';

  @override
  String get paywallNotAvailable =>
      'Käufe sind in dieser Version noch nicht verfügbar.';

  @override
  String get paywallCancelNote => 'Abos sind jederzeit kündbar.';

  @override
  String get packageAvailable => 'Verfügbar';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsTraining => 'Einheiten';

  @override
  String get settingsReminders => 'Erinnerungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsTheme => 'Erscheinungsbild';

  @override
  String get settingsWeeklyGoal => 'Wochenziel';

  @override
  String get settingsChildAssist => 'Kinderunterstützung';

  @override
  String get settingsConnectTrainer => 'Trainer verbinden';

  @override
  String get moroRestartSettingsTitle => 'Zurück zum Moro';

  @override
  String get moroRestartSettingsSubtitle =>
      'Moro für 4 Wochen neu starten und das aktuelle Paket unterbrechen.';

  @override
  String get moroRestartTitle => 'Zum Moro zurückkehren?';

  @override
  String get moroRestartBody =>
      'Der Moro-Reflex kann im Unterschied zu vielen anderen Reflexen durch stark belastende oder traumatische Ereignisse erneut aktiviert werden, zum Beispiel durch einen Autounfall, den Tod eines Angehörigen oder andere intensive Schockerlebnisse.\n\nWenn du fortfährst, wird dein aktuelles Paket unterbrochen. Du startest Moro für 4 Wochen neu. Nach dem Moro-Abschluss kehrst du zu deinem unterbrochenen Paket zurück und beginnst dort wieder bei Tag 1.';

  @override
  String get moroRestartConfirm => 'Moro neu starten';

  @override
  String get reminderEnabled => 'Erinnerungen aktiviert';

  @override
  String get reminderWindow => 'Erinnerungsfenster';

  @override
  String get quietHours => 'Ruhezeiten';

  @override
  String get reminderFrom => 'Von';

  @override
  String get reminderTo => 'Bis';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String weeklyGoalSessions(int goal) {
    return '$goal Einheiten/Woche';
  }

  @override
  String get settingsFeedback => 'Einheits-Feedback';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get disclaimer => 'Medizinischer Hinweis';

  @override
  String get disclaimerText =>
      'Diese Einheiten ersetzen keine medizinische Behandlung. Bitte konsultiere einen Arzt, wenn du gesundheitliche Bedenken hast. Achte auf die Signale deines Körpers und mache Pausen, wenn nötig.';

  @override
  String get disclaimerAccept => 'Verstanden, weiter';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorNoNetwork => 'Keine Internetverbindung.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get done => 'Fertig';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get trainerClients => 'Meine Klienten';

  @override
  String get trainerNoClients => 'Noch keine Klienten verknüpft.';

  @override
  String get trainerNoClientsHint =>
      'Erstelle einen Einladungscode und teile ihn mit deinem Klienten.';

  @override
  String get trainerInviteCode => 'Einladungscode';

  @override
  String get trainerInviteCodeHint =>
      'Teile diesen Code mit deinem Klienten. Er kann einmalig verwendet werden.';

  @override
  String get trainerGenerateCode => 'Einladung erstellen';

  @override
  String get trainerCopyCode => 'Code kopieren';

  @override
  String get trainerCodeCopied => 'Code in die Zwischenablage kopiert.';

  @override
  String get trainerAtRisk => 'Risiko';

  @override
  String trainerLastActive(int days) {
    return 'Vor $days Tag(en)';
  }

  @override
  String get trainerNotes => 'Trainer-Notizen';

  @override
  String get trainerNotesHint => 'Private Notizen zu diesem Klienten...';

  @override
  String get trainerNotesSaved => 'Notizen gespeichert.';

  @override
  String get trainerRecentSessions => 'Letzte Einheiten (30 Tage)';

  @override
  String get trainerNoSessions => 'Keine Einheiten in den letzten 30 Tagen.';

  @override
  String get trainerView => 'Trainer-Ansicht';

  @override
  String get connectToTrainer => 'Mit Trainer verbinden';

  @override
  String get enterInviteCode => 'Einladungscode eingeben';

  @override
  String get connectToTrainerSuccess => 'Mit Trainer verbunden!';

  @override
  String get connectToTrainerError =>
      'Ungültiger oder abgelaufener Einladungscode.';

  @override
  String get loading => 'Lädt...';

  @override
  String get skip => 'Überspringen';

  @override
  String dayNumber(int day) {
    return 'Tag $day';
  }

  @override
  String weeksCount(int count) {
    return '$count Wochen';
  }

  @override
  String daysCount(int count) {
    return '$count Tage';
  }

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get journal => 'Tagebuch';

  @override
  String get journalEmptyTitle => 'Noch keine Einträge.';

  @override
  String get journalEmptySubtitle =>
      'Schreib auf, was du in deinem Alltag beobachtest — nach einer Einheit oder wann immer du möchtest.';

  @override
  String get journalEmptyHint =>
      'Halte fest, was sich in deinem Alltag verändert.';

  @override
  String get journalNewEntry => 'Neue Notiz';

  @override
  String get journalPostTrainingTitle => 'Veränderungen im Alltag?';

  @override
  String get journalPostTrainingHint =>
      'Hast du etwas bemerkt — in deinem Schlaf, deinen Reaktionen, deinem Körpergefühl?';

  @override
  String get journalPlaceholder => 'Schreib hier deine Beobachtung...';

  @override
  String get journalLoadFailed => 'Einträge konnten nicht geladen werden.';

  @override
  String get moodHistory => 'Stimmungsverlauf';

  @override
  String get profile => 'Profil';

  @override
  String get completionBannerTitle => 'Paket bereit zur Einschätzung';

  @override
  String get completionBannerSubtitle =>
      'Beantworte den kurzen Fragebogen, um dieses Paket abzuschließen oder um 7 Tage zu verlängern.';

  @override
  String get settingsDataSync => 'Daten & Sync';

  @override
  String get settingsTrainingModeDescription =>
      'Tutorial ist für den Einstieg. Routine ist kompakter.';

  @override
  String get settingsAdvanced => 'Erweitert';

  @override
  String get settingsResetIntroductions => 'Einführungen erneut anzeigen';

  @override
  String get settingsResetIntroductionsDescription =>
      'Zeigt die kurzen Hinweise auf Heute, Verlauf, Begleitung und Profil wieder an.';

  @override
  String get settingsResetIntroductionsSuccess =>
      'Einführungen werden wieder angezeigt.';

  @override
  String get syncStatusOk => 'Alles synchronisiert';

  @override
  String syncStatusPending(int count) {
    return '$count Einträge ausstehend';
  }

  @override
  String syncStatusFailed(int count) {
    return '$count Einträge fehlgeschlagen';
  }

  @override
  String get syncInProgress => 'Synchronisiert...';

  @override
  String get syncNow => 'Jetzt sync';

  @override
  String get errorSaveFailed =>
      'Speichern fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get errorLoadFailed => 'Daten konnten nicht geladen werden.';

  @override
  String get errorLoadFailedInline => 'Fehler beim Laden';

  @override
  String get validationRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get validationInvalidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get validationPasswordTooShort =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileChangePassword => 'Passwort ändern';

  @override
  String get profileChangePasswordSent =>
      'Passwort-Reset-E-Mail wurde gesendet.';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get passwordConfirm => 'Passwort bestätigen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get passwordChanged => 'Passwort erfolgreich geändert.';

  @override
  String get passwordSet => 'Neues Passwort gesetzt. Bitte einloggen.';

  @override
  String get authErrorSamePassword =>
      'Das neue Passwort muss sich vom bisherigen unterscheiden.';

  @override
  String get authErrorInvalidCurrentPassword =>
      'Das aktuelle Passwort ist falsch.';

  @override
  String get validationPasswordMismatch => 'Passwörter stimmen nicht überein.';

  @override
  String get profileDeleteAccount => 'Konto löschen';

  @override
  String get profileDeleteAccountTitle => 'Konto löschen?';

  @override
  String get profileDeleteAccountBody =>
      'Dein Konto und alle deine Daten werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get profileDeleteAccountConfirm => 'Dauerhaft löschen';

  @override
  String get profileDeleteAccountSuccess => 'Konto gelöscht.';

  @override
  String get profileDeleteAccountError =>
      'Konto konnte nicht gelöscht werden. Bitte kontaktiere den Support.';

  @override
  String get redeemAccessCodeTitle => 'Gründungscode einlösen';

  @override
  String get redeemAccessCodeSubtitle =>
      'Schalte mit deinem Code alle kostenpflichtigen Pakete frei.';

  @override
  String get redeemAccessCodeHint => 'Code eingeben';

  @override
  String get redeemAccessCodeAction => 'Einlösen';

  @override
  String get redeemAccessCodeSuccess =>
      'Code eingelöst. Premium-Zugang ist aktiv.';

  @override
  String get redeemAccessCodeErrorInvalid => 'Dieser Code ist ungültig.';

  @override
  String get redeemAccessCodeErrorUsed =>
      'Dieser Code wurde bereits eingelöst.';

  @override
  String get redeemAccessCodeErrorExpired => 'Dieser Code ist abgelaufen.';

  @override
  String get redeemAccessCodeErrorUnsupported =>
      'Dieser Code-Typ wird noch nicht unterstützt.';

  @override
  String get redeemAccessCodeErrorUnauthorized =>
      'Bitte melde dich erneut an und versuche es noch einmal.';

  @override
  String get redeemAccessCodeErrorUnknown =>
      'Code konnte nicht eingelöst werden. Bitte erneut versuchen.';

  @override
  String get trainerDashboard => 'Trainer-Dashboard';

  @override
  String get trainerTabTrainees => 'Klienten';

  @override
  String get trainerTabCalendar => 'Kalender';

  @override
  String get trainerMyLink => 'Mein Einladungslink';

  @override
  String get trainerCopyLink => 'Link kopieren';

  @override
  String get trainerLinkCopied => 'Link kopiert.';

  @override
  String get trainerScheduleAppointment => 'Planen';

  @override
  String get trainerBookNow => 'Jetzt buchen';

  @override
  String get trainerAppointmentMissing => 'Termin fehlt';

  @override
  String get trainerNoAppointments => 'Keine Termine geplant.';

  @override
  String get appointmentSchedulerTitle => 'Termin buchen';

  @override
  String appointmentWith(String name) {
    return 'Termin mit $name';
  }

  @override
  String get appointmentSessionTitle => 'Isometrische Partnerübung';

  @override
  String get appointmentFreeSlotsTitle => 'Freie Zeiten (nächste 14 Tage):';

  @override
  String get appointmentBook => 'Buchen';

  @override
  String get appointmentOtherTime => 'Andere Zeit wählen';

  @override
  String get appointmentLocationLabel => 'Ort (optional)';

  @override
  String get appointmentNotesLabel => 'Notiz';

  @override
  String get appointmentConfirmButton => 'Termin buchen';

  @override
  String get appointmentLoadingSlots => 'Freie Zeiten werden gesucht...';

  @override
  String get appointmentNoFreeSlots => 'Keine freien Zeitfenster gefunden.';

  @override
  String get appointmentNoCalendars => 'Keine Kalender gefunden.';

  @override
  String get appointmentSelectCalendarTitle => 'Arbeitskalender wählen';

  @override
  String get appointmentSelectCalendarSubtitle =>
      'Wähle den Kalender für Reflex Journey-Termine.';

  @override
  String get appointmentStatusPlanned => 'Geplant';

  @override
  String get appointmentStatusConfirmed => 'Bestätigt';

  @override
  String get appointmentStatusCancelled => 'Abgesagt';

  @override
  String get appointmentStatusDone => 'Abgeschlossen';

  @override
  String get appointmentOpenInCalendar => 'Im Kalender öffnen';

  @override
  String get trainerRequestsTitle => 'Anfragen';

  @override
  String get trainerRequestNoRequests => 'Keine offenen Anfragen.';

  @override
  String get trainerRequestAccept => 'Annehmen';

  @override
  String get trainerRequestDecline => 'Ablehnen';

  @override
  String get trainerDiscoveryTitle => 'Trainer finden';

  @override
  String trainerDiscoveryRadiusLabel(int radius) {
    return '$radius km';
  }

  @override
  String get trainerDiscoveryAll => 'Alle';

  @override
  String get trainerDiscoveryNearby => 'Umkreis';

  @override
  String get trainerDiscoveryTabMap => 'Karte';

  @override
  String get trainerDiscoveryTabList => 'Liste';

  @override
  String get trainerDiscoverySearchHint => 'Trainer suchen';

  @override
  String get trainerDiscoveryNoMatches => 'Keine Treffer.';

  @override
  String get trainerDiscoveryLocationCtaText =>
      'Finde Trainer in deiner Nähe. Dein Standort wird nur für diese Suche verwendet und nicht gespeichert.';

  @override
  String get trainerDiscoveryLocationCtaButton => 'Standort verwenden';

  @override
  String get trainerDiscoveryServiceDisabled =>
      'Die Ortungsdienste deines Geräts sind ausgeschaltet. Schalte sie ein, um Trainer in deiner Nähe zu finden.';

  @override
  String get trainerDiscoveryOpenLocationSettings => 'Ortungs-Einstellungen';

  @override
  String get trainerDiscoveryDenied =>
      'Ohne Standort-Freigabe zeigen wir dir alle Trainer ohne Umkreisfilter.';

  @override
  String get trainerDiscoveryDeniedForever =>
      'Der Standort-Zugriff ist für die App deaktiviert. Du kannst ihn in den Einstellungen wieder erlauben.';

  @override
  String get trainerDiscoveryOpenAppSettings => 'Einstellungen öffnen';

  @override
  String get trainerDiscoveryLocationError =>
      'Dein Standort konnte nicht ermittelt werden. Versuch es gleich noch einmal.';

  @override
  String get trainerDiscoveryRetry => 'Erneut versuchen';

  @override
  String get trainerDiscoveryEmptyGlobalTitle =>
      'Noch keine Trainer freigeschaltet';

  @override
  String get trainerDiscoveryEmptyGlobalBody =>
      'Wir prüfen und schalten gerade die ersten Trainer frei. Schau bald wieder vorbei — dein Training läuft auch ohne Trainer weiter.';

  @override
  String get trainerDiscoveryEmptyGlobalCta => 'Zurück zum Training';

  @override
  String get trainerDiscoveryEmptyNearbyTitle => 'Keine Trainer in deiner Nähe';

  @override
  String get trainerDiscoveryEmptyNearbyBody =>
      'Vergrößere den Umkreis oder sieh dir alle Trainer an.';

  @override
  String get trainerDiscoveryEmptyNearbyCta => 'Alle Trainer anzeigen';

  @override
  String get trainerDiscoveryLoadErrorTitle =>
      'Trainer konnten nicht geladen werden';

  @override
  String get trainerDiscoveryLoadErrorBody =>
      'Prüfe deine Internetverbindung und versuch es erneut.';

  @override
  String get trainerDiscoveryOfflineBanner =>
      'Du bist offline — die Karte braucht eine Internetverbindung.';

  @override
  String trainerDiscoveryDistanceLabel(double distance) {
    return '$distance km entfernt';
  }

  @override
  String get trainerDiscoveryRequestAlreadySent =>
      'Anfrage wurde bereits gesendet.';

  @override
  String get trainerDiscoveryRequestAlreadyConnected =>
      'Du bist bereits mit diesem Trainer verbunden.';

  @override
  String get trainerDiscoveryRequestSent => 'Anfrage gesendet.';

  @override
  String get trainerDiscoverySendRequest => 'Anfrage senden';

  @override
  String get trainerPublicProfileTitle => 'Trainer-Profil';

  @override
  String get trainerPublicProfileVerified => 'Verifizierter Trainer';

  @override
  String get trainerSetupTitle => 'Trainer-Profil';

  @override
  String get trainerSetupDisplayNameLabel => 'Anzeigename';

  @override
  String get trainerSetupBioLabel => 'Bio';

  @override
  String get trainerSetupEmailLabel => 'E-Mail';

  @override
  String get trainerSetupPhoneLabel => 'Telefon';

  @override
  String get trainerSetupLocationTitle => 'Standort';

  @override
  String get trainerSetupLocationHint =>
      'Wähle deinen Trainer-Standort, damit Klienten dich in der Nähe finden.';

  @override
  String get trainerSetupLocationMissing => 'Bitte wähle einen Standort.';

  @override
  String get trainerSetupSubmit => 'Zur Prüfung einreichen';

  @override
  String get trainerSetupPendingTitle => 'Profil wird geprüft';

  @override
  String get trainerSetupPendingBody =>
      'Wir benachrichtigen dich, sobald dein Trainer-Profil freigegeben ist.';

  @override
  String get adminTrainerReviewTab => 'Trainer-Prüfung';

  @override
  String get adminTrainerNoPending => 'Keine Trainer-Profile zur Prüfung.';

  @override
  String get adminTrainerApproveSuccess => 'Trainer freigegeben.';

  @override
  String get adminTrainerSuspendSuccess => 'Trainer gesperrt.';

  @override
  String get adminTrainerApprove => 'Freigeben';

  @override
  String get adminTrainerSuspend => 'Sperren';
}
