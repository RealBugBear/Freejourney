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
  String get loginDiscoverLead =>
      'Gleich entdeckst du dein persönliches Reflex-Profil — in deinem Tempo.';

  @override
  String get consentShortTitle => 'Kurz zustimmen';

  @override
  String get consentDiscoverLead =>
      'Dann entdeckst du dein persönliches Reflex-Profil — in deinem Tempo.';

  @override
  String get consentRowSafety => 'Sicherheit';

  @override
  String get consentRowTerms => 'Nutzung';

  @override
  String get consentRowPrivacy => 'Datenschutz';

  @override
  String get consentReadLinkHint => 'Lesen';

  @override
  String get consentCheckboxLabel =>
      'Ich habe die Hinweise gelesen und stimme den Nutzungsbedingungen sowie der Datenschutzerklärung zu.';

  @override
  String get consentDiscoverCta => 'Reflex-Profil entdecken';

  @override
  String get profileContactNameDiscoverBody =>
      'Dein Kontaktname ist für Trainer sichtbar — danach entdeckst du dein Reflex-Profil.';

  @override
  String get profileContactNameDiscoverBodyWithCommunity =>
      'Dein Kontaktname ist für Trainer sichtbar und kann sich von deinem Community-Namen unterscheiden — danach entdeckst du dein Reflex-Profil.';

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
  String get tutorialMode => 'Lernmodus';

  @override
  String get routineMode => 'Routinemodus';

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
  String get redeemAccessCodeTitle => 'Zugangscode einlösen';

  @override
  String get redeemAccessCodeSubtitle =>
      'Nutze einen Vorteilscode für Premium oder Studio.';

  @override
  String get redeemAccessCodeDialogBody =>
      'Ein Code kann Premium- oder Studio-Zugang direkt freischalten oder auf ein Store-Angebot verweisen.';

  @override
  String get redeemAccessCodeHint => 'Code eingeben';

  @override
  String get redeemAccessCodeAction => 'Einlösen';

  @override
  String get redeemAccessCodeSuccess =>
      'Code eingelöst. Premium-Zugang ist aktiv. Dies ist kein Abo und es erfolgt keine automatische Belastung.';

  @override
  String get redeemAccessCodeBenefitPremium => 'Premium';

  @override
  String get redeemAccessCodeBenefitStudio => 'Studio';

  @override
  String redeemAccessCodeInternalGrantSuccess(String benefit) {
    return 'Code eingelöst. $benefit-Zugang ist aktiv. Dies ist kein Abo und es erfolgt keine automatische Belastung.';
  }

  @override
  String redeemAccessCodeInternalGrantUntil(String benefit, String date) {
    return 'Code eingelöst. $benefit-Zugang ist bis $date aktiv. Dies ist kein Abo und es erfolgt keine automatische Belastung.';
  }

  @override
  String get redeemAccessCodeStoreOfferPending =>
      'Store-Angebot erkannt. Der Zugang ist noch nicht aktiv. Der Angebotsablauf ist in einer späteren Version verfügbar.';

  @override
  String get redeemAccessCodeUnknownBenefit =>
      'Der Code wurde erkannt, aber der Zugang konnte nicht bestätigt werden. Es wurde kein Zugang aktiviert. Bitte kontaktiere den Support.';

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
  String get redeemAccessCodeErrorCampaignInactive =>
      'Diese Vorteilskampagne ist nicht mehr aktiv.';

  @override
  String get redeemAccessCodeErrorRoleNotEligible =>
      'Dieser Code ist für deine Kontorolle nicht verfügbar.';

  @override
  String get redeemAccessCodeErrorLimitReached =>
      'Dieser Code hat sein Einlöselimit erreicht.';

  @override
  String get redeemAccessCodeErrorOfferUnavailable =>
      'Für diesen Code ist auf deinem Gerät kein Store-Angebot verfügbar.';

  @override
  String get redeemAccessCodeErrorInvalidPlatform =>
      'Dieser Code kann auf diesem Gerät nicht eingelöst werden.';

  @override
  String get redeemAccessCodeErrorServiceUnavailable =>
      'Die Code-Einlösung ist vorübergehend nicht verfügbar. Bitte versuche es später erneut.';

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

  @override
  String get saving => 'Speichern...';

  @override
  String get entryPointsTitle => 'Viele Wege führen hierher';

  @override
  String get entryPointsSubtitle =>
      'Reflexintegration ist für sehr unterschiedliche Menschen relevant. Schau, was für dich klingt.';

  @override
  String get entryPointsChipQuestion =>
      'Was klingt für dich vertraut? (optional, Mehrfachauswahl)';

  @override
  String get entryPointsSelectionNote =>
      'Deine Auswahl ändert nichts am Training — sie hilft uns zu verstehen, wer die App nutzt.';

  @override
  String get entryPointsShowMore => 'Mehr';

  @override
  String get entryPointsShowLess => 'Weniger';

  @override
  String get entryPointsBodyTitle => 'Körper & Therapie';

  @override
  String get entryPointsBodyTeaser =>
      'Verspannungen, Fehlhaltungen, Empfehlung vom Therapeuten';

  @override
  String get entryPointsBodyDetail =>
      'Aktive Reflexmuster können zu dauerhafter Muskelanspannung führen — unabhängig von äußeren Auslösern. Physiotherapeut·innen und Ergotherapeut·innen empfehlen Reflexintegration häufig ergänzend, wenn klassische Behandlung nicht vollständig greift.\n\nTypische Hinweise: chronische Rücken- oder Nackenverspannungen, Kieferspannung, Fehlhaltungen die immer wiederkehren.';

  @override
  String get entryPointsBodyChip => 'Körper';

  @override
  String get entryPointsBodySource =>
      'Vgl. Goddard Blythe: (Über)leben mit Reflexen';

  @override
  String get entryPointsCoordinationTitle => 'Koordination & Leistung';

  @override
  String get entryPointsCoordinationTeaser =>
      'Bewegungsqualität, Gleichgewicht, sportliche Koordination';

  @override
  String get entryPointsCoordinationDetail =>
      'Unintegrierte Reflexe binden motorische Ressourcen — was sich in eingeschränkter Koordination, verlangsamten Reaktionen oder Gleichgewichtsproblemen zeigen kann. Sportler·innen nutzen Reflexintegration um koordinative Grenzen zu erweitern, die durch klassisches Training nicht erreichbar sind.\n\nTypische Hinweise: Bewegungsabläufe fühlen sich schwerer an als nötig, Asymmetrien, Gleichgewicht unter Druck.';

  @override
  String get entryPointsCoordinationChip => 'Koordination';

  @override
  String get entryPointsCoordinationSource =>
      'Vgl. Blomberg: Bewegungen die heilen';

  @override
  String get entryPointsEmotionTitle => 'Emotionale Regulation & Innenwelt';

  @override
  String get entryPointsEmotionTeaser =>
      'Stressreaktionen, Reizempfindlichkeit, Selbstwahrnehmung';

  @override
  String get entryPointsEmotionDetail =>
      'Manche Reflexmuster beeinflussen direkt wie das Nervensystem auf Reize reagiert — Stressempfindlichkeit, emotionale Reaktivität, Reizüberflutung. Rhythmische Bewegung kann helfen, das Nervensystem zu regulieren und Zugang zu inneren Zuständen zu finden.\n\nTypische Hinweise: schnelle emotionale Überflutung, Schwierigkeit zur Ruhe zu kommen, Körperspannung in Stress. Verläuft sehr individuell.';

  @override
  String get entryPointsEmotionChip => 'Emotionale Regulation';

  @override
  String get entryPointsEmotionSource => 'Vgl. Blomberg: Bewegungen die heilen';

  @override
  String get entryPointsChildTitle => 'Mein Kind: Schule & Entwicklung';

  @override
  String get entryPointsChildTeaser =>
      'Konzentration, Lernen, Schule — als Elternteil';

  @override
  String get entryPointsChildDetail =>
      'Frühkindliche Reflexmuster die nicht vollständig integriert wurden, können sich später in Schwierigkeiten beim Lesen, Schreiben oder Konzentrieren zeigen — oft ohne klare organische Ursache.\n\nTypische Hinweise: Kind kommt in der Schule nicht mit, kann sich schwer fokussieren, ist unruhig im Unterricht, Feinmotorik oder Lesen bereitet Mühe.';

  @override
  String get entryPointsChildChip => 'Mein Kind';

  @override
  String get entryPointsChildSource =>
      'Vgl. Goddard Blythe: (Über)leben mit Reflexen';

  @override
  String get entryPointsCuriosityTitle => 'Neugierde & Entdeckung';

  @override
  String get entryPointsCuriosityTeaser =>
      'Kein konkretes Problem — einfach erkunden';

  @override
  String get entryPointsCuriosityDetail =>
      'Manche Menschen kommen ohne konkretes Symptom — sie haben von Reflexintegration gehört und sind neugierig was rhythmische Bewegung über mehrere Wochen verändert. Das ist ein vollständig gültiger Einstieg.\n\nDas Training wirkt unabhängig davon ob man ein \"Problem\" benennen kann oder nicht.';

  @override
  String get entryPointsCuriosityChip => 'Einfach neugierig';

  @override
  String get forWhomTitle => 'Für wen trainierst du?';

  @override
  String get forWhomSubtitle =>
      'Du kannst später jederzeit weitere Profile hinzufügen.';

  @override
  String get forWhomSelfTitle => 'Für mich';

  @override
  String get forWhomSelfSubtitle => 'Eigenes Erwachsenenprofil anlegen';

  @override
  String get forWhomChildTitle => 'Für mein Kind';

  @override
  String get forWhomChildSubtitle => 'Kinderprofil anlegen';

  @override
  String get forWhomChildNameLabel => 'Name oder Spitzname';

  @override
  String get forWhomBirthDateLabel => 'Geburtsdatum *';

  @override
  String get forWhomBirthDateHelper =>
      'Pflichtfeld – für die Altersauswertung benötigt';

  @override
  String get forWhomBirthDatePickerHelp => 'Geburtsdatum auswählen';

  @override
  String get forWhomSelectDate => 'Datum auswählen';

  @override
  String get forWhomCreateChildProfile => 'Kinderprofil anlegen';

  @override
  String get forWhomMissingFields => 'Bitte Name und Geburtsdatum angeben.';

  @override
  String forWhomCreateError(String error) {
    return 'Fehler beim Anlegen: $error';
  }

  @override
  String forWhomReflexProfileSheetTitle(String name) {
    return 'Reflexprofil für $name anlegen?';
  }

  @override
  String get forWhomReflexProfileSheetBody =>
      'Der Fragebogen dauert ca. 10–15 Minuten und hilft dabei, gezielt das passende Training zu empfehlen.';

  @override
  String get forWhomStartReflexProfile => 'Jetzt Reflexprofil ausfüllen';

  @override
  String get forWhomLaterToTraining => 'Später — direkt zum Training';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get today => 'Heute';

  @override
  String get packageShortMoro => 'Moro';

  @override
  String get packageShortSpinalGalant => 'Spinaler Galant';

  @override
  String get packageShortTlr => 'TLR';

  @override
  String get packageShortBabkin => 'Babkin';

  @override
  String get packageShortSuchSaug => 'Such-Saug';

  @override
  String get packageShortAtnr => 'ATNR';

  @override
  String get packageShortStnr => 'STNR';

  @override
  String get packageShortBabinski => 'Babinski';

  @override
  String get packageShortLandau => 'Landau';

  @override
  String get dashboardRoutineTipTitle => 'Du kennst die Übungen jetzt';

  @override
  String get dashboardRoutineTipBody =>
      'Probiere den Routine-Modus — er führt dich komplett hands-free per Audio durch das Training.';

  @override
  String get dashboardLogUnitTitle => 'Einheit eintragen';

  @override
  String get dashboardLogUnitBody =>
      'Die heutige Einheit wird eingetragen. Danach kannst du direkt nachspüren und eine Beobachtung festhalten.';

  @override
  String get dashboardLogUnitConfirm => 'Heute geübt eintragen';

  @override
  String get dashboardLogUnitSuccess =>
      'Die heutige Einheit wurde eingetragen.';

  @override
  String dashboardLogUnitError(String error) {
    return 'Die Einheit konnte nicht eingetragen werden: $error';
  }

  @override
  String get reminderSessionTitle => 'Zeit für deine Einheit';

  @override
  String get reminderSessionBody => 'Nimm dir Zeit für deine heutige Einheit.';

  @override
  String get dashboardJointTrainingTitle => 'Zusammen trainieren?';

  @override
  String get dashboardJointTrainingBody =>
      'Diese Kinder haben dasselbe aktive Paket. Soll die Einheit nach dem Training auch für sie eingetragen werden?';

  @override
  String get dashboardJointTrainingOnlyThis => 'Nur dieses Profil';

  @override
  String get dashboardJointTrainingTogether => 'Gemeinsam eintragen';

  @override
  String get dashboardVorrunde => 'Vorrunde';

  @override
  String dashboardPackageHeadline(String name) {
    return '$name Paket';
  }

  @override
  String get dashboardNoActivePackage => 'Noch kein aktives Paket';

  @override
  String get dashboardCompletedToday => 'Heute abgeschlossen';

  @override
  String get dashboardVorrundeReady =>
      'Die vier Wochen Vorrunde sind erreicht. Du kannst jetzt Moro starten.';

  @override
  String get dashboardVorrundeIntro =>
      'Die Vorrunde bereitet dich rhythmisch auf Moro vor. Du kannst sie fortsetzen oder jederzeit mit Moro starten.';

  @override
  String get dashboardStartMoroNow => 'Jetzt Moro starten';

  @override
  String get dashboardContinueVorrunde => 'Vorrunde fortsetzen';

  @override
  String get dashboardStartMoroAnyway => 'Trotzdem Moro starten';

  @override
  String dashboardDayOfTotal(int current, int total) {
    return 'Tag $current von $total';
  }

  @override
  String dashboardMovementCount(int count) {
    return '$count Bewegungen';
  }

  @override
  String dashboardEstimatedMinutes(int minutes) {
    return 'ca. $minutes Min.';
  }

  @override
  String get dashboardRegularityNote =>
      'Die Bewegungen bleiben bewusst gleich. Regelmäßigkeit ist wichtiger als Intensität.';

  @override
  String get dashboardBeginUnit => 'Einheit beginnen';

  @override
  String get dashboardDocumentExperience => 'Erfahrung dokumentieren';

  @override
  String get dashboardDoneToday => 'Heute erledigt';

  @override
  String get dashboardRoutineModeButton => 'Routine-Modus';

  @override
  String get dashboardVorrundeCalm => 'Vorrunde zur Beruhigung';

  @override
  String get dashboardDidBothToday =>
      'Heute Pakettraining und Vorrunde gemacht';

  @override
  String get dashboardDidVorrundeToday => 'Heute Vorrunde gemacht';

  @override
  String get dashboardCreateFirstProfileHint =>
      'Leg dein erstes Reflexprofil an, um loszulegen.';

  @override
  String get dashboardCreateFirstProfile => 'Erstes Profil anlegen';

  @override
  String get dashboardStartPackageHint =>
      'Du hast ein Profil angelegt. Starte jetzt ein Paket, um deinen Rhythmus aufzubauen.';

  @override
  String get dashboardStartPackage => 'Paket starten';

  @override
  String get dashboardImpulseRegularity =>
      'Heute zählt nicht Perfektion, sondern Regelmäßigkeit.';

  @override
  String get dashboardImpulseObserve => 'Beobachte, ohne zu bewerten.';

  @override
  String get dashboardImpulseSlowIsEnough =>
      'Langsam und regelmäßig ist genug.';

  @override
  String get dashboardImpulseNextStep =>
      'Hier ist dein nächster ruhiger Schritt.';

  @override
  String get dashboardImpulsePerceive => 'Nimm wahr, was heute da ist.';

  @override
  String get dashboardImpulseRhythm =>
      'Ruhiger Rhythmus gibt dem Körper Orientierung.';

  @override
  String get dashboardImpulseShortUnit =>
      'Eine kurze Einheit ist besser als Druck.';

  @override
  String dashboardPracticedOfWeek(int count) {
    return '$count/7 geübt';
  }

  @override
  String dashboardProposalsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Terminvorschläge offen',
      one: '1 Terminvorschlag offen',
    );
    return '$_temp0';
  }

  @override
  String dashboardNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Nachrichten',
      one: '1 neue Nachricht',
    );
    return '$_temp0';
  }

  @override
  String dashboardProposalBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Terminvorschläge',
      one: 'Neuer Terminvorschlag',
    );
    return '$_temp0';
  }

  @override
  String dashboardProposalBannerBody(String name) {
    return '$name hat dir Termine vorgeschlagen.';
  }

  @override
  String get dashboardSwitchProfile => 'Profil wechseln';

  @override
  String get profileBadgeSelf => 'Ich';

  @override
  String get profileBadgeChild => 'Kind';

  @override
  String get dashboardAddProfile => 'Profil hinzufügen';

  @override
  String get trainingIntroTitle => 'Willkommen zu deiner Einheit';

  @override
  String get trainingIntroDescription =>
      'Heute gehst du 7 Bewegungen in ruhigem Rhythmus durch.';

  @override
  String get trainingIntroRegularity =>
      'Regelmäßigkeit ist wichtiger als Intensität.';

  @override
  String get trainingIntroMovementCount => '7 Bewegungen';

  @override
  String get trainingIntroDuration => 'ca. 15-20 Minuten';

  @override
  String get trainingIntroClothing => 'Bequeme Kleidung empfohlen';

  @override
  String trainingProgressSemantics(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Fortschritt $current von $total Schritten.',
      one: 'Fortschritt $current von einem Schritt.',
    );
    return '$_temp0';
  }

  @override
  String get trainingExitTooltip => 'Training abbrechen';

  @override
  String get trainingContinueToMovement => 'Weiter zur Bewegung';

  @override
  String get trainingHintTitle => 'Hinweis';

  @override
  String trainingRepetitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count× Wiederholungen',
      one: '$count× Wiederholungen',
    );
    return '$_temp0';
  }

  @override
  String get trainingStartExercise => 'Übung starten';

  @override
  String get trainingAbortTitle => 'Training abbrechen?';

  @override
  String get trainingAbortBody =>
      'Möchtest du das Training wirklich abbrechen? Dein Fortschritt geht verloren.';

  @override
  String get trainingAbortStay => 'Nein, weiter trainieren';

  @override
  String get trainingAbortConfirm => 'Ja, abbrechen';

  @override
  String trainingFeedbackModeActivated(String label) {
    return 'Feedbackmodus $label aktiviert.';
  }

  @override
  String get trainingFeedbackVoice => 'Stimme';

  @override
  String get trainingFeedbackSounds => 'Töne';

  @override
  String get trainingFeedbackHaptics => 'Haptik';

  @override
  String get trainingFeedbackSilent => 'Stumm';

  @override
  String trainingTempoAnnouncement(String seconds) {
    return 'Tempo $seconds Sekunden.';
  }

  @override
  String trainingExerciseDurationSemantics(int seconds, int repetitions) {
    return 'Übungsdauer $seconds Sekunden, $repetitions Wiederholungen.';
  }

  @override
  String trainingRepeatCount(int count) {
    return '$count× wiederholen';
  }

  @override
  String get trainingAnimationSemantics =>
      'Animationsbereich der Übung. Startet automatisch und kann pausiert oder neu gestartet werden.';

  @override
  String get trainingAutoplayHint =>
      'Startet automatisch. Bei Bedarf pausieren.';

  @override
  String trainingTempoFeedbackSummary(String seconds, String feedback) {
    return 'Tempo: ${seconds}s  •  Feedback: $feedback';
  }

  @override
  String get trainingFastTempoWarning =>
      'Sehr schnelles Tempo aktiv. Fokus auf saubere Ausführung.';

  @override
  String get trainingAdaptiveSuggestion => 'Adaptiver Vorschlag aktiv';

  @override
  String get trainingTempoSlowerSemantics => 'Tempo langsamer';

  @override
  String get trainingTempoFasterSemantics => 'Tempo schneller';

  @override
  String trainingSecondsValue(String seconds) {
    return '$seconds Sekunden';
  }

  @override
  String get trainingSlower => 'Langsamer';

  @override
  String get trainingFaster => 'Schneller';

  @override
  String get trainingFeedbackChangeSemantics => 'Feedbackmodus wechseln';

  @override
  String get trainingControlsHint =>
      'Tempo und Feedback hier direkt mit einem Tap anpassen.';

  @override
  String get trainingCompleteExercise => 'Übung abschließen';

  @override
  String get trainingContinueNextExercise => 'Weiter zur nächsten Übung';

  @override
  String get trainingSwitchCueUpper => 'WECHSEL!';

  @override
  String get trainingPauseCue => 'Pause...';

  @override
  String get trainingHoldCueUpper => 'HALTEN';

  @override
  String trainingExerciseOfTotalCompact(int current, int total) {
    return 'Übung $current · $total gesamt';
  }

  @override
  String get trainingPause => 'Pause';

  @override
  String get trainingRest => 'Pause';

  @override
  String get trainingResume => 'Weiter';

  @override
  String get trainingRestart => 'Neu starten';

  @override
  String trainingSecondsOf(int count) {
    return 'von $count Sek.';
  }

  @override
  String trainingBeatsOf(int count) {
    return 'von $count Schlägen';
  }

  @override
  String trainingHoldTime(int seconds) {
    return '${seconds}s Haltezeit';
  }

  @override
  String trainingSecondsPerBeat(String seconds) {
    return '${seconds}s / Schlag';
  }

  @override
  String get trainingMusic => 'Musik';

  @override
  String get trainingMusicOn => 'Musik an';

  @override
  String get trainingSessionExitUnsaved =>
      'Deine aktuelle Stelle wird auf diesem Gerät gesichert. Möchtest du die Einheit verlassen?';

  @override
  String get trainingReminderSessionBody =>
      'Nimm dir Zeit für deine heutige Reflexintegrations-Einheit.';

  @override
  String get trainingProfileSkipTitle => 'Reflexprofil überspringen?';

  @override
  String get trainingProfileSkipBody =>
      'Ohne persönliches Reflexprofil zur Einschätzung deines Standes fortfahren?';

  @override
  String get trainingContinue => 'Fortfahren';

  @override
  String get trainingActiveProfile => 'Aktives Profil';

  @override
  String get trainingStartPackage => 'Paket starten';

  @override
  String trainingStartForProfile(String name) {
    return 'Start für $name';
  }

  @override
  String get trainingWarmupBeforeMoroTitle => 'Vorrunde vor Moro';

  @override
  String get trainingWarmupBeforeMoroBody =>
      'Die Vorrunde dient dazu, den Körper auf die kommende Integration der Reflexe vorzubereiten. Die rhythmischen Bewegungen geben deinem Gehirn Signale, die es an den Zeitraum erinnern, in dem diese Reflexe sich ursprünglich selbst integrieren sollten.\n\nDiese Übungen kannst du später immer wieder zur Beruhigung und Entspannung nutzen.';

  @override
  String get trainingStartWarmup => 'Vorrunde starten';

  @override
  String get trainingContinueWithPackage => 'Direkt mit Paket fortfahren';

  @override
  String get trainingUseReflexProfile => 'Reflexprofil nutzen';

  @override
  String trainingReflexProfileMissingBody(String name) {
    return 'Für $name liegt noch keine abgeschlossene Reflexprofil-Auswertung vor. Mit dem Profil wird die Dauerempfehlung genauer und nachvollziehbarer.';
  }

  @override
  String get trainingStartReflexProfile => 'Reflexprofil starten';

  @override
  String get trainingSkipDeliberately => 'Bewusst überspringen';

  @override
  String get trainingIsometricPartnerTitle => 'Isometrisches Partnertraining';

  @override
  String trainingIsometricPartnerQuestion(String name) {
    return 'Hat $name bereits isometrisches Partnertraining mit einer Fachperson gemacht?';
  }

  @override
  String get trainingWarmupStillRunning =>
      'Die Vorrundenphase läuft noch. Du kannst Moro trotzdem starten; sie ist eine Empfehlung und kein Blocker.';

  @override
  String get trainingWarmupReady =>
      'Die Vorrunde ist bereit. Jetzt Moro starten.';

  @override
  String trainingConnectedWithoutIsometric(String name) {
    return 'Du bist mit $name verbunden. Ohne isometrisches Partnertraining bleibt die Angabe trotzdem „Nein“.';
  }

  @override
  String trainingTrainerRequestPending(String name) {
    return 'Traineranfrage an $name ist offen.';
  }

  @override
  String get trainingFindTrainer => 'Trainer finden';

  @override
  String get trainingWarmupWhileWaitingBody =>
      'Während du auf Rückmeldung oder einen Termin wartest, kannst du die Vorrunde nutzen. Sie bereitet rhythmisch vor und ist unabhängig vom isometrischen Partnertraining.';

  @override
  String get trainingUseWarmup => 'Vorrunde nutzen';

  @override
  String get trainingBeforeYouStart => 'Bevor du startest';

  @override
  String get trainingWarmupInterstitialBody =>
      'Die Vorrunde bereitet deinen Körper auf das Reflex-Training vor. Viele Nutzer erleben deutlich stärkere Ergebnisse.';

  @override
  String get trainingStartWarmupNow => 'Vorrunde jetzt starten';

  @override
  String get trainingRecommended => 'empfohlen';

  @override
  String get trainingWarmupSummary =>
      '4 Wochen · 6 Übungen täglich · ca. 8 Min.';

  @override
  String get trainingStartFirstPackageDirectly =>
      'Direkt mit erstem Paket starten';

  @override
  String get trainingWarmupAvailableLater =>
      'Vorrunde kann jederzeit nachgeholt werden.';

  @override
  String get trainingCongratulations => 'Herzlichen Glückwunsch!';

  @override
  String get trainingCompletedTodayBody =>
      'Du hast dein heutiges Training\nerfolgreich abgeschlossen.';

  @override
  String get trainingCompletedToday => 'Heute abgeschlossen';

  @override
  String get trainingExercisesLabel => 'Übungen';

  @override
  String get trainingMinutesLabel => 'Minuten';

  @override
  String get trainingKeepGoing =>
      'Weiter so! Regelmäßiges Training führt zum Erfolg.';

  @override
  String trainingExerciseOfTotal(int current, int total) {
    return 'Übung $current von $total';
  }

  @override
  String trainingProgressStepCounter(int current, int total) {
    return '$current von $total';
  }

  @override
  String trainingProgressPercentComplete(int percent) {
    return '$percent% geschafft! 🎉';
  }

  @override
  String get trainingProgressAlmostThere => 'Fantastisch! Fast am Ziel! 🏆';

  @override
  String get trainingProgressGreat => 'Großartig! Du schaffst das! 💪';

  @override
  String get trainingProgressHalfway => 'Super! Schon über die Hälfte! 🎯';

  @override
  String get trainingProgressKeepGoing => 'Gut gemacht! Weiter so! ⭐';

  @override
  String get trainingProgressLetsGo => 'Los geht\'s! Du packst das! 🚀';

  @override
  String get trainingVideo => 'Video';

  @override
  String trainingRepetitionsAbbreviated(int count) {
    return '$count× Wdh.';
  }

  @override
  String trainingSecondsPerRep(int seconds) {
    return '$seconds Sek / Rep';
  }

  @override
  String get trainingPositionLabel => 'Position';

  @override
  String trainingStartsInSeconds(int seconds) {
    return 'Startet in $seconds s';
  }

  @override
  String get trainingStartNow => 'Jetzt starten';

  @override
  String get trainingAnnouncementPlaying => 'Ansage läuft...';

  @override
  String get trainingVideoPreparing => 'Video wird vorbereitet...';

  @override
  String get trainingMusicOff => 'Aus';

  @override
  String get trainingMusicVolume => 'Lautstärke';

  @override
  String get trainingMusicAmbientFlow => 'Ambient Flow';

  @override
  String get trainingMusicQuietNature => 'Stille Natur';

  @override
  String get trainingMusicDeepTones => 'Tiefe Töne';

  @override
  String get trainingOwnMusicMixNote =>
      'Eigene Musik wird in dieser Version nicht von der App gesteuert oder abgesenkt.';

  @override
  String get trainingShortBreak => 'Kurze Pause';

  @override
  String get trainingNextExercise => 'Nächste Übung:';

  @override
  String get trainingTutorialSubtitle => 'Mit Anleitung';

  @override
  String get trainingRoutineSubtitle => 'Automatischer Ablauf';

  @override
  String trainingDurationAndRepetitions(int seconds, int repetitions) {
    return '${seconds}s · ${repetitions}x';
  }

  @override
  String trainingCompletedExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen',
      one: '$count Übungen',
    );
    return '$_temp0';
  }

  @override
  String get trainingSecondsAbbreviation => 'sec';

  @override
  String get trainingAndAgain => 'Und wieder';

  @override
  String get trainingSwitchArmCross => 'Armkreuz wechseln';

  @override
  String get trainingSwitchCue => 'Wechsel';

  @override
  String get delete => 'Löschen';

  @override
  String get packagesNameMoro => 'Moro Reflex';

  @override
  String get packagesNameSpinalGalant => 'Spinaler Galant + Amphibien';

  @override
  String get packagesNameTlr => 'Tonischer Labirint Reflex (TLR)';

  @override
  String get packagesNameBabkin => 'Babkin + Plantar + Greifen';

  @override
  String get packagesNameSuchSaug => 'Such-Saug Reflex';

  @override
  String get packagesNameAtnr => 'ATNR';

  @override
  String get packagesNameStnr => 'STNR';

  @override
  String get packagesNameBabinski => 'Babinski Reflex';

  @override
  String get packagesNameLandau => 'Landau Reflex';

  @override
  String get packagesDevSelectionAvailable => 'Dev-Auswahl verfügbar';

  @override
  String get packagesFixedSequenceStatus => 'Im festen Paketverlauf';

  @override
  String get journalMoodAndEntry => 'Stimmung + Eintrag';

  @override
  String get journalEntryOnly => 'Nur Eintrag';

  @override
  String get journalEntriesHeading => 'Einträge';

  @override
  String journalEntrySummary(int entryCount, int entriesThisWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      entriesThisWeek,
      locale: localeName,
      other: '$entriesThisWeek Woche',
      one: '$entriesThisWeek Woche',
    );
    return '$entryCount gesamt · $_temp0';
  }

  @override
  String get journalTimelineEmptyTitle => 'Noch keine Einträge';

  @override
  String get journalTimelineEmptyBody =>
      'Deine Notizen erscheinen hier als kompakte Timeline. Der Verlauf bleibt im Dashboard.';

  @override
  String get journalDeleteEntryTitle => 'Eintrag löschen?';

  @override
  String get journalDeleteEntryBody =>
      'Dieser Eintrag wird dauerhaft entfernt.';

  @override
  String get journalEntryTypeNote => 'Notiz';

  @override
  String get journalShowLess => 'Weniger anzeigen';

  @override
  String get journalShowMore => 'Mehr anzeigen';

  @override
  String get progressTitle => 'Verlauf';

  @override
  String get progressLoadFailed => 'Verlauf konnte nicht geladen werden.';

  @override
  String get progressAddObservation => 'Beobachtung eintragen';

  @override
  String get progressWellbeingTitle => 'Befinden im Verlauf';

  @override
  String get progressWellbeingDescription =>
      'Stimmung, Energie und Stress als ruhige Orientierung.';

  @override
  String get progressWellbeingSeries => 'Befinden';

  @override
  String get progressWellbeingEmpty =>
      'Noch keine Einträge im gewählten Zeitraum.';

  @override
  String get progressRange30Days => '30d';

  @override
  String get progressRange90Days => '90d';

  @override
  String get progressRangeOneYear => '1J';

  @override
  String get progressRangeAll => 'All';

  @override
  String get progressReflexProfilesTitle => 'Reflexprofile';

  @override
  String progressReflexProfilesLoadFailed(String error) {
    return 'Reflexprofile konnten nicht geladen werden: $error';
  }

  @override
  String get progressNoReflexProfileBody =>
      'Noch kein Reflexprofil vorhanden. Es zeigt Hinweistärken, keine Diagnose.';

  @override
  String get progressStartReflexProfile => 'Reflexprofil starten';

  @override
  String get progressProfileDetails => 'Details';

  @override
  String get progressAdultLegacyCardBody =>
      'Erstellt mit älterer Methode. Tippen, um den Hinweis zu öffnen.';

  @override
  String get progressAdultNoPatternsYet => 'Noch keine Antwortmuster';

  @override
  String progressProfileAgeYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre',
      one: '$years Jahr',
    );
    return '$_temp0';
  }

  @override
  String get progressNoAssessmentProfile => 'Noch kein\nProfil';

  @override
  String get progressAddAnotherProfile => 'Weiteres\nProfil';

  @override
  String get progressCurrentPackageTitle => 'Aktuelles Paket';

  @override
  String progressCurrentPackageDay(
      String packageName, int currentDay, int totalDays) {
    return '$packageName · Tag $currentDay von $totalDays';
  }

  @override
  String get progressNoNextFixedPackage =>
      'Nach diesem Paket folgt kein weiteres festes Paket.';

  @override
  String progressNextFixedPackage(String packageName) {
    return 'Nächstes festes Paket: $packageName';
  }

  @override
  String get progressViewPackageSequence => 'Paketverlauf ansehen';

  @override
  String get progressObservationsTitle => 'Beobachtungen';

  @override
  String get progressObservationsEmptySummary =>
      'Noch keine Beobachtungen festgehalten.';

  @override
  String progressObservationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge im aktuellen Zeitraum',
      one: '$count Einträge im aktuellen Zeitraum',
    );
    return '$_temp0';
  }

  @override
  String get progressObservationsEmptyBody =>
      'Nach einer Einheit oder zwischendurch kannst du Beobachtungen zu Körper, Stimmung, Energie und Schlaf eintragen.';

  @override
  String get goldenDayTitle => 'Golden Day 🎉';

  @override
  String get goldenDayCongratulations => 'Glückwunsch!';

  @override
  String get goldenDayCompletionMessage =>
      'Du hast das 4-Wochen-Training erfolgreich abgeschlossen!';

  @override
  String get goldenDayFeelingPrompt => 'Wie fühlst du dich?';

  @override
  String get goldenDayReadyForMore => 'Bereit für mehr!';

  @override
  String get goldenDayPracticeMore => 'Noch etwas üben';

  @override
  String get anonymous => 'Anonym';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get submit => 'Einreichen';

  @override
  String get noThanks => 'Nein danke';

  @override
  String get continueAction => 'Weiter';

  @override
  String get accompanimentTitle => 'Begleitung';

  @override
  String get accompanimentConnectBody =>
      'Füge den Einladungslink oder den 6-stelligen Code ein, den du von deinem Trainer erhalten hast.';

  @override
  String get accompanimentInviteLinkOrCodeLabel => 'Einladungslink oder Code';

  @override
  String get accompanimentInviteLinkOrCodeHint => 'A1B2C3 oder https://...';

  @override
  String get accompanimentConnectInvalidInvite =>
      'Bitte gib einen gültigen 6-stelligen Code oder Einladungslink ein.';

  @override
  String accompanimentConnectFailed(String error) {
    return 'Verbindung konnte nicht hergestellt werden: $error';
  }

  @override
  String get accompanimentConnectAction => 'Verbinden';

  @override
  String get accompanimentConnectedSuccess => 'Trainer wurde verbunden.';

  @override
  String get accompanimentSwitchTitle => 'Begleitung wechseln';

  @override
  String get accompanimentSwitchBody =>
      'Nach dem Wechsel erscheint dein Verlauf beim neuen Trainer. Dein bisheriger Trainer sieht dich danach nicht mehr in seiner Klientenübersicht.';

  @override
  String get accompanimentSwitchInvalidInvite =>
      'Bitte gib einen gültigen Einladungslink oder Code ein.';

  @override
  String get accompanimentSwitchConfirm => 'Wechsel bestätigen';

  @override
  String get accompanimentSwitchUpdated => 'Begleitung wurde aktualisiert.';

  @override
  String accompanimentSwitchFailed(String error) {
    return 'Wechsel konnte nicht gespeichert werden: $error';
  }

  @override
  String get accompanimentEndAction => 'Begleitung beenden';

  @override
  String get accompanimentEndDialogTitle => 'Begleitung wirklich beenden?';

  @override
  String get accompanimentEndConsequenceProfiles =>
      'Dein Trainer kann deine Reflexprofile nicht mehr sehen.';

  @override
  String get accompanimentEndConsequenceChat =>
      'Ihr könnt euch keine Nachrichten mehr schreiben. Euer bisheriger Verlauf bleibt erhalten.';

  @override
  String get accompanimentEndConsequenceAppointments =>
      'Alle offenen Termine werden abgesagt.';

  @override
  String get accompanimentEndTrainerNotice =>
      'Dein Trainer wird darüber informiert.';

  @override
  String get accompanimentEndReconnectHint =>
      'Du kannst dich später mit einem neuen Code wieder verbinden.';

  @override
  String get accompanimentEndConfirm => 'Begleitung beenden';

  @override
  String get accompanimentEnded => 'Begleitung beendet.';

  @override
  String accompanimentEndFailed(String error) {
    return 'Begleitung konnte nicht beendet werden: $error';
  }

  @override
  String get chatWriteLockedNoRelationship =>
      'Diese Begleitung ist beendet. Du kannst den Verlauf weiter lesen, aber keine Nachrichten mehr senden.';

  @override
  String get accompanimentWithdrawTitle => 'Anfrage zurückziehen?';

  @override
  String accompanimentWithdrawBody(String name) {
    return 'Die Anfrage an $name wird zurückgezogen. Du kannst später erneut eine passende Begleitung anfragen.';
  }

  @override
  String get accompanimentWithdrawAction => 'Anfrage zurückziehen';

  @override
  String get accompanimentWithdrawSuccess => 'Anfrage wurde zurückgezogen.';

  @override
  String accompanimentWithdrawFailed(String error) {
    return 'Anfrage konnte nicht zurückgezogen werden: $error';
  }

  @override
  String get accompanimentSharedExperiencesTitle => 'Geteilte Erfahrungen';

  @override
  String get accompanimentSharedExperiencesBody =>
      'Moderierte Beobachtungen aus laufenden Paketen ansehen.';

  @override
  String get accompanimentSharedExperiencesAction => 'Erfahrungen öffnen';

  @override
  String get accompanimentProfessionalTitle => 'Professionelle Begleitung';

  @override
  String get accompanimentProfessionalBody =>
      'Manche Übungen werden mit einer zweiten Person durchgeführt. Dabei geht es nicht um Krafttraining, sondern um klares Spüren von Richtung, Bewegung und Widerstand. Ein geschulter Trainer kann dich dabei sicher anleiten.';

  @override
  String get accompanimentPackageStartNote =>
      'Besonders relevant am Anfang eines Pakets.';

  @override
  String get accompanimentDailySessionsNote =>
      'Deine täglichen rhythmischen Einheiten bleiben selbstgeführt.';

  @override
  String get accompanimentNoTrainerTitle => 'Noch keine Begleitung verbunden';

  @override
  String get accompanimentNoTrainerBody =>
      'Du kannst dein Paket weiter selbstgeführt üben und bei Bedarf eine professionelle Begleitung für Partnerübungen oder Gespräche finden.';

  @override
  String get accompanimentEnterInviteLink => 'Einladungslink eingeben';

  @override
  String get accompanimentContinueWithoutTrainer => 'Ohne Trainer fortfahren';

  @override
  String get accompanimentProfileSharingTitle => 'Reflexprofil-Freigabe';

  @override
  String get accompanimentProfileSharingBody =>
      'Du kannst festlegen, ob der verbundene Trainer die abgeschlossenen Reflexprofile sehen darf. Das gilt nur, solange diese Begleitung aktiv ist.';

  @override
  String accompanimentProfileSharingLoadFailed(String error) {
    return 'Freigabe konnte nicht geladen werden: $error';
  }

  @override
  String get accompanimentProfileShared =>
      'Der verbundene Trainer darf dieses Reflexprofil sehen.';

  @override
  String get accompanimentProfileNotShared =>
      'Nicht für den verbundenen Trainer freigegeben.';

  @override
  String accompanimentProfileSharingSaveFailed(String error) {
    return 'Reflexprofil-Freigabe konnte nicht gespeichert werden: $error';
  }

  @override
  String accompanimentProposalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offene Terminvorschläge',
      one: '1 offener Terminvorschlag',
    );
    return '$_temp0';
  }

  @override
  String get accompanimentProposalsLoading =>
      'Terminvorschläge werden geladen ...';

  @override
  String get accompanimentProposalsBody =>
      'Wähle einen passenden Termin direkt in deiner Begleitung aus.';

  @override
  String get accompanimentViewProposals => 'Vorschläge ansehen';

  @override
  String accompanimentPendingRequestTitle(String name) {
    return 'Anfrage offen bei $name';
  }

  @override
  String accompanimentExtraPendingRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Anfragen offen',
      one: '$count weitere Anfrage offen',
    );
    return '$_temp0';
  }

  @override
  String get accompanimentPendingRequestAcceptedNotice =>
      'Du wirst informiert, sobald die Anfrage angenommen wurde.';

  @override
  String get accompanimentMoreTrainers => 'Mehr Trainer';

  @override
  String get accompanimentInviteLinkShort => 'Einladungslink';

  @override
  String get accompanimentActiveGuidance => 'Aktive Begleitung';

  @override
  String get accompanimentMessage => 'Nachricht';

  @override
  String get accompanimentAppointmentProposals => 'Terminvorschläge';

  @override
  String get accompanimentNextAppointments => 'Nächste Termine';

  @override
  String get accompanimentNoAppointments => 'Noch keine geplanten Termine.';

  @override
  String get accompanimentSwitchAccessBody =>
      'Beim Wechsel sieht dein neuer Trainer deinen Verlauf. Dein bisheriger Trainer verliert den Zugriff auf deine Klientenübersicht.';

  @override
  String get accompanimentEnterCode => 'Code eingeben';

  @override
  String accompanimentAppointmentForProfile(String profileName) {
    return 'für $profileName';
  }

  @override
  String get moodWriteNote => 'Notiz schreiben';

  @override
  String get moodNoActiveProgram => 'Kein aktives Programm gefunden.';

  @override
  String get moodCommunityShareTitle => 'Geteilte Erfahrung einreichen?';

  @override
  String get moodCommunityShareBody =>
      'Möchtest du diese Beobachtung als geteilte Erfahrung einreichen?';

  @override
  String get moodEditEntry => 'Eintrag bearbeiten';

  @override
  String get moodLogMood => 'Stimmung eintragen';

  @override
  String get moodForWhom => 'Für wen?';

  @override
  String get moodGeneral => 'Allgemein';

  @override
  String get moodMetricSelectionHint =>
      'Tippe auf einen Wert, um ihn auszuwählen, oder lass ihn frei.';

  @override
  String get moodNoteBody =>
      'Unabhängig von deiner Stimmung — schreib was dir gerade durch den Kopf geht.';

  @override
  String get moodNoteHint => 'Deine Gedanken...';

  @override
  String moodExperienceSaveFailed(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String moodExperienceSessionNote(String values) {
    return 'Einheit: $values';
  }

  @override
  String moodExperienceSinceLastSessionNote(String values) {
    return 'Seit letzter Einheit: $values';
  }

  @override
  String get moodExperienceTitle => 'Wie hat sich die Einheit angefühlt?';

  @override
  String get moodExperienceDescription =>
      'Was hast du während der Einheit oder seit deiner letzten Einheit wahrgenommen?';

  @override
  String get moodExperienceImpressionCalm => 'ruhig';

  @override
  String get moodExperienceImpressionPleasant => 'angenehm';

  @override
  String get moodExperienceImpressionTired => 'müde';

  @override
  String get moodExperienceImpressionRestless => 'unruhig';

  @override
  String get moodExperienceImpressionEmotional => 'emotional';

  @override
  String get moodExperienceImpressionPhysicallyUncomfortable =>
      'körperlich unangenehm';

  @override
  String get moodExperienceImpressionUnsure => 'schwer einzuschätzen';

  @override
  String get moodExperienceSinceLastTitle =>
      'Was ist dir seit der letzten Einheit aufgefallen?';

  @override
  String get moodExperienceSinceMoreCalm => 'mehr Ruhe';

  @override
  String get moodExperienceSinceMoreEnergy => 'mehr Energie';

  @override
  String get moodExperienceSinceLessEnergy => 'weniger Energie';

  @override
  String get moodExperienceSinceMoodChanged => 'Stimmung schwankte';

  @override
  String get moodExperienceSinceMoreEmotional => 'emotionaler als sonst';

  @override
  String get moodExperienceSinceMoreSensitive => 'reizempfindlicher';

  @override
  String get moodExperienceSinceBetterSleep => 'besserer Schlaf';

  @override
  String get moodExperienceSinceRestlessSleep => 'unruhiger Schlaf';

  @override
  String get moodExperienceSinceBodyTension => 'körperliche Spannung';

  @override
  String get moodExperienceSinceNothingNotable => 'keine Besonderheit';

  @override
  String get moodExperienceOwnObservationHint =>
      'Eigene Beobachtung... (optional)';

  @override
  String get moodExperienceShare => 'Als geteilte Erfahrung einreichen';

  @override
  String get moodExperienceShareAnonymously => 'Anonym einreichen';

  @override
  String get themeSystemDescription => 'Folgt den System-Einstellungen';

  @override
  String get themeLightDescription => 'Immer helles Design';

  @override
  String get themeDarkDescription => 'Immer dunkles Design';

  @override
  String themeChanged(String title) {
    return 'Theme geändert zu: $title';
  }

  @override
  String get profileTrainingProfilesSection => 'Trainingsprofile';

  @override
  String get profileJournalItemTitle => 'Journal';

  @override
  String get profileJournalSubtitle => 'Deine Einträge und Reflexionen';

  @override
  String get profileTrainerSection => 'Trainer';

  @override
  String get profileManageGuidance => 'Begleitung verwalten';

  @override
  String profileConnectedWith(String name) {
    return 'Aktuell verbunden mit $name';
  }

  @override
  String get profileFindManageTrainer =>
      'Trainer finden, Anfragen und Termine verwalten';

  @override
  String get profileWorkspaceSection => 'Arbeitsbereich';

  @override
  String get profileAdminPanel => 'Admin Panel';

  @override
  String get profileMessages => 'Nachrichten';

  @override
  String get profileReviewChannels => 'Trainer-Bewerbungen und Review-Kanäle';

  @override
  String get profileTrainerArea => 'Trainerbereich';

  @override
  String get profileProfessionalAccessSection => 'Beruflicher Zugang';

  @override
  String get profileBecomeTrainer => 'Trainer werden';

  @override
  String get profileApplicationSubtitle =>
      'Bewerbung einreichen und prüfen lassen';

  @override
  String get profileAccountSection => 'Account';

  @override
  String profileSubjectProfilesLoadFailed(String error) {
    return 'Profile konnten nicht geladen werden: $error';
  }

  @override
  String get profileCreateFirst => 'Erstes Profil anlegen';

  @override
  String get profileEditTooltip => 'Profil bearbeiten';

  @override
  String get profileActivate => 'Aktivieren';

  @override
  String get profileViewReflexProfile => 'Reflexprofil ansehen';

  @override
  String get profileStartReflexProfile => 'Reflexprofil ausfüllen';

  @override
  String get profileAdd => 'Profil hinzufügen';

  @override
  String get profileSaved => 'Profil gespeichert.';

  @override
  String profileSaveFailed(String error) {
    return 'Profil konnte nicht gespeichert werden: $error';
  }

  @override
  String get profileAdult => 'Erwachsenenprofil';

  @override
  String get profileChild => 'Kinderprofil';

  @override
  String profileAgeYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre',
      one: '$years Jahr',
    );
    return '$_temp0';
  }

  @override
  String get profileSelectBirthDateHelp => 'Geburtsdatum auswählen';

  @override
  String get profileNameRequired => 'Bitte gib einen Namen an.';

  @override
  String get profileBirthDateRequired => 'Bitte gib ein Geburtsdatum an.';

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileChildNameLabel => 'Name oder Spitzname';

  @override
  String get profileNameLabel => 'Profilname';

  @override
  String get profileBirthDateLabel => 'Geburtsdatum';

  @override
  String get profileSelectDate => 'Datum auswählen';

  @override
  String get profileDisplayNameLabel => 'Anzeigename';

  @override
  String get profileCommunityDisplayNameHint =>
      'Wird im Community-Feed angezeigt, wenn du Erfahrungen teilst.';

  @override
  String get profileTrainerDisplayNameHint =>
      'Sichtbar für deinen Trainer, zum Beispiel im Chat.';

  @override
  String profileMinimumCharacters(int count) {
    return 'Mindestens $count Zeichen';
  }

  @override
  String profileMaximumCharacters(int count) {
    return 'Maximal $count Zeichen';
  }

  @override
  String get profileAtNotAllowed => 'Kein @ erlaubt';

  @override
  String get profileSaveFailedShort => 'Speichern fehlgeschlagen';

  @override
  String get profileContactNameRequired => 'Bitte gib einen Kontaktnamen ein.';

  @override
  String get profileContactNameQuestion => 'Wie sollen wir dich nennen?';

  @override
  String get profileContactNameBody =>
      'Dein Kontaktname ist sichtbar für Trainer und im Kursbereich.';

  @override
  String get profileContactNameBodyWithCommunity =>
      'Dein Kontaktname ist sichtbar für Trainer und im Kursbereich. Er kann sich von deinem Community-Namen unterscheiden.';

  @override
  String get profileContactNameHint => 'z. B. Maria oder Familie Müller';

  @override
  String get tabTrainer => 'Trainer';

  @override
  String get tabAdmin => 'Admin';

  @override
  String routeNotFound(String error) {
    return 'Seite nicht gefunden: $error';
  }

  @override
  String get startupCouldNotStart =>
      'Reflex Journey konnte nicht gestartet werden. Bitte starte die App neu oder installiere sie neu.';

  @override
  String get startupBootstrapFailedTitle => 'Start fehlgeschlagen';

  @override
  String get clientFallbackName => 'Klient';

  @override
  String get appointmentCalendarFallbackTitle => 'Isometrische Partnerübung';

  @override
  String appointmentCalendarEventTitle(String title, String name) {
    return '$title (mit $name)';
  }

  @override
  String appointmentCalendarAdded(String name) {
    return 'Termin mit $name wurde dem Kalender hinzugefügt.';
  }

  @override
  String appointmentCalendarOpenFailed(String error) {
    return 'Kalender konnte nicht geöffnet werden: $error';
  }

  @override
  String get hintDashboardBody =>
      'Hier steuerst du deinen täglichen Rhythmus und dokumentierst, was du wahrnimmst.';

  @override
  String get hintDashboardItemStart =>
      'Starte deine geführte Einheit oder den Routine-Modus.';

  @override
  String get hintDashboardItemLog =>
      'Trage eine Einheit ein, wenn du heute geübt hast.';

  @override
  String get hintDashboardItemNote =>
      'Halte Erfahrungen direkt nach der Einheit fest.';

  @override
  String get hintProgressBody =>
      'Der Verlauf hilft dir, Muster zu sehen, ohne einzelne Tage zu überbewerten.';

  @override
  String get hintProgressItemOverview =>
      'Sieh Trainingstage, Beobachtungen und Einträge zusammen.';

  @override
  String get hintProgressItemObserve =>
      'Ergänze Beobachtungen, wenn dir etwas auffällt.';

  @override
  String get hintProgressItemJournal =>
      'Öffne einzelne Journal-Einträge für mehr Kontext.';

  @override
  String get hintAccompanimentBody =>
      'Hier liegt alles, was mit Trainer, Kommunikation und Terminen zu tun hat.';

  @override
  String get hintAccompanimentItemTrainer =>
      'Finde Trainer oder verwalte deine aktive Begleitung.';

  @override
  String get hintAccompanimentItemChat =>
      'Öffne Nachrichten und bleib mit deinem Trainer im Kontakt.';

  @override
  String get hintAccompanimentItemAppointments =>
      'Sieh Terminvorschläge und geplante Termine an.';

  @override
  String get hintProfileBody =>
      'Im Profil findest du Konto, Einstellungen und administrative Zugänge.';

  @override
  String get hintProfileItemSettings =>
      'Passe Sprache, Darstellung und Erinnerungen an.';

  @override
  String get hintProfileItemAccount =>
      'Verwalte Account, Passwort und Profilinformationen.';

  @override
  String get hintProfileItemRoles =>
      'Öffne Trainer- oder Admin-Bereiche, wenn sie für dich freigeschaltet sind.';

  @override
  String get hintDontShowAgain => 'Nicht mehr anzeigen';

  @override
  String get hintGotIt => 'Verstanden';

  @override
  String get hintShowLater => 'Später nochmal zeigen';

  @override
  String get notificationChannelTrainingReminders => 'Training-Erinnerungen';

  @override
  String get pushVideoCallTitle => 'Eingehender Video-Call';

  @override
  String get pushVideoCallBody => 'Tippe, um den Anruf zu öffnen.';

  @override
  String get pushCallRequestTitle => 'Video-Call Anfrage';

  @override
  String get pushCallRequestBody =>
      'Ein Klient möchte einen Video-Call starten.';

  @override
  String get pushAppointmentProposalTitle => 'Neue Terminvorschläge';

  @override
  String get pushAppointmentProposalBody => 'Wähle einen passenden Termin aus.';

  @override
  String get pushAppointmentConfirmedTitle => 'Termin bestätigt';

  @override
  String get pushAppointmentConfirmedBody =>
      'Tippe, um den Termin in deinen Kalender einzutragen.';

  @override
  String get pushTrainingReminderTitle => 'Training-Erinnerung';

  @override
  String get pushTrainingReminderBody => 'Tippe, um dein Training zu öffnen.';

  @override
  String trainerAlertPrepareTitle(String traineeName) {
    return 'Termin vorbereiten — $traineeName';
  }

  @override
  String trainerAlertPrepareBody(String traineeName) {
    return '$traineeName ist bei Tag 25. In ~3 Tagen ist die Isometrische Partnerübung fällig.';
  }

  @override
  String trainerAlertDay28Title(String traineeName) {
    return '$traineeName hat Tag 28 erreicht!';
  }

  @override
  String get trainerAlertDay28Body =>
      'Jetzt Termin für die Isometrische Partnerübung buchen.';

  @override
  String get traineeFallbackName => 'Dein Trainee';

  @override
  String get answerUnknown => 'Weiß ich nicht';

  @override
  String get scoreBandStrong => 'stark ausgeprägt';

  @override
  String get scoreBandElevated => 'auffällig';

  @override
  String get scoreBandIndication => 'Anzeichen';

  @override
  String get scoreBandInconspicuous => 'unauffällig';

  @override
  String get scoreBandInsufficientData => 'zu wenig Daten';

  @override
  String monthsCount(int count) {
    return '$count Monate';
  }

  @override
  String yearsCount(int count) {
    return '$count Jahre';
  }

  @override
  String get leave => 'Verlassen';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get finish => 'Abschließen';

  @override
  String get switchAction => 'Wechseln';

  @override
  String get selfName => 'Ich';

  @override
  String get analysisPlaceholderTitle => 'Analyse';

  @override
  String get analysisPlaceholderContinue => 'Weiter zur Zustimmung';

  @override
  String get analysisPlaceholderHeadline =>
      'Hier startet bald deine persönliche Standortanalyse.';

  @override
  String get analysisPlaceholderBody =>
      'Vor dem ersten Training wird hier ein kurzer Fragebogen stehen. Damit kann Reflex Journey deinen aktuellen Stand besser einordnen und die Empfehlung sauberer machen.';

  @override
  String get analysisPlaceholderStepQuestionnaireTitle => 'Fragebogen';

  @override
  String get analysisPlaceholderStepQuestionnaireBody =>
      'Symptome, Belastung, Trainingsziel und bisherige Erfahrung.';

  @override
  String get analysisPlaceholderStepAssessmentTitle => 'Auswertung';

  @override
  String get analysisPlaceholderStepAssessmentBody =>
      'Eine ruhige Einschätzung deines aktuellen Ausgangspunkts.';

  @override
  String get durationRecAccept => 'Empfehlung übernehmen';

  @override
  String get durationRecSkippedBody =>
      'Du hast das Reflexprofil übersprungen oder es liegt für dieses Profil noch keine Auswertung vor. Die Empfehlung nutzt deshalb die Standardlogik anhand deiner Angabe zum isometrischen Partnertraining.';

  @override
  String get durationRecRangeWithTrainer => '4 bis 6';

  @override
  String get durationRecRangeWithoutTrainer => '6 bis 8';

  @override
  String get durationRecTrainerAlready => 'bereits';

  @override
  String get durationRecTrainerNotYet => 'noch nicht';

  @override
  String durationRecMoroBody(
      String percent, String trainerStatus, String range) {
    return 'Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung.\n\nFür das Moro-Paket betrachten wir sowohl Moro als auch FLR, weil beide in dieser Auswertung relevant sind. Der stärkere Hinweis liegt bei $percent und bestimmt die Dauerstufe.\n\nDa du $trainerStatus isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich $range Wochen. Du kannst die Empfehlung übernehmen oder die Dauer manuell anpassen.';
  }

  @override
  String durationRecGenericBody(int weeks, String trainerStatus, String range) {
    return 'Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung. Aufgrund deiner ermittelten Reflex-Tendenz empfehlen wir für dieses Paket eine Dauer von $weeks Wochen.\n\nDa du $trainerStatus isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich $range Wochen.';
  }

  @override
  String durationRecTendency(String label, String percent) {
    return '$label-Tendenz: $percent';
  }

  @override
  String get durationRecStrongerHint =>
      'Für die Dauer zählt der stärkere Hinweis.';

  @override
  String get durationRecNoData => 'keine ausreichenden Daten';

  @override
  String get radarNotEnoughData => 'Zu wenig Daten';

  @override
  String get reflexProfileNameBirthRequired =>
      'Bitte gib einen Namen und das Geburtsdatum an.';

  @override
  String get reflexProfileBirthFuture =>
      'Das Geburtsdatum darf nicht in der Zukunft liegen.';

  @override
  String reflexProfileCreateChildFailed(String error) {
    return 'Kinderprofil konnte nicht angelegt werden: $error';
  }

  @override
  String get reflexProfileClearanceTitle => 'Rücksprache erforderlich';

  @override
  String reflexProfileClearanceBody(String question) {
    return 'Bei dieser Angabe empfehlen wir dringend, das Training nur nach Rücksprache und mit ausdrücklicher Zustimmung eines behandelnden Arztes, Therapeuten oder Psychologen durchzuführen.\n\nMit dem Fortfahren bestätigst du, dass du diese Rücksprache eigenverantwortlich berücksichtigst und das Training entsprechend begleitet oder freigegeben durchführst.\n\nFrage: $question';
  }

  @override
  String get reflexProfileClearanceConfirm => 'Verstanden und bestätigt';

  @override
  String get reflexProfileAnswerAllChoice =>
      'Bitte beantworte alle Auswahl- und Zahlenfragen.';

  @override
  String reflexProfileCompleteFailed(String error) {
    return 'Reflexprofil konnte nicht abgeschlossen werden: $error';
  }

  @override
  String get reflexProfileLeaveTitle => 'Fragebogen verlassen?';

  @override
  String get reflexProfileLeaveBody =>
      'Dein Fortschritt wird gespeichert. Du kannst jederzeit weitermachen.';

  @override
  String get reflexProfileResumeTitle => 'Fragebogen fortsetzen?';

  @override
  String get reflexProfileResumeBody =>
      'Du hast diesen Fragebogen bereits begonnen. Möchtest du dort weitermachen, wo du aufgehört hast?';

  @override
  String get reflexProfileStartOver => 'Von vorne';

  @override
  String reflexProfileLoadProfilesFailed(String error) {
    return 'Profile konnten nicht geladen werden: $error';
  }

  @override
  String get reflexProfileForWhomTitle =>
      'Für wen machst du diesen Fragebogen?';

  @override
  String get reflexProfileForWhomBody =>
      'Der Fragebogen unterscheidet sich je nachdem, ob er für ein Kind oder für dich selbst ausgefüllt wird.';

  @override
  String get reflexProfileForMyChild => 'Für mein Kind';

  @override
  String get reflexProfileParentQuestionnaire => 'Elternfragebogen';

  @override
  String get reflexProfileForMyself => 'Für mich';

  @override
  String get reflexProfileForMyselfComingSoon =>
      'Für mich selbst · bald verfügbar';

  @override
  String get reflexProfileAdultComingSoonTitle =>
      'Erwachsenenfragebogen kommt bald';

  @override
  String get reflexProfileAdultComingSoonBody =>
      'Der Fragebogen für Erwachsene befindet sich noch in Entwicklung. Du kannst ihn bald hier ausfüllen.';

  @override
  String get answerNotApplicable => 'Trifft nicht zu';

  @override
  String get reflexProfileAdultSelfReport => 'Selbstauskunft für Erwachsene';

  @override
  String get reflexProfileAdultOrientationTitle =>
      'Deine Antwortmuster — kein Befund';

  @override
  String get reflexProfileAdultOrientationBody =>
      'Dieser Fragebogen sammelt deine eigenen Beobachtungen. Er zeigt nur Antwortmuster. Er stellt keinen Reflexnachweis fest und ersetzt keine persönliche Einschätzung.';

  @override
  String get reflexProfileSelectAdultProfile => 'Profil auswählen';

  @override
  String get reflexProfileNewAdultProfile => 'Neues Erwachsenenprofil';

  @override
  String get reflexProfileAdultAgeHelper =>
      'Ab 16 Jahren. Unter 16 bitte den Kinderfragebogen nutzen (Elternbericht).';

  @override
  String get reflexProfileAdultUnder16Hint =>
      'Dieser Erwachsenenfragebogen ist ab 16 Jahren. Für jüngere Personen bitte den Kinderfragebogen nutzen — das ist ein Elternbericht über ein Kind, keine Selbstauskunft.';

  @override
  String reflexProfileAdultItemProgress(int answered, int visible) {
    return '$answered von $visible sichtbaren Angaben beantwortet';
  }

  @override
  String get reflexProfileAdultContinueToSummary => 'Angaben prüfen';

  @override
  String get reflexProfileAdultSummaryTitle => 'Bevor du absendest';

  @override
  String get reflexProfileAdultSummaryDisclaimer =>
      'Dein Profil zeigt nur Antwortmuster — keine Diagnose und keinen Reflexnachweis.';

  @override
  String reflexProfileAdultSummaryAnswered(int count) {
    return 'Beantwortet: $count';
  }

  @override
  String reflexProfileAdultSummarySkipped(int count) {
    return 'Übersprungen (? / n. z.): $count';
  }

  @override
  String reflexProfileAdultSummaryHidden(int count) {
    return 'Durch Filter ausgeblendet: $count';
  }

  @override
  String get reflexProfileAdultSummaryOpenHeading => 'Offene Fragen';

  @override
  String get reflexProfileAdultSafetyNoticeTitle => 'Hinweis';

  @override
  String get reflexProfileAdultSafetyNoticeBody =>
      'Deine Angabe kann bedeuten, dass einzelne Bewegungen oder Trainingsübungen angepasst oder vorher fachlich besprochen werden sollten. Dieses Ergebnis bewertet deine Diagnose nicht.';

  @override
  String get reflexProfileAdultSafetyNoticeMovementAppendix =>
      'Führe die gekennzeichneten Übungen nicht ohne die hier empfohlene Rücksprache durch.';

  @override
  String get reflexProfileAdultSafetyNoticeConfirm => 'Hinweis gelesen.';

  @override
  String get adultResultTitle => 'Dein Reflexprofil';

  @override
  String adultResultSubline(
      String date, String questionnaireVersion, String scoringVersion) {
    return 'Erwachsenenprofil · $date · $questionnaireVersion / $scoringVersion';
  }

  @override
  String get adultResultDisclaimer =>
      'Das sind nur deine subjektiven Antwortmuster. Sie sind kein Reflexnachweis und keine Diagnose.';

  @override
  String get adultResultHintListTitle => 'Antwortmuster nach Reflex';

  @override
  String adultResultFeaturesAnswered(int answered, int possible) {
    return '$answered von $possible Merkmalen beantwortet';
  }

  @override
  String get adultResultDetailHintStrength => 'Hinweisstärke';

  @override
  String get adultResultDetailDataBasis => 'Datengrundlage';

  @override
  String get adultResultDetailMatchingAnswers => 'Passende eigene Angaben';

  @override
  String get adultResultDetailAlternatives => 'Alternativerklärungen';

  @override
  String get adultResultDetailLimits => 'Grenzen';

  @override
  String get adultResultLegacyTitle => 'Erstellt mit älterer Methode';

  @override
  String get adultResultLegacyBody =>
      'Dieses Erwachsenenprofil wurde mit einer früheren Fragebogen-Version erstellt. Werte werden nicht angezeigt und nicht mit aktuellen Profilen verglichen.';

  @override
  String adultResultLegacyVersion(
      String questionnaireVersion, String scoringVersion) {
    return 'Version: $questionnaireVersion · Scoring: $scoringVersion';
  }

  @override
  String get adultHintBandFewMatching => 'Wenige passende Angaben';

  @override
  String get adultHintBandSomeMatching => 'Einige passende Angaben';

  @override
  String get adultHintBandClusteredPattern => 'Gehäuftes Antwortmuster';

  @override
  String get adultHintBandStronglyClustered => 'Stark gehäuftes Muster';

  @override
  String get adultHintBandInsufficientData =>
      'Keine ausreichende Datengrundlage';

  @override
  String get adultAmphibianInsufficientData => 'Keine Angaben';

  @override
  String get adultAmphibianNoneMatching => 'Kein passender Einzelhinweis';

  @override
  String get adultAmphibianSingleHint => 'Einzelner Hinweis';

  @override
  String get adultAmphibianClearSingleHint => 'Deutlicher Einzelhinweis';

  @override
  String get reflexProfileOrientationTitle =>
      'Eine Orientierung, keine Diagnose';

  @override
  String get reflexProfileOrientationBody =>
      'Das Reflexprofil sammelt Beobachtungen und zeigt Hinweisstärken. Es ersetzt keine medizinische oder therapeutische Diagnose.';

  @override
  String get reflexProfileSelectChild => 'Kinderprofil auswählen';

  @override
  String get reflexProfileStartQuestionnaire => 'Fragebogen starten';

  @override
  String get reflexProfileNewChild => 'Neues Kinderprofil';

  @override
  String get reflexProfileNameOrNickname => 'Name oder Spitzname';

  @override
  String get reflexProfilePickBirthDate => 'Geburtsdatum auswählen';

  @override
  String get reflexProfileBirthDateRequired => 'Geburtsdatum *';

  @override
  String get reflexProfileBirthDateHelper =>
      'Pflichtfeld – wird für die Altersauswertung benötigt';

  @override
  String get reflexProfileSelectDate => 'Datum auswählen';

  @override
  String get reflexProfileCreateAndStart => 'Profil anlegen und starten';

  @override
  String get reflexProfileAnswerRequiredSection =>
      'Bitte beantworte alle Pflichtfragen in diesem Abschnitt.';

  @override
  String get reflexProfileChildFallback => 'Kinderprofil';

  @override
  String reflexProfileSectionOf(int current, int total) {
    return 'Abschnitt $current von $total';
  }

  @override
  String get reflexProfileWhatIsMeant => 'Was ist gemeint?';

  @override
  String get reflexProfileMonthsLabel => 'Monate';

  @override
  String get reflexProfileFreeTextLabel => 'Freitext';

  @override
  String get reflexProfileOtherLabel => 'Sonstiges / Ergänzung';

  @override
  String get reflexResultTitle => 'Reflexprofil-Auswertung';

  @override
  String reflexResultLoadFailed(String error) {
    return 'Auswertung konnte nicht geladen werden: $error';
  }

  @override
  String get reflexResultIndicationStrengths => 'Hinweistärken';

  @override
  String get reflexResultDisclaimer =>
      'Diese Auswertung zeigt Antwortmuster und ersetzt keine medizinische oder therapeutische Diagnose.';

  @override
  String get reflexResultChartCaption =>
      'Die Grafik zeigt die stärksten Reflexbereiche aus deinem Antwortmuster.';

  @override
  String reflexResultWarningNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Du hast $count Hinweise bestätigt, bei denen wir dringend Rücksprache mit Arzt, Therapeut oder Psychologe empfehlen. Eine Trainerbegleitung ist in deinem Fall besonders sinnvoll.',
      one:
          'Du hast 1 Hinweis bestätigt, bei dem wir dringend Rücksprache mit Arzt, Therapeut oder Psychologe empfehlen. Eine Trainerbegleitung ist in deinem Fall besonders sinnvoll.',
    );
    return '$_temp0';
  }

  @override
  String get reflexResultAreasTitle => 'Reflexbereiche';

  @override
  String get reflexResultAdditionalInfo => 'Ergänzende Angaben';

  @override
  String get reflexResultSharePdf => 'PDF-Zusammenfassung teilen';

  @override
  String get reflexResultToDashboard => 'Zum Dashboard';

  @override
  String get reflexResultShareSubject => 'Reflex Journey Reflexprofil';

  @override
  String get reflexResultShareText =>
      'Reflex Journey Reflexprofil-Zusammenfassung';

  @override
  String reflexResultPdfFailed(String error) {
    return 'PDF konnte nicht erstellt werden: $error';
  }

  @override
  String get reflexResultShareWithTrainer => 'Mit Trainer teilen';

  @override
  String reflexResultShareWithTrainerBody(String trainerName) {
    return 'Du kannst $trainerName dein vollständiges Reflexprofil freigeben. Das hilft bei der gemeinsamen Begleitung und kann später widerrufen werden.';
  }

  @override
  String reflexResultShareLoadFailed(String error) {
    return 'Freigabe konnte nicht geladen werden: $error';
  }

  @override
  String get reflexResultShareRevoked => 'Freigabe wurde widerrufen.';

  @override
  String reflexResultShareRevokeFailed(String error) {
    return 'Freigabe konnte nicht widerrufen werden: $error';
  }

  @override
  String get reflexResultRevokeShare => 'Freigabe widerrufen';

  @override
  String get reflexResultShareGranted => 'Reflexprofil wurde freigegeben.';

  @override
  String reflexResultShareGrantFailed(String error) {
    return 'Reflexprofil konnte nicht freigegeben werden: $error';
  }

  @override
  String get reflexResultAllowTrainer => 'Trainer darf Auswertung sehen';

  @override
  String reflexResultYesOfAnswered(int yesCount, int answeredCount) {
    return '$yesCount von $answeredCount beantworteten zugeordneten Fragen wurden mit Ja beantwortet.';
  }

  @override
  String get reflexResultNoAdditional => 'Keine weiteren Angaben vorhanden.';

  @override
  String get reflexResultNoCompleted =>
      'Noch keine abgeschlossene Auswertung vorhanden.';

  @override
  String get reflexResultStartProfile => 'Reflexprofil starten';

  @override
  String get reflexDemoAnswerAll => 'Bitte beantworte alle Fragen.';

  @override
  String get reflexDemoFullTest => 'Volltest';

  @override
  String get reflexDemoForWhomTitle => 'Für wen machst du den Kurztest?';

  @override
  String get reflexDemoForWhomBody =>
      'Dieser Kurztest zeigt beispielhaft, wie eine Reflexprofil-Auswertung aussehen kann. Er wird nicht gespeichert.';

  @override
  String get reflexDemoSelfComingSoonTitle =>
      'Kurztest für mich selbst kommt bald';

  @override
  String get reflexDemoSelfComingSoonBody =>
      'Der Fragebogen für dich selbst befindet sich noch in Entwicklung.';

  @override
  String get reflexDemoTitle => 'Kurztest';

  @override
  String get reflexDemoIntro =>
      'Diese Demo zeigt beispielhaft, wie eine Reflexprofil-Auswertung aussehen kann. Sie wird nicht gespeichert und ersetzt keinen vollständigen Fragebogen.';

  @override
  String get reflexDemoEvaluate => 'Demo auswerten';

  @override
  String get reflexDemoSignInForFull =>
      'Für den vollständigen Fragebogen anmelden';

  @override
  String get reflexDemoStartFull => 'Vollständigen Fragebogen starten';

  @override
  String get reflexDemoGuestHint =>
      'Nach der Registrierung kannst du Kinderprofile anlegen, den vollständigen Fragebogen speichern und die Auswertung später erneut ansehen.';

  @override
  String get reflexDemoSignedInHint =>
      'Im vollständigen Fragebogen werden alle Kategorien abgefragt und die Auswertung kann gespeichert werden.';

  @override
  String get reflexDemoOpenFullTest => 'Volltest öffnen';

  @override
  String get reflexDemoSignInOrRegister => 'Anmelden oder registrieren';

  @override
  String get reflexDemoResultTitle => 'Demo-Auswertung';

  @override
  String get reflexDemoResultHeadline => 'Dein Demo-Ergebnis';

  @override
  String get reflexDemoResultDisclaimer =>
      'Diese Auswertung basiert nur auf dem Kurztest und ist keine Diagnose. Sie zeigt Antwortmuster — für ein vollständiges Reflexprofil sind alle 112 Fragen notwendig.';

  @override
  String get reflexDemoNotEnoughChartData =>
      'Nicht genug Daten für die Grafik.';

  @override
  String get reflexDemoChartCaption =>
      'Die Grafik zeigt die stärksten Reflexbereiche aus deinen Kurztest-Antworten.';

  @override
  String get reflexDemoAccountBenefitGuest =>
      'Mit einem Konto kannst du den vollständigen Fragebogen ausfüllen, dein Ergebnis speichern und mit deinem Trainer teilen.';

  @override
  String get reflexDemoAccountBenefitSignedIn =>
      'Im vollständigen Fragebogen werden alle Kategorien erfasst und das Ergebnis dauerhaft gespeichert.';

  @override
  String get reflexPdfTitle => 'Reflexprofil Zusammenfassung';

  @override
  String reflexPdfHeaderMeta(
      String date, String questionnaireVersion, String scoringVersion) {
    return 'Erstellt am $date · $questionnaireVersion / $scoringVersion';
  }

  @override
  String get reflexPdfSummaryNotice =>
      'Diese Auswertung zeigt Antwortmuster und Hinweisstärken. Sie ersetzt keine medizinische oder therapeutische Diagnose.';

  @override
  String reflexPdfSafetyNotice(int count) {
    return '$count Sicherheits-/Rücksprache-Hinweise wurden bestätigt. Training sollte nur nach ausdrücklicher Rücksprache mit Arzt, Therapeut oder Psychologe erfolgen.';
  }

  @override
  String get reflexPdfOverviewTitle => 'Reflexbereiche';

  @override
  String get reflexPdfFileNameStem => 'reflexjourney_reflexprofil';

  @override
  String get reflexProfileNameRequired => 'Bitte gib einen Namen an.';

  @override
  String get trainerWorkOverview => 'Arbeitsübersicht';

  @override
  String get trainerWorkOverviewSubtitle =>
      'Priorisiert nach Paketübergängen, Anfragen, Terminen und Beobachtungen.';

  @override
  String get trainerPackageTransitions => 'Paketübergänge';

  @override
  String get trainerOpenInvites => 'Offene Einladungen';

  @override
  String get trainerNewRequests => 'Neue Anfragen';

  @override
  String get trainerAppointmentsMetric => 'Termine';

  @override
  String get trainerNewObservations => 'Neue Beobachtungen';

  @override
  String trainerMoreInvitesOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Einladungen offen',
      one: '1 weitere Einladung offen',
    );
    return '$_temp0';
  }

  @override
  String get trainerReviewSharedExperiences => 'Geteilte Erfahrungen prüfen';

  @override
  String get trainerReviewSharedExperiencesBody =>
      'Moderierte Erfahrungsbeiträge aus laufenden Paketen im Blick behalten.';

  @override
  String get trainerConnectionCheck => 'Trainer-Verknüpfung prüfen';

  @override
  String get trainerConnectionChecking => 'Prüfe Datenbank...';

  @override
  String get trainerConnectionCheckError => 'Fehler bei der Prüfung';

  @override
  String get trainerConnectionTapToOpen => 'Zum Öffnen antippen';

  @override
  String get trainerConnectionRefresh => 'Prüfung aktualisieren';

  @override
  String trainerConnectionCheckFailed(String error) {
    return 'Prüfungsfehler: $error';
  }

  @override
  String get trainerInviteCodeOnce =>
      'Einmaliger Code — teile ihn mit deinem Klienten';

  @override
  String get trainerInviteNew => 'Neu';

  @override
  String get trainerInviteCreating => 'Wird erstellt…';

  @override
  String trainerCodeCopiedWithValue(String code) {
    return 'Code $code kopiert!';
  }

  @override
  String get trainerLocationMissingTitle => 'Standort fehlt';

  @override
  String get trainerLocationMissingBody =>
      'Dein Trainerprofil ist aktiv, erscheint aber erst in der Trainersuche, wenn ein Standort gesetzt ist. Öffentlich wird nur ein ungefährer Pin angezeigt.';

  @override
  String get trainerSetLocation => 'Standort setzen';

  @override
  String get trainerLocationSaved => 'Standort gespeichert';

  @override
  String trainerLocationSaveFailed(String error) {
    return 'Standort konnte nicht gespeichert werden: $error';
  }

  @override
  String get trainerDay28Badge => 'Tag 28 ✓';

  @override
  String trainerDaysLeft(int days) {
    return '$days Tage übrig';
  }

  @override
  String get trainerProposeAppointment => 'Termin vorschlagen';

  @override
  String trainerProposeNextPackage(int days) {
    return 'Noch $days Tage: Termin für das isometrische Training des nächsten Pakets vorschlagen.';
  }

  @override
  String get trainerOpenDetail => 'Detail öffnen';

  @override
  String get trainerOpenChat => 'Chat öffnen';

  @override
  String get trainerClientFallback => 'Client';

  @override
  String get trainerSharedReflexProfiles => 'Freigegebene Reflexprofile';

  @override
  String trainerProfilesLoadFailed(String error) {
    return 'Profile konnten nicht geladen werden: $error';
  }

  @override
  String get trainerNoProfilesShared => 'Keine Profile freigegeben.';

  @override
  String trainerNoCompletedReflexProfile(String name) {
    return '$name: Noch kein abgeschlossenes Reflexprofil.';
  }

  @override
  String get trainerObservations => 'Beobachtungen';

  @override
  String get trainerNoSharedObservations =>
      'Noch keine geteilten Beobachtungen.';

  @override
  String get trainerReflexNoteSaved => 'Reflexprofil-Notiz gespeichert.';

  @override
  String trainerNoteSaveFailed(String error) {
    return 'Notiz konnte nicht gespeichert werden: $error';
  }

  @override
  String get trainerReflexNotesTitle => 'Reflexprofil-Notizen';

  @override
  String get trainerReflexNotesBody =>
      'Diese Notizen haften am Profil und sind bei bestehender Freigabe auch für spätere Trainer als Übergabe sichtbar.';

  @override
  String get trainerReflexNoteHint => 'Notiz zur Begleitung oder Übergabe';

  @override
  String get trainerSaveNote => 'Notiz speichern';

  @override
  String trainerNotesLoadFailed(String error) {
    return 'Notizen konnten nicht geladen werden: $error';
  }

  @override
  String get trainerNoReflexNotes => 'Noch keine Reflexprofil-Notizen.';

  @override
  String get trainerMessageAction => 'Nachricht';

  @override
  String get trainerAppointmentAction => 'Termin';

  @override
  String trainerDaysCount(int count) {
    return '$count Tage';
  }

  @override
  String get trainerNoPlannedAppointments => 'Noch keine geplanten Termine.';

  @override
  String get trainerAppointmentProposed => 'Termin vorgeschlagen';

  @override
  String trainerAppointmentFor(String name) {
    return 'für $name';
  }

  @override
  String get appointmentStatusProposal => 'Vorschlag';

  @override
  String get appointmentStatusCompletedShort => 'Erledigt';

  @override
  String trainerDayNumber(int day) {
    return 'Tag $day';
  }

  @override
  String trainerAgeYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jahre',
      one: '$count Jahr',
    );
    return '$_temp0';
  }

  @override
  String get trainerBandStrongNoticeable => 'stark auffällig';

  @override
  String appointmentProposalSent(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Terminvorschläge an $name gesendet.',
      one: '1 Terminvorschlag an $name gesendet.',
    );
    return '$_temp0';
  }

  @override
  String get appointmentProposalSentHint =>
      'Die andere Person wählt einen passenden Slot aus.';

  @override
  String appointmentVideoWith(String name) {
    return 'Video-Termin mit $name';
  }

  @override
  String get appointmentPickSlotsInterview =>
      'Wähle 2–4 freie Slots für das Bewerbungsgespräch aus.';

  @override
  String get appointmentPickSlotsClient =>
      'Wähle 2–4 freie Slots aus — dein Klient sucht sich einen aus.';

  @override
  String appointmentSlotsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Slots ausgewählt',
      one: '1 Slot ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get appointmentResetSlots => 'Zurücksetzen';

  @override
  String get appointmentLocationOrVideo => 'Ort oder Video-Call';

  @override
  String get appointmentSelectSlots => 'Slots auswählen';

  @override
  String appointmentSendProposal(int count) {
    return 'Vorschlag senden ($count)';
  }

  @override
  String get appointmentForOptional => 'Termin für (optional)';

  @override
  String get appointmentForOptionalHint =>
      'Wähle Profile aus, wenn dieser Termin für bestimmte Kinder ist.';

  @override
  String get trainerApplicationTitle => 'Trainer-Bewerbung';

  @override
  String get trainerApplicationSubmittedStep => 'Bewerbung eingereicht';

  @override
  String get trainerApplicationBgCheckStep =>
      'Führungszeugnis Stufe 2 per Sichtprüfung geprüft';

  @override
  String get trainerApplicationCodeStep => 'Aktivierungscode erzeugt';

  @override
  String get trainerApplicationOpenReview => 'Review-Kanal öffnen';

  @override
  String get trainerApplicationActivate => 'Trainer aktivieren';

  @override
  String get trainerApplicationApprovedTitle => 'Freigegeben';

  @override
  String get trainerApplicationApprovedBody =>
      'Deine Bewerbung wurde freigegeben. Aktiviere jetzt dein verifiziertes Trainerprofil.';

  @override
  String get trainerApplicationRejectedTitle => 'Abgelehnt';

  @override
  String get trainerApplicationRejectedBody =>
      'Deine Bewerbung wurde abgelehnt. Details findest du im Review-Kanal.';

  @override
  String get trainerApplicationNeedsInfoTitle => 'Rückfrage offen';

  @override
  String get trainerApplicationNeedsInfoBody =>
      'Die Admins benötigen weitere Informationen. Bitte prüfe den Review-Kanal.';

  @override
  String get trainerApplicationInReviewBody =>
      'Deine Bewerbung ist im Review. Die Admins melden sich im Review-Kanal zur weiteren Prüfung.';

  @override
  String get trainerApplicationNoneTitle => 'Noch keine Trainer-Bewerbung';

  @override
  String get trainerApplicationStart => 'Bewerbung starten';

  @override
  String get trainerApplicationFieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get trainerApplicationFullName => 'Vollständiger Name';

  @override
  String get trainerApplicationEmail => 'E-Mail';

  @override
  String get trainerApplicationEmailInvalid => 'Gültige E-Mail erforderlich.';

  @override
  String get trainerApplicationPhoneOptional => 'Telefon optional';

  @override
  String get trainerApplicationCityRegion => 'Stadt / Region';

  @override
  String get trainerApplicationBackground => 'Beruflicher Hintergrund';

  @override
  String get trainerApplicationMotivationOptional => 'Motivation optional';

  @override
  String get trainerApplicationPublicProfile => 'Öffentliches Trainerprofil';

  @override
  String get trainerApplicationDisplayNameOptional => 'Anzeigename optional';

  @override
  String get trainerApplicationBioOptional => 'Bio optional';

  @override
  String get trainerApplicationLocationOptional => 'Standort optional';

  @override
  String get trainerApplicationLocationHint =>
      'Wenn du einen Standort setzt, kann dein Profil nach Freigabe in der Trainer-Suche erscheinen. Öffentlich wird nur ein ungefährer Pin angezeigt.';

  @override
  String get trainerApplicationSubmit => 'Bewerbung einreichen';

  @override
  String get trainerBecomeTitle => 'Trainer werden';

  @override
  String get trainerBecomeHeadline => 'Bewerbung und Prüfung';

  @override
  String get trainerBecomeBody =>
      'Reflex Journey-Trainer arbeiten in einem sensiblen Umfeld. Deshalb prüfen wir jede Bewerbung manuell, bevor ein Trainerprofil freigeschaltet wird.';

  @override
  String get trainerBecomeBackgroundTitle => 'Fachlicher Hintergrund';

  @override
  String get trainerBecomeBackgroundBody =>
      'Beschreibe deine Ausbildung, Erfahrung oder Praxis im relevanten Bereich.';

  @override
  String get trainerBecomeBgCheckTitle => 'Erweitertes Führungszeugnis Stufe 2';

  @override
  String get trainerBecomeBgCheckBody =>
      'Im Review-Kanal fordern Admins die Sichtprüfung an. Das Dokument wird nicht hochgeladen oder gespeichert.';

  @override
  String get trainerBecomeReviewTitle => 'Admin-Review-Kanal';

  @override
  String get trainerBecomeReviewBody =>
      'Nach dem Absenden öffnet sich ein geschützter Kommunikationskanal mit den Admins.';

  @override
  String get trainerBecomeImportant =>
      'Wichtig: Der Aktivierungscode wird erst nach erfolgreicher Prüfung erzeugt.';

  @override
  String get appointmentProposalsTitle => 'Terminvorschläge';

  @override
  String get appointmentNoOpenProposals => 'Keine offenen Terminvorschläge.';

  @override
  String get appointmentAddToCalendarTitle => 'Zum Kalender hinzufügen?';

  @override
  String appointmentAddToCalendarBody(String when) {
    return 'Soll der Termin am $when in deinen Kalender eingetragen werden?';
  }

  @override
  String get appointmentAddToCalendarConfirm => 'Ja, hinzufügen';

  @override
  String get appointmentConfirmedSnack => 'Termin bestätigt!';

  @override
  String get appointmentChooseSlot => 'Wähle einen passenden Termin:';

  @override
  String get appointmentConfirmSlot => 'Termin bestätigen';

  @override
  String get trainerRequestAccepted =>
      'Anfrage angenommen. Der Klient erscheint jetzt in deiner Übersicht.';

  @override
  String get trainerRequestDeclined => 'Anfrage abgelehnt.';

  @override
  String trainerClientRegularDays(
      String packageName, String dayLabel, int days) {
    return '$packageName · $dayLabel · $days Tage regelmäßig';
  }

  @override
  String get trainerAppStatusSubmitted => 'Eingereicht';

  @override
  String get trainerAppStatusInReview => 'In Prüfung';

  @override
  String get trainerAppStatusNeedsInfo => 'Rückfrage offen';

  @override
  String get trainerAppStatusApproved => 'Freigegeben';

  @override
  String get trainerAppStatusRejected => 'Abgelehnt';

  @override
  String get trainerAppStatusWithdrawn => 'Zurückgezogen';

  @override
  String calendarImportTitle(String title) {
    return 'Kalendereintrag für $title importieren';
  }

  @override
  String get osmAttribution => 'OpenStreetMap contributors';

  @override
  String get trainerMapTapHint => 'Tippe auf die Karte';

  @override
  String get trainerFallbackName => 'Trainer';

  @override
  String get trainerYourTrainer => 'Dein Trainer';

  @override
  String get trainerYourClient => 'Dein Nutzer';

  @override
  String get trainerChatFallback => 'Chat';

  @override
  String get trainerDiagNotSignedIn => 'auth.uid: nicht eingeloggt';

  @override
  String trainerDiagAuthUid(String id) {
    return 'auth.uid: $id';
  }

  @override
  String trainerDiagEmail(String email) {
    return 'email: $email';
  }

  @override
  String trainerDiagProfileRole(String role) {
    return 'profiles.role: $role';
  }

  @override
  String trainerDiagProfileName(String name) {
    return 'profiles.display_name: $name';
  }

  @override
  String trainerDiagScopeError(String scope, String error) {
    return '$scope: Fehler $error';
  }

  @override
  String trainerDiagRelationshipsTotal(int count) {
    return 'relationships gesamt: $count';
  }

  @override
  String trainerDiagRelationshipsActive(int count) {
    return 'relationships active: $count';
  }

  @override
  String trainerDiagRelationshipStatuses(String statuses) {
    return 'relationship statuses: $statuses';
  }

  @override
  String get trainerDiagRelationshipClientIds => 'relationship client_ids:';

  @override
  String trainerDiagAppointmentsAsTrainer(int count) {
    return 'appointments als trainer: $count';
  }

  @override
  String get trainerDiagAppointmentTraineeIds => 'appointment trainee_ids:';

  @override
  String get trainerDiagReconcileOk => 'reconcile_trainer_clients: ok';

  @override
  String trainerDiagGetClientsRows(int count) {
    return 'get_trainer_clients rows: $count';
  }

  @override
  String trainerActivateFailed(String error) {
    return 'Fehler beim Aktivieren: $error';
  }

  @override
  String get trainerNotSignedIn => 'Nicht eingeloggt.';

  @override
  String get trainerPkgMoro => 'Moro';

  @override
  String get trainerPkgSpinalGalant => 'Spinal Galant';

  @override
  String get trainerPkgTlr => 'TLR';

  @override
  String get trainerPkgBabkin => 'Babkin';

  @override
  String get trainerPkgSuchSaug => 'Such-Saug';

  @override
  String get trainerPkgAtnr => 'ATNR';

  @override
  String get trainerPkgStnr => 'STNR';

  @override
  String get trainerPkgBabinski => 'Babinski';

  @override
  String get trainerPkgLandau => 'Landau';

  @override
  String get chatChannelTypeCommunity => 'Community';

  @override
  String get chatChannelTypeApplicationReview => 'Trainer-Bewerbung';

  @override
  String get chatUserFallback => 'Nutzer';

  @override
  String get chatApplicantFallback => 'Bewerber';

  @override
  String get chatInboxTitle => 'Trainer-Kommunikation';

  @override
  String get chatInboxSectionMyTrainer => 'MEIN TRAINER';

  @override
  String get chatYesterday => 'Gestern';

  @override
  String get chatNoMessagesYet => 'Noch keine Nachrichten';

  @override
  String get chatInboxEmptyBody =>
      'Hier erscheinen deine Chats.\nVerbinde dich mit deinem Trainer, um Nachrichten und Video-Calls zu nutzen.';

  @override
  String get dmChatWithTrainer => 'Chat mit Trainer';

  @override
  String get dmEmptyBody =>
      'Hier erscheinen deine direkten Nachrichten mit deinem Trainer.';

  @override
  String chatWithName(String name) {
    return 'Chat mit $name';
  }

  @override
  String get chatStartCall => 'Call starten';

  @override
  String get chatRequestVideoCall => 'Video-Call anfragen';

  @override
  String get chatRequestVideoCallTitle => 'Video-Call anfragen?';

  @override
  String get chatRequestVideoCallBody =>
      'Du sendest deinem Trainer eine Anfrage für einen Video-Call. Der Trainer entscheidet, ob und wann er den Call startet.';

  @override
  String get chatSendRequest => 'Anfrage senden';

  @override
  String get chatMessagesLoadFailed =>
      'Nachrichten konnten gerade nicht geladen werden. Bitte Verbindung prüfen.';

  @override
  String get chatEmptyThread => 'Noch keine Nachrichten.\nSchreib die erste!';

  @override
  String get chatDeleteMessageTitle => 'Nachricht entfernen?';

  @override
  String get chatDeleteMessageBody =>
      'Die Nachricht wird für alle als entfernt angezeigt.';

  @override
  String get chatRemove => 'Entfernen';

  @override
  String get chatCameraMicPermissionRequired =>
      'Kamera & Mikrofon-Zugriff erforderlich. Bitte in den Einstellungen erlauben.';

  @override
  String chatCallStartFailed(String error) {
    return 'Fehler beim Starten des Calls: $error';
  }

  @override
  String get chatAppointmentOpenFailed =>
      'Terminplanung konnte nicht geöffnet werden.';

  @override
  String chatOpenFailed(String error) {
    return 'Chat konnte nicht geöffnet werden: $error';
  }

  @override
  String get chatAppointmentProposal => 'Terminvorschlag';

  @override
  String get chatViewProposal => 'Vorschlag ansehen';

  @override
  String get chatMessageRemoved => 'Diese Nachricht wurde entfernt.';

  @override
  String get chatAssistantName => 'Reflex Journey Assistent';

  @override
  String get chatCallRequestSentAsTrainer => 'Trainer-Anfrage gesendet';

  @override
  String get chatCallRequestSentAsClient => 'Video-Call-Anfrage gesendet';

  @override
  String get chatCallRequestIncomingAsTrainer =>
      'Nutzer möchte einen Video-Call';

  @override
  String get chatCallRequestIncomingAsClient =>
      'Trainer möchte einen Video-Call';

  @override
  String get chatMessageHint => 'Nachricht schreiben …';

  @override
  String chatTyping(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tippen …',
      one: 'tippt …',
    );
    return '$_temp0';
  }

  @override
  String get chatCallRequestMessageContent => '📹 Video-Call angefragt';

  @override
  String get trainingReadyForMovement => 'Bereit für die Bewegung?';

  @override
  String get trainingReadyBody =>
      'Prüfe deine Position. Starte erst, wenn du dich sicher und stabil fühlst.';

  @override
  String get trainingRepeatInstruction => 'Anleitung wiederholen';

  @override
  String trainingPreparationCountdown(int seconds) {
    return 'Start in $seconds Sekunden';
  }

  @override
  String trainingRepetitionOf(int current, int total) {
    return 'Wiederholung $current von $total';
  }

  @override
  String trainingPhaseOf(int current, int total) {
    return 'Phase $current von $total';
  }

  @override
  String trainingTimeRemaining(int seconds) {
    return 'Noch $seconds Sekunden';
  }

  @override
  String get trainingAudioContentUnavailableTitle =>
      'Sprachbegleitung noch nicht verfügbar';

  @override
  String get trainingAudioContentUnavailableBody =>
      'Die geprüften Aufnahmen fehlen noch. Der Ablauf funktioniert visuell und haptisch; er ist derzeit nicht vollständig sprachgeführt.';

  @override
  String get trainingSafetyStop =>
      'Stoppe bei Schmerzen, Schwindel, Übelkeit oder starkem Unwohlsein. Hole vor dem Fortsetzen fachlichen Rat ein.';

  @override
  String get trainingInterruptedTitle => 'Training pausiert';

  @override
  String get trainingInterruptedBody =>
      'Die Zeit wurde angehalten. Prüfe deine Position und setze bewusst fort.';

  @override
  String get trainingCompletionSaving => 'Abschluss wird sicher gespeichert …';

  @override
  String get trainingCompletionSaveFailed =>
      'Der Abschluss konnte noch nicht gespeichert werden. Deine Einheit bleibt lokal erhalten.';

  @override
  String get trainingContentUnavailableTitle => 'Training nicht verfügbar';

  @override
  String get trainingContentUnavailableBody =>
      'Für dieses Paket liegt kein geprüfter Trainingsinhalt vor. Es wurde kein anderes Paket als Ersatz gestartet.';

  @override
  String get trainingResumeSessionTitle => 'Einheit fortsetzen?';

  @override
  String get trainingResumeSessionBody =>
      'Eine unterbrochene Einheit wurde gefunden. Du kannst an derselben Stelle fortfahren oder neu beginnen.';

  @override
  String get trainingResumeSession => 'Fortsetzen';

  @override
  String get trainingStartOver => 'Neu beginnen';

  @override
  String get trainingSignInRequired =>
      'Melde dich an, bevor du eine Einheit startest.';

  @override
  String get trainingEnrollmentMissing =>
      'Für dieses Paket wurde keine aktive Teilnahme gefunden. Starte oder aktiviere das Paket zuerst.';

  @override
  String get trainingProgressMissing =>
      'Der Trainingsfortschritt ist noch nicht eingerichtet. Bitte synchronisiere erneut oder wende dich an den Support.';

  @override
  String trainingSideNumber(int number) {
    return 'Seite $number';
  }

  @override
  String trainingArmCrossNumber(int number) {
    return 'Armkreuz $number';
  }

  @override
  String get trainingMusicUnavailable =>
      'Für diese Version sind noch keine geprüften internen Musiktitel verfügbar.';

  @override
  String get trainingOrientationLabel => 'Orientierung';

  @override
  String get trainingBreathingLabel => 'Atmung';

  @override
  String get trainingRoutineCueLabel => 'Kurzhinweis';

  @override
  String get trainingSafetyLabel => 'Sicherheit';

  @override
  String get trainingRoutineLocked => 'Nach zwei begleiteten Einheiten';

  @override
  String get trainingLearningFirstTitle =>
      'Erster Durchlauf: in Ruhe kennenlernen';

  @override
  String get trainingLearningFirstBody =>
      'Der Lernmodus zeigt dir Position, Bewegung, Atmung und Sicherheit vollständig.';

  @override
  String get trainingLearningSecondTitle =>
      'Zweiter Durchlauf: sicher festigen';

  @override
  String get trainingLearningSecondBody =>
      'Du erhältst eine kompaktere Anleitung. Danach steht dir der Routinemodus zur Verfügung.';

  @override
  String get trainingRoutineReadyTitle => 'Routinemodus ist verfügbar';

  @override
  String get trainingRoutineReadyBody =>
      'Du kennst den Ablauf. Nutze die automatische Führung oder bleibe bei der ausführlichen Anleitung.';

  @override
  String get trainingContentChecking =>
      'Der geprüfte Offline-Inhalt ist bereit. Aktualisierungen werden im Hintergrund geprüft.';

  @override
  String get trainingOfflineSnapshotNotice =>
      'Der lokale oder entfernte Cache war nicht verwendbar. Du trainierst mit dem geprüften Offline-Inhalt dieser Version.';

  @override
  String get inviteTitle => 'Einladen';

  @override
  String get inviteTreeHeadlineZero => 'Verschenke einen guten Start';

  @override
  String inviteTreeHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Menschen sind über deine Einladung gestartet.',
      one: '1 Mensch ist über deine Einladung gestartet.',
    );
    return '$_temp0';
  }

  @override
  String get inviteTreeEmptyHint =>
      'Wenn jemand über deine Einladung sein erstes Training abschließt, wächst hier ein Zweig.';

  @override
  String get inviteWhy =>
      'Der Selbstcheck ist kostenlos, dauert fünf Minuten und braucht kein Konto. Du kannst ihn weitergeben.';

  @override
  String get inviteShareAction => 'Einladung teilen';

  @override
  String get inviteCodeLabel => 'Dein Code';

  @override
  String get inviteCodeCopied => 'Code kopiert';

  @override
  String get invitePrivacyFootnote =>
      'Du erfährst nur, wie viele Menschen begonnen haben. Nie wer.';

  @override
  String inviteShareMessage(String link) {
    return 'Falls du dich fragst, ob frühkindliche Reflexe bei euch eine Rolle spielen: Hier gibt es einen kostenlosen 5-Minuten-Check – ohne Anmeldung und ohne App. $link';
  }

  @override
  String inviteTreeSemantics(int count) {
    return 'Wachsender Baum. $count Menschen sind über deine Einladung gestartet.';
  }

  @override
  String get inviteErrorOffline =>
      'Dafür braucht es kurz Internet. Versuch es später noch einmal.';

  @override
  String get inviteEntryTitle => 'Freunde einladen';

  @override
  String get inviteEntrySubtitle => 'Den kostenlosen Selbstcheck weitergeben';

  @override
  String get impulseInviteTitle => 'Verschenke einen guten Start';

  @override
  String get impulseInviteBody =>
      'Kennst du jemanden, der sich dieselbe Frage stellt? Der 5-Minuten-Check ist kostenlos.';

  @override
  String get inviteRedeemQuestion => 'Hat dich jemand eingeladen?';

  @override
  String get inviteRedeemPaste => 'Aus Zwischenablage einfügen';

  @override
  String get inviteRedeemSkip => 'Überspringen';

  @override
  String get inviteConfirmTitle => 'Einladung annehmen?';

  @override
  String get inviteConfirmBody =>
      'Die Person, die dich eingeladen hat, sieht später nur, dass eine weitere Person über ihre Einladung mit dem Training begonnen hat – niemals deinen Namen.';

  @override
  String get inviteConfirmAccept => 'Einladung annehmen';

  @override
  String get inviteConfirmDecline => 'Nicht jetzt';

  @override
  String get inviteRedeemSuccess => 'Einladung angenommen.';

  @override
  String get inviteErrorUnknownCode =>
      'Diesen Code kennen wir nicht. Prüf bitte die Schreibweise.';

  @override
  String get inviteErrorCodeInactive => 'Dieser Code ist nicht mehr gültig.';

  @override
  String get inviteErrorOwnCode => 'Das ist dein eigener Code.';

  @override
  String get inviteErrorAlreadyReferred =>
      'Zu deinem Konto gehört schon eine Einladung.';

  @override
  String get inviteErrorAccountTooOld =>
      'Eine Einladung lässt sich nur in den ersten 30 Tagen eines Kontos annehmen.';

  @override
  String get inviteErrorUnexpected =>
      'Das hat gerade nicht geklappt. Versuch es bitte später noch einmal.';

  @override
  String get inviteCodeFieldLabel => 'Einladungscode';
}
