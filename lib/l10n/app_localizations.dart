import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// App title
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Du kannst sie später in den Einstellungen ändern.'**
  String get languageSelectionSubtitle;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get languageContinue;

  /// No description provided for @tryShortAssessment.
  ///
  /// In de, this message translates to:
  /// **'Kurztest ohne Konto ausprobieren'**
  String get tryShortAssessment;

  /// No description provided for @signInWithAlternativeDivider.
  ///
  /// In de, this message translates to:
  /// **'oder'**
  String get signInWithAlternativeDivider;

  /// No description provided for @signInWithApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple fortfahren'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In de, this message translates to:
  /// **'Mit Google fortfahren'**
  String get signInWithGoogle;

  /// No description provided for @authErrorSocialConfiguration.
  ///
  /// In de, this message translates to:
  /// **'Social Login ist noch nicht korrekt konfiguriert. Bitte Support kontaktieren.'**
  String get authErrorSocialConfiguration;

  /// No description provided for @authErrorSocialCancelled.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung wurde abgebrochen.'**
  String get authErrorSocialCancelled;

  /// No description provided for @email.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get resetPassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In de, this message translates to:
  /// **'Wir haben dir eine E-Mail zum Zurücksetzen des Passworts gesendet.'**
  String get passwordResetSent;

  /// No description provided for @signUpConfirmEmailSent.
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft! Wir haben dir eine E-Mail zur Bestätigung deines Kontos gesendet. Bitte tippe auf den Link darin, dann kannst du dich anmelden.'**
  String get signUpConfirmEmailSent;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In de, this message translates to:
  /// **'E-Mail oder Passwort ist falsch.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In de, this message translates to:
  /// **'Diese E-Mail-Adresse ist bereits registriert.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort muss mindestens 8 Zeichen lang sein.'**
  String get authErrorWeakPassword;

  /// No description provided for @dashboard.
  ///
  /// In de, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @startTraining.
  ///
  /// In de, this message translates to:
  /// **'Einheit beginnen'**
  String get startTraining;

  /// No description provided for @currentDay.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} von {total}'**
  String currentDay(int day, int total);

  /// No description provided for @dailyStreak.
  ///
  /// In de, this message translates to:
  /// **'Regelmäßigkeit'**
  String get dailyStreak;

  /// No description provided for @weeklyProgress.
  ///
  /// In de, this message translates to:
  /// **'{count} von {goal} diese Woche'**
  String weeklyProgress(int count, int goal);

  /// No description provided for @goldenDay.
  ///
  /// In de, this message translates to:
  /// **'Golden Day'**
  String get goldenDay;

  /// No description provided for @daysRemaining.
  ///
  /// In de, this message translates to:
  /// **'{days} Tage verbleibend'**
  String daysRemaining(int days);

  /// No description provided for @trainingMode.
  ///
  /// In de, this message translates to:
  /// **'Einheitsmodus'**
  String get trainingMode;

  /// No description provided for @tutorialMode.
  ///
  /// In de, this message translates to:
  /// **'Tutorial'**
  String get tutorialMode;

  /// No description provided for @routineMode.
  ///
  /// In de, this message translates to:
  /// **'Routine'**
  String get routineMode;

  /// No description provided for @silentMode.
  ///
  /// In de, this message translates to:
  /// **'Silent'**
  String get silentMode;

  /// No description provided for @hapticMode.
  ///
  /// In de, this message translates to:
  /// **'Haptisch'**
  String get hapticMode;

  /// No description provided for @voiceCuesMode.
  ///
  /// In de, this message translates to:
  /// **'Stimme & Cues'**
  String get voiceCuesMode;

  /// No description provided for @exercisePosition.
  ///
  /// In de, this message translates to:
  /// **'Ausgangsposition'**
  String get exercisePosition;

  /// No description provided for @exerciseMovement.
  ///
  /// In de, this message translates to:
  /// **'Bewegung'**
  String get exerciseMovement;

  /// No description provided for @exerciseHints.
  ///
  /// In de, this message translates to:
  /// **'Hinweise'**
  String get exerciseHints;

  /// No description provided for @exerciseReps.
  ///
  /// In de, this message translates to:
  /// **'{count} Wiederholungen'**
  String exerciseReps(int count);

  /// No description provided for @sessionComplete.
  ///
  /// In de, this message translates to:
  /// **'Einheit abgeschlossen'**
  String get sessionComplete;

  /// No description provided for @sessionCompleteSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Du hast deine heutige Einheit abgeschlossen.'**
  String get sessionCompleteSubtitle;

  /// No description provided for @moodCheckIn.
  ///
  /// In de, this message translates to:
  /// **'Wie geht es dir?'**
  String get moodCheckIn;

  /// No description provided for @moodLabel.
  ///
  /// In de, this message translates to:
  /// **'Stimmung'**
  String get moodLabel;

  /// No description provided for @energyLabel.
  ///
  /// In de, this message translates to:
  /// **'Energie'**
  String get energyLabel;

  /// No description provided for @stressLabel.
  ///
  /// In de, this message translates to:
  /// **'Stress'**
  String get stressLabel;

  /// No description provided for @moodSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get moodSkip;

  /// No description provided for @moodSubmit.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get moodSubmit;

  /// No description provided for @moodChartEmpty.
  ///
  /// In de, this message translates to:
  /// **'Trage eine Einheit ein, um dein Befinden im Verlauf zu sehen.'**
  String get moodChartEmpty;

  /// No description provided for @intakeAssessmentTitle.
  ///
  /// In de, this message translates to:
  /// **'Programmstart'**
  String get intakeAssessmentTitle;

  /// No description provided for @intakeWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen in deinem Reflexintegrations-Programm'**
  String get intakeWelcomeTitle;

  /// No description provided for @intakeWelcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey begleitet dich bei der Integration pränataler Reflexe — ein Prozess, der dabei helfen kann, tief verwurzelte körperliche und emotionale Muster zu transformieren.'**
  String get intakeWelcomeBody;

  /// No description provided for @intakeTrainerTitle.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung: Mit Trainer starten'**
  String get intakeTrainerTitle;

  /// No description provided for @intakeTrainerBody.
  ///
  /// In de, this message translates to:
  /// **'Wir empfehlen, das Programm mit einem zertifizierten Trainer zu beginnen und begleiten zu lassen. Ein Trainer führt isometrische Partnerübungen durch, die klares Spüren von Richtung, Bewegung und Widerstand unterstützen. Ohne diese Begleitung braucht der Körper in der Regel mehr ruhige Wiederholung.'**
  String get intakeTrainerBody;

  /// No description provided for @intakeQuestionLabel.
  ///
  /// In de, this message translates to:
  /// **'Eine Frage zu deinem Start'**
  String get intakeQuestionLabel;

  /// No description provided for @questionIsometricWithTrainer.
  ///
  /// In de, this message translates to:
  /// **'Hast du bereits isometrische Partnerübungen mit einem Trainer durchgeführt?'**
  String get questionIsometricWithTrainer;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @durationRecommendation.
  ///
  /// In de, this message translates to:
  /// **'Empfohlene Dauer: {weeks} Wochen'**
  String durationRecommendation(int weeks);

  /// No description provided for @adjustDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer anpassen'**
  String get adjustDuration;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @durationWithoutTrainerInfo.
  ///
  /// In de, this message translates to:
  /// **'Ohne begleitenden Trainer empfehlen wir etwa 8 Wochen, damit der Körper mehr Zeit für die Integration hat.'**
  String get durationWithoutTrainerInfo;

  /// No description provided for @durationTrainerMinimumInfo.
  ///
  /// In de, this message translates to:
  /// **'Mit begleitendem Trainer empfehlen wir mindestens 4 Wochen. Du kannst die Dauer verlängern, wenn du mehr Integrationszeit möchtest.'**
  String get durationTrainerMinimumInfo;

  /// No description provided for @trainerOnboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Begleitung'**
  String get trainerOnboardingTitle;

  /// No description provided for @trainerOnboardingFindTitle.
  ///
  /// In de, this message translates to:
  /// **'Starte mit einem Trainer in deiner Nähe'**
  String get trainerOnboardingFindTitle;

  /// No description provided for @trainerOnboardingFindBody.
  ///
  /// In de, this message translates to:
  /// **'Da du die isometrische Aktivierung noch nicht mit einem Trainer gemacht hast, empfehlen wir dir, zuerst einen passenden Trainer zu finden. Du kannst trotzdem direkt starten, wenn du das möchtest.'**
  String get trainerOnboardingFindBody;

  /// No description provided for @trainerOnboardingConnectTitle.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfe dich mit deinem Trainer'**
  String get trainerOnboardingConnectTitle;

  /// No description provided for @trainerOnboardingConnectBody.
  ///
  /// In de, this message translates to:
  /// **'Wenn du bereits mit einem Trainer gearbeitet hast, kannst du dich jetzt verbinden. So kann dein Trainer deinen Fortschritt begleiten und bei Bedarf Termine abstimmen.'**
  String get trainerOnboardingConnectBody;

  /// No description provided for @trainerOnboardingSearchCta.
  ///
  /// In de, this message translates to:
  /// **'Trainer in meiner Nähe suchen'**
  String get trainerOnboardingSearchCta;

  /// No description provided for @trainerOnboardingInviteCta.
  ///
  /// In de, this message translates to:
  /// **'Einladungscode eingeben'**
  String get trainerOnboardingInviteCta;

  /// No description provided for @trainerOnboardingSkipCta.
  ///
  /// In de, this message translates to:
  /// **'Später machen'**
  String get trainerOnboardingSkipCta;

  /// No description provided for @trainerOnboardingInviteTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit Trainer verbinden'**
  String get trainerOnboardingInviteTitle;

  /// No description provided for @trainerOnboardingInviteBody.
  ///
  /// In de, this message translates to:
  /// **'Gib den 6-stelligen Einladungscode ein, den du von deinem Trainer erhalten hast.'**
  String get trainerOnboardingInviteBody;

  /// No description provided for @trainerOnboardingInviteInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte 6-stelligen Code eingeben.'**
  String get trainerOnboardingInviteInvalid;

  /// No description provided for @trainerOnboardingInviteFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Verbinden mit dem Trainer.'**
  String get trainerOnboardingInviteFailed;

  /// No description provided for @trainerOnboardingContinueAfterRequest.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Dauerempfehlung'**
  String get trainerOnboardingContinueAfterRequest;

  /// No description provided for @completionQuestionnaireTitle.
  ///
  /// In de, this message translates to:
  /// **'Abschlussreflexion'**
  String get completionQuestionnaireTitle;

  /// No description provided for @completionCelebrationTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket abgeschlossen'**
  String get completionCelebrationTitle;

  /// No description provided for @completionCelebrationSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Du hast dieses Paket über die geplante Zeit begleitet.'**
  String get completionCelebrationSubtitle;

  /// No description provided for @completionNextPackage.
  ///
  /// In de, this message translates to:
  /// **'Weiter zum nächsten Paket'**
  String get completionNextPackage;

  /// No description provided for @completionBackToDashboard.
  ///
  /// In de, this message translates to:
  /// **'Zum Dashboard'**
  String get completionBackToDashboard;

  /// No description provided for @completionReachedTitle.
  ///
  /// In de, this message translates to:
  /// **'Paketdauer erreicht'**
  String get completionReachedTitle;

  /// No description provided for @completionReachedBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast die geplante Paketdauer erreicht. In Heute findest du jetzt oben eine kurze Einschätzung, mit der du das Paket abschließen oder um 7 Tage verlängern kannst.'**
  String get completionReachedBody;

  /// No description provided for @completionPlaceholderQuestion.
  ///
  /// In de, this message translates to:
  /// **'Platzhalter-Einschätzung: Fühlt sich dieses Paket stimmig abgeschlossen an?'**
  String get completionPlaceholderQuestion;

  /// No description provided for @completionPass.
  ///
  /// In de, this message translates to:
  /// **'Paket abschließen'**
  String get completionPass;

  /// No description provided for @completionInsufficient.
  ///
  /// In de, this message translates to:
  /// **'Noch 7 Tage wiederholen'**
  String get completionInsufficient;

  /// No description provided for @completionMoroReturnSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Der erneute Moro-Durchlauf ist abgeschlossen. Du kehrst jetzt zu deinem unterbrochenen Paket zurück und startest dort wieder bei Tag 1.'**
  String get completionMoroReturnSubtitle;

  /// No description provided for @completionBackToInterruptedPackage.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum unterbrochenen Paket'**
  String get completionBackToInterruptedPackage;

  /// No description provided for @completionExtendedTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch eine Woche'**
  String get completionExtendedTitle;

  /// No description provided for @completionExtendedSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Du hast 7 weitere Tage in diesem Paket.'**
  String get completionExtendedSubtitle;

  /// No description provided for @completionQuestion.
  ///
  /// In de, this message translates to:
  /// **'Hast du seit Beginn dieses Pakets stärkere emotionale oder stressbezogene Reaktionen bemerkt und konntest du sie etwas besser einordnen oder regulieren?'**
  String get completionQuestion;

  /// No description provided for @completionYes.
  ///
  /// In de, this message translates to:
  /// **'Ja, ich bin bereit'**
  String get completionYes;

  /// No description provided for @completionNotYet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht'**
  String get completionNotYet;

  /// No description provided for @packages.
  ///
  /// In de, this message translates to:
  /// **'Programm'**
  String get packages;

  /// No description provided for @packageLocked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get packageLocked;

  /// No description provided for @packageCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get packageCurrent;

  /// No description provided for @packageCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get packageCompleted;

  /// No description provided for @paywallTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Pakete freischalten'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Paket 1 bleibt für immer kostenlos. Mit Premium schaltest du alle weiteren Reflexpakete frei — für dich und deine Familienprofile.'**
  String get paywallSubtitle;

  /// No description provided for @paywallDurationNote.
  ///
  /// In de, this message translates to:
  /// **'Das gesamte Programm dauert typischerweise 10–12 Monate — in deinem Tempo, Pausen inklusive.'**
  String get paywallDurationNote;

  /// No description provided for @paywallMonthlyTitle.
  ///
  /// In de, this message translates to:
  /// **'Monatlich'**
  String get paywallMonthlyTitle;

  /// No description provided for @paywallPerMonth.
  ///
  /// In de, this message translates to:
  /// **'pro Monat'**
  String get paywallPerMonth;

  /// No description provided for @paywallYearlyTitle.
  ///
  /// In de, this message translates to:
  /// **'Jährlich'**
  String get paywallYearlyTitle;

  /// No description provided for @paywallPerYear.
  ///
  /// In de, this message translates to:
  /// **'pro Jahr'**
  String get paywallPerYear;

  /// No description provided for @paywallYearlyBadge.
  ///
  /// In de, this message translates to:
  /// **'2 Monate geschenkt'**
  String get paywallYearlyBadge;

  /// No description provided for @paywallLifetimeTitle.
  ///
  /// In de, this message translates to:
  /// **'Einmalig'**
  String get paywallLifetimeTitle;

  /// No description provided for @paywallOnce.
  ///
  /// In de, this message translates to:
  /// **'einmalig, dauerhaft'**
  String get paywallOnce;

  /// No description provided for @paywallUnlock.
  ///
  /// In de, this message translates to:
  /// **'Freischalten'**
  String get paywallUnlock;

  /// No description provided for @paywallRestore.
  ///
  /// In de, this message translates to:
  /// **'Käufe wiederherstellen'**
  String get paywallRestore;

  /// No description provided for @paywallNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Käufe sind in dieser Version noch nicht verfügbar.'**
  String get paywallNotAvailable;

  /// No description provided for @paywallCancelNote.
  ///
  /// In de, this message translates to:
  /// **'Abos sind jederzeit kündbar.'**
  String get paywallCancelNote;

  /// No description provided for @packageAvailable.
  ///
  /// In de, this message translates to:
  /// **'Verfügbar'**
  String get packageAvailable;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @settingsTraining.
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get settingsTraining;

  /// No description provided for @settingsReminders.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get settingsReminders;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get settingsTheme;

  /// No description provided for @settingsWeeklyGoal.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel'**
  String get settingsWeeklyGoal;

  /// No description provided for @settingsChildAssist.
  ///
  /// In de, this message translates to:
  /// **'Kinderunterstützung'**
  String get settingsChildAssist;

  /// No description provided for @settingsConnectTrainer.
  ///
  /// In de, this message translates to:
  /// **'Trainer verbinden'**
  String get settingsConnectTrainer;

  /// No description provided for @moroRestartSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Moro'**
  String get moroRestartSettingsTitle;

  /// No description provided for @moroRestartSettingsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Moro für 4 Wochen neu starten und das aktuelle Paket unterbrechen.'**
  String get moroRestartSettingsSubtitle;

  /// No description provided for @moroRestartTitle.
  ///
  /// In de, this message translates to:
  /// **'Zum Moro zurückkehren?'**
  String get moroRestartTitle;

  /// No description provided for @moroRestartBody.
  ///
  /// In de, this message translates to:
  /// **'Der Moro-Reflex kann im Unterschied zu vielen anderen Reflexen durch stark belastende oder traumatische Ereignisse erneut aktiviert werden, zum Beispiel durch einen Autounfall, den Tod eines Angehörigen oder andere intensive Schockerlebnisse.\n\nWenn du fortfährst, wird dein aktuelles Paket unterbrochen. Du startest Moro für 4 Wochen neu. Nach dem Moro-Abschluss kehrst du zu deinem unterbrochenen Paket zurück und beginnst dort wieder bei Tag 1.'**
  String get moroRestartBody;

  /// No description provided for @moroRestartConfirm.
  ///
  /// In de, this message translates to:
  /// **'Moro neu starten'**
  String get moroRestartConfirm;

  /// No description provided for @reminderEnabled.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen aktiviert'**
  String get reminderEnabled;

  /// No description provided for @reminderWindow.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungsfenster'**
  String get reminderWindow;

  /// No description provided for @quietHours.
  ///
  /// In de, this message translates to:
  /// **'Ruhezeiten'**
  String get quietHours;

  /// No description provided for @reminderFrom.
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get reminderFrom;

  /// No description provided for @reminderTo.
  ///
  /// In de, this message translates to:
  /// **'Bis'**
  String get reminderTo;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @weeklyGoalSessions.
  ///
  /// In de, this message translates to:
  /// **'{goal} Einheiten/Woche'**
  String weeklyGoalSessions(int goal);

  /// No description provided for @settingsFeedback.
  ///
  /// In de, this message translates to:
  /// **'Einheits-Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get settingsAccount;

  /// No description provided for @disclaimer.
  ///
  /// In de, this message translates to:
  /// **'Medizinischer Hinweis'**
  String get disclaimer;

  /// No description provided for @disclaimerText.
  ///
  /// In de, this message translates to:
  /// **'Diese Einheiten ersetzen keine medizinische Behandlung. Bitte konsultiere einen Arzt, wenn du gesundheitliche Bedenken hast. Achte auf die Signale deines Körpers und mache Pausen, wenn nötig.'**
  String get disclaimerText;

  /// No description provided for @disclaimerAccept.
  ///
  /// In de, this message translates to:
  /// **'Verstanden, weiter'**
  String get disclaimerAccept;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte versuche es erneut.'**
  String get errorGeneric;

  /// No description provided for @errorNoNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung.'**
  String get errorNoNetwork;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @trainerClients.
  ///
  /// In de, this message translates to:
  /// **'Meine Klienten'**
  String get trainerClients;

  /// No description provided for @trainerNoClients.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Klienten verknüpft.'**
  String get trainerNoClients;

  /// No description provided for @trainerNoClientsHint.
  ///
  /// In de, this message translates to:
  /// **'Erstelle einen Einladungscode und teile ihn mit deinem Klienten.'**
  String get trainerNoClientsHint;

  /// No description provided for @trainerInviteCode.
  ///
  /// In de, this message translates to:
  /// **'Einladungscode'**
  String get trainerInviteCode;

  /// No description provided for @trainerInviteCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Teile diesen Code mit deinem Klienten. Er kann einmalig verwendet werden.'**
  String get trainerInviteCodeHint;

  /// No description provided for @trainerGenerateCode.
  ///
  /// In de, this message translates to:
  /// **'Einladung erstellen'**
  String get trainerGenerateCode;

  /// No description provided for @trainerCopyCode.
  ///
  /// In de, this message translates to:
  /// **'Code kopieren'**
  String get trainerCopyCode;

  /// No description provided for @trainerCodeCopied.
  ///
  /// In de, this message translates to:
  /// **'Code in die Zwischenablage kopiert.'**
  String get trainerCodeCopied;

  /// No description provided for @trainerAtRisk.
  ///
  /// In de, this message translates to:
  /// **'Risiko'**
  String get trainerAtRisk;

  /// No description provided for @trainerLastActive.
  ///
  /// In de, this message translates to:
  /// **'Vor {days} Tag(en)'**
  String trainerLastActive(int days);

  /// No description provided for @trainerNotes.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Notizen'**
  String get trainerNotes;

  /// No description provided for @trainerNotesHint.
  ///
  /// In de, this message translates to:
  /// **'Private Notizen zu diesem Klienten...'**
  String get trainerNotesHint;

  /// No description provided for @trainerNotesSaved.
  ///
  /// In de, this message translates to:
  /// **'Notizen gespeichert.'**
  String get trainerNotesSaved;

  /// No description provided for @trainerRecentSessions.
  ///
  /// In de, this message translates to:
  /// **'Letzte Einheiten (30 Tage)'**
  String get trainerRecentSessions;

  /// No description provided for @trainerNoSessions.
  ///
  /// In de, this message translates to:
  /// **'Keine Einheiten in den letzten 30 Tagen.'**
  String get trainerNoSessions;

  /// No description provided for @trainerView.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Ansicht'**
  String get trainerView;

  /// No description provided for @connectToTrainer.
  ///
  /// In de, this message translates to:
  /// **'Mit Trainer verbinden'**
  String get connectToTrainer;

  /// No description provided for @enterInviteCode.
  ///
  /// In de, this message translates to:
  /// **'Einladungscode eingeben'**
  String get enterInviteCode;

  /// No description provided for @connectToTrainerSuccess.
  ///
  /// In de, this message translates to:
  /// **'Mit Trainer verbunden!'**
  String get connectToTrainerSuccess;

  /// No description provided for @connectToTrainerError.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger oder abgelaufener Einladungscode.'**
  String get connectToTrainerError;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lädt...'**
  String get loading;

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @dayNumber.
  ///
  /// In de, this message translates to:
  /// **'Tag {day}'**
  String dayNumber(int day);

  /// No description provided for @weeksCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Wochen'**
  String weeksCount(int count);

  /// No description provided for @daysCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Tage'**
  String daysCount(int count);

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @journal.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch'**
  String get journal;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge.'**
  String get journalEmptyTitle;

  /// No description provided for @journalEmptySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Schreib auf, was du in deinem Alltag beobachtest — nach einer Einheit oder wann immer du möchtest.'**
  String get journalEmptySubtitle;

  /// No description provided for @journalEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Halte fest, was sich in deinem Alltag verändert.'**
  String get journalEmptyHint;

  /// No description provided for @journalNewEntry.
  ///
  /// In de, this message translates to:
  /// **'Neue Notiz'**
  String get journalNewEntry;

  /// No description provided for @journalPostTrainingTitle.
  ///
  /// In de, this message translates to:
  /// **'Veränderungen im Alltag?'**
  String get journalPostTrainingTitle;

  /// No description provided for @journalPostTrainingHint.
  ///
  /// In de, this message translates to:
  /// **'Hast du etwas bemerkt — in deinem Schlaf, deinen Reaktionen, deinem Körpergefühl?'**
  String get journalPostTrainingHint;

  /// No description provided for @journalPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Schreib hier deine Beobachtung...'**
  String get journalPlaceholder;

  /// No description provided for @journalLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Einträge konnten nicht geladen werden.'**
  String get journalLoadFailed;

  /// No description provided for @moodHistory.
  ///
  /// In de, this message translates to:
  /// **'Stimmungsverlauf'**
  String get moodHistory;

  /// No description provided for @profile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @completionBannerTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket bereit zur Einschätzung'**
  String get completionBannerTitle;

  /// No description provided for @completionBannerSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Beantworte den kurzen Fragebogen, um dieses Paket abzuschließen oder um 7 Tage zu verlängern.'**
  String get completionBannerSubtitle;

  /// No description provided for @settingsDataSync.
  ///
  /// In de, this message translates to:
  /// **'Daten & Sync'**
  String get settingsDataSync;

  /// No description provided for @settingsTrainingModeDescription.
  ///
  /// In de, this message translates to:
  /// **'Tutorial ist für den Einstieg. Routine ist kompakter.'**
  String get settingsTrainingModeDescription;

  /// No description provided for @settingsAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Erweitert'**
  String get settingsAdvanced;

  /// No description provided for @settingsResetIntroductions.
  ///
  /// In de, this message translates to:
  /// **'Einführungen erneut anzeigen'**
  String get settingsResetIntroductions;

  /// No description provided for @settingsResetIntroductionsDescription.
  ///
  /// In de, this message translates to:
  /// **'Zeigt die kurzen Hinweise auf Heute, Verlauf, Begleitung und Profil wieder an.'**
  String get settingsResetIntroductionsDescription;

  /// No description provided for @settingsResetIntroductionsSuccess.
  ///
  /// In de, this message translates to:
  /// **'Einführungen werden wieder angezeigt.'**
  String get settingsResetIntroductionsSuccess;

  /// No description provided for @syncStatusOk.
  ///
  /// In de, this message translates to:
  /// **'Alles synchronisiert'**
  String get syncStatusOk;

  /// No description provided for @syncStatusPending.
  ///
  /// In de, this message translates to:
  /// **'{count} Einträge ausstehend'**
  String syncStatusPending(int count);

  /// No description provided for @syncStatusFailed.
  ///
  /// In de, this message translates to:
  /// **'{count} Einträge fehlgeschlagen'**
  String syncStatusFailed(int count);

  /// No description provided for @syncInProgress.
  ///
  /// In de, this message translates to:
  /// **'Synchronisiert...'**
  String get syncInProgress;

  /// No description provided for @syncNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt sync'**
  String get syncNow;

  /// No description provided for @errorSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen. Bitte erneut versuchen.'**
  String get errorSaveFailed;

  /// No description provided for @errorLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Daten konnten nicht geladen werden.'**
  String get errorLoadFailed;

  /// No description provided for @errorLoadFailedInline.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden'**
  String get errorLoadFailedInline;

  /// No description provided for @validationRequired.
  ///
  /// In de, this message translates to:
  /// **'Dieses Feld ist erforderlich.'**
  String get validationRequired;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige E-Mail-Adresse ein.'**
  String get validationInvalidEmail;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort muss mindestens 8 Zeichen lang sein.'**
  String get validationPasswordTooShort;

  /// No description provided for @profileVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);

  /// No description provided for @profileChangePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort ändern'**
  String get profileChangePassword;

  /// No description provided for @profileChangePasswordSent.
  ///
  /// In de, this message translates to:
  /// **'Passwort-Reset-E-Mail wurde gesendet.'**
  String get profileChangePasswordSent;

  /// No description provided for @newPassword.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort'**
  String get newPassword;

  /// No description provided for @passwordConfirm.
  ///
  /// In de, this message translates to:
  /// **'Passwort bestätigen'**
  String get passwordConfirm;

  /// No description provided for @currentPassword.
  ///
  /// In de, this message translates to:
  /// **'Aktuelles Passwort'**
  String get currentPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In de, this message translates to:
  /// **'Passwort erfolgreich geändert.'**
  String get passwordChanged;

  /// No description provided for @passwordSet.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort gesetzt. Bitte einloggen.'**
  String get passwordSet;

  /// No description provided for @authErrorSamePassword.
  ///
  /// In de, this message translates to:
  /// **'Das neue Passwort muss sich vom bisherigen unterscheiden.'**
  String get authErrorSamePassword;

  /// No description provided for @authErrorInvalidCurrentPassword.
  ///
  /// In de, this message translates to:
  /// **'Das aktuelle Passwort ist falsch.'**
  String get authErrorInvalidCurrentPassword;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In de, this message translates to:
  /// **'Passwörter stimmen nicht überein.'**
  String get validationPasswordMismatch;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen?'**
  String get profileDeleteAccountTitle;

  /// No description provided for @profileDeleteAccountBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto und alle deine Daten werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.'**
  String get profileDeleteAccountBody;

  /// No description provided for @profileDeleteAccountConfirm.
  ///
  /// In de, this message translates to:
  /// **'Dauerhaft löschen'**
  String get profileDeleteAccountConfirm;

  /// No description provided for @profileDeleteAccountSuccess.
  ///
  /// In de, this message translates to:
  /// **'Konto gelöscht.'**
  String get profileDeleteAccountSuccess;

  /// No description provided for @profileDeleteAccountError.
  ///
  /// In de, this message translates to:
  /// **'Konto konnte nicht gelöscht werden. Bitte kontaktiere den Support.'**
  String get profileDeleteAccountError;

  /// No description provided for @redeemAccessCodeTitle.
  ///
  /// In de, this message translates to:
  /// **'Gründungscode einlösen'**
  String get redeemAccessCodeTitle;

  /// No description provided for @redeemAccessCodeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Schalte mit deinem Code alle kostenpflichtigen Pakete frei.'**
  String get redeemAccessCodeSubtitle;

  /// No description provided for @redeemAccessCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Code eingeben'**
  String get redeemAccessCodeHint;

  /// No description provided for @redeemAccessCodeAction.
  ///
  /// In de, this message translates to:
  /// **'Einlösen'**
  String get redeemAccessCodeAction;

  /// No description provided for @redeemAccessCodeSuccess.
  ///
  /// In de, this message translates to:
  /// **'Code eingelöst. Premium-Zugang ist aktiv.'**
  String get redeemAccessCodeSuccess;

  /// No description provided for @redeemAccessCodeErrorInvalid.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code ist ungültig.'**
  String get redeemAccessCodeErrorInvalid;

  /// No description provided for @redeemAccessCodeErrorUsed.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code wurde bereits eingelöst.'**
  String get redeemAccessCodeErrorUsed;

  /// No description provided for @redeemAccessCodeErrorExpired.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code ist abgelaufen.'**
  String get redeemAccessCodeErrorExpired;

  /// No description provided for @redeemAccessCodeErrorUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code-Typ wird noch nicht unterstützt.'**
  String get redeemAccessCodeErrorUnsupported;

  /// No description provided for @redeemAccessCodeErrorUnauthorized.
  ///
  /// In de, this message translates to:
  /// **'Bitte melde dich erneut an und versuche es noch einmal.'**
  String get redeemAccessCodeErrorUnauthorized;

  /// No description provided for @redeemAccessCodeErrorUnknown.
  ///
  /// In de, this message translates to:
  /// **'Code konnte nicht eingelöst werden. Bitte erneut versuchen.'**
  String get redeemAccessCodeErrorUnknown;

  /// No description provided for @trainerDashboard.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Dashboard'**
  String get trainerDashboard;

  /// No description provided for @trainerTabTrainees.
  ///
  /// In de, this message translates to:
  /// **'Klienten'**
  String get trainerTabTrainees;

  /// No description provided for @trainerTabCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get trainerTabCalendar;

  /// No description provided for @trainerMyLink.
  ///
  /// In de, this message translates to:
  /// **'Mein Einladungslink'**
  String get trainerMyLink;

  /// No description provided for @trainerCopyLink.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get trainerCopyLink;

  /// No description provided for @trainerLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert.'**
  String get trainerLinkCopied;

  /// No description provided for @trainerScheduleAppointment.
  ///
  /// In de, this message translates to:
  /// **'Planen'**
  String get trainerScheduleAppointment;

  /// No description provided for @trainerBookNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt buchen'**
  String get trainerBookNow;

  /// No description provided for @trainerAppointmentMissing.
  ///
  /// In de, this message translates to:
  /// **'Termin fehlt'**
  String get trainerAppointmentMissing;

  /// No description provided for @trainerNoAppointments.
  ///
  /// In de, this message translates to:
  /// **'Keine Termine geplant.'**
  String get trainerNoAppointments;

  /// No description provided for @appointmentSchedulerTitle.
  ///
  /// In de, this message translates to:
  /// **'Termin buchen'**
  String get appointmentSchedulerTitle;

  /// No description provided for @appointmentWith.
  ///
  /// In de, this message translates to:
  /// **'Termin mit {name}'**
  String appointmentWith(String name);

  /// No description provided for @appointmentSessionTitle.
  ///
  /// In de, this message translates to:
  /// **'Isometrische Partnerübung'**
  String get appointmentSessionTitle;

  /// No description provided for @appointmentFreeSlotsTitle.
  ///
  /// In de, this message translates to:
  /// **'Freie Zeiten (nächste 14 Tage):'**
  String get appointmentFreeSlotsTitle;

  /// No description provided for @appointmentBook.
  ///
  /// In de, this message translates to:
  /// **'Buchen'**
  String get appointmentBook;

  /// No description provided for @appointmentOtherTime.
  ///
  /// In de, this message translates to:
  /// **'Andere Zeit wählen'**
  String get appointmentOtherTime;

  /// No description provided for @appointmentLocationLabel.
  ///
  /// In de, this message translates to:
  /// **'Ort (optional)'**
  String get appointmentLocationLabel;

  /// No description provided for @appointmentNotesLabel.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get appointmentNotesLabel;

  /// No description provided for @appointmentConfirmButton.
  ///
  /// In de, this message translates to:
  /// **'Termin buchen'**
  String get appointmentConfirmButton;

  /// No description provided for @appointmentLoadingSlots.
  ///
  /// In de, this message translates to:
  /// **'Freie Zeiten werden gesucht...'**
  String get appointmentLoadingSlots;

  /// No description provided for @appointmentNoFreeSlots.
  ///
  /// In de, this message translates to:
  /// **'Keine freien Zeitfenster gefunden.'**
  String get appointmentNoFreeSlots;

  /// No description provided for @appointmentNoCalendars.
  ///
  /// In de, this message translates to:
  /// **'Keine Kalender gefunden.'**
  String get appointmentNoCalendars;

  /// No description provided for @appointmentSelectCalendarTitle.
  ///
  /// In de, this message translates to:
  /// **'Arbeitskalender wählen'**
  String get appointmentSelectCalendarTitle;

  /// No description provided for @appointmentSelectCalendarSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle den Kalender für Reflex Journey-Termine.'**
  String get appointmentSelectCalendarSubtitle;

  /// No description provided for @appointmentStatusPlanned.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get appointmentStatusPlanned;

  /// No description provided for @appointmentStatusConfirmed.
  ///
  /// In de, this message translates to:
  /// **'Bestätigt'**
  String get appointmentStatusConfirmed;

  /// No description provided for @appointmentStatusCancelled.
  ///
  /// In de, this message translates to:
  /// **'Abgesagt'**
  String get appointmentStatusCancelled;

  /// No description provided for @appointmentStatusDone.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get appointmentStatusDone;

  /// No description provided for @appointmentOpenInCalendar.
  ///
  /// In de, this message translates to:
  /// **'Im Kalender öffnen'**
  String get appointmentOpenInCalendar;

  /// No description provided for @trainerRequestsTitle.
  ///
  /// In de, this message translates to:
  /// **'Anfragen'**
  String get trainerRequestsTitle;

  /// No description provided for @trainerRequestNoRequests.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Anfragen.'**
  String get trainerRequestNoRequests;

  /// No description provided for @trainerRequestAccept.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get trainerRequestAccept;

  /// No description provided for @trainerRequestDecline.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get trainerRequestDecline;

  /// No description provided for @trainerDiscoveryTitle.
  ///
  /// In de, this message translates to:
  /// **'Trainer finden'**
  String get trainerDiscoveryTitle;

  /// No description provided for @trainerDiscoveryRadiusLabel.
  ///
  /// In de, this message translates to:
  /// **'{radius} km'**
  String trainerDiscoveryRadiusLabel(int radius);

  /// No description provided for @trainerDiscoveryAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get trainerDiscoveryAll;

  /// No description provided for @trainerDiscoveryNearby.
  ///
  /// In de, this message translates to:
  /// **'Umkreis'**
  String get trainerDiscoveryNearby;

  /// No description provided for @trainerDiscoveryTabMap.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get trainerDiscoveryTabMap;

  /// No description provided for @trainerDiscoveryTabList.
  ///
  /// In de, this message translates to:
  /// **'Liste'**
  String get trainerDiscoveryTabList;

  /// No description provided for @trainerDiscoverySearchHint.
  ///
  /// In de, this message translates to:
  /// **'Trainer suchen'**
  String get trainerDiscoverySearchHint;

  /// No description provided for @trainerDiscoveryNoMatches.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer.'**
  String get trainerDiscoveryNoMatches;

  /// No description provided for @trainerDiscoveryLocationCtaText.
  ///
  /// In de, this message translates to:
  /// **'Finde Trainer in deiner Nähe. Dein Standort wird nur für diese Suche verwendet und nicht gespeichert.'**
  String get trainerDiscoveryLocationCtaText;

  /// No description provided for @trainerDiscoveryLocationCtaButton.
  ///
  /// In de, this message translates to:
  /// **'Standort verwenden'**
  String get trainerDiscoveryLocationCtaButton;

  /// No description provided for @trainerDiscoveryServiceDisabled.
  ///
  /// In de, this message translates to:
  /// **'Die Ortungsdienste deines Geräts sind ausgeschaltet. Schalte sie ein, um Trainer in deiner Nähe zu finden.'**
  String get trainerDiscoveryServiceDisabled;

  /// No description provided for @trainerDiscoveryOpenLocationSettings.
  ///
  /// In de, this message translates to:
  /// **'Ortungs-Einstellungen'**
  String get trainerDiscoveryOpenLocationSettings;

  /// No description provided for @trainerDiscoveryDenied.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort-Freigabe zeigen wir dir alle Trainer ohne Umkreisfilter.'**
  String get trainerDiscoveryDenied;

  /// No description provided for @trainerDiscoveryDeniedForever.
  ///
  /// In de, this message translates to:
  /// **'Der Standort-Zugriff ist für die App deaktiviert. Du kannst ihn in den Einstellungen wieder erlauben.'**
  String get trainerDiscoveryDeniedForever;

  /// No description provided for @trainerDiscoveryOpenAppSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get trainerDiscoveryOpenAppSettings;

  /// No description provided for @trainerDiscoveryLocationError.
  ///
  /// In de, this message translates to:
  /// **'Dein Standort konnte nicht ermittelt werden. Versuch es gleich noch einmal.'**
  String get trainerDiscoveryLocationError;

  /// No description provided for @trainerDiscoveryRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get trainerDiscoveryRetry;

  /// No description provided for @trainerDiscoveryEmptyGlobalTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Trainer freigeschaltet'**
  String get trainerDiscoveryEmptyGlobalTitle;

  /// No description provided for @trainerDiscoveryEmptyGlobalBody.
  ///
  /// In de, this message translates to:
  /// **'Wir prüfen und schalten gerade die ersten Trainer frei. Schau bald wieder vorbei — dein Training läuft auch ohne Trainer weiter.'**
  String get trainerDiscoveryEmptyGlobalBody;

  /// No description provided for @trainerDiscoveryEmptyGlobalCta.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Training'**
  String get trainerDiscoveryEmptyGlobalCta;

  /// No description provided for @trainerDiscoveryEmptyNearbyTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Trainer in deiner Nähe'**
  String get trainerDiscoveryEmptyNearbyTitle;

  /// No description provided for @trainerDiscoveryEmptyNearbyBody.
  ///
  /// In de, this message translates to:
  /// **'Vergrößere den Umkreis oder sieh dir alle Trainer an.'**
  String get trainerDiscoveryEmptyNearbyBody;

  /// No description provided for @trainerDiscoveryEmptyNearbyCta.
  ///
  /// In de, this message translates to:
  /// **'Alle Trainer anzeigen'**
  String get trainerDiscoveryEmptyNearbyCta;

  /// No description provided for @trainerDiscoveryLoadErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Trainer konnten nicht geladen werden'**
  String get trainerDiscoveryLoadErrorTitle;

  /// No description provided for @trainerDiscoveryLoadErrorBody.
  ///
  /// In de, this message translates to:
  /// **'Prüfe deine Internetverbindung und versuch es erneut.'**
  String get trainerDiscoveryLoadErrorBody;

  /// No description provided for @trainerDiscoveryOfflineBanner.
  ///
  /// In de, this message translates to:
  /// **'Du bist offline — die Karte braucht eine Internetverbindung.'**
  String get trainerDiscoveryOfflineBanner;

  /// No description provided for @trainerDiscoveryDistanceLabel.
  ///
  /// In de, this message translates to:
  /// **'{distance} km entfernt'**
  String trainerDiscoveryDistanceLabel(double distance);

  /// No description provided for @trainerDiscoveryRequestAlreadySent.
  ///
  /// In de, this message translates to:
  /// **'Anfrage wurde bereits gesendet.'**
  String get trainerDiscoveryRequestAlreadySent;

  /// No description provided for @trainerDiscoveryRequestAlreadyConnected.
  ///
  /// In de, this message translates to:
  /// **'Du bist bereits mit diesem Trainer verbunden.'**
  String get trainerDiscoveryRequestAlreadyConnected;

  /// No description provided for @trainerDiscoveryRequestSent.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gesendet.'**
  String get trainerDiscoveryRequestSent;

  /// No description provided for @trainerDiscoverySendRequest.
  ///
  /// In de, this message translates to:
  /// **'Anfrage senden'**
  String get trainerDiscoverySendRequest;

  /// No description provided for @trainerPublicProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Profil'**
  String get trainerPublicProfileTitle;

  /// No description provided for @trainerPublicProfileVerified.
  ///
  /// In de, this message translates to:
  /// **'Verifizierter Trainer'**
  String get trainerPublicProfileVerified;

  /// No description provided for @trainerSetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Profil'**
  String get trainerSetupTitle;

  /// No description provided for @trainerSetupDisplayNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get trainerSetupDisplayNameLabel;

  /// No description provided for @trainerSetupBioLabel.
  ///
  /// In de, this message translates to:
  /// **'Bio'**
  String get trainerSetupBioLabel;

  /// No description provided for @trainerSetupEmailLabel.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get trainerSetupEmailLabel;

  /// No description provided for @trainerSetupPhoneLabel.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get trainerSetupPhoneLabel;

  /// No description provided for @trainerSetupLocationTitle.
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get trainerSetupLocationTitle;

  /// No description provided for @trainerSetupLocationHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle deinen Trainer-Standort, damit Klienten dich in der Nähe finden.'**
  String get trainerSetupLocationHint;

  /// No description provided for @trainerSetupLocationMissing.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle einen Standort.'**
  String get trainerSetupLocationMissing;

  /// No description provided for @trainerSetupSubmit.
  ///
  /// In de, this message translates to:
  /// **'Zur Prüfung einreichen'**
  String get trainerSetupSubmit;

  /// No description provided for @trainerSetupPendingTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil wird geprüft'**
  String get trainerSetupPendingTitle;

  /// No description provided for @trainerSetupPendingBody.
  ///
  /// In de, this message translates to:
  /// **'Wir benachrichtigen dich, sobald dein Trainer-Profil freigegeben ist.'**
  String get trainerSetupPendingBody;

  /// No description provided for @adminTrainerReviewTab.
  ///
  /// In de, this message translates to:
  /// **'Trainer-Prüfung'**
  String get adminTrainerReviewTab;

  /// No description provided for @adminTrainerNoPending.
  ///
  /// In de, this message translates to:
  /// **'Keine Trainer-Profile zur Prüfung.'**
  String get adminTrainerNoPending;

  /// No description provided for @adminTrainerApproveSuccess.
  ///
  /// In de, this message translates to:
  /// **'Trainer freigegeben.'**
  String get adminTrainerApproveSuccess;

  /// No description provided for @adminTrainerSuspendSuccess.
  ///
  /// In de, this message translates to:
  /// **'Trainer gesperrt.'**
  String get adminTrainerSuspendSuccess;

  /// No description provided for @adminTrainerApprove.
  ///
  /// In de, this message translates to:
  /// **'Freigeben'**
  String get adminTrainerApprove;

  /// No description provided for @adminTrainerSuspend.
  ///
  /// In de, this message translates to:
  /// **'Sperren'**
  String get adminTrainerSuspend;

  /// Generic in-progress label while a save operation runs
  ///
  /// In de, this message translates to:
  /// **'Speichern...'**
  String get saving;

  /// Onboarding entry-points screen: headline
  ///
  /// In de, this message translates to:
  /// **'Viele Wege führen hierher'**
  String get entryPointsTitle;

  /// Onboarding entry-points screen: intro below headline
  ///
  /// In de, this message translates to:
  /// **'Reflexintegration ist für sehr unterschiedliche Menschen relevant. Schau, was für dich klingt.'**
  String get entryPointsSubtitle;

  /// Label above the multi-select chips
  ///
  /// In de, this message translates to:
  /// **'Was klingt für dich vertraut? (optional, Mehrfachauswahl)'**
  String get entryPointsChipQuestion;

  /// Note under the chips explaining the selection has no training effect
  ///
  /// In de, this message translates to:
  /// **'Deine Auswahl ändert nichts am Training — sie hilft uns zu verstehen, wer die App nutzt.'**
  String get entryPointsSelectionNote;

  /// Expand toggle on an area card (arrow appended in code)
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get entryPointsShowMore;

  /// Collapse toggle on an area card (arrow appended in code)
  ///
  /// In de, this message translates to:
  /// **'Weniger'**
  String get entryPointsShowLess;

  /// Area card: body/tension entry point — title
  ///
  /// In de, this message translates to:
  /// **'Körper & Therapie'**
  String get entryPointsBodyTitle;

  /// Area card: body — one-line teaser
  ///
  /// In de, this message translates to:
  /// **'Verspannungen, Fehlhaltungen, Empfehlung vom Therapeuten'**
  String get entryPointsBodyTeaser;

  /// Area card: body — expanded detail text
  ///
  /// In de, this message translates to:
  /// **'Aktive Reflexmuster können zu dauerhafter Muskelanspannung führen — unabhängig von äußeren Auslösern. Physiotherapeut·innen und Ergotherapeut·innen empfehlen Reflexintegration häufig ergänzend, wenn klassische Behandlung nicht vollständig greift.\n\nTypische Hinweise: chronische Rücken- oder Nackenverspannungen, Kieferspannung, Fehlhaltungen die immer wiederkehren.'**
  String get entryPointsBodyDetail;

  /// Area card: body — chip label
  ///
  /// In de, this message translates to:
  /// **'Körper'**
  String get entryPointsBodyChip;

  /// Area card: body — book citation (published edition titles per language)
  ///
  /// In de, this message translates to:
  /// **'Vgl. Goddard Blythe: (Über)leben mit Reflexen'**
  String get entryPointsBodySource;

  /// Area card: coordination/performance — title
  ///
  /// In de, this message translates to:
  /// **'Koordination & Leistung'**
  String get entryPointsCoordinationTitle;

  /// Area card: coordination — one-line teaser
  ///
  /// In de, this message translates to:
  /// **'Bewegungsqualität, Gleichgewicht, sportliche Koordination'**
  String get entryPointsCoordinationTeaser;

  /// Area card: coordination — expanded detail text
  ///
  /// In de, this message translates to:
  /// **'Unintegrierte Reflexe binden motorische Ressourcen — was sich in eingeschränkter Koordination, verlangsamten Reaktionen oder Gleichgewichtsproblemen zeigen kann. Sportler·innen nutzen Reflexintegration um koordinative Grenzen zu erweitern, die durch klassisches Training nicht erreichbar sind.\n\nTypische Hinweise: Bewegungsabläufe fühlen sich schwerer an als nötig, Asymmetrien, Gleichgewicht unter Druck.'**
  String get entryPointsCoordinationDetail;

  /// Area card: coordination — chip label
  ///
  /// In de, this message translates to:
  /// **'Koordination'**
  String get entryPointsCoordinationChip;

  /// Area card: coordination — book citation (published edition titles per language)
  ///
  /// In de, this message translates to:
  /// **'Vgl. Blomberg: Bewegungen die heilen'**
  String get entryPointsCoordinationSource;

  /// Area card: emotional regulation — title
  ///
  /// In de, this message translates to:
  /// **'Emotionale Regulation & Innenwelt'**
  String get entryPointsEmotionTitle;

  /// Area card: emotional regulation — one-line teaser
  ///
  /// In de, this message translates to:
  /// **'Stressreaktionen, Reizempfindlichkeit, Selbstwahrnehmung'**
  String get entryPointsEmotionTeaser;

  /// Area card: emotional regulation — expanded detail text
  ///
  /// In de, this message translates to:
  /// **'Manche Reflexmuster beeinflussen direkt wie das Nervensystem auf Reize reagiert — Stressempfindlichkeit, emotionale Reaktivität, Reizüberflutung. Rhythmische Bewegung kann helfen, das Nervensystem zu regulieren und Zugang zu inneren Zuständen zu finden.\n\nTypische Hinweise: schnelle emotionale Überflutung, Schwierigkeit zur Ruhe zu kommen, Körperspannung in Stress. Verläuft sehr individuell.'**
  String get entryPointsEmotionDetail;

  /// Area card: emotional regulation — chip label
  ///
  /// In de, this message translates to:
  /// **'Emotionale Regulation'**
  String get entryPointsEmotionChip;

  /// Area card: emotional regulation — book citation
  ///
  /// In de, this message translates to:
  /// **'Vgl. Blomberg: Bewegungen die heilen'**
  String get entryPointsEmotionSource;

  /// Area card: my child — title
  ///
  /// In de, this message translates to:
  /// **'Mein Kind: Schule & Entwicklung'**
  String get entryPointsChildTitle;

  /// Area card: my child — one-line teaser
  ///
  /// In de, this message translates to:
  /// **'Konzentration, Lernen, Schule — als Elternteil'**
  String get entryPointsChildTeaser;

  /// Area card: my child — expanded detail text
  ///
  /// In de, this message translates to:
  /// **'Frühkindliche Reflexmuster die nicht vollständig integriert wurden, können sich später in Schwierigkeiten beim Lesen, Schreiben oder Konzentrieren zeigen — oft ohne klare organische Ursache.\n\nTypische Hinweise: Kind kommt in der Schule nicht mit, kann sich schwer fokussieren, ist unruhig im Unterricht, Feinmotorik oder Lesen bereitet Mühe.'**
  String get entryPointsChildDetail;

  /// Area card: my child — chip label
  ///
  /// In de, this message translates to:
  /// **'Mein Kind'**
  String get entryPointsChildChip;

  /// Area card: my child — book citation
  ///
  /// In de, this message translates to:
  /// **'Vgl. Goddard Blythe: (Über)leben mit Reflexen'**
  String get entryPointsChildSource;

  /// Area card: curiosity — title
  ///
  /// In de, this message translates to:
  /// **'Neugierde & Entdeckung'**
  String get entryPointsCuriosityTitle;

  /// Area card: curiosity — one-line teaser
  ///
  /// In de, this message translates to:
  /// **'Kein konkretes Problem — einfach erkunden'**
  String get entryPointsCuriosityTeaser;

  /// Area card: curiosity — expanded detail text
  ///
  /// In de, this message translates to:
  /// **'Manche Menschen kommen ohne konkretes Symptom — sie haben von Reflexintegration gehört und sind neugierig was rhythmische Bewegung über mehrere Wochen verändert. Das ist ein vollständig gültiger Einstieg.\n\nDas Training wirkt unabhängig davon ob man ein \"Problem\" benennen kann oder nicht.'**
  String get entryPointsCuriosityDetail;

  /// Area card: curiosity — chip label
  ///
  /// In de, this message translates to:
  /// **'Einfach neugierig'**
  String get entryPointsCuriosityChip;

  /// Profile choice screen: headline
  ///
  /// In de, this message translates to:
  /// **'Für wen trainierst du?'**
  String get forWhomTitle;

  /// Profile choice screen: subline
  ///
  /// In de, this message translates to:
  /// **'Du kannst später jederzeit weitere Profile hinzufügen.'**
  String get forWhomSubtitle;

  /// Option card: train for myself — title
  ///
  /// In de, this message translates to:
  /// **'Für mich'**
  String get forWhomSelfTitle;

  /// Option card: train for myself — subtitle
  ///
  /// In de, this message translates to:
  /// **'Eigenes Erwachsenenprofil anlegen'**
  String get forWhomSelfSubtitle;

  /// Option card: train for my child — title
  ///
  /// In de, this message translates to:
  /// **'Für mein Kind'**
  String get forWhomChildTitle;

  /// Option card: train for my child — subtitle
  ///
  /// In de, this message translates to:
  /// **'Kinderprofil anlegen'**
  String get forWhomChildSubtitle;

  /// Text field label for the child's name
  ///
  /// In de, this message translates to:
  /// **'Name oder Spitzname'**
  String get forWhomChildNameLabel;

  /// Birth date field label (asterisk = required)
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum *'**
  String get forWhomBirthDateLabel;

  /// Helper text under the birth date field
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld – für die Altersauswertung benötigt'**
  String get forWhomBirthDateHelper;

  /// Date picker helpText for the birth date
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum auswählen'**
  String get forWhomBirthDatePickerHelp;

  /// Placeholder shown before a date was picked
  ///
  /// In de, this message translates to:
  /// **'Datum auswählen'**
  String get forWhomSelectDate;

  /// Submit button to create the child profile
  ///
  /// In de, this message translates to:
  /// **'Kinderprofil anlegen'**
  String get forWhomCreateChildProfile;

  /// Snackbar when name or birth date is missing
  ///
  /// In de, this message translates to:
  /// **'Bitte Name und Geburtsdatum angeben.'**
  String get forWhomMissingFields;

  /// Snackbar when profile creation fails
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Anlegen: {error}'**
  String forWhomCreateError(String error);

  /// Bottom sheet title after profile creation
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil für {name} anlegen?'**
  String forWhomReflexProfileSheetTitle(String name);

  /// Bottom sheet body explaining the questionnaire
  ///
  /// In de, this message translates to:
  /// **'Der Fragebogen dauert ca. 10–15 Minuten und hilft dabei, gezielt das passende Training zu empfehlen.'**
  String get forWhomReflexProfileSheetBody;

  /// Primary button: start the reflex profile questionnaire now
  ///
  /// In de, this message translates to:
  /// **'Jetzt Reflexprofil ausfüllen'**
  String get forWhomStartReflexProfile;

  /// Secondary button: skip questionnaire, go to training
  ///
  /// In de, this message translates to:
  /// **'Später — direkt zum Training'**
  String get forWhomLaterToTraining;

  /// Generic acknowledgement button
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get gotIt;

  /// Generic label for today
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'Moro'**
  String get packageShortMoro;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'Spinaler Galant'**
  String get packageShortSpinalGalant;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'TLR'**
  String get packageShortTlr;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'Babkin'**
  String get packageShortBabkin;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'Such-Saug'**
  String get packageShortSuchSaug;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'ATNR'**
  String get packageShortAtnr;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'STNR'**
  String get packageShortStnr;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'Babinski'**
  String get packageShortBabinski;

  /// Short package name shown on dashboard
  ///
  /// In de, this message translates to:
  /// **'Landau'**
  String get packageShortLandau;

  /// Bottom sheet suggesting routine mode: title
  ///
  /// In de, this message translates to:
  /// **'Du kennst die Übungen jetzt'**
  String get dashboardRoutineTipTitle;

  /// Bottom sheet suggesting routine mode: body
  ///
  /// In de, this message translates to:
  /// **'Probiere den Routine-Modus — er führt dich komplett hands-free per Audio durch das Training.'**
  String get dashboardRoutineTipBody;

  /// Log-session dialog title, also used as button label
  ///
  /// In de, this message translates to:
  /// **'Einheit eintragen'**
  String get dashboardLogUnitTitle;

  /// Log-session dialog body
  ///
  /// In de, this message translates to:
  /// **'Die heutige Einheit wird eingetragen. Danach kannst du direkt nachspüren und eine Beobachtung festhalten.'**
  String get dashboardLogUnitBody;

  /// Log-session dialog confirm button
  ///
  /// In de, this message translates to:
  /// **'Heute geübt eintragen'**
  String get dashboardLogUnitConfirm;

  /// Snackbar after logging today's session
  ///
  /// In de, this message translates to:
  /// **'Die heutige Einheit wurde eingetragen.'**
  String get dashboardLogUnitSuccess;

  /// Snackbar when logging fails
  ///
  /// In de, this message translates to:
  /// **'Die Einheit konnte nicht eingetragen werden: {error}'**
  String dashboardLogUnitError(String error);

  /// Local reminder notification title
  ///
  /// In de, this message translates to:
  /// **'Zeit für deine Einheit'**
  String get reminderSessionTitle;

  /// Local reminder notification body
  ///
  /// In de, this message translates to:
  /// **'Nimm dir Zeit für deine heutige Einheit.'**
  String get reminderSessionBody;

  /// Joint-training dialog title (multiple child profiles)
  ///
  /// In de, this message translates to:
  /// **'Zusammen trainieren?'**
  String get dashboardJointTrainingTitle;

  /// Joint-training dialog body
  ///
  /// In de, this message translates to:
  /// **'Diese Kinder haben dasselbe aktive Paket. Soll die Einheit nach dem Training auch für sie eingetragen werden?'**
  String get dashboardJointTrainingBody;

  /// Joint-training dialog: log only active profile
  ///
  /// In de, this message translates to:
  /// **'Nur dieses Profil'**
  String get dashboardJointTrainingOnlyThis;

  /// Joint-training dialog: log for selected profiles too
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam eintragen'**
  String get dashboardJointTrainingTogether;

  /// Headline when the warm-up round is the primary activity
  ///
  /// In de, this message translates to:
  /// **'Vorrunde'**
  String get dashboardVorrunde;

  /// Headline for the active package
  ///
  /// In de, this message translates to:
  /// **'{name} Paket'**
  String dashboardPackageHeadline(String name);

  /// Headline when no package is active
  ///
  /// In de, this message translates to:
  /// **'Noch kein aktives Paket'**
  String get dashboardNoActivePackage;

  /// Status chip when today's session is done
  ///
  /// In de, this message translates to:
  /// **'Heute abgeschlossen'**
  String get dashboardCompletedToday;

  /// Info text when warm-up phase is complete
  ///
  /// In de, this message translates to:
  /// **'Die vier Wochen Vorrunde sind erreicht. Du kannst jetzt Moro starten.'**
  String get dashboardVorrundeReady;

  /// Info text while warm-up phase is running
  ///
  /// In de, this message translates to:
  /// **'Die Vorrunde bereitet dich rhythmisch auf Moro vor. Du kannst sie fortsetzen oder jederzeit mit Moro starten.'**
  String get dashboardVorrundeIntro;

  /// Button: start Moro after warm-up complete
  ///
  /// In de, this message translates to:
  /// **'Jetzt Moro starten'**
  String get dashboardStartMoroNow;

  /// Button: continue the warm-up round
  ///
  /// In de, this message translates to:
  /// **'Vorrunde fortsetzen'**
  String get dashboardContinueVorrunde;

  /// Button: start Moro before warm-up is complete
  ///
  /// In de, this message translates to:
  /// **'Trotzdem Moro starten'**
  String get dashboardStartMoroAnyway;

  /// Chip: current day within package
  ///
  /// In de, this message translates to:
  /// **'Tag {current} von {total}'**
  String dashboardDayOfTotal(int current, int total);

  /// Chip: number of movements in today's session
  ///
  /// In de, this message translates to:
  /// **'{count} Bewegungen'**
  String dashboardMovementCount(int count);

  /// Chip: estimated session duration
  ///
  /// In de, this message translates to:
  /// **'ca. {minutes} Min.'**
  String dashboardEstimatedMinutes(int minutes);

  /// Note under the daily unit card
  ///
  /// In de, this message translates to:
  /// **'Die Bewegungen bleiben bewusst gleich. Regelmäßigkeit ist wichtiger als Intensität.'**
  String get dashboardRegularityNote;

  /// Primary button: start today's session
  ///
  /// In de, this message translates to:
  /// **'Einheit beginnen'**
  String get dashboardBeginUnit;

  /// Button: open observation sheet
  ///
  /// In de, this message translates to:
  /// **'Erfahrung dokumentieren'**
  String get dashboardDocumentExperience;

  /// Disabled button label when already logged today
  ///
  /// In de, this message translates to:
  /// **'Heute erledigt'**
  String get dashboardDoneToday;

  /// Button: start session in routine mode
  ///
  /// In de, this message translates to:
  /// **'Routine-Modus'**
  String get dashboardRoutineModeButton;

  /// Button: start warm-up round for calming
  ///
  /// In de, this message translates to:
  /// **'Vorrunde zur Beruhigung'**
  String get dashboardVorrundeCalm;

  /// Note when both package session and warm-up were done today
  ///
  /// In de, this message translates to:
  /// **'Heute Pakettraining und Vorrunde gemacht'**
  String get dashboardDidBothToday;

  /// Note when only the warm-up was done today
  ///
  /// In de, this message translates to:
  /// **'Heute Vorrunde gemacht'**
  String get dashboardDidVorrundeToday;

  /// Empty state: no profile yet
  ///
  /// In de, this message translates to:
  /// **'Leg dein erstes Reflexprofil an, um loszulegen.'**
  String get dashboardCreateFirstProfileHint;

  /// Button: create first profile
  ///
  /// In de, this message translates to:
  /// **'Erstes Profil anlegen'**
  String get dashboardCreateFirstProfile;

  /// Empty state: profile exists, no package
  ///
  /// In de, this message translates to:
  /// **'Du hast ein Profil angelegt. Starte jetzt ein Paket, um deinen Rhythmus aufzubauen.'**
  String get dashboardStartPackageHint;

  /// Button: start a package
  ///
  /// In de, this message translates to:
  /// **'Paket starten'**
  String get dashboardStartPackage;

  /// Daily impulse card (Monday)
  ///
  /// In de, this message translates to:
  /// **'Heute zählt nicht Perfektion, sondern Regelmäßigkeit.'**
  String get dashboardImpulseRegularity;

  /// Daily impulse card (Tuesday)
  ///
  /// In de, this message translates to:
  /// **'Beobachte, ohne zu bewerten.'**
  String get dashboardImpulseObserve;

  /// Daily impulse card (Wednesday)
  ///
  /// In de, this message translates to:
  /// **'Langsam und regelmäßig ist genug.'**
  String get dashboardImpulseSlowIsEnough;

  /// Daily impulse card (Thursday)
  ///
  /// In de, this message translates to:
  /// **'Hier ist dein nächster ruhiger Schritt.'**
  String get dashboardImpulseNextStep;

  /// Daily impulse card (Friday)
  ///
  /// In de, this message translates to:
  /// **'Nimm wahr, was heute da ist.'**
  String get dashboardImpulsePerceive;

  /// Daily impulse card (Saturday)
  ///
  /// In de, this message translates to:
  /// **'Ruhiger Rhythmus gibt dem Körper Orientierung.'**
  String get dashboardImpulseRhythm;

  /// Daily impulse card (Sunday)
  ///
  /// In de, this message translates to:
  /// **'Eine kurze Einheit ist besser als Druck.'**
  String get dashboardImpulseShortUnit;

  /// Weekly regularity strip: practiced days count
  ///
  /// In de, this message translates to:
  /// **'{count}/7 geübt'**
  String dashboardPracticedOfWeek(int count);

  /// Guidance notice: open appointment proposals
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Terminvorschlag offen} other{{count} Terminvorschläge offen}}'**
  String dashboardProposalsOpen(int count);

  /// Guidance notice: unread messages
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 neue Nachricht} other{{count} neue Nachrichten}}'**
  String dashboardNewMessages(int count);

  /// Appointment proposal banner title
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Neuer Terminvorschlag} other{{count} neue Terminvorschläge}}'**
  String dashboardProposalBannerTitle(int count);

  /// Appointment proposal banner body
  ///
  /// In de, this message translates to:
  /// **'{name} hat dir Termine vorgeschlagen.'**
  String dashboardProposalBannerBody(String name);

  /// Tooltip on the profile switcher
  ///
  /// In de, this message translates to:
  /// **'Profil wechseln'**
  String get dashboardSwitchProfile;

  /// Badge marking the adult self profile in the switcher
  ///
  /// In de, this message translates to:
  /// **'Ich'**
  String get profileBadgeSelf;

  /// Badge marking a child profile in the switcher
  ///
  /// In de, this message translates to:
  /// **'Kind'**
  String get profileBadgeChild;

  /// Menu item: add another profile
  ///
  /// In de, this message translates to:
  /// **'Profil hinzufügen'**
  String get dashboardAddProfile;

  /// Headline on the training session introduction screen
  ///
  /// In de, this message translates to:
  /// **'Willkommen zu deiner Einheit'**
  String get trainingIntroTitle;

  /// Description on the training session introduction screen
  ///
  /// In de, this message translates to:
  /// **'Heute gehst du 7 Bewegungen in ruhigem Rhythmus durch.'**
  String get trainingIntroDescription;

  /// Encouraging note on the training session introduction screen
  ///
  /// In de, this message translates to:
  /// **'Regelmäßigkeit ist wichtiger als Intensität.'**
  String get trainingIntroRegularity;

  /// Movement count in the training introduction info card
  ///
  /// In de, this message translates to:
  /// **'7 Bewegungen'**
  String get trainingIntroMovementCount;

  /// Estimated duration in the training introduction info card
  ///
  /// In de, this message translates to:
  /// **'ca. 15-20 Minuten'**
  String get trainingIntroDuration;

  /// Clothing recommendation in the training introduction info card
  ///
  /// In de, this message translates to:
  /// **'Bequeme Kleidung empfohlen'**
  String get trainingIntroClothing;

  /// Accessibility label for progress through training instruction steps
  ///
  /// In de, this message translates to:
  /// **'{total, plural, one{Fortschritt {current} von einem Schritt.} other{Fortschritt {current} von {total} Schritten.}}'**
  String trainingProgressSemantics(int current, int total);

  /// Tooltip for the button that exits an active training session
  ///
  /// In de, this message translates to:
  /// **'Training abbrechen'**
  String get trainingExitTooltip;

  /// Button from position instructions to movement instructions
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Bewegung'**
  String get trainingContinueToMovement;

  /// Heading above an exercise hint
  ///
  /// In de, this message translates to:
  /// **'Hinweis'**
  String get trainingHintTitle;

  /// Number of repetitions shown before an exercise
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{{count}× Wiederholungen} other{{count}× Wiederholungen}}'**
  String trainingRepetitionCount(int count);

  /// Button that starts the current exercise
  ///
  /// In de, this message translates to:
  /// **'Übung starten'**
  String get trainingStartExercise;

  /// Title of the confirmation dialog for exiting training
  ///
  /// In de, this message translates to:
  /// **'Training abbrechen?'**
  String get trainingAbortTitle;

  /// Body of the confirmation dialog for exiting training
  ///
  /// In de, this message translates to:
  /// **'Möchtest du das Training wirklich abbrechen? Dein Fortschritt geht verloren.'**
  String get trainingAbortBody;

  /// Button that dismisses the exit-training confirmation
  ///
  /// In de, this message translates to:
  /// **'Nein, weiter trainieren'**
  String get trainingAbortStay;

  /// Destructive button that confirms exiting training
  ///
  /// In de, this message translates to:
  /// **'Ja, abbrechen'**
  String get trainingAbortConfirm;

  /// Accessibility announcement after changing the training feedback mode
  ///
  /// In de, this message translates to:
  /// **'Feedbackmodus {label} aktiviert.'**
  String trainingFeedbackModeActivated(String label);

  /// Voice feedback mode label
  ///
  /// In de, this message translates to:
  /// **'Stimme'**
  String get trainingFeedbackVoice;

  /// Sound feedback mode label in the immersive player
  ///
  /// In de, this message translates to:
  /// **'Töne'**
  String get trainingFeedbackSounds;

  /// Haptic feedback mode label
  ///
  /// In de, this message translates to:
  /// **'Haptik'**
  String get trainingFeedbackHaptics;

  /// Silent feedback mode label
  ///
  /// In de, this message translates to:
  /// **'Stumm'**
  String get trainingFeedbackSilent;

  /// Accessibility announcement after changing exercise tempo
  ///
  /// In de, this message translates to:
  /// **'Tempo {seconds} Sekunden.'**
  String trainingTempoAnnouncement(String seconds);

  /// Accessibility summary of exercise duration and repetitions
  ///
  /// In de, this message translates to:
  /// **'Übungsdauer {seconds} Sekunden, {repetitions} Wiederholungen.'**
  String trainingExerciseDurationSemantics(int seconds, int repetitions);

  /// Compact repeat count beside the exercise duration
  ///
  /// In de, this message translates to:
  /// **'{count}× wiederholen'**
  String trainingRepeatCount(int count);

  /// Accessibility description of the exercise animation controls
  ///
  /// In de, this message translates to:
  /// **'Animationsbereich der Übung. Startet automatisch und kann pausiert oder neu gestartet werden.'**
  String get trainingAnimationSemantics;

  /// Hint below an automatically starting exercise animation
  ///
  /// In de, this message translates to:
  /// **'Startet automatisch. Bei Bedarf pausieren.'**
  String get trainingAutoplayHint;

  /// Current tempo and feedback summary
  ///
  /// In de, this message translates to:
  /// **'Tempo: {seconds}s  •  Feedback: {feedback}'**
  String trainingTempoFeedbackSummary(String seconds, String feedback);

  /// Warning shown when a very fast exercise tempo is selected
  ///
  /// In de, this message translates to:
  /// **'Sehr schnelles Tempo aktiv. Fokus auf saubere Ausführung.'**
  String get trainingFastTempoWarning;

  /// Note that an adaptively suggested tempo is active
  ///
  /// In de, this message translates to:
  /// **'Adaptiver Vorschlag aktiv'**
  String get trainingAdaptiveSuggestion;

  /// Accessibility label for slowing the exercise tempo
  ///
  /// In de, this message translates to:
  /// **'Tempo langsamer'**
  String get trainingTempoSlowerSemantics;

  /// Accessibility label for increasing the exercise tempo
  ///
  /// In de, this message translates to:
  /// **'Tempo schneller'**
  String get trainingTempoFasterSemantics;

  /// Accessibility value for a duration in seconds
  ///
  /// In de, this message translates to:
  /// **'{seconds} Sekunden'**
  String trainingSecondsValue(String seconds);

  /// Button that slows the exercise tempo
  ///
  /// In de, this message translates to:
  /// **'Langsamer'**
  String get trainingSlower;

  /// Button that increases the exercise tempo
  ///
  /// In de, this message translates to:
  /// **'Schneller'**
  String get trainingFaster;

  /// Accessibility label for cycling through feedback modes
  ///
  /// In de, this message translates to:
  /// **'Feedbackmodus wechseln'**
  String get trainingFeedbackChangeSemantics;

  /// Hint below the exercise tempo and feedback controls
  ///
  /// In de, this message translates to:
  /// **'Tempo und Feedback hier direkt mit einem Tap anpassen.'**
  String get trainingControlsHint;

  /// Button and accessibility label for completing the final exercise
  ///
  /// In de, this message translates to:
  /// **'Übung abschließen'**
  String get trainingCompleteExercise;

  /// Button and accessibility label for continuing to the next exercise
  ///
  /// In de, this message translates to:
  /// **'Weiter zur nächsten Übung'**
  String get trainingContinueNextExercise;

  /// Large uppercase cue shown when the user should switch sides
  ///
  /// In de, this message translates to:
  /// **'WECHSEL!'**
  String get trainingSwitchCueUpper;

  /// Large cue shown during the rest between repetitions
  ///
  /// In de, this message translates to:
  /// **'Pause...'**
  String get trainingPauseCue;

  /// Fallback uppercase hold cue
  ///
  /// In de, this message translates to:
  /// **'HALTEN'**
  String get trainingHoldCueUpper;

  /// Compact immersive exercise counter
  ///
  /// In de, this message translates to:
  /// **'Übung {current} · {total} gesamt'**
  String trainingExerciseOfTotalCompact(int current, int total);

  /// Button label for pausing an exercise
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get trainingPause;

  /// Rest phase label between repetitions
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get trainingRest;

  /// Button label for resuming a paused exercise
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get trainingResume;

  /// Button label for restarting an exercise animation
  ///
  /// In de, this message translates to:
  /// **'Neu starten'**
  String get trainingRestart;

  /// Seconds total below the current immersive beat
  ///
  /// In de, this message translates to:
  /// **'von {count} Sek.'**
  String trainingSecondsOf(int count);

  /// Beat total below the current immersive beat
  ///
  /// In de, this message translates to:
  /// **'von {count} Schlägen'**
  String trainingBeatsOf(int count);

  /// Current hold duration in the immersive exercise controls
  ///
  /// In de, this message translates to:
  /// **'{seconds}s Haltezeit'**
  String trainingHoldTime(int seconds);

  /// Current seconds per beat in the immersive exercise controls
  ///
  /// In de, this message translates to:
  /// **'{seconds}s / Schlag'**
  String trainingSecondsPerBeat(String seconds);

  /// Music control and music picker title
  ///
  /// In de, this message translates to:
  /// **'Musik'**
  String get trainingMusic;

  /// Active music control label
  ///
  /// In de, this message translates to:
  /// **'Musik an'**
  String get trainingMusicOn;

  /// Confirmation text when leaving an unsaved training session
  ///
  /// In de, this message translates to:
  /// **'Deine Einheit wird nicht gespeichert. Wirklich abbrechen?'**
  String get trainingSessionExitUnsaved;

  /// Daily reminder body rescheduled after completing a training session
  ///
  /// In de, this message translates to:
  /// **'Nimm dir Zeit für deine heutige Reflexintegrations-Einheit.'**
  String get trainingReminderSessionBody;

  /// Title of the confirmation dialog for skipping the reflex profile
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil überspringen?'**
  String get trainingProfileSkipTitle;

  /// Body of the confirmation dialog for skipping the reflex profile
  ///
  /// In de, this message translates to:
  /// **'Ohne persönliches Reflexprofil zur Einschätzung deines Standes fortfahren?'**
  String get trainingProfileSkipBody;

  /// Button that confirms continuing without a reflex profile
  ///
  /// In de, this message translates to:
  /// **'Fortfahren'**
  String get trainingContinue;

  /// Fallback name for the currently selected profile
  ///
  /// In de, this message translates to:
  /// **'Aktives Profil'**
  String get trainingActiveProfile;

  /// Title for the package start flow
  ///
  /// In de, this message translates to:
  /// **'Paket starten'**
  String get trainingStartPackage;

  /// Header identifying the profile for which a package is being started
  ///
  /// In de, this message translates to:
  /// **'Start für {name}'**
  String trainingStartForProfile(String name);

  /// Title of the warm-up decision before starting the Moro package
  ///
  /// In de, this message translates to:
  /// **'Vorrunde vor Moro'**
  String get trainingWarmupBeforeMoroTitle;

  /// Explanation of the optional warm-up round before Moro
  ///
  /// In de, this message translates to:
  /// **'Die Vorrunde dient dazu, den Körper auf die kommende Integration der Reflexe vorzubereiten. Die rhythmischen Bewegungen geben deinem Gehirn Signale, die es an den Zeitraum erinnern, in dem diese Reflexe sich ursprünglich selbst integrieren sollten.\n\nDiese Übungen kannst du später immer wieder zur Beruhigung und Entspannung nutzen.'**
  String get trainingWarmupBeforeMoroBody;

  /// Button that starts the warm-up round
  ///
  /// In de, this message translates to:
  /// **'Vorrunde starten'**
  String get trainingStartWarmup;

  /// Button that skips the warm-up and continues with the package
  ///
  /// In de, this message translates to:
  /// **'Direkt mit Paket fortfahren'**
  String get trainingContinueWithPackage;

  /// Title encouraging the user to complete a reflex profile first
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil nutzen'**
  String get trainingUseReflexProfile;

  /// Explanation that the selected profile has no completed reflex profile results
  ///
  /// In de, this message translates to:
  /// **'Für {name} liegt noch keine abgeschlossene Reflexprofil-Auswertung vor. Mit dem Profil wird die Dauerempfehlung genauer und nachvollziehbarer.'**
  String trainingReflexProfileMissingBody(String name);

  /// Button that starts the reflex profile questionnaire
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil starten'**
  String get trainingStartReflexProfile;

  /// Button that deliberately skips the reflex profile
  ///
  /// In de, this message translates to:
  /// **'Bewusst überspringen'**
  String get trainingSkipDeliberately;

  /// Title of the isometric partner exercise question
  ///
  /// In de, this message translates to:
  /// **'Isometrisches Partnertraining'**
  String get trainingIsometricPartnerTitle;

  /// Question about prior isometric partner exercises with a professional
  ///
  /// In de, this message translates to:
  /// **'Hat {name} bereits isometrisches Partnertraining mit einer Fachperson gemacht?'**
  String trainingIsometricPartnerQuestion(String name);

  /// Information shown while the recommended warm-up phase is still running
  ///
  /// In de, this message translates to:
  /// **'Die Vorrundenphase läuft noch. Du kannst Moro trotzdem starten; sie ist eine Empfehlung und kein Blocker.'**
  String get trainingWarmupStillRunning;

  /// Information shown when the warm-up phase is ready for Moro
  ///
  /// In de, this message translates to:
  /// **'Die Vorrunde ist bereit. Jetzt Moro starten.'**
  String get trainingWarmupReady;

  /// Information for a connected trainer when no isometric partner exercises were completed
  ///
  /// In de, this message translates to:
  /// **'Du bist mit {name} verbunden. Ohne isometrisches Partnertraining bleibt die Angabe trotzdem „Nein“.'**
  String trainingConnectedWithoutIsometric(String name);

  /// Information about a pending trainer connection request
  ///
  /// In de, this message translates to:
  /// **'Traineranfrage an {name} ist offen.'**
  String trainingTrainerRequestPending(String name);

  /// Button for opening trainer discovery
  ///
  /// In de, this message translates to:
  /// **'Trainer finden'**
  String get trainingFindTrainer;

  /// Information about using the warm-up while waiting for a trainer
  ///
  /// In de, this message translates to:
  /// **'Während du auf Rückmeldung oder einen Termin wartest, kannst du die Vorrunde nutzen. Sie bereitet rhythmisch vor und ist unabhängig vom isometrischen Partnertraining.'**
  String get trainingWarmupWhileWaitingBody;

  /// Button that starts the warm-up while waiting for a trainer
  ///
  /// In de, this message translates to:
  /// **'Vorrunde nutzen'**
  String get trainingUseWarmup;

  /// Eyebrow text on the warm-up interstitial
  ///
  /// In de, this message translates to:
  /// **'Bevor du startest'**
  String get trainingBeforeYouStart;

  /// Warm-up interstitial description
  ///
  /// In de, this message translates to:
  /// **'Die Vorrunde bereitet deinen Körper auf das Reflex-Training vor. Viele Nutzer erleben deutlich stärkere Ergebnisse.'**
  String get trainingWarmupInterstitialBody;

  /// Primary action on the warm-up interstitial
  ///
  /// In de, this message translates to:
  /// **'Vorrunde jetzt starten'**
  String get trainingStartWarmupNow;

  /// Badge marking the warm-up as recommended
  ///
  /// In de, this message translates to:
  /// **'empfohlen'**
  String get trainingRecommended;

  /// Duration and daily exercise summary for the warm-up round
  ///
  /// In de, this message translates to:
  /// **'4 Wochen · 6 Übungen täglich · ca. 8 Min.'**
  String get trainingWarmupSummary;

  /// Action that skips the warm-up and starts the first package
  ///
  /// In de, this message translates to:
  /// **'Direkt mit erstem Paket starten'**
  String get trainingStartFirstPackageDirectly;

  /// Note that the warm-up can be completed later
  ///
  /// In de, this message translates to:
  /// **'Vorrunde kann jederzeit nachgeholt werden.'**
  String get trainingWarmupAvailableLater;

  /// Celebratory heading after completing a training session
  ///
  /// In de, this message translates to:
  /// **'Herzlichen Glückwunsch!'**
  String get trainingCongratulations;

  /// Completion message after today's training session
  ///
  /// In de, this message translates to:
  /// **'Du hast dein heutiges Training\nerfolgreich abgeschlossen.'**
  String get trainingCompletedTodayBody;

  /// Heading above completed-session statistics
  ///
  /// In de, this message translates to:
  /// **'Heute abgeschlossen'**
  String get trainingCompletedToday;

  /// Standalone exercises statistic label
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get trainingExercisesLabel;

  /// Standalone minutes statistic label
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get trainingMinutesLabel;

  /// Encouraging message after completing a session
  ///
  /// In de, this message translates to:
  /// **'Weiter so! Regelmäßiges Training führt zum Erfolg.'**
  String get trainingKeepGoing;

  /// Exercise position in the current session
  ///
  /// In de, this message translates to:
  /// **'Übung {current} von {total}'**
  String trainingExerciseOfTotal(int current, int total);

  /// Step counter below the full progress bar
  ///
  /// In de, this message translates to:
  /// **'{current} von {total}'**
  String trainingProgressStepCounter(int current, int total);

  /// Completed percentage below the full progress bar
  ///
  /// In de, this message translates to:
  /// **'{percent}% geschafft! 🎉'**
  String trainingProgressPercentComplete(int percent);

  /// Encouragement shown at ninety percent progress
  ///
  /// In de, this message translates to:
  /// **'Fantastisch! Fast am Ziel! 🏆'**
  String get trainingProgressAlmostThere;

  /// Encouragement shown at seventy-five percent progress
  ///
  /// In de, this message translates to:
  /// **'Großartig! Du schaffst das! 💪'**
  String get trainingProgressGreat;

  /// Encouragement shown at halfway progress
  ///
  /// In de, this message translates to:
  /// **'Super! Schon über die Hälfte! 🎯'**
  String get trainingProgressHalfway;

  /// Encouragement shown at twenty-five percent progress
  ///
  /// In de, this message translates to:
  /// **'Gut gemacht! Weiter so! ⭐'**
  String get trainingProgressKeepGoing;

  /// Encouragement shown near the start of training
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s! Du packst das! 🚀'**
  String get trainingProgressLetsGo;

  /// Video label and action
  ///
  /// In de, this message translates to:
  /// **'Video'**
  String get trainingVideo;

  /// Abbreviated repetition count in the exercise transition
  ///
  /// In de, this message translates to:
  /// **'{count}× Wdh.'**
  String trainingRepetitionsAbbreviated(int count);

  /// Seconds per repetition in the exercise transition
  ///
  /// In de, this message translates to:
  /// **'{seconds} Sek / Rep'**
  String trainingSecondsPerRep(int seconds);

  /// Short position section heading in the exercise transition
  ///
  /// In de, this message translates to:
  /// **'Position'**
  String get trainingPositionLabel;

  /// Countdown before an exercise starts
  ///
  /// In de, this message translates to:
  /// **'Startet in {seconds} s'**
  String trainingStartsInSeconds(int seconds);

  /// Button that starts an exercise immediately
  ///
  /// In de, this message translates to:
  /// **'Jetzt starten'**
  String get trainingStartNow;

  /// Status while the spoken exercise announcement is playing
  ///
  /// In de, this message translates to:
  /// **'Ansage läuft...'**
  String get trainingAnnouncementPlaying;

  /// Fallback status while an exercise video is being prepared
  ///
  /// In de, this message translates to:
  /// **'Video wird vorbereitet...'**
  String get trainingVideoPreparing;

  /// Option that turns in-app music off
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get trainingMusicOff;

  /// In-app music volume control label
  ///
  /// In de, this message translates to:
  /// **'Lautstärke'**
  String get trainingMusicVolume;

  /// Display name of the Ambient Flow music track
  ///
  /// In de, this message translates to:
  /// **'Ambient Flow'**
  String get trainingMusicAmbientFlow;

  /// Display name of the Quiet Nature music track
  ///
  /// In de, this message translates to:
  /// **'Stille Natur'**
  String get trainingMusicQuietNature;

  /// Display name of the Deep Tones music track
  ///
  /// In de, this message translates to:
  /// **'Tiefe Töne'**
  String get trainingMusicDeepTones;

  /// Note explaining how in-app sounds mix with the user's own music
  ///
  /// In de, this message translates to:
  /// **'Eigene Musik (Spotify etc.) läuft weiter - Töne mischen sich darunter.'**
  String get trainingOwnMusicMixNote;

  /// Heading during the short break between exercises
  ///
  /// In de, this message translates to:
  /// **'Kurze Pause'**
  String get trainingShortBreak;

  /// Label introducing the next exercise during a break
  ///
  /// In de, this message translates to:
  /// **'Nächste Übung:'**
  String get trainingNextExercise;

  /// Subtitle describing tutorial training mode
  ///
  /// In de, this message translates to:
  /// **'Mit Anleitung'**
  String get trainingTutorialSubtitle;

  /// Subtitle describing routine training mode
  ///
  /// In de, this message translates to:
  /// **'Hands-free'**
  String get trainingRoutineSubtitle;

  /// Compact exercise duration and repetition summary
  ///
  /// In de, this message translates to:
  /// **'{seconds}s · {repetitions}x'**
  String trainingDurationAndRepetitions(int seconds, int repetitions);

  /// Number of exercises completed in the session outro
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{{count} Übungen} other{{count} Übungen}}'**
  String trainingCompletedExerciseCount(int count);

  /// Short seconds label inside the exercise timer
  ///
  /// In de, this message translates to:
  /// **'sec'**
  String get trainingSecondsAbbreviation;

  /// Spoken cue before the next repetition
  ///
  /// In de, this message translates to:
  /// **'Und wieder'**
  String get trainingAndAgain;

  /// Spoken cue to switch the arm cross midway through an exercise
  ///
  /// In de, this message translates to:
  /// **'Armkreuz wechseln'**
  String get trainingSwitchArmCross;

  /// Short spoken cue to switch sides
  ///
  /// In de, this message translates to:
  /// **'Wechsel'**
  String get trainingSwitchCue;

  /// Generic delete action
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// Full Moro package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Moro Reflex'**
  String get packagesNameMoro;

  /// Full spinal Galant package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Spinaler Galant + Amphibien'**
  String get packagesNameSpinalGalant;

  /// Full tonic labyrinthine reflex package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Tonischer Labirint Reflex (TLR)'**
  String get packagesNameTlr;

  /// Full Babkin package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Babkin + Plantar + Greifen'**
  String get packagesNameBabkin;

  /// Full rooting-sucking package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Such-Saug Reflex'**
  String get packagesNameSuchSaug;

  /// Full ATNR package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'ATNR'**
  String get packagesNameAtnr;

  /// Full STNR package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'STNR'**
  String get packagesNameStnr;

  /// Full Babinski package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Babinski Reflex'**
  String get packagesNameBabinski;

  /// Full Landau package name in the package sequence
  ///
  /// In de, this message translates to:
  /// **'Landau Reflex'**
  String get packagesNameLandau;

  /// Package subtitle shown when developer package switching is available
  ///
  /// In de, this message translates to:
  /// **'Dev-Auswahl verfügbar'**
  String get packagesDevSelectionAvailable;

  /// Package subtitle for an available package in the fixed sequence
  ///
  /// In de, this message translates to:
  /// **'Im festen Paketverlauf'**
  String get packagesFixedSequenceStatus;

  /// Journal action for recording mood and an entry
  ///
  /// In de, this message translates to:
  /// **'Stimmung + Eintrag'**
  String get journalMoodAndEntry;

  /// Journal action for recording an entry without mood
  ///
  /// In de, this message translates to:
  /// **'Nur Eintrag'**
  String get journalEntryOnly;

  /// Heading above the journal timeline
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get journalEntriesHeading;

  /// Journal entry total and entries recorded during the last week
  ///
  /// In de, this message translates to:
  /// **'{entryCount} gesamt · {entriesThisWeek, plural, one{{entriesThisWeek} Woche} other{{entriesThisWeek} Woche}}'**
  String journalEntrySummary(int entryCount, int entriesThisWeek);

  /// Empty journal timeline title
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge'**
  String get journalTimelineEmptyTitle;

  /// Empty journal timeline explanation
  ///
  /// In de, this message translates to:
  /// **'Deine Notizen erscheinen hier als kompakte Timeline. Der Verlauf bleibt im Dashboard.'**
  String get journalTimelineEmptyBody;

  /// Confirmation dialog title before deleting a journal entry
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get journalDeleteEntryTitle;

  /// Confirmation dialog body before deleting a journal entry
  ///
  /// In de, this message translates to:
  /// **'Dieser Eintrag wird dauerhaft entfernt.'**
  String get journalDeleteEntryBody;

  /// Type label shown on a journal note
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get journalEntryTypeNote;

  /// Action that collapses a long journal entry
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get journalShowLess;

  /// Action that expands a long journal entry
  ///
  /// In de, this message translates to:
  /// **'Mehr anzeigen'**
  String get journalShowMore;

  /// Progress history screen title
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get progressTitle;

  /// Error shown when the progress history cannot be loaded
  ///
  /// In de, this message translates to:
  /// **'Verlauf konnte nicht geladen werden.'**
  String get progressLoadFailed;

  /// Button for recording a new observation
  ///
  /// In de, this message translates to:
  /// **'Beobachtung eintragen'**
  String get progressAddObservation;

  /// Title above the wellbeing history chart
  ///
  /// In de, this message translates to:
  /// **'Befinden im Verlauf'**
  String get progressWellbeingTitle;

  /// Description below the wellbeing history title
  ///
  /// In de, this message translates to:
  /// **'Stimmung, Energie und Stress als ruhige Orientierung.'**
  String get progressWellbeingDescription;

  /// Default wellbeing chart series label when no profiles exist
  ///
  /// In de, this message translates to:
  /// **'Befinden'**
  String get progressWellbeingSeries;

  /// Empty state inside the wellbeing history chart
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge im gewählten Zeitraum.'**
  String get progressWellbeingEmpty;

  /// Thirty-day range filter label
  ///
  /// In de, this message translates to:
  /// **'30d'**
  String get progressRange30Days;

  /// Ninety-day range filter label
  ///
  /// In de, this message translates to:
  /// **'90d'**
  String get progressRange90Days;

  /// One-year range filter label
  ///
  /// In de, this message translates to:
  /// **'1J'**
  String get progressRangeOneYear;

  /// All-time range filter label
  ///
  /// In de, this message translates to:
  /// **'All'**
  String get progressRangeAll;

  /// Heading above reflex profile cards
  ///
  /// In de, this message translates to:
  /// **'Reflexprofile'**
  String get progressReflexProfilesTitle;

  /// Error shown when reflex profiles cannot be loaded
  ///
  /// In de, this message translates to:
  /// **'Reflexprofile konnten nicht geladen werden: {error}'**
  String progressReflexProfilesLoadFailed(String error);

  /// Explanation shown when no reflex profile exists
  ///
  /// In de, this message translates to:
  /// **'Noch kein Reflexprofil vorhanden. Es zeigt Hinweistärken, keine Diagnose.'**
  String get progressNoReflexProfileBody;

  /// Button that starts a reflex profile
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil starten'**
  String get progressStartReflexProfile;

  /// Action label on a reflex profile card with results
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get progressProfileDetails;

  /// Age shown on a reflex profile card
  ///
  /// In de, this message translates to:
  /// **'{years, plural, one{{years} Jahr} other{{years} Jahre}}'**
  String progressProfileAgeYears(int years);

  /// Placeholder inside a profile card without an assessment
  ///
  /// In de, this message translates to:
  /// **'Noch kein\nProfil'**
  String get progressNoAssessmentProfile;

  /// Card for adding another reflex profile
  ///
  /// In de, this message translates to:
  /// **'Weiteres\nProfil'**
  String get progressAddAnotherProfile;

  /// Heading above current package progress
  ///
  /// In de, this message translates to:
  /// **'Aktuelles Paket'**
  String get progressCurrentPackageTitle;

  /// Current package name and day progress
  ///
  /// In de, this message translates to:
  /// **'{packageName} · Tag {currentDay} von {totalDays}'**
  String progressCurrentPackageDay(
      String packageName, int currentDay, int totalDays);

  /// Message when the current package is last in the fixed sequence
  ///
  /// In de, this message translates to:
  /// **'Nach diesem Paket folgt kein weiteres festes Paket.'**
  String get progressNoNextFixedPackage;

  /// Name of the next package in the fixed sequence
  ///
  /// In de, this message translates to:
  /// **'Nächstes festes Paket: {packageName}'**
  String progressNextFixedPackage(String packageName);

  /// Button that opens the package sequence
  ///
  /// In de, this message translates to:
  /// **'Paketverlauf ansehen'**
  String get progressViewPackageSequence;

  /// Heading above recent observations
  ///
  /// In de, this message translates to:
  /// **'Beobachtungen'**
  String get progressObservationsTitle;

  /// Summary shown when there are no observations
  ///
  /// In de, this message translates to:
  /// **'Noch keine Beobachtungen festgehalten.'**
  String get progressObservationsEmptySummary;

  /// Number of observation entries in the current period
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{{count} Einträge im aktuellen Zeitraum} other{{count} Einträge im aktuellen Zeitraum}}'**
  String progressObservationCount(int count);

  /// Explanation shown when no observations have been recorded
  ///
  /// In de, this message translates to:
  /// **'Nach einer Einheit oder zwischendurch kannst du Beobachtungen zu Körper, Stimmung, Energie und Schlaf eintragen.'**
  String get progressObservationsEmptyBody;

  /// Golden Day screen title
  ///
  /// In de, this message translates to:
  /// **'Golden Day 🎉'**
  String get goldenDayTitle;

  /// Golden Day congratulatory heading
  ///
  /// In de, this message translates to:
  /// **'Glückwunsch!'**
  String get goldenDayCongratulations;

  /// Message shown after completing four weeks of training
  ///
  /// In de, this message translates to:
  /// **'Du hast das 4-Wochen-Training erfolgreich abgeschlossen!'**
  String get goldenDayCompletionMessage;

  /// Golden Day prompt asking how the user feels
  ///
  /// In de, this message translates to:
  /// **'Wie fühlst du dich?'**
  String get goldenDayFeelingPrompt;

  /// Golden Day action to continue with more training
  ///
  /// In de, this message translates to:
  /// **'Bereit für mehr!'**
  String get goldenDayReadyForMore;

  /// Golden Day action to keep practicing the current track
  ///
  /// In de, this message translates to:
  /// **'Noch etwas üben'**
  String get goldenDayPracticeMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
