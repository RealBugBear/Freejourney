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

  /// B1 framing under login brand toward discovering the Reflex Profile
  ///
  /// In de, this message translates to:
  /// **'Gleich entdeckst du dein persönliches Reflex-Profil — in deinem Tempo.'**
  String get loginDiscoverLead;

  /// Layout B consent screen short title
  ///
  /// In de, this message translates to:
  /// **'Kurz zustimmen'**
  String get consentShortTitle;

  /// B1 emotional lead on consent before the three document links
  ///
  /// In de, this message translates to:
  /// **'Dann entdeckst du dein persönliches Reflex-Profil — in deinem Tempo.'**
  String get consentDiscoverLead;

  /// Consent Layout B row that opens the safety/medical sheet
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get consentRowSafety;

  /// Consent Layout B row that opens the terms of use sheet
  ///
  /// In de, this message translates to:
  /// **'Nutzung'**
  String get consentRowTerms;

  /// Consent Layout B row that opens the privacy policy sheet
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get consentRowPrivacy;

  /// Trailing hint on consent document rows
  ///
  /// In de, this message translates to:
  /// **'Lesen'**
  String get consentReadLinkHint;

  /// Single consent checkbox label (Layout B)
  ///
  /// In de, this message translates to:
  /// **'Ich habe die Hinweise gelesen und stimme den Nutzungsbedingungen sowie der Datenschutzerklärung zu.'**
  String get consentCheckboxLabel;

  /// Primary consent CTA — B1 discover tone
  ///
  /// In de, this message translates to:
  /// **'Reflex-Profil entdecken'**
  String get consentDiscoverCta;

  /// Shorter B1 Kontaktname benefit line without community
  ///
  /// In de, this message translates to:
  /// **'Dein Kontaktname ist für Trainer sichtbar — danach entdeckst du dein Reflex-Profil.'**
  String get profileContactNameDiscoverBody;

  /// Shorter B1 Kontaktname benefit line with community
  ///
  /// In de, this message translates to:
  /// **'Dein Kontaktname ist für Trainer sichtbar und kann sich von deinem Community-Namen unterscheiden — danach entdeckst du dein Reflex-Profil.'**
  String get profileContactNameDiscoverBodyWithCommunity;

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
  /// **'Lernmodus'**
  String get tutorialMode;

  /// No description provided for @routineMode.
  ///
  /// In de, this message translates to:
  /// **'Routinemodus'**
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
  /// **'Zugangscode einlösen'**
  String get redeemAccessCodeTitle;

  /// No description provided for @redeemAccessCodeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Nutze einen Vorteilscode für Premium oder Studio.'**
  String get redeemAccessCodeSubtitle;

  /// No description provided for @redeemAccessCodeDialogBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Code kann Premium- oder Studio-Zugang direkt freischalten oder auf ein Store-Angebot verweisen.'**
  String get redeemAccessCodeDialogBody;

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
  /// **'Code eingelöst. Premium-Zugang ist aktiv. Dies ist kein Abo und es erfolgt keine automatische Belastung.'**
  String get redeemAccessCodeSuccess;

  /// No description provided for @redeemAccessCodeBenefitPremium.
  ///
  /// In de, this message translates to:
  /// **'Premium'**
  String get redeemAccessCodeBenefitPremium;

  /// No description provided for @redeemAccessCodeBenefitStudio.
  ///
  /// In de, this message translates to:
  /// **'Studio'**
  String get redeemAccessCodeBenefitStudio;

  /// No description provided for @redeemAccessCodeInternalGrantSuccess.
  ///
  /// In de, this message translates to:
  /// **'Code eingelöst. {benefit}-Zugang ist aktiv. Dies ist kein Abo und es erfolgt keine automatische Belastung.'**
  String redeemAccessCodeInternalGrantSuccess(String benefit);

  /// No description provided for @redeemAccessCodeInternalGrantUntil.
  ///
  /// In de, this message translates to:
  /// **'Code eingelöst. {benefit}-Zugang ist bis {date} aktiv. Dies ist kein Abo und es erfolgt keine automatische Belastung.'**
  String redeemAccessCodeInternalGrantUntil(String benefit, String date);

  /// No description provided for @redeemAccessCodeStoreOfferPending.
  ///
  /// In de, this message translates to:
  /// **'Store-Angebot erkannt. Der Zugang ist noch nicht aktiv. Der Angebotsablauf ist in einer späteren Version verfügbar.'**
  String get redeemAccessCodeStoreOfferPending;

  /// No description provided for @redeemAccessCodeUnknownBenefit.
  ///
  /// In de, this message translates to:
  /// **'Der Code wurde erkannt, aber der Zugang konnte nicht bestätigt werden. Es wurde kein Zugang aktiviert. Bitte kontaktiere den Support.'**
  String get redeemAccessCodeUnknownBenefit;

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

  /// No description provided for @redeemAccessCodeErrorCampaignInactive.
  ///
  /// In de, this message translates to:
  /// **'Diese Vorteilskampagne ist nicht mehr aktiv.'**
  String get redeemAccessCodeErrorCampaignInactive;

  /// No description provided for @redeemAccessCodeErrorRoleNotEligible.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code ist für deine Kontorolle nicht verfügbar.'**
  String get redeemAccessCodeErrorRoleNotEligible;

  /// No description provided for @redeemAccessCodeErrorLimitReached.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code hat sein Einlöselimit erreicht.'**
  String get redeemAccessCodeErrorLimitReached;

  /// No description provided for @redeemAccessCodeErrorOfferUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Code ist auf deinem Gerät kein Store-Angebot verfügbar.'**
  String get redeemAccessCodeErrorOfferUnavailable;

  /// No description provided for @redeemAccessCodeErrorInvalidPlatform.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code kann auf diesem Gerät nicht eingelöst werden.'**
  String get redeemAccessCodeErrorInvalidPlatform;

  /// No description provided for @redeemAccessCodeErrorServiceUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Code-Einlösung ist vorübergehend nicht verfügbar. Bitte versuche es später erneut.'**
  String get redeemAccessCodeErrorServiceUnavailable;

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
  /// **'Deine aktuelle Stelle wird auf diesem Gerät gesichert. Möchtest du die Einheit verlassen?'**
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

  /// Honest note that external music control and ducking are not released
  ///
  /// In de, this message translates to:
  /// **'Eigene Musik wird in dieser Version nicht von der App gesteuert oder abgesenkt.'**
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
  /// **'Automatischer Ablauf'**
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

  /// Progress strip card for non-adult_v3 adult assessments (§10.3a)
  ///
  /// In de, this message translates to:
  /// **'Erstellt mit älterer Methode. Tippen, um den Hinweis zu öffnen.'**
  String get progressAdultLegacyCardBody;

  /// Adult progress card when parsed scores have no ranked patterns
  ///
  /// In de, this message translates to:
  /// **'Noch keine Antwortmuster'**
  String get progressAdultNoPatternsYet;

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

  /// Generic anonymous display name and option
  ///
  /// In de, this message translates to:
  /// **'Anonym'**
  String get anonymous;

  /// Generic edit action
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// Generic submit action
  ///
  /// In de, this message translates to:
  /// **'Einreichen'**
  String get submit;

  /// Generic action declining an optional prompt
  ///
  /// In de, this message translates to:
  /// **'Nein danke'**
  String get noThanks;

  /// Generic continue action
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueAction;

  /// Guidance screen title
  ///
  /// In de, this message translates to:
  /// **'Begleitung'**
  String get accompanimentTitle;

  /// Instructions for connecting to a trainer by invite link or code
  ///
  /// In de, this message translates to:
  /// **'Füge den Einladungslink oder den 6-stelligen Code ein, den du von deinem Trainer erhalten hast.'**
  String get accompanimentConnectBody;

  /// Input label for a trainer invite link or code
  ///
  /// In de, this message translates to:
  /// **'Einladungslink oder Code'**
  String get accompanimentInviteLinkOrCodeLabel;

  /// Example trainer invite code or link
  ///
  /// In de, this message translates to:
  /// **'A1B2C3 oder https://...'**
  String get accompanimentInviteLinkOrCodeHint;

  /// Validation error for an invalid trainer invite
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen 6-stelligen Code oder Einladungslink ein.'**
  String get accompanimentConnectInvalidInvite;

  /// Error shown when a trainer connection fails
  ///
  /// In de, this message translates to:
  /// **'Verbindung konnte nicht hergestellt werden: {error}'**
  String accompanimentConnectFailed(String error);

  /// Action connecting to a trainer
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
  String get accompanimentConnectAction;

  /// Confirmation after connecting to a trainer
  ///
  /// In de, this message translates to:
  /// **'Trainer wurde verbunden.'**
  String get accompanimentConnectedSuccess;

  /// Title and section heading for switching trainers
  ///
  /// In de, this message translates to:
  /// **'Begleitung wechseln'**
  String get accompanimentSwitchTitle;

  /// Dialog explanation before switching trainers
  ///
  /// In de, this message translates to:
  /// **'Nach dem Wechsel erscheint dein Verlauf beim neuen Trainer. Dein bisheriger Trainer sieht dich danach nicht mehr in seiner Klientenübersicht.'**
  String get accompanimentSwitchBody;

  /// Validation error while switching trainers
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Einladungslink oder Code ein.'**
  String get accompanimentSwitchInvalidInvite;

  /// Action confirming a trainer switch
  ///
  /// In de, this message translates to:
  /// **'Wechsel bestätigen'**
  String get accompanimentSwitchConfirm;

  /// Confirmation after switching trainers
  ///
  /// In de, this message translates to:
  /// **'Begleitung wurde aktualisiert.'**
  String get accompanimentSwitchUpdated;

  /// Error shown when switching trainers fails
  ///
  /// In de, this message translates to:
  /// **'Wechsel konnte nicht gespeichert werden: {error}'**
  String accompanimentSwitchFailed(String error);

  /// Action to end the current trainer accompaniment
  ///
  /// In de, this message translates to:
  /// **'Begleitung beenden'**
  String get accompanimentEndAction;

  /// Confirmation dialog title before ending accompaniment
  ///
  /// In de, this message translates to:
  /// **'Begleitung wirklich beenden?'**
  String get accompanimentEndDialogTitle;

  /// Consequence: reflex profile access ends
  ///
  /// In de, this message translates to:
  /// **'Dein Trainer kann deine Reflexprofile nicht mehr sehen.'**
  String get accompanimentEndConsequenceProfiles;

  /// Consequence: messaging ends, history kept
  ///
  /// In de, this message translates to:
  /// **'Ihr könnt euch keine Nachrichten mehr schreiben. Euer bisheriger Verlauf bleibt erhalten.'**
  String get accompanimentEndConsequenceChat;

  /// Consequence: open appointments are cancelled
  ///
  /// In de, this message translates to:
  /// **'Alle offenen Termine werden abgesagt.'**
  String get accompanimentEndConsequenceAppointments;

  /// Notice that the trainer will be informed (no delivery claim)
  ///
  /// In de, this message translates to:
  /// **'Dein Trainer wird darüber informiert.'**
  String get accompanimentEndTrainerNotice;

  /// Hint that reconnecting later is possible
  ///
  /// In de, this message translates to:
  /// **'Du kannst dich später mit einem neuen Code wieder verbinden.'**
  String get accompanimentEndReconnectHint;

  /// Destructive confirm button in the end-accompaniment dialog
  ///
  /// In de, this message translates to:
  /// **'Begleitung beenden'**
  String get accompanimentEndConfirm;

  /// Snackbar after successfully ending accompaniment
  ///
  /// In de, this message translates to:
  /// **'Begleitung beendet.'**
  String get accompanimentEnded;

  /// Error snackbar when ending accompaniment fails
  ///
  /// In de, this message translates to:
  /// **'Begleitung konnte nicht beendet werden: {error}'**
  String accompanimentEndFailed(String error);

  /// Composer replacement when a direct chat is no longer writable
  ///
  /// In de, this message translates to:
  /// **'Diese Begleitung ist beendet. Du kannst den Verlauf weiter lesen, aber keine Nachrichten mehr senden.'**
  String get chatWriteLockedNoRelationship;

  /// Confirmation title before withdrawing a trainer request
  ///
  /// In de, this message translates to:
  /// **'Anfrage zurückziehen?'**
  String get accompanimentWithdrawTitle;

  /// Confirmation body before withdrawing a trainer request
  ///
  /// In de, this message translates to:
  /// **'Die Anfrage an {name} wird zurückgezogen. Du kannst später erneut eine passende Begleitung anfragen.'**
  String accompanimentWithdrawBody(String name);

  /// Action withdrawing a pending trainer request
  ///
  /// In de, this message translates to:
  /// **'Anfrage zurückziehen'**
  String get accompanimentWithdrawAction;

  /// Confirmation after withdrawing a trainer request
  ///
  /// In de, this message translates to:
  /// **'Anfrage wurde zurückgezogen.'**
  String get accompanimentWithdrawSuccess;

  /// Error shown when a trainer request cannot be withdrawn
  ///
  /// In de, this message translates to:
  /// **'Anfrage konnte nicht zurückgezogen werden: {error}'**
  String accompanimentWithdrawFailed(String error);

  /// Title for the shared experiences action card
  ///
  /// In de, this message translates to:
  /// **'Geteilte Erfahrungen'**
  String get accompanimentSharedExperiencesTitle;

  /// Description of shared package observations
  ///
  /// In de, this message translates to:
  /// **'Moderierte Beobachtungen aus laufenden Paketen ansehen.'**
  String get accompanimentSharedExperiencesBody;

  /// Action opening shared experiences
  ///
  /// In de, this message translates to:
  /// **'Erfahrungen öffnen'**
  String get accompanimentSharedExperiencesAction;

  /// Heading explaining professional trainer guidance
  ///
  /// In de, this message translates to:
  /// **'Professionelle Begleitung'**
  String get accompanimentProfessionalTitle;

  /// Explanation of partner exercises and trainer guidance
  ///
  /// In de, this message translates to:
  /// **'Manche Übungen werden mit einer zweiten Person durchgeführt. Dabei geht es nicht um Krafttraining, sondern um klares Spüren von Richtung, Bewegung und Widerstand. Ein geschulter Trainer kann dich dabei sicher anleiten.'**
  String get accompanimentProfessionalBody;

  /// Note that trainer guidance is especially relevant early in a package
  ///
  /// In de, this message translates to:
  /// **'Besonders relevant am Anfang eines Pakets.'**
  String get accompanimentPackageStartNote;

  /// Note that daily rhythmic sessions remain self-guided
  ///
  /// In de, this message translates to:
  /// **'Deine täglichen rhythmischen Einheiten bleiben selbstgeführt.'**
  String get accompanimentDailySessionsNote;

  /// Heading when no trainer guidance is connected
  ///
  /// In de, this message translates to:
  /// **'Noch keine Begleitung verbunden'**
  String get accompanimentNoTrainerTitle;

  /// Explanation when no trainer is connected
  ///
  /// In de, this message translates to:
  /// **'Du kannst dein Paket weiter selbstgeführt üben und bei Bedarf eine professionelle Begleitung für Partnerübungen oder Gespräche finden.'**
  String get accompanimentNoTrainerBody;

  /// Action entering a trainer invite link
  ///
  /// In de, this message translates to:
  /// **'Einladungslink eingeben'**
  String get accompanimentEnterInviteLink;

  /// Action continuing without a trainer
  ///
  /// In de, this message translates to:
  /// **'Ohne Trainer fortfahren'**
  String get accompanimentContinueWithoutTrainer;

  /// Heading for sharing reflex profiles with a connected trainer
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil-Freigabe'**
  String get accompanimentProfileSharingTitle;

  /// Explanation of reflex profile sharing with a connected trainer
  ///
  /// In de, this message translates to:
  /// **'Du kannst festlegen, ob der verbundene Trainer die abgeschlossenen Reflexprofile sehen darf. Das gilt nur, solange diese Begleitung aktiv ist.'**
  String get accompanimentProfileSharingBody;

  /// Error shown when reflex profile sharing cannot be loaded
  ///
  /// In de, this message translates to:
  /// **'Freigabe konnte nicht geladen werden: {error}'**
  String accompanimentProfileSharingLoadFailed(String error);

  /// Status when a reflex profile is shared with the connected trainer
  ///
  /// In de, this message translates to:
  /// **'Der verbundene Trainer darf dieses Reflexprofil sehen.'**
  String get accompanimentProfileShared;

  /// Status when a reflex profile is not shared with the connected trainer
  ///
  /// In de, this message translates to:
  /// **'Nicht für den verbundenen Trainer freigegeben.'**
  String get accompanimentProfileNotShared;

  /// Error shown when reflex profile sharing cannot be saved
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil-Freigabe konnte nicht gespeichert werden: {error}'**
  String accompanimentProfileSharingSaveFailed(String error);

  /// Number of open appointment proposals
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 offener Terminvorschlag} other{{count} offene Terminvorschläge}}'**
  String accompanimentProposalCount(int count);

  /// Status while appointment proposals load
  ///
  /// In de, this message translates to:
  /// **'Terminvorschläge werden geladen ...'**
  String get accompanimentProposalsLoading;

  /// Prompt to choose an appointment proposal
  ///
  /// In de, this message translates to:
  /// **'Wähle einen passenden Termin direkt in deiner Begleitung aus.'**
  String get accompanimentProposalsBody;

  /// Action opening appointment proposals
  ///
  /// In de, this message translates to:
  /// **'Vorschläge ansehen'**
  String get accompanimentViewProposals;

  /// Heading for a pending trainer request
  ///
  /// In de, this message translates to:
  /// **'Anfrage offen bei {name}'**
  String accompanimentPendingRequestTitle(String name);

  /// Number of additional pending trainer requests
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{{count} weitere Anfrage offen} other{{count} weitere Anfragen offen}}'**
  String accompanimentExtraPendingRequests(int count);

  /// Notice shown while a trainer request is pending
  ///
  /// In de, this message translates to:
  /// **'Du wirst informiert, sobald die Anfrage angenommen wurde.'**
  String get accompanimentPendingRequestAcceptedNotice;

  /// Action finding additional trainers
  ///
  /// In de, this message translates to:
  /// **'Mehr Trainer'**
  String get accompanimentMoreTrainers;

  /// Short action label for entering an invite link
  ///
  /// In de, this message translates to:
  /// **'Einladungslink'**
  String get accompanimentInviteLinkShort;

  /// Status label for an active trainer connection
  ///
  /// In de, this message translates to:
  /// **'Aktive Begleitung'**
  String get accompanimentActiveGuidance;

  /// Action messaging the connected trainer
  ///
  /// In de, this message translates to:
  /// **'Nachricht'**
  String get accompanimentMessage;

  /// Action opening appointment proposals
  ///
  /// In de, this message translates to:
  /// **'Terminvorschläge'**
  String get accompanimentAppointmentProposals;

  /// Heading above upcoming appointments
  ///
  /// In de, this message translates to:
  /// **'Nächste Termine'**
  String get accompanimentNextAppointments;

  /// Empty state when no upcoming appointments are scheduled
  ///
  /// In de, this message translates to:
  /// **'Noch keine geplanten Termine.'**
  String get accompanimentNoAppointments;

  /// Explanation of trainer access after switching guidance
  ///
  /// In de, this message translates to:
  /// **'Beim Wechsel sieht dein neuer Trainer deinen Verlauf. Dein bisheriger Trainer verliert den Zugriff auf deine Klientenübersicht.'**
  String get accompanimentSwitchAccessBody;

  /// Action entering a trainer invite code
  ///
  /// In de, this message translates to:
  /// **'Code eingeben'**
  String get accompanimentEnterCode;

  /// Profile associated with an appointment
  ///
  /// In de, this message translates to:
  /// **'für {profileName}'**
  String accompanimentAppointmentForProfile(String profileName);

  /// Action and heading for writing a standalone mood note
  ///
  /// In de, this message translates to:
  /// **'Notiz schreiben'**
  String get moodWriteNote;

  /// Error shown when a mood entry has no active program
  ///
  /// In de, this message translates to:
  /// **'Kein aktives Programm gefunden.'**
  String get moodNoActiveProgram;

  /// Confirmation title for sharing a mood observation
  ///
  /// In de, this message translates to:
  /// **'Geteilte Erfahrung einreichen?'**
  String get moodCommunityShareTitle;

  /// Confirmation body for sharing a mood observation
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diese Beobachtung als geteilte Erfahrung einreichen?'**
  String get moodCommunityShareBody;

  /// Heading for editing a mood entry
  ///
  /// In de, this message translates to:
  /// **'Eintrag bearbeiten'**
  String get moodEditEntry;

  /// Heading for recording a mood entry
  ///
  /// In de, this message translates to:
  /// **'Stimmung eintragen'**
  String get moodLogMood;

  /// Label above the subject profile picker in a mood entry
  ///
  /// In de, this message translates to:
  /// **'Für wen?'**
  String get moodForWhom;

  /// General option in the mood subject profile picker
  ///
  /// In de, this message translates to:
  /// **'Allgemein'**
  String get moodGeneral;

  /// Hint explaining that mood metrics are optional
  ///
  /// In de, this message translates to:
  /// **'Tippe auf einen Wert, um ihn auszuwählen, oder lass ihn frei.'**
  String get moodMetricSelectionHint;

  /// Description in the standalone note sheet
  ///
  /// In de, this message translates to:
  /// **'Unabhängig von deiner Stimmung — schreib was dir gerade durch den Kopf geht.'**
  String get moodNoteBody;

  /// Placeholder for a standalone mood note
  ///
  /// In de, this message translates to:
  /// **'Deine Gedanken...'**
  String get moodNoteHint;

  /// Error shown when a post-training experience cannot be saved
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern: {error}'**
  String moodExperienceSaveFailed(String error);

  /// Stored note line containing selected session impressions
  ///
  /// In de, this message translates to:
  /// **'Einheit: {values}'**
  String moodExperienceSessionNote(String values);

  /// Stored note line containing observations since the previous session
  ///
  /// In de, this message translates to:
  /// **'Seit letzter Einheit: {values}'**
  String moodExperienceSinceLastSessionNote(String values);

  /// Post-training experience sheet title
  ///
  /// In de, this message translates to:
  /// **'Wie hat sich die Einheit angefühlt?'**
  String get moodExperienceTitle;

  /// Post-training experience sheet description
  ///
  /// In de, this message translates to:
  /// **'Was hast du während der Einheit oder seit deiner letzten Einheit wahrgenommen?'**
  String get moodExperienceDescription;

  /// Calm session impression chip
  ///
  /// In de, this message translates to:
  /// **'ruhig'**
  String get moodExperienceImpressionCalm;

  /// Pleasant session impression chip
  ///
  /// In de, this message translates to:
  /// **'angenehm'**
  String get moodExperienceImpressionPleasant;

  /// Tired session impression chip
  ///
  /// In de, this message translates to:
  /// **'müde'**
  String get moodExperienceImpressionTired;

  /// Restless session impression chip
  ///
  /// In de, this message translates to:
  /// **'unruhig'**
  String get moodExperienceImpressionRestless;

  /// Emotional session impression chip
  ///
  /// In de, this message translates to:
  /// **'emotional'**
  String get moodExperienceImpressionEmotional;

  /// Physically uncomfortable session impression chip
  ///
  /// In de, this message translates to:
  /// **'körperlich unangenehm'**
  String get moodExperienceImpressionPhysicallyUncomfortable;

  /// Hard-to-assess session impression chip
  ///
  /// In de, this message translates to:
  /// **'schwer einzuschätzen'**
  String get moodExperienceImpressionUnsure;

  /// Question about observations since the previous session
  ///
  /// In de, this message translates to:
  /// **'Was ist dir seit der letzten Einheit aufgefallen?'**
  String get moodExperienceSinceLastTitle;

  /// More calm observation chip
  ///
  /// In de, this message translates to:
  /// **'mehr Ruhe'**
  String get moodExperienceSinceMoreCalm;

  /// More energy observation chip
  ///
  /// In de, this message translates to:
  /// **'mehr Energie'**
  String get moodExperienceSinceMoreEnergy;

  /// Less energy observation chip
  ///
  /// In de, this message translates to:
  /// **'weniger Energie'**
  String get moodExperienceSinceLessEnergy;

  /// Mood fluctuated observation chip
  ///
  /// In de, this message translates to:
  /// **'Stimmung schwankte'**
  String get moodExperienceSinceMoodChanged;

  /// More emotional observation chip
  ///
  /// In de, this message translates to:
  /// **'emotionaler als sonst'**
  String get moodExperienceSinceMoreEmotional;

  /// More sensitive observation chip
  ///
  /// In de, this message translates to:
  /// **'reizempfindlicher'**
  String get moodExperienceSinceMoreSensitive;

  /// Better sleep observation chip
  ///
  /// In de, this message translates to:
  /// **'besserer Schlaf'**
  String get moodExperienceSinceBetterSleep;

  /// Restless sleep observation chip
  ///
  /// In de, this message translates to:
  /// **'unruhiger Schlaf'**
  String get moodExperienceSinceRestlessSleep;

  /// Physical tension observation chip
  ///
  /// In de, this message translates to:
  /// **'körperliche Spannung'**
  String get moodExperienceSinceBodyTension;

  /// Nothing notable observation chip
  ///
  /// In de, this message translates to:
  /// **'keine Besonderheit'**
  String get moodExperienceSinceNothingNotable;

  /// Placeholder for a custom post-training observation
  ///
  /// In de, this message translates to:
  /// **'Eigene Beobachtung... (optional)'**
  String get moodExperienceOwnObservationHint;

  /// Option to submit a post-training observation as a shared experience
  ///
  /// In de, this message translates to:
  /// **'Als geteilte Erfahrung einreichen'**
  String get moodExperienceShare;

  /// Option to share a post-training experience anonymously
  ///
  /// In de, this message translates to:
  /// **'Anonym einreichen'**
  String get moodExperienceShareAnonymously;

  /// Description of the system theme option
  ///
  /// In de, this message translates to:
  /// **'Folgt den System-Einstellungen'**
  String get themeSystemDescription;

  /// Description of the light theme option
  ///
  /// In de, this message translates to:
  /// **'Immer helles Design'**
  String get themeLightDescription;

  /// Description of the dark theme option
  ///
  /// In de, this message translates to:
  /// **'Immer dunkles Design'**
  String get themeDarkDescription;

  /// Confirmation after changing the app theme
  ///
  /// In de, this message translates to:
  /// **'Theme geändert zu: {title}'**
  String themeChanged(String title);

  /// Profile screen section for training subject profiles
  ///
  /// In de, this message translates to:
  /// **'Trainingsprofile'**
  String get profileTrainingProfilesSection;

  /// Profile screen journal navigation item
  ///
  /// In de, this message translates to:
  /// **'Journal'**
  String get profileJournalItemTitle;

  /// Profile screen journal navigation subtitle
  ///
  /// In de, this message translates to:
  /// **'Deine Einträge und Reflexionen'**
  String get profileJournalSubtitle;

  /// Profile screen trainer section heading
  ///
  /// In de, this message translates to:
  /// **'Trainer'**
  String get profileTrainerSection;

  /// Profile screen action for managing guidance
  ///
  /// In de, this message translates to:
  /// **'Begleitung verwalten'**
  String get profileManageGuidance;

  /// Profile screen subtitle naming the connected trainer
  ///
  /// In de, this message translates to:
  /// **'Aktuell verbunden mit {name}'**
  String profileConnectedWith(String name);

  /// Profile screen guidance navigation subtitle without a connected trainer
  ///
  /// In de, this message translates to:
  /// **'Trainer finden, Anfragen und Termine verwalten'**
  String get profileFindManageTrainer;

  /// Profile screen professional workspace section
  ///
  /// In de, this message translates to:
  /// **'Arbeitsbereich'**
  String get profileWorkspaceSection;

  /// Profile screen admin panel navigation item
  ///
  /// In de, this message translates to:
  /// **'Admin Panel'**
  String get profileAdminPanel;

  /// Profile screen messages navigation item
  ///
  /// In de, this message translates to:
  /// **'Nachrichten'**
  String get profileMessages;

  /// Profile screen admin messages subtitle
  ///
  /// In de, this message translates to:
  /// **'Trainer-Bewerbungen und Review-Kanäle'**
  String get profileReviewChannels;

  /// Profile screen trainer workspace navigation item
  ///
  /// In de, this message translates to:
  /// **'Trainerbereich'**
  String get profileTrainerArea;

  /// Profile screen professional access section
  ///
  /// In de, this message translates to:
  /// **'Beruflicher Zugang'**
  String get profileProfessionalAccessSection;

  /// Profile screen action to apply as a trainer
  ///
  /// In de, this message translates to:
  /// **'Trainer werden'**
  String get profileBecomeTrainer;

  /// Profile screen trainer application subtitle
  ///
  /// In de, this message translates to:
  /// **'Bewerbung einreichen und prüfen lassen'**
  String get profileApplicationSubtitle;

  /// Profile screen account section
  ///
  /// In de, this message translates to:
  /// **'Account'**
  String get profileAccountSection;

  /// Error shown when training subject profiles cannot be loaded
  ///
  /// In de, this message translates to:
  /// **'Profile konnten nicht geladen werden: {error}'**
  String profileSubjectProfilesLoadFailed(String error);

  /// Action creating the first training subject profile
  ///
  /// In de, this message translates to:
  /// **'Erstes Profil anlegen'**
  String get profileCreateFirst;

  /// Tooltip for editing a training subject profile
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get profileEditTooltip;

  /// Action activating a training subject profile
  ///
  /// In de, this message translates to:
  /// **'Aktivieren'**
  String get profileActivate;

  /// Profile section: open completed reflex result (§10.3a)
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil ansehen'**
  String get profileViewReflexProfile;

  /// Profile section: start questionnaire when no assessment (§10.3a)
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil ausfüllen'**
  String get profileStartReflexProfile;

  /// Action adding a training subject profile
  ///
  /// In de, this message translates to:
  /// **'Profil hinzufügen'**
  String get profileAdd;

  /// Confirmation after saving a training subject profile
  ///
  /// In de, this message translates to:
  /// **'Profil gespeichert.'**
  String get profileSaved;

  /// Error shown when a training subject profile cannot be saved
  ///
  /// In de, this message translates to:
  /// **'Profil konnte nicht gespeichert werden: {error}'**
  String profileSaveFailed(String error);

  /// Adult training subject profile type
  ///
  /// In de, this message translates to:
  /// **'Erwachsenenprofil'**
  String get profileAdult;

  /// Child training subject profile type
  ///
  /// In de, this message translates to:
  /// **'Kinderprofil'**
  String get profileChild;

  /// Age of a training subject profile
  ///
  /// In de, this message translates to:
  /// **'{years, plural, one{{years} Jahr} other{{years} Jahre}}'**
  String profileAgeYears(int years);

  /// Date picker help text for a subject profile birth date
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum auswählen'**
  String get profileSelectBirthDateHelp;

  /// Validation error when a subject profile name is empty
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen an.'**
  String get profileNameRequired;

  /// Validation error when a child subject profile has no birth date
  ///
  /// In de, this message translates to:
  /// **'Bitte gib ein Geburtsdatum an.'**
  String get profileBirthDateRequired;

  /// Subject profile edit dialog title
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get profileEditTitle;

  /// Name field label for a child subject profile
  ///
  /// In de, this message translates to:
  /// **'Name oder Spitzname'**
  String get profileChildNameLabel;

  /// Name field label for an adult subject profile
  ///
  /// In de, this message translates to:
  /// **'Profilname'**
  String get profileNameLabel;

  /// Subject profile birth date field label
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum'**
  String get profileBirthDateLabel;

  /// Prompt to select a subject profile birth date
  ///
  /// In de, this message translates to:
  /// **'Datum auswählen'**
  String get profileSelectDate;

  /// Profile display name field heading
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get profileDisplayNameLabel;

  /// Explanation of the profile display name when community features are enabled
  ///
  /// In de, this message translates to:
  /// **'Wird im Community-Feed angezeigt, wenn du Erfahrungen teilst.'**
  String get profileCommunityDisplayNameHint;

  /// Explanation of the profile display name when community features are disabled
  ///
  /// In de, this message translates to:
  /// **'Sichtbar für deinen Trainer, zum Beispiel im Chat.'**
  String get profileTrainerDisplayNameHint;

  /// Minimum display name length validation
  ///
  /// In de, this message translates to:
  /// **'Mindestens {count} Zeichen'**
  String profileMinimumCharacters(int count);

  /// Maximum display name length validation
  ///
  /// In de, this message translates to:
  /// **'Maximal {count} Zeichen'**
  String profileMaximumCharacters(int count);

  /// Validation error when a profile name contains an at sign
  ///
  /// In de, this message translates to:
  /// **'Kein @ erlaubt'**
  String get profileAtNotAllowed;

  /// Short error shown when a profile display name cannot be saved
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen'**
  String get profileSaveFailedShort;

  /// Validation error when the initial contact name is empty
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Kontaktnamen ein.'**
  String get profileContactNameRequired;

  /// Initial contact name setup heading
  ///
  /// In de, this message translates to:
  /// **'Wie sollen wir dich nennen?'**
  String get profileContactNameQuestion;

  /// Initial contact name explanation without community features
  ///
  /// In de, this message translates to:
  /// **'Dein Kontaktname ist sichtbar für Trainer und im Kursbereich.'**
  String get profileContactNameBody;

  /// Initial contact name explanation with community features
  ///
  /// In de, this message translates to:
  /// **'Dein Kontaktname ist sichtbar für Trainer und im Kursbereich. Er kann sich von deinem Community-Namen unterscheiden.'**
  String get profileContactNameBodyWithCommunity;

  /// Example initial contact name
  ///
  /// In de, this message translates to:
  /// **'z. B. Maria oder Familie Müller'**
  String get profileContactNameHint;

  /// Bottom navigation tab label for the trainer area
  ///
  /// In de, this message translates to:
  /// **'Trainer'**
  String get tabTrainer;

  /// Bottom navigation tab label for the admin panel
  ///
  /// In de, this message translates to:
  /// **'Admin'**
  String get tabAdmin;

  /// Router error screen when no route matches
  ///
  /// In de, this message translates to:
  /// **'Seite nicht gefunden: {error}'**
  String routeNotFound(String error);

  /// Full-screen message when app initialization fails at launch
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey konnte nicht gestartet werden. Bitte starte die App neu oder installiere sie neu.'**
  String get startupCouldNotStart;

  /// Heading on the development boot screen when initialization fails
  ///
  /// In de, this message translates to:
  /// **'Start fehlgeschlagen'**
  String get startupBootstrapFailedTitle;

  /// Generic client display name when the real name is unavailable
  ///
  /// In de, this message translates to:
  /// **'Klient'**
  String get clientFallbackName;

  /// Calendar event title when the appointment payload has none
  ///
  /// In de, this message translates to:
  /// **'Isometrische Partnerübung'**
  String get appointmentCalendarFallbackTitle;

  /// Calendar event title combining appointment title and client name
  ///
  /// In de, this message translates to:
  /// **'{title} (mit {name})'**
  String appointmentCalendarEventTitle(String title, String name);

  /// Snackbar after a confirmed appointment was written to the device calendar
  ///
  /// In de, this message translates to:
  /// **'Termin mit {name} wurde dem Kalender hinzugefügt.'**
  String appointmentCalendarAdded(String name);

  /// Snackbar when writing a confirmed appointment to the device calendar fails
  ///
  /// In de, this message translates to:
  /// **'Kalender konnte nicht geöffnet werden: {error}'**
  String appointmentCalendarOpenFailed(String error);

  /// Onboarding hint body for the dashboard tab
  ///
  /// In de, this message translates to:
  /// **'Hier steuerst du deinen täglichen Rhythmus und dokumentierst, was du wahrnimmst.'**
  String get hintDashboardBody;

  /// Dashboard onboarding hint bullet: starting a session
  ///
  /// In de, this message translates to:
  /// **'Starte deine geführte Einheit oder den Routine-Modus.'**
  String get hintDashboardItemStart;

  /// Dashboard onboarding hint bullet: logging a session
  ///
  /// In de, this message translates to:
  /// **'Trage eine Einheit ein, wenn du heute geübt hast.'**
  String get hintDashboardItemLog;

  /// Dashboard onboarding hint bullet: capturing experiences
  ///
  /// In de, this message translates to:
  /// **'Halte Erfahrungen direkt nach der Einheit fest.'**
  String get hintDashboardItemNote;

  /// Onboarding hint body for the history tab
  ///
  /// In de, this message translates to:
  /// **'Der Verlauf hilft dir, Muster zu sehen, ohne einzelne Tage zu überbewerten.'**
  String get hintProgressBody;

  /// History onboarding hint bullet: combined overview
  ///
  /// In de, this message translates to:
  /// **'Sieh Trainingstage, Beobachtungen und Einträge zusammen.'**
  String get hintProgressItemOverview;

  /// History onboarding hint bullet: adding observations
  ///
  /// In de, this message translates to:
  /// **'Ergänze Beobachtungen, wenn dir etwas auffällt.'**
  String get hintProgressItemObserve;

  /// History onboarding hint bullet: journal entries
  ///
  /// In de, this message translates to:
  /// **'Öffne einzelne Journal-Einträge für mehr Kontext.'**
  String get hintProgressItemJournal;

  /// Onboarding hint body for the guidance tab
  ///
  /// In de, this message translates to:
  /// **'Hier liegt alles, was mit Trainer, Kommunikation und Terminen zu tun hat.'**
  String get hintAccompanimentBody;

  /// Guidance onboarding hint bullet: finding trainers
  ///
  /// In de, this message translates to:
  /// **'Finde Trainer oder verwalte deine aktive Begleitung.'**
  String get hintAccompanimentItemTrainer;

  /// Guidance onboarding hint bullet: messages
  ///
  /// In de, this message translates to:
  /// **'Öffne Nachrichten und bleib mit deinem Trainer im Kontakt.'**
  String get hintAccompanimentItemChat;

  /// Guidance onboarding hint bullet: appointments
  ///
  /// In de, this message translates to:
  /// **'Sieh Terminvorschläge und geplante Termine an.'**
  String get hintAccompanimentItemAppointments;

  /// Onboarding hint body for the profile tab
  ///
  /// In de, this message translates to:
  /// **'Im Profil findest du Konto, Einstellungen und administrative Zugänge.'**
  String get hintProfileBody;

  /// Profile onboarding hint bullet: settings
  ///
  /// In de, this message translates to:
  /// **'Passe Sprache, Darstellung und Erinnerungen an.'**
  String get hintProfileItemSettings;

  /// Profile onboarding hint bullet: account management
  ///
  /// In de, this message translates to:
  /// **'Verwalte Account, Passwort und Profilinformationen.'**
  String get hintProfileItemAccount;

  /// Profile onboarding hint bullet: role-gated areas
  ///
  /// In de, this message translates to:
  /// **'Öffne Trainer- oder Admin-Bereiche, wenn sie für dich freigeschaltet sind.'**
  String get hintProfileItemRoles;

  /// Onboarding hint sheet checkbox to hide the hint permanently
  ///
  /// In de, this message translates to:
  /// **'Nicht mehr anzeigen'**
  String get hintDontShowAgain;

  /// Onboarding hint sheet confirm button
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get hintGotIt;

  /// Onboarding hint sheet button to keep showing the hint
  ///
  /// In de, this message translates to:
  /// **'Später nochmal zeigen'**
  String get hintShowLater;

  /// Android notification channel name shown in system settings
  ///
  /// In de, this message translates to:
  /// **'Training-Erinnerungen'**
  String get notificationChannelTrainingReminders;

  /// Foreground push fallback title for an incoming video call
  ///
  /// In de, this message translates to:
  /// **'Eingehender Video-Call'**
  String get pushVideoCallTitle;

  /// Foreground push fallback body for an incoming video call
  ///
  /// In de, this message translates to:
  /// **'Tippe, um den Anruf zu öffnen.'**
  String get pushVideoCallBody;

  /// Foreground push fallback title for a video call request
  ///
  /// In de, this message translates to:
  /// **'Video-Call Anfrage'**
  String get pushCallRequestTitle;

  /// Foreground push fallback body for a video call request
  ///
  /// In de, this message translates to:
  /// **'Ein Klient möchte einen Video-Call starten.'**
  String get pushCallRequestBody;

  /// Foreground push fallback title for new appointment proposals
  ///
  /// In de, this message translates to:
  /// **'Neue Terminvorschläge'**
  String get pushAppointmentProposalTitle;

  /// Foreground push fallback body for new appointment proposals
  ///
  /// In de, this message translates to:
  /// **'Wähle einen passenden Termin aus.'**
  String get pushAppointmentProposalBody;

  /// Foreground push fallback title for a confirmed appointment
  ///
  /// In de, this message translates to:
  /// **'Termin bestätigt'**
  String get pushAppointmentConfirmedTitle;

  /// Foreground push fallback body for a confirmed appointment
  ///
  /// In de, this message translates to:
  /// **'Tippe, um den Termin in deinen Kalender einzutragen.'**
  String get pushAppointmentConfirmedBody;

  /// Foreground push fallback title for a training reminder
  ///
  /// In de, this message translates to:
  /// **'Training-Erinnerung'**
  String get pushTrainingReminderTitle;

  /// Foreground push fallback body for a training reminder
  ///
  /// In de, this message translates to:
  /// **'Tippe, um dein Training zu öffnen.'**
  String get pushTrainingReminderBody;

  /// Trainer notification title when a trainee reaches day 25
  ///
  /// In de, this message translates to:
  /// **'Termin vorbereiten — {traineeName}'**
  String trainerAlertPrepareTitle(String traineeName);

  /// Trainer notification body when a trainee reaches day 25
  ///
  /// In de, this message translates to:
  /// **'{traineeName} ist bei Tag 25. In ~3 Tagen ist die Isometrische Partnerübung fällig.'**
  String trainerAlertPrepareBody(String traineeName);

  /// Trainer notification title when a trainee reaches day 28
  ///
  /// In de, this message translates to:
  /// **'{traineeName} hat Tag 28 erreicht!'**
  String trainerAlertDay28Title(String traineeName);

  /// Trainer notification body when a trainee reaches day 28
  ///
  /// In de, this message translates to:
  /// **'Jetzt Termin für die Isometrische Partnerübung buchen.'**
  String get trainerAlertDay28Body;

  /// Fallback name when a trainee has no display name or email
  ///
  /// In de, this message translates to:
  /// **'Dein Trainee'**
  String get traineeFallbackName;

  /// Yes/no/unknown answer option
  ///
  /// In de, this message translates to:
  /// **'Weiß ich nicht'**
  String get answerUnknown;

  /// Reflex score band: strong
  ///
  /// In de, this message translates to:
  /// **'stark ausgeprägt'**
  String get scoreBandStrong;

  /// Reflex score band: elevated
  ///
  /// In de, this message translates to:
  /// **'auffällig'**
  String get scoreBandElevated;

  /// Reflex score band: indication
  ///
  /// In de, this message translates to:
  /// **'Anzeichen'**
  String get scoreBandIndication;

  /// Reflex score band: inconspicuous
  ///
  /// In de, this message translates to:
  /// **'unauffällig'**
  String get scoreBandInconspicuous;

  /// Reflex score band: insufficient data
  ///
  /// In de, this message translates to:
  /// **'zu wenig Daten'**
  String get scoreBandInsufficientData;

  /// Count of months
  ///
  /// In de, this message translates to:
  /// **'{count} Monate'**
  String monthsCount(int count);

  /// Count of years
  ///
  /// In de, this message translates to:
  /// **'{count} Jahre'**
  String yearsCount(int count);

  /// Dialog action to leave a flow
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get leave;

  /// Dialog action to resume a draft
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resume;

  /// Primary action to finish a questionnaire
  ///
  /// In de, this message translates to:
  /// **'Abschließen'**
  String get finish;

  /// Switch profile/subject action
  ///
  /// In de, this message translates to:
  /// **'Wechseln'**
  String get switchAction;

  /// Default display name for adult self profile
  ///
  /// In de, this message translates to:
  /// **'Ich'**
  String get selfName;

  /// Analysis placeholder screen title
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get analysisPlaceholderTitle;

  /// CTA to consent
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Zustimmung'**
  String get analysisPlaceholderContinue;

  /// Analysis placeholder headline
  ///
  /// In de, this message translates to:
  /// **'Hier startet bald deine persönliche Standortanalyse.'**
  String get analysisPlaceholderHeadline;

  /// Analysis placeholder body
  ///
  /// In de, this message translates to:
  /// **'Vor dem ersten Training wird hier ein kurzer Fragebogen stehen. Damit kann Reflex Journey deinen aktuellen Stand besser einordnen und die Empfehlung sauberer machen.'**
  String get analysisPlaceholderBody;

  /// Placeholder step title
  ///
  /// In de, this message translates to:
  /// **'Fragebogen'**
  String get analysisPlaceholderStepQuestionnaireTitle;

  /// Placeholder step body
  ///
  /// In de, this message translates to:
  /// **'Symptome, Belastung, Trainingsziel und bisherige Erfahrung.'**
  String get analysisPlaceholderStepQuestionnaireBody;

  /// Placeholder assessment step title
  ///
  /// In de, this message translates to:
  /// **'Auswertung'**
  String get analysisPlaceholderStepAssessmentTitle;

  /// Placeholder assessment step body
  ///
  /// In de, this message translates to:
  /// **'Eine ruhige Einschätzung deines aktuellen Ausgangspunkts.'**
  String get analysisPlaceholderStepAssessmentBody;

  /// Accept recommended duration
  ///
  /// In de, this message translates to:
  /// **'Empfehlung übernehmen'**
  String get durationRecAccept;

  /// Duration recommendation when assessment unused
  ///
  /// In de, this message translates to:
  /// **'Du hast das Reflexprofil übersprungen oder es liegt für dieses Profil noch keine Auswertung vor. Die Empfehlung nutzt deshalb die Standardlogik anhand deiner Angabe zum isometrischen Partnertraining.'**
  String get durationRecSkippedBody;

  /// Week range when user had trainer
  ///
  /// In de, this message translates to:
  /// **'4 bis 6'**
  String get durationRecRangeWithTrainer;

  /// Week range when user had no trainer
  ///
  /// In de, this message translates to:
  /// **'6 bis 8'**
  String get durationRecRangeWithoutTrainer;

  /// Trainer status fragment: already
  ///
  /// In de, this message translates to:
  /// **'bereits'**
  String get durationRecTrainerAlready;

  /// Trainer status fragment: not yet
  ///
  /// In de, this message translates to:
  /// **'noch nicht'**
  String get durationRecTrainerNotYet;

  /// Moro package duration recommendation body
  ///
  /// In de, this message translates to:
  /// **'Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung.\n\nFür das Moro-Paket betrachten wir sowohl Moro als auch FLR, weil beide in dieser Auswertung relevant sind. Der stärkere Hinweis liegt bei {percent} und bestimmt die Dauerstufe.\n\nDa du {trainerStatus} isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich {range} Wochen. Du kannst die Empfehlung übernehmen oder die Dauer manuell anpassen.'**
  String durationRecMoroBody(
      String percent, String trainerStatus, String range);

  /// Generic package duration recommendation body
  ///
  /// In de, this message translates to:
  /// **'Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung. Aufgrund deiner ermittelten Reflex-Tendenz empfehlen wir für dieses Paket eine Dauer von {weeks} Wochen.\n\nDa du {trainerStatus} isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich {range} Wochen.'**
  String durationRecGenericBody(int weeks, String trainerStatus, String range);

  /// Reflex tendency line in duration recommendation
  ///
  /// In de, this message translates to:
  /// **'{label}-Tendenz: {percent}'**
  String durationRecTendency(String label, String percent);

  /// Note when multiple reflexes considered
  ///
  /// In de, this message translates to:
  /// **'Für die Dauer zählt der stärkere Hinweis.'**
  String get durationRecStrongerHint;

  /// Percent placeholder when missing
  ///
  /// In de, this message translates to:
  /// **'keine ausreichenden Daten'**
  String get durationRecNoData;

  /// Radar chart empty state
  ///
  /// In de, this message translates to:
  /// **'Zu wenig Daten'**
  String get radarNotEnoughData;

  /// Validation error
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen und das Geburtsdatum an.'**
  String get reflexProfileNameBirthRequired;

  /// Validation error
  ///
  /// In de, this message translates to:
  /// **'Das Geburtsdatum darf nicht in der Zukunft liegen.'**
  String get reflexProfileBirthFuture;

  /// Error creating child profile
  ///
  /// In de, this message translates to:
  /// **'Kinderprofil konnte nicht angelegt werden: {error}'**
  String reflexProfileCreateChildFailed(String error);

  /// Professional clearance dialog title
  ///
  /// In de, this message translates to:
  /// **'Rücksprache erforderlich'**
  String get reflexProfileClearanceTitle;

  /// Professional clearance dialog body
  ///
  /// In de, this message translates to:
  /// **'Bei dieser Angabe empfehlen wir dringend, das Training nur nach Rücksprache und mit ausdrücklicher Zustimmung eines behandelnden Arztes, Therapeuten oder Psychologen durchzuführen.\n\nMit dem Fortfahren bestätigst du, dass du diese Rücksprache eigenverantwortlich berücksichtigst und das Training entsprechend begleitet oder freigegeben durchführst.\n\nFrage: {question}'**
  String reflexProfileClearanceBody(String question);

  /// Clearance dialog confirm button
  ///
  /// In de, this message translates to:
  /// **'Verstanden und bestätigt'**
  String get reflexProfileClearanceConfirm;

  /// Submit validation
  ///
  /// In de, this message translates to:
  /// **'Bitte beantworte alle Auswahl- und Zahlenfragen.'**
  String get reflexProfileAnswerAllChoice;

  /// Submit error
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil konnte nicht abgeschlossen werden: {error}'**
  String reflexProfileCompleteFailed(String error);

  /// Exit confirmation title
  ///
  /// In de, this message translates to:
  /// **'Fragebogen verlassen?'**
  String get reflexProfileLeaveTitle;

  /// Exit confirmation body
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt wird gespeichert. Du kannst jederzeit weitermachen.'**
  String get reflexProfileLeaveBody;

  /// Resume draft dialog title
  ///
  /// In de, this message translates to:
  /// **'Fragebogen fortsetzen?'**
  String get reflexProfileResumeTitle;

  /// Resume draft dialog body
  ///
  /// In de, this message translates to:
  /// **'Du hast diesen Fragebogen bereits begonnen. Möchtest du dort weitermachen, wo du aufgehört hast?'**
  String get reflexProfileResumeBody;

  /// Discard draft and restart
  ///
  /// In de, this message translates to:
  /// **'Von vorne'**
  String get reflexProfileStartOver;

  /// Profiles load error
  ///
  /// In de, this message translates to:
  /// **'Profile konnten nicht geladen werden: {error}'**
  String reflexProfileLoadProfilesFailed(String error);

  /// Subject selection title
  ///
  /// In de, this message translates to:
  /// **'Für wen machst du diesen Fragebogen?'**
  String get reflexProfileForWhomTitle;

  /// Subject selection body
  ///
  /// In de, this message translates to:
  /// **'Der Fragebogen unterscheidet sich je nachdem, ob er für ein Kind oder für dich selbst ausgefüllt wird.'**
  String get reflexProfileForWhomBody;

  /// Choose child subject
  ///
  /// In de, this message translates to:
  /// **'Für mein Kind'**
  String get reflexProfileForMyChild;

  /// Child path subtitle
  ///
  /// In de, this message translates to:
  /// **'Elternfragebogen'**
  String get reflexProfileParentQuestionnaire;

  /// Choose adult self subject
  ///
  /// In de, this message translates to:
  /// **'Für mich'**
  String get reflexProfileForMyself;

  /// Adult path disabled subtitle
  ///
  /// In de, this message translates to:
  /// **'Für mich selbst · bald verfügbar'**
  String get reflexProfileForMyselfComingSoon;

  /// Adult coming soon title
  ///
  /// In de, this message translates to:
  /// **'Erwachsenenfragebogen kommt bald'**
  String get reflexProfileAdultComingSoonTitle;

  /// Adult coming soon body
  ///
  /// In de, this message translates to:
  /// **'Der Fragebogen für Erwachsene befindet sich noch in Entwicklung. Du kannst ihn bald hier ausfüllen.'**
  String get reflexProfileAdultComingSoonBody;

  /// Adult answer: not applicable to my life situation
  ///
  /// In de, this message translates to:
  /// **'Trifft nicht zu'**
  String get answerNotApplicable;

  /// For-whom subtitle when adult path is enabled
  ///
  /// In de, this message translates to:
  /// **'Selbstauskunft für Erwachsene'**
  String get reflexProfileAdultSelfReport;

  /// Adult start screen title
  ///
  /// In de, this message translates to:
  /// **'Deine Antwortmuster — kein Befund'**
  String get reflexProfileAdultOrientationTitle;

  /// Adult start screen body — no diagnostic claims
  ///
  /// In de, this message translates to:
  /// **'Dieser Fragebogen sammelt deine eigenen Beobachtungen. Er zeigt nur Antwortmuster. Er stellt keinen Reflexnachweis fest und ersetzt keine persönliche Einschätzung.'**
  String get reflexProfileAdultOrientationBody;

  /// Adult profile picker heading
  ///
  /// In de, this message translates to:
  /// **'Profil auswählen'**
  String get reflexProfileSelectAdultProfile;

  /// Create adult profile heading
  ///
  /// In de, this message translates to:
  /// **'Neues Erwachsenenprofil'**
  String get reflexProfileNewAdultProfile;

  /// Birth date helper for adult age gate
  ///
  /// In de, this message translates to:
  /// **'Ab 16 Jahren. Unter 16 bitte den Kinderfragebogen nutzen (Elternbericht).'**
  String get reflexProfileAdultAgeHelper;

  /// Shown when adult profile age is under 16
  ///
  /// In de, this message translates to:
  /// **'Dieser Erwachsenenfragebogen ist ab 16 Jahren. Für jüngere Personen bitte den Kinderfragebogen nutzen — das ist ein Elternbericht über ein Kind, keine Selbstauskunft.'**
  String get reflexProfileAdultUnder16Hint;

  /// Adult module progress item counter
  ///
  /// In de, this message translates to:
  /// **'{answered} von {visible} sichtbaren Angaben beantwortet'**
  String reflexProfileAdultItemProgress(int answered, int visible);

  /// CTA from last adult module to summary
  ///
  /// In de, this message translates to:
  /// **'Angaben prüfen'**
  String get reflexProfileAdultContinueToSummary;

  /// Adult pre-submit summary title
  ///
  /// In de, this message translates to:
  /// **'Bevor du absendest'**
  String get reflexProfileAdultSummaryTitle;

  /// Adult summary non-diagnostic reminder
  ///
  /// In de, this message translates to:
  /// **'Dein Profil zeigt nur Antwortmuster — keine Diagnose und keinen Reflexnachweis.'**
  String get reflexProfileAdultSummaryDisclaimer;

  /// Adult summary answered count
  ///
  /// In de, this message translates to:
  /// **'Beantwortet: {count}'**
  String reflexProfileAdultSummaryAnswered(int count);

  /// Adult summary skipped count
  ///
  /// In de, this message translates to:
  /// **'Übersprungen (? / n. z.): {count}'**
  String reflexProfileAdultSummarySkipped(int count);

  /// Adult summary hidden count
  ///
  /// In de, this message translates to:
  /// **'Durch Filter ausgeblendet: {count}'**
  String reflexProfileAdultSummaryHidden(int count);

  /// Adult summary open items heading
  ///
  /// In de, this message translates to:
  /// **'Offene Fragen'**
  String get reflexProfileAdultSummaryOpenHeading;

  /// Adult safety notice dialog title (expert draft v0)
  ///
  /// In de, this message translates to:
  /// **'Hinweis'**
  String get reflexProfileAdultSafetyNoticeTitle;

  /// Adult safety notice body without movement appendix — Expertendokument §6 wörtlich
  ///
  /// In de, this message translates to:
  /// **'Deine Angabe kann bedeuten, dass einzelne Bewegungen oder Trainingsübungen angepasst oder vorher fachlich besprochen werden sollten. Dieses Ergebnis bewertet deine Diagnose nicht.'**
  String get reflexProfileAdultSafetyNoticeBody;

  /// Adult safety notice closing sentence — only when movement flag is on
  ///
  /// In de, this message translates to:
  /// **'Führe die gekennzeichneten Übungen nicht ohne die hier empfohlene Rücksprache durch.'**
  String get reflexProfileAdultSafetyNoticeMovementAppendix;

  /// Adult safety notice confirm — documents display only, no liability transfer
  ///
  /// In de, this message translates to:
  /// **'Hinweis gelesen.'**
  String get reflexProfileAdultSafetyNoticeConfirm;

  /// Adult result screen title
  ///
  /// In de, this message translates to:
  /// **'Dein Reflexprofil'**
  String get adultResultTitle;

  /// Adult result meta subline
  ///
  /// In de, this message translates to:
  /// **'Erwachsenenprofil · {date} · {questionnaireVersion} / {scoringVersion}'**
  String adultResultSubline(
      String date, String questionnaireVersion, String scoringVersion);

  /// Adult result non-diagnostic disclaimer
  ///
  /// In de, this message translates to:
  /// **'Das sind nur deine subjektiven Antwortmuster. Sie sind kein Reflexnachweis und keine Diagnose.'**
  String get adultResultDisclaimer;

  /// Adult result list heading — no overall score
  ///
  /// In de, this message translates to:
  /// **'Antwortmuster nach Reflex'**
  String get adultResultHintListTitle;

  /// Adult result coverage line
  ///
  /// In de, this message translates to:
  /// **'{answered} von {possible} Merkmalen beantwortet'**
  String adultResultFeaturesAnswered(int answered, int possible);

  /// Adult detail section: hint strength
  ///
  /// In de, this message translates to:
  /// **'Hinweisstärke'**
  String get adultResultDetailHintStrength;

  /// Adult detail section: data basis
  ///
  /// In de, this message translates to:
  /// **'Datengrundlage'**
  String get adultResultDetailDataBasis;

  /// Adult detail section: positive indications
  ///
  /// In de, this message translates to:
  /// **'Passende eigene Angaben'**
  String get adultResultDetailMatchingAnswers;

  /// Adult detail section: alternatives
  ///
  /// In de, this message translates to:
  /// **'Alternativerklärungen'**
  String get adultResultDetailAlternatives;

  /// Adult detail section: limits
  ///
  /// In de, this message translates to:
  /// **'Grenzen'**
  String get adultResultDetailLimits;

  /// Legacy adult assessment banner title
  ///
  /// In de, this message translates to:
  /// **'Erstellt mit älterer Methode'**
  String get adultResultLegacyTitle;

  /// Legacy adult assessment body
  ///
  /// In de, this message translates to:
  /// **'Dieses Erwachsenenprofil wurde mit einer früheren Fragebogen-Version erstellt. Werte werden nicht angezeigt und nicht mit aktuellen Profilen verglichen.'**
  String get adultResultLegacyBody;

  /// Legacy adult version line
  ///
  /// In de, this message translates to:
  /// **'Version: {questionnaireVersion} · Scoring: {scoringVersion}'**
  String adultResultLegacyVersion(
      String questionnaireVersion, String scoringVersion);

  /// Adult band 0–29
  ///
  /// In de, this message translates to:
  /// **'Wenige passende Angaben'**
  String get adultHintBandFewMatching;

  /// Adult band 30–59
  ///
  /// In de, this message translates to:
  /// **'Einige passende Angaben'**
  String get adultHintBandSomeMatching;

  /// Adult band 60–79
  ///
  /// In de, this message translates to:
  /// **'Gehäuftes Antwortmuster'**
  String get adultHintBandClusteredPattern;

  /// Adult band 80–100
  ///
  /// In de, this message translates to:
  /// **'Stark gehäuftes Muster'**
  String get adultHintBandStronglyClustered;

  /// Adult band insufficient
  ///
  /// In de, this message translates to:
  /// **'Keine ausreichende Datengrundlage'**
  String get adultHintBandInsufficientData;

  /// AmphibianDisplay.insufficientData — short card label (§10.2b)
  ///
  /// In de, this message translates to:
  /// **'Keine Angaben'**
  String get adultAmphibianInsufficientData;

  /// AmphibianDisplay.noneMatching
  ///
  /// In de, this message translates to:
  /// **'Kein passender Einzelhinweis'**
  String get adultAmphibianNoneMatching;

  /// AmphibianDisplay.singleHint
  ///
  /// In de, this message translates to:
  /// **'Einzelner Hinweis'**
  String get adultAmphibianSingleHint;

  /// AmphibianDisplay.clearSingleHint
  ///
  /// In de, this message translates to:
  /// **'Deutlicher Einzelhinweis'**
  String get adultAmphibianClearSingleHint;

  /// Start screen disclaimer title
  ///
  /// In de, this message translates to:
  /// **'Eine Orientierung, keine Diagnose'**
  String get reflexProfileOrientationTitle;

  /// Start screen disclaimer body
  ///
  /// In de, this message translates to:
  /// **'Das Reflexprofil sammelt Beobachtungen und zeigt Hinweisstärken. Es ersetzt keine medizinische oder therapeutische Diagnose.'**
  String get reflexProfileOrientationBody;

  /// Child profile picker heading
  ///
  /// In de, this message translates to:
  /// **'Kinderprofil auswählen'**
  String get reflexProfileSelectChild;

  /// Start questionnaire CTA
  ///
  /// In de, this message translates to:
  /// **'Fragebogen starten'**
  String get reflexProfileStartQuestionnaire;

  /// Create child profile heading
  ///
  /// In de, this message translates to:
  /// **'Neues Kinderprofil'**
  String get reflexProfileNewChild;

  /// Child name field label
  ///
  /// In de, this message translates to:
  /// **'Name oder Spitzname'**
  String get reflexProfileNameOrNickname;

  /// Date picker help text
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum auswählen'**
  String get reflexProfilePickBirthDate;

  /// Birth date field label
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum *'**
  String get reflexProfileBirthDateRequired;

  /// Birth date helper
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld – wird für die Altersauswertung benötigt'**
  String get reflexProfileBirthDateHelper;

  /// Empty date placeholder
  ///
  /// In de, this message translates to:
  /// **'Datum auswählen'**
  String get reflexProfileSelectDate;

  /// Create child profile CTA
  ///
  /// In de, this message translates to:
  /// **'Profil anlegen und starten'**
  String get reflexProfileCreateAndStart;

  /// Module validation
  ///
  /// In de, this message translates to:
  /// **'Bitte beantworte alle Pflichtfragen in diesem Abschnitt.'**
  String get reflexProfileAnswerRequiredSection;

  /// Fallback when no child name
  ///
  /// In de, this message translates to:
  /// **'Kinderprofil'**
  String get reflexProfileChildFallback;

  /// Module progress
  ///
  /// In de, this message translates to:
  /// **'Abschnitt {current} von {total}'**
  String reflexProfileSectionOf(int current, int total);

  /// Help expansion title
  ///
  /// In de, this message translates to:
  /// **'Was ist gemeint?'**
  String get reflexProfileWhatIsMeant;

  /// Months input label
  ///
  /// In de, this message translates to:
  /// **'Monate'**
  String get reflexProfileMonthsLabel;

  /// Free text input label
  ///
  /// In de, this message translates to:
  /// **'Freitext'**
  String get reflexProfileFreeTextLabel;

  /// Multi-select free text label
  ///
  /// In de, this message translates to:
  /// **'Sonstiges / Ergänzung'**
  String get reflexProfileOtherLabel;

  /// Result screen app bar
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil-Auswertung'**
  String get reflexResultTitle;

  /// Result load error
  ///
  /// In de, this message translates to:
  /// **'Auswertung konnte nicht geladen werden: {error}'**
  String reflexResultLoadFailed(String error);

  /// Result headline
  ///
  /// In de, this message translates to:
  /// **'Hinweistärken'**
  String get reflexResultIndicationStrengths;

  /// Result disclaimer
  ///
  /// In de, this message translates to:
  /// **'Diese Auswertung zeigt Antwortmuster und ersetzt keine medizinische oder therapeutische Diagnose.'**
  String get reflexResultDisclaimer;

  /// Radar caption
  ///
  /// In de, this message translates to:
  /// **'Die Grafik zeigt die stärksten Reflexbereiche aus deinem Antwortmuster.'**
  String get reflexResultChartCaption;

  /// Warning confirmations banner
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Du hast 1 Hinweis bestätigt, bei dem wir dringend Rücksprache mit Arzt, Therapeut oder Psychologe empfehlen. Eine Trainerbegleitung ist in deinem Fall besonders sinnvoll.} other{Du hast {count} Hinweise bestätigt, bei denen wir dringend Rücksprache mit Arzt, Therapeut oder Psychologe empfehlen. Eine Trainerbegleitung ist in deinem Fall besonders sinnvoll.}}'**
  String reflexResultWarningNotice(int count);

  /// Score list title
  ///
  /// In de, this message translates to:
  /// **'Reflexbereiche'**
  String get reflexResultAreasTitle;

  /// Additional answers section
  ///
  /// In de, this message translates to:
  /// **'Ergänzende Angaben'**
  String get reflexResultAdditionalInfo;

  /// Share PDF button
  ///
  /// In de, this message translates to:
  /// **'PDF-Zusammenfassung teilen'**
  String get reflexResultSharePdf;

  /// Dashboard CTA
  ///
  /// In de, this message translates to:
  /// **'Zum Dashboard'**
  String get reflexResultToDashboard;

  /// PDF share subject
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey Reflexprofil'**
  String get reflexResultShareSubject;

  /// PDF share text
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey Reflexprofil-Zusammenfassung'**
  String get reflexResultShareText;

  /// PDF creation error
  ///
  /// In de, this message translates to:
  /// **'PDF konnte nicht erstellt werden: {error}'**
  String reflexResultPdfFailed(String error);

  /// Trainer share card title
  ///
  /// In de, this message translates to:
  /// **'Mit Trainer teilen'**
  String get reflexResultShareWithTrainer;

  /// Trainer share card body
  ///
  /// In de, this message translates to:
  /// **'Du kannst {trainerName} dein vollständiges Reflexprofil freigeben. Das hilft bei der gemeinsamen Begleitung und kann später widerrufen werden.'**
  String reflexResultShareWithTrainerBody(String trainerName);

  /// Share status error
  ///
  /// In de, this message translates to:
  /// **'Freigabe konnte nicht geladen werden: {error}'**
  String reflexResultShareLoadFailed(String error);

  /// Share revoked snackbar
  ///
  /// In de, this message translates to:
  /// **'Freigabe wurde widerrufen.'**
  String get reflexResultShareRevoked;

  /// Revoke error
  ///
  /// In de, this message translates to:
  /// **'Freigabe konnte nicht widerrufen werden: {error}'**
  String reflexResultShareRevokeFailed(String error);

  /// Revoke button
  ///
  /// In de, this message translates to:
  /// **'Freigabe widerrufen'**
  String get reflexResultRevokeShare;

  /// Share granted snackbar
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil wurde freigegeben.'**
  String get reflexResultShareGranted;

  /// Grant error
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil konnte nicht freigegeben werden: {error}'**
  String reflexResultShareGrantFailed(String error);

  /// Grant share button
  ///
  /// In de, this message translates to:
  /// **'Trainer darf Auswertung sehen'**
  String get reflexResultAllowTrainer;

  /// Score tile yes ratio
  ///
  /// In de, this message translates to:
  /// **'{yesCount} von {answeredCount} beantworteten zugeordneten Fragen wurden mit Ja beantwortet.'**
  String reflexResultYesOfAnswered(int yesCount, int answeredCount);

  /// Empty additional answers
  ///
  /// In de, this message translates to:
  /// **'Keine weiteren Angaben vorhanden.'**
  String get reflexResultNoAdditional;

  /// Empty result state
  ///
  /// In de, this message translates to:
  /// **'Noch keine abgeschlossene Auswertung vorhanden.'**
  String get reflexResultNoCompleted;

  /// Empty result CTA
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil starten'**
  String get reflexResultStartProfile;

  /// Demo validation
  ///
  /// In de, this message translates to:
  /// **'Bitte beantworte alle Fragen.'**
  String get reflexDemoAnswerAll;

  /// App bar action when signed in
  ///
  /// In de, this message translates to:
  /// **'Volltest'**
  String get reflexDemoFullTest;

  /// Demo subject title
  ///
  /// In de, this message translates to:
  /// **'Für wen machst du den Kurztest?'**
  String get reflexDemoForWhomTitle;

  /// Demo subject body
  ///
  /// In de, this message translates to:
  /// **'Dieser Kurztest zeigt beispielhaft, wie eine Reflexprofil-Auswertung aussehen kann. Er wird nicht gespeichert.'**
  String get reflexDemoForWhomBody;

  /// Demo adult coming soon title
  ///
  /// In de, this message translates to:
  /// **'Kurztest für mich selbst kommt bald'**
  String get reflexDemoSelfComingSoonTitle;

  /// Demo adult coming soon body
  ///
  /// In de, this message translates to:
  /// **'Der Fragebogen für dich selbst befindet sich noch in Entwicklung.'**
  String get reflexDemoSelfComingSoonBody;

  /// Demo questionnaire title
  ///
  /// In de, this message translates to:
  /// **'Kurztest'**
  String get reflexDemoTitle;

  /// Demo intro
  ///
  /// In de, this message translates to:
  /// **'Diese Demo zeigt beispielhaft, wie eine Reflexprofil-Auswertung aussehen kann. Sie wird nicht gespeichert und ersetzt keinen vollständigen Fragebogen.'**
  String get reflexDemoIntro;

  /// Evaluate demo CTA
  ///
  /// In de, this message translates to:
  /// **'Demo auswerten'**
  String get reflexDemoEvaluate;

  /// Guest CTA to auth
  ///
  /// In de, this message translates to:
  /// **'Für den vollständigen Fragebogen anmelden'**
  String get reflexDemoSignInForFull;

  /// Signed-in CTA to full questionnaire
  ///
  /// In de, this message translates to:
  /// **'Vollständigen Fragebogen starten'**
  String get reflexDemoStartFull;

  /// Guest hint under CTA
  ///
  /// In de, this message translates to:
  /// **'Nach der Registrierung kannst du Kinderprofile anlegen, den vollständigen Fragebogen speichern und die Auswertung später erneut ansehen.'**
  String get reflexDemoGuestHint;

  /// Signed-in hint under CTA
  ///
  /// In de, this message translates to:
  /// **'Im vollständigen Fragebogen werden alle Kategorien abgefragt und die Auswertung kann gespeichert werden.'**
  String get reflexDemoSignedInHint;

  /// Open full assessment button
  ///
  /// In de, this message translates to:
  /// **'Volltest öffnen'**
  String get reflexDemoOpenFullTest;

  /// Auth CTA
  ///
  /// In de, this message translates to:
  /// **'Anmelden oder registrieren'**
  String get reflexDemoSignInOrRegister;

  /// Demo result app bar
  ///
  /// In de, this message translates to:
  /// **'Demo-Auswertung'**
  String get reflexDemoResultTitle;

  /// Demo result headline
  ///
  /// In de, this message translates to:
  /// **'Dein Demo-Ergebnis'**
  String get reflexDemoResultHeadline;

  /// Demo result disclaimer
  ///
  /// In de, this message translates to:
  /// **'Diese Auswertung basiert nur auf dem Kurztest und ist keine Diagnose. Sie zeigt Antwortmuster — für ein vollständiges Reflexprofil sind alle 112 Fragen notwendig.'**
  String get reflexDemoResultDisclaimer;

  /// Demo chart empty
  ///
  /// In de, this message translates to:
  /// **'Nicht genug Daten für die Grafik.'**
  String get reflexDemoNotEnoughChartData;

  /// Demo chart caption
  ///
  /// In de, this message translates to:
  /// **'Die Grafik zeigt die stärksten Reflexbereiche aus deinen Kurztest-Antworten.'**
  String get reflexDemoChartCaption;

  /// Demo result account benefit for guests
  ///
  /// In de, this message translates to:
  /// **'Mit einem Konto kannst du den vollständigen Fragebogen ausfüllen, dein Ergebnis speichern und mit deinem Trainer teilen.'**
  String get reflexDemoAccountBenefitGuest;

  /// Demo result account benefit when signed in
  ///
  /// In de, this message translates to:
  /// **'Im vollständigen Fragebogen werden alle Kategorien erfasst und das Ergebnis dauerhaft gespeichert.'**
  String get reflexDemoAccountBenefitSignedIn;

  /// PDF document title
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil Zusammenfassung'**
  String get reflexPdfTitle;

  /// PDF generated-on line
  ///
  /// In de, this message translates to:
  /// **'Erstellt am {date}'**
  String reflexPdfGeneratedOn(String date);

  /// PDF summary notice
  ///
  /// In de, this message translates to:
  /// **'Diese Auswertung zeigt Antwortmuster und Hinweisstärken. Sie ersetzt keine medizinische oder therapeutische Diagnose.'**
  String get reflexPdfSummaryNotice;

  /// PDF safety notice
  ///
  /// In de, this message translates to:
  /// **'{count} Sicherheits-/Rücksprache-Hinweise wurden bestätigt. Training sollte nur nach ausdrücklicher Rücksprache mit Arzt, Therapeut oder Psychologe erfolgen.'**
  String reflexPdfSafetyNotice(int count);

  /// PDF scores section title
  ///
  /// In de, this message translates to:
  /// **'Übersicht Reflexbereiche'**
  String get reflexPdfOverviewTitle;

  /// PDF table header
  ///
  /// In de, this message translates to:
  /// **'Reflexbereich'**
  String get reflexPdfAreaHeader;

  /// PDF table header
  ///
  /// In de, this message translates to:
  /// **'Prozent'**
  String get reflexPdfPercentHeader;

  /// PDF table header
  ///
  /// In de, this message translates to:
  /// **'Einordnung'**
  String get reflexPdfClassificationHeader;

  /// PDF table header
  ///
  /// In de, this message translates to:
  /// **'Ja / Beantwortet'**
  String get reflexPdfYesAnsweredHeader;

  /// PDF answers title
  ///
  /// In de, this message translates to:
  /// **'Antwortübersicht'**
  String get reflexPdfAnswersTitle;

  /// PDF answers header
  ///
  /// In de, this message translates to:
  /// **'Frage'**
  String get reflexPdfQuestionHeader;

  /// PDF answers header
  ///
  /// In de, this message translates to:
  /// **'Antwort'**
  String get reflexPdfAnswerHeader;

  /// PDF empty answer placeholder
  ///
  /// In de, this message translates to:
  /// **'-'**
  String get reflexPdfEmptyAnswer;

  /// PDF temp file name stem
  ///
  /// In de, this message translates to:
  /// **'reflexjourney_reflexprofil'**
  String get reflexPdfFileNameStem;

  /// Validation when subject display name is empty
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen an.'**
  String get reflexProfileNameRequired;

  /// Trainer dashboard overview title
  ///
  /// In de, this message translates to:
  /// **'Arbeitsübersicht'**
  String get trainerWorkOverview;

  /// Trainer dashboard overview subtitle
  ///
  /// In de, this message translates to:
  /// **'Priorisiert nach Paketübergängen, Anfragen, Terminen und Beobachtungen.'**
  String get trainerWorkOverviewSubtitle;

  /// Overview metric
  ///
  /// In de, this message translates to:
  /// **'Paketübergänge'**
  String get trainerPackageTransitions;

  /// Overview metric / section
  ///
  /// In de, this message translates to:
  /// **'Offene Einladungen'**
  String get trainerOpenInvites;

  /// Overview metric
  ///
  /// In de, this message translates to:
  /// **'Neue Anfragen'**
  String get trainerNewRequests;

  /// Overview metric
  ///
  /// In de, this message translates to:
  /// **'Termine'**
  String get trainerAppointmentsMetric;

  /// Overview metric / section
  ///
  /// In de, this message translates to:
  /// **'Neue Beobachtungen'**
  String get trainerNewObservations;

  /// Collapsed open invites count
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 weitere Einladung offen} other{{count} weitere Einladungen offen}}'**
  String trainerMoreInvitesOpen(int count);

  /// Dashboard CTA to moderated experiences
  ///
  /// In de, this message translates to:
  /// **'Geteilte Erfahrungen prüfen'**
  String get trainerReviewSharedExperiences;

  /// Dashboard shared experiences body
  ///
  /// In de, this message translates to:
  /// **'Moderierte Erfahrungsbeiträge aus laufenden Paketen im Blick behalten.'**
  String get trainerReviewSharedExperiencesBody;

  /// Debug panel title (avoid claim-word diagnose)
  ///
  /// In de, this message translates to:
  /// **'Trainer-Verknüpfung prüfen'**
  String get trainerConnectionCheck;

  /// Debug loading
  ///
  /// In de, this message translates to:
  /// **'Prüfe Datenbank...'**
  String get trainerConnectionChecking;

  /// Debug error state
  ///
  /// In de, this message translates to:
  /// **'Fehler bei der Prüfung'**
  String get trainerConnectionCheckError;

  /// Debug collapsed hint
  ///
  /// In de, this message translates to:
  /// **'Zum Öffnen antippen'**
  String get trainerConnectionTapToOpen;

  /// Debug refresh tooltip
  ///
  /// In de, this message translates to:
  /// **'Prüfung aktualisieren'**
  String get trainerConnectionRefresh;

  /// Debug error with detail
  ///
  /// In de, this message translates to:
  /// **'Prüfungsfehler: {error}'**
  String trainerConnectionCheckFailed(String error);

  /// Invite code helper
  ///
  /// In de, this message translates to:
  /// **'Einmaliger Code — teile ihn mit deinem Klienten'**
  String get trainerInviteCodeOnce;

  /// Regenerate invite code button
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get trainerInviteNew;

  /// Invite code creating state
  ///
  /// In de, this message translates to:
  /// **'Wird erstellt…'**
  String get trainerInviteCreating;

  /// SnackBar after copying invite code
  ///
  /// In de, this message translates to:
  /// **'Code {code} kopiert!'**
  String trainerCodeCopiedWithValue(String code);

  /// Location banner title
  ///
  /// In de, this message translates to:
  /// **'Standort fehlt'**
  String get trainerLocationMissingTitle;

  /// Location banner body
  ///
  /// In de, this message translates to:
  /// **'Dein Trainerprofil ist aktiv, erscheint aber erst in der Trainersuche, wenn ein Standort gesetzt ist. Öffentlich wird nur ein ungefährer Pin angezeigt.'**
  String get trainerLocationMissingBody;

  /// Expand location picker CTA
  ///
  /// In de, this message translates to:
  /// **'Standort setzen'**
  String get trainerSetLocation;

  /// Location save snackbar
  ///
  /// In de, this message translates to:
  /// **'Standort gespeichert'**
  String get trainerLocationSaved;

  /// Location save error
  ///
  /// In de, this message translates to:
  /// **'Standort konnte nicht gespeichert werden: {error}'**
  String trainerLocationSaveFailed(String error);

  /// Client card day-28 badge
  ///
  /// In de, this message translates to:
  /// **'Tag 28 ✓'**
  String get trainerDay28Badge;

  /// Days remaining badge
  ///
  /// In de, this message translates to:
  /// **'{days} Tage übrig'**
  String trainerDaysLeft(int days);

  /// Propose appointment CTA
  ///
  /// In de, this message translates to:
  /// **'Termin vorschlagen'**
  String get trainerProposeAppointment;

  /// Package transition hint
  ///
  /// In de, this message translates to:
  /// **'Noch {days} Tage: Termin für das isometrische Training des nächsten Pakets vorschlagen.'**
  String trainerProposeNextPackage(int days);

  /// Open client detail tooltip
  ///
  /// In de, this message translates to:
  /// **'Detail öffnen'**
  String get trainerOpenDetail;

  /// Open chat tooltip
  ///
  /// In de, this message translates to:
  /// **'Chat öffnen'**
  String get trainerOpenChat;

  /// Fallback client label on detail screen
  ///
  /// In de, this message translates to:
  /// **'Client'**
  String get trainerClientFallback;

  /// Shared profiles section
  ///
  /// In de, this message translates to:
  /// **'Freigegebene Reflexprofile'**
  String get trainerSharedReflexProfiles;

  /// Profiles load error
  ///
  /// In de, this message translates to:
  /// **'Profile konnten nicht geladen werden: {error}'**
  String trainerProfilesLoadFailed(String error);

  /// Empty shared profiles
  ///
  /// In de, this message translates to:
  /// **'Keine Profile freigegeben.'**
  String get trainerNoProfilesShared;

  /// Profile without completed assessment
  ///
  /// In de, this message translates to:
  /// **'{name}: Noch kein abgeschlossenes Reflexprofil.'**
  String trainerNoCompletedReflexProfile(String name);

  /// Observations section title
  ///
  /// In de, this message translates to:
  /// **'Beobachtungen'**
  String get trainerObservations;

  /// Empty observations
  ///
  /// In de, this message translates to:
  /// **'Noch keine geteilten Beobachtungen.'**
  String get trainerNoSharedObservations;

  /// Note saved snackbar
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil-Notiz gespeichert.'**
  String get trainerReflexNoteSaved;

  /// Note save error
  ///
  /// In de, this message translates to:
  /// **'Notiz konnte nicht gespeichert werden: {error}'**
  String trainerNoteSaveFailed(String error);

  /// Notes section title
  ///
  /// In de, this message translates to:
  /// **'Reflexprofil-Notizen'**
  String get trainerReflexNotesTitle;

  /// Notes section body
  ///
  /// In de, this message translates to:
  /// **'Diese Notizen haften am Profil und sind bei bestehender Freigabe auch für spätere Trainer als Übergabe sichtbar.'**
  String get trainerReflexNotesBody;

  /// Note field hint
  ///
  /// In de, this message translates to:
  /// **'Notiz zur Begleitung oder Übergabe'**
  String get trainerReflexNoteHint;

  /// Save note button
  ///
  /// In de, this message translates to:
  /// **'Notiz speichern'**
  String get trainerSaveNote;

  /// Notes load error
  ///
  /// In de, this message translates to:
  /// **'Notizen konnten nicht geladen werden: {error}'**
  String trainerNotesLoadFailed(String error);

  /// Empty notes
  ///
  /// In de, this message translates to:
  /// **'Noch keine Reflexprofil-Notizen.'**
  String get trainerNoReflexNotes;

  /// Message action label
  ///
  /// In de, this message translates to:
  /// **'Nachricht'**
  String get trainerMessageAction;

  /// Appointment action label
  ///
  /// In de, this message translates to:
  /// **'Termin'**
  String get trainerAppointmentAction;

  /// Day count label
  ///
  /// In de, this message translates to:
  /// **'{count} Tage'**
  String trainerDaysCount(int count);

  /// Empty appointments
  ///
  /// In de, this message translates to:
  /// **'Noch keine geplanten Termine.'**
  String get trainerNoPlannedAppointments;

  /// Proposed appointment status line
  ///
  /// In de, this message translates to:
  /// **'Termin vorgeschlagen'**
  String get trainerAppointmentProposed;

  /// Appointment subject line
  ///
  /// In de, this message translates to:
  /// **'für {name}'**
  String trainerAppointmentFor(String name);

  /// Appointment status: proposal
  ///
  /// In de, this message translates to:
  /// **'Vorschlag'**
  String get appointmentStatusProposal;

  /// Appointment status short: done
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get appointmentStatusCompletedShort;

  /// Session day chip
  ///
  /// In de, this message translates to:
  /// **'Tag {day}'**
  String trainerDayNumber(int day);

  /// Age in years
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{count} Jahr} other{{count} Jahre}}'**
  String trainerAgeYears(int count);

  /// Trainer-facing score band stronger than elevated
  ///
  /// In de, this message translates to:
  /// **'stark auffällig'**
  String get trainerBandStrongNoticeable;

  /// Proposal sent confirmation
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Terminvorschlag an {name} gesendet.} other{{count} Terminvorschläge an {name} gesendet.}}'**
  String appointmentProposalSent(int count, String name);

  /// After proposal hint
  ///
  /// In de, this message translates to:
  /// **'Die andere Person wählt einen passenden Slot aus.'**
  String get appointmentProposalSentHint;

  /// Video appointment title
  ///
  /// In de, this message translates to:
  /// **'Video-Termin mit {name}'**
  String appointmentVideoWith(String name);

  /// Interview scheduling help
  ///
  /// In de, this message translates to:
  /// **'Wähle 2–4 freie Slots für das Bewerbungsgespräch aus.'**
  String get appointmentPickSlotsInterview;

  /// Client scheduling help
  ///
  /// In de, this message translates to:
  /// **'Wähle 2–4 freie Slots aus — dein Klient sucht sich einen aus.'**
  String get appointmentPickSlotsClient;

  /// Selected slots count
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Slot ausgewählt} other{{count} Slots ausgewählt}}'**
  String appointmentSlotsSelected(int count);

  /// Reset slot selection
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get appointmentResetSlots;

  /// Location field label
  ///
  /// In de, this message translates to:
  /// **'Ort oder Video-Call'**
  String get appointmentLocationOrVideo;

  /// Select slots CTA disabled
  ///
  /// In de, this message translates to:
  /// **'Slots auswählen'**
  String get appointmentSelectSlots;

  /// Send proposal CTA
  ///
  /// In de, this message translates to:
  /// **'Vorschlag senden ({count})'**
  String appointmentSendProposal(int count);

  /// Subject profile picker title
  ///
  /// In de, this message translates to:
  /// **'Termin für (optional)'**
  String get appointmentForOptional;

  /// Subject profile picker hint
  ///
  /// In de, this message translates to:
  /// **'Wähle Profile aus, wenn dieser Termin für bestimmte Kinder ist.'**
  String get appointmentForOptionalHint;

  /// Application screens title
  ///
  /// In de, this message translates to:
  /// **'Trainer-Bewerbung'**
  String get trainerApplicationTitle;

  /// Status timeline step
  ///
  /// In de, this message translates to:
  /// **'Bewerbung eingereicht'**
  String get trainerApplicationSubmittedStep;

  /// Status timeline step
  ///
  /// In de, this message translates to:
  /// **'Führungszeugnis Stufe 2 per Sichtprüfung geprüft'**
  String get trainerApplicationBgCheckStep;

  /// Status timeline step
  ///
  /// In de, this message translates to:
  /// **'Aktivierungscode erzeugt'**
  String get trainerApplicationCodeStep;

  /// Open review chat CTA
  ///
  /// In de, this message translates to:
  /// **'Review-Kanal öffnen'**
  String get trainerApplicationOpenReview;

  /// Activate CTA
  ///
  /// In de, this message translates to:
  /// **'Trainer aktivieren'**
  String get trainerApplicationActivate;

  /// Status title approved
  ///
  /// In de, this message translates to:
  /// **'Freigegeben'**
  String get trainerApplicationApprovedTitle;

  /// Status body approved
  ///
  /// In de, this message translates to:
  /// **'Deine Bewerbung wurde freigegeben. Aktiviere jetzt dein verifiziertes Trainerprofil.'**
  String get trainerApplicationApprovedBody;

  /// Status title rejected
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get trainerApplicationRejectedTitle;

  /// Status body rejected
  ///
  /// In de, this message translates to:
  /// **'Deine Bewerbung wurde abgelehnt. Details findest du im Review-Kanal.'**
  String get trainerApplicationRejectedBody;

  /// Status title needs more info
  ///
  /// In de, this message translates to:
  /// **'Rückfrage offen'**
  String get trainerApplicationNeedsInfoTitle;

  /// Status body needs more info
  ///
  /// In de, this message translates to:
  /// **'Die Admins benötigen weitere Informationen. Bitte prüfe den Review-Kanal.'**
  String get trainerApplicationNeedsInfoBody;

  /// Status body in review
  ///
  /// In de, this message translates to:
  /// **'Deine Bewerbung ist im Review. Die Admins melden sich im Review-Kanal zur weiteren Prüfung.'**
  String get trainerApplicationInReviewBody;

  /// Empty application state
  ///
  /// In de, this message translates to:
  /// **'Noch keine Trainer-Bewerbung'**
  String get trainerApplicationNoneTitle;

  /// Start application CTA
  ///
  /// In de, this message translates to:
  /// **'Bewerbung starten'**
  String get trainerApplicationStart;

  /// Form validation
  ///
  /// In de, this message translates to:
  /// **'Dieses Feld ist erforderlich.'**
  String get trainerApplicationFieldRequired;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Vollständiger Name'**
  String get trainerApplicationFullName;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get trainerApplicationEmail;

  /// Email validation
  ///
  /// In de, this message translates to:
  /// **'Gültige E-Mail erforderlich.'**
  String get trainerApplicationEmailInvalid;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Telefon optional'**
  String get trainerApplicationPhoneOptional;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Stadt / Region'**
  String get trainerApplicationCityRegion;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Beruflicher Hintergrund'**
  String get trainerApplicationBackground;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Motivation optional'**
  String get trainerApplicationMotivationOptional;

  /// Form section
  ///
  /// In de, this message translates to:
  /// **'Öffentliches Trainerprofil'**
  String get trainerApplicationPublicProfile;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Anzeigename optional'**
  String get trainerApplicationDisplayNameOptional;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Bio optional'**
  String get trainerApplicationBioOptional;

  /// Form label
  ///
  /// In de, this message translates to:
  /// **'Standort optional'**
  String get trainerApplicationLocationOptional;

  /// Form location hint
  ///
  /// In de, this message translates to:
  /// **'Wenn du einen Standort setzt, kann dein Profil nach Freigabe in der Trainer-Suche erscheinen. Öffentlich wird nur ein ungefährer Pin angezeigt.'**
  String get trainerApplicationLocationHint;

  /// Submit form CTA
  ///
  /// In de, this message translates to:
  /// **'Bewerbung einreichen'**
  String get trainerApplicationSubmit;

  /// Intro app bar
  ///
  /// In de, this message translates to:
  /// **'Trainer werden'**
  String get trainerBecomeTitle;

  /// Intro headline
  ///
  /// In de, this message translates to:
  /// **'Bewerbung und Prüfung'**
  String get trainerBecomeHeadline;

  /// Intro body
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey-Trainer arbeiten in einem sensiblen Umfeld. Deshalb prüfen wir jede Bewerbung manuell, bevor ein Trainerprofil freigeschaltet wird.'**
  String get trainerBecomeBody;

  /// Intro card title
  ///
  /// In de, this message translates to:
  /// **'Fachlicher Hintergrund'**
  String get trainerBecomeBackgroundTitle;

  /// Intro card body
  ///
  /// In de, this message translates to:
  /// **'Beschreibe deine Ausbildung, Erfahrung oder Praxis im relevanten Bereich.'**
  String get trainerBecomeBackgroundBody;

  /// Intro card title
  ///
  /// In de, this message translates to:
  /// **'Erweitertes Führungszeugnis Stufe 2'**
  String get trainerBecomeBgCheckTitle;

  /// Intro card body
  ///
  /// In de, this message translates to:
  /// **'Im Review-Kanal fordern Admins die Sichtprüfung an. Das Dokument wird nicht hochgeladen oder gespeichert.'**
  String get trainerBecomeBgCheckBody;

  /// Intro card title
  ///
  /// In de, this message translates to:
  /// **'Admin-Review-Kanal'**
  String get trainerBecomeReviewTitle;

  /// Intro card body
  ///
  /// In de, this message translates to:
  /// **'Nach dem Absenden öffnet sich ein geschützter Kommunikationskanal mit den Admins.'**
  String get trainerBecomeReviewBody;

  /// Intro important note
  ///
  /// In de, this message translates to:
  /// **'Wichtig: Der Aktivierungscode wird erst nach erfolgreicher Prüfung erzeugt.'**
  String get trainerBecomeImportant;

  /// Proposal screen title
  ///
  /// In de, this message translates to:
  /// **'Terminvorschläge'**
  String get appointmentProposalsTitle;

  /// Empty proposals
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Terminvorschläge.'**
  String get appointmentNoOpenProposals;

  /// Calendar dialog title
  ///
  /// In de, this message translates to:
  /// **'Zum Kalender hinzufügen?'**
  String get appointmentAddToCalendarTitle;

  /// Calendar dialog body
  ///
  /// In de, this message translates to:
  /// **'Soll der Termin am {when} in deinen Kalender eingetragen werden?'**
  String appointmentAddToCalendarBody(String when);

  /// Calendar dialog confirm
  ///
  /// In de, this message translates to:
  /// **'Ja, hinzufügen'**
  String get appointmentAddToCalendarConfirm;

  /// Confirmed snackbar
  ///
  /// In de, this message translates to:
  /// **'Termin bestätigt!'**
  String get appointmentConfirmedSnack;

  /// Slot picker prompt
  ///
  /// In de, this message translates to:
  /// **'Wähle einen passenden Termin:'**
  String get appointmentChooseSlot;

  /// Confirm selected slot
  ///
  /// In de, this message translates to:
  /// **'Termin bestätigen'**
  String get appointmentConfirmSlot;

  /// Accept snackbar
  ///
  /// In de, this message translates to:
  /// **'Anfrage angenommen. Der Klient erscheint jetzt in deiner Übersicht.'**
  String get trainerRequestAccepted;

  /// Decline snackbar
  ///
  /// In de, this message translates to:
  /// **'Anfrage abgelehnt.'**
  String get trainerRequestDeclined;

  /// Client list subtitle
  ///
  /// In de, this message translates to:
  /// **'{packageName} · {dayLabel} · {days} Tage regelmäßig'**
  String trainerClientRegularDays(
      String packageName, String dayLabel, int days);

  /// Application status
  ///
  /// In de, this message translates to:
  /// **'Eingereicht'**
  String get trainerAppStatusSubmitted;

  /// Application status
  ///
  /// In de, this message translates to:
  /// **'In Prüfung'**
  String get trainerAppStatusInReview;

  /// Application status
  ///
  /// In de, this message translates to:
  /// **'Rückfrage offen'**
  String get trainerAppStatusNeedsInfo;

  /// Application status
  ///
  /// In de, this message translates to:
  /// **'Freigegeben'**
  String get trainerAppStatusApproved;

  /// Application status
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get trainerAppStatusRejected;

  /// Application status
  ///
  /// In de, this message translates to:
  /// **'Zurückgezogen'**
  String get trainerAppStatusWithdrawn;

  /// ICS share sheet title
  ///
  /// In de, this message translates to:
  /// **'Kalendereintrag für {title} importieren'**
  String calendarImportTitle(String title);

  /// Map attribution
  ///
  /// In de, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get osmAttribution;

  /// Location picker hint
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte'**
  String get trainerMapTapHint;

  /// Fallback trainer display name
  ///
  /// In de, this message translates to:
  /// **'Trainer'**
  String get trainerFallbackName;

  /// Chat channel title for client
  ///
  /// In de, this message translates to:
  /// **'Dein Trainer'**
  String get trainerYourTrainer;

  /// Chat channel title for trainer
  ///
  /// In de, this message translates to:
  /// **'Dein Nutzer'**
  String get trainerYourClient;

  /// Chat fallback title
  ///
  /// In de, this message translates to:
  /// **'Chat'**
  String get trainerChatFallback;

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'auth.uid: nicht eingeloggt'**
  String get trainerDiagNotSignedIn;

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'auth.uid: {id}'**
  String trainerDiagAuthUid(String id);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'email: {email}'**
  String trainerDiagEmail(String email);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'profiles.role: {role}'**
  String trainerDiagProfileRole(String role);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'profiles.display_name: {name}'**
  String trainerDiagProfileName(String name);

  /// Debug error line
  ///
  /// In de, this message translates to:
  /// **'{scope}: Fehler {error}'**
  String trainerDiagScopeError(String scope, String error);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'relationships gesamt: {count}'**
  String trainerDiagRelationshipsTotal(int count);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'relationships active: {count}'**
  String trainerDiagRelationshipsActive(int count);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'relationship statuses: {statuses}'**
  String trainerDiagRelationshipStatuses(String statuses);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'relationship client_ids:'**
  String get trainerDiagRelationshipClientIds;

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'appointments als trainer: {count}'**
  String trainerDiagAppointmentsAsTrainer(int count);

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'appointment trainee_ids:'**
  String get trainerDiagAppointmentTraineeIds;

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'reconcile_trainer_clients: ok'**
  String get trainerDiagReconcileOk;

  /// Debug line
  ///
  /// In de, this message translates to:
  /// **'get_trainer_clients rows: {count}'**
  String trainerDiagGetClientsRows(int count);

  /// Activation error
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Aktivieren: {error}'**
  String trainerActivateFailed(String error);

  /// Auth error shown in trainer flows
  ///
  /// In de, this message translates to:
  /// **'Nicht eingeloggt.'**
  String get trainerNotSignedIn;

  /// Short Moro package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'Moro'**
  String get trainerPkgMoro;

  /// Short spinal Galant label as shown on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'Spinal Galant'**
  String get trainerPkgSpinalGalant;

  /// Short TLR package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'TLR'**
  String get trainerPkgTlr;

  /// Short Babkin package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'Babkin'**
  String get trainerPkgBabkin;

  /// Short rooting-sucking package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'Such-Saug'**
  String get trainerPkgSuchSaug;

  /// Short ATNR package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'ATNR'**
  String get trainerPkgAtnr;

  /// Short STNR package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'STNR'**
  String get trainerPkgStnr;

  /// Short Babinski package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'Babinski'**
  String get trainerPkgBabinski;

  /// Short Landau package label on trainer clients list
  ///
  /// In de, this message translates to:
  /// **'Landau'**
  String get trainerPkgLandau;

  /// Chat channel type label for community channels
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get chatChannelTypeCommunity;

  /// Chat channel type label for trainer application review
  ///
  /// In de, this message translates to:
  /// **'Trainer-Bewerbung'**
  String get chatChannelTypeApplicationReview;

  /// Fallback display name when user name is missing
  ///
  /// In de, this message translates to:
  /// **'Nutzer'**
  String get chatUserFallback;

  /// Fallback display name for trainer applicants
  ///
  /// In de, this message translates to:
  /// **'Bewerber'**
  String get chatApplicantFallback;

  /// Chat inbox screen title
  ///
  /// In de, this message translates to:
  /// **'Trainer-Kommunikation'**
  String get chatInboxTitle;

  /// Section header for the linked trainer chat
  ///
  /// In de, this message translates to:
  /// **'MEIN TRAINER'**
  String get chatInboxSectionMyTrainer;

  /// Relative date label for yesterday
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get chatYesterday;

  /// Empty inbox/DM title when there are no chats
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten'**
  String get chatNoMessagesYet;

  /// Empty chat inbox body
  ///
  /// In de, this message translates to:
  /// **'Hier erscheinen deine Chats.\nVerbinde dich mit deinem Trainer, um Nachrichten und Video-Calls zu nutzen.'**
  String get chatInboxEmptyBody;

  /// FAB label to open trainer chat from DM screen
  ///
  /// In de, this message translates to:
  /// **'Chat mit Trainer'**
  String get dmChatWithTrainer;

  /// Empty DM list body
  ///
  /// In de, this message translates to:
  /// **'Hier erscheinen deine direkten Nachrichten mit deinem Trainer.'**
  String get dmEmptyBody;

  /// Direct chat title with partner name
  ///
  /// In de, this message translates to:
  /// **'Chat mit {name}'**
  String chatWithName(String name);

  /// Tooltip to start a video call as trainer
  ///
  /// In de, this message translates to:
  /// **'Call starten'**
  String get chatStartCall;

  /// Tooltip/action to request a video call
  ///
  /// In de, this message translates to:
  /// **'Video-Call anfragen'**
  String get chatRequestVideoCall;

  /// Confirm dialog title for video call request
  ///
  /// In de, this message translates to:
  /// **'Video-Call anfragen?'**
  String get chatRequestVideoCallTitle;

  /// Confirm dialog body for video call request
  ///
  /// In de, this message translates to:
  /// **'Du sendest deinem Trainer eine Anfrage für einen Video-Call. Der Trainer entscheidet, ob und wann er den Call startet.'**
  String get chatRequestVideoCallBody;

  /// Confirm button to send a video call request
  ///
  /// In de, this message translates to:
  /// **'Anfrage senden'**
  String get chatSendRequest;

  /// Error message when chat messages fail to load
  ///
  /// In de, this message translates to:
  /// **'Nachrichten konnten gerade nicht geladen werden. Bitte Verbindung prüfen.'**
  String get chatMessagesLoadFailed;

  /// Empty state inside a chat thread
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten.\nSchreib die erste!'**
  String get chatEmptyThread;

  /// Confirm dialog title for soft-deleting a message
  ///
  /// In de, this message translates to:
  /// **'Nachricht entfernen?'**
  String get chatDeleteMessageTitle;

  /// Confirm dialog body for soft-deleting a message
  ///
  /// In de, this message translates to:
  /// **'Die Nachricht wird für alle als entfernt angezeigt.'**
  String get chatDeleteMessageBody;

  /// Confirm button to remove a chat message
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get chatRemove;

  /// SnackBar when camera/mic permission is denied for calls
  ///
  /// In de, this message translates to:
  /// **'Kamera & Mikrofon-Zugriff erforderlich. Bitte in den Einstellungen erlauben.'**
  String get chatCameraMicPermissionRequired;

  /// SnackBar when starting a video call fails
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Starten des Calls: {error}'**
  String chatCallStartFailed(String error);

  /// SnackBar when appointment scheduler cannot be opened from chat
  ///
  /// In de, this message translates to:
  /// **'Terminplanung konnte nicht geöffnet werden.'**
  String get chatAppointmentOpenFailed;

  /// SnackBar when opening a chat channel fails
  ///
  /// In de, this message translates to:
  /// **'Chat konnte nicht geöffnet werden: {error}'**
  String chatOpenFailed(String error);

  /// Label on appointment proposal message bubble
  ///
  /// In de, this message translates to:
  /// **'Terminvorschlag'**
  String get chatAppointmentProposal;

  /// Button to view an appointment proposal from chat
  ///
  /// In de, this message translates to:
  /// **'Vorschlag ansehen'**
  String get chatViewProposal;

  /// Placeholder text for a soft-deleted message
  ///
  /// In de, this message translates to:
  /// **'Diese Nachricht wurde entfernt.'**
  String get chatMessageRemoved;

  /// Display name for system/assistant chat messages
  ///
  /// In de, this message translates to:
  /// **'Reflex Journey Assistent'**
  String get chatAssistantName;

  /// Outgoing call-request bubble when sender is trainer
  ///
  /// In de, this message translates to:
  /// **'Trainer-Anfrage gesendet'**
  String get chatCallRequestSentAsTrainer;

  /// Outgoing call-request bubble when sender is client
  ///
  /// In de, this message translates to:
  /// **'Video-Call-Anfrage gesendet'**
  String get chatCallRequestSentAsClient;

  /// Incoming call-request bubble shown to trainer
  ///
  /// In de, this message translates to:
  /// **'Nutzer möchte einen Video-Call'**
  String get chatCallRequestIncomingAsTrainer;

  /// Incoming call-request bubble shown to client
  ///
  /// In de, this message translates to:
  /// **'Trainer möchte einen Video-Call'**
  String get chatCallRequestIncomingAsClient;

  /// Hint text in the chat message input field
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben …'**
  String get chatMessageHint;

  /// Typing indicator label
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{tippt …} other{{count} tippen …}}'**
  String chatTyping(int count);

  /// Persisted chat message content for a video call request
  ///
  /// In de, this message translates to:
  /// **'📹 Video-Call angefragt'**
  String get chatCallRequestMessageContent;

  /// Learning-mode confirmation heading before an exercise
  ///
  /// In de, this message translates to:
  /// **'Bereit für die Bewegung?'**
  String get trainingReadyForMovement;

  /// Learning-mode confirmation guidance
  ///
  /// In de, this message translates to:
  /// **'Prüfe deine Position. Starte erst, wenn du dich sicher und stabil fühlst.'**
  String get trainingReadyBody;

  /// Button to replay or revisit the current instruction
  ///
  /// In de, this message translates to:
  /// **'Anleitung wiederholen'**
  String get trainingRepeatInstruction;

  /// Preparation countdown
  ///
  /// In de, this message translates to:
  /// **'Start in {seconds} Sekunden'**
  String trainingPreparationCountdown(int seconds);

  /// Current repetition counter
  ///
  /// In de, this message translates to:
  /// **'Wiederholung {current} von {total}'**
  String trainingRepetitionOf(int current, int total);

  /// Current phase counter
  ///
  /// In de, this message translates to:
  /// **'Phase {current} von {total}'**
  String trainingPhaseOf(int current, int total);

  /// Remaining time in the current training step
  ///
  /// In de, this message translates to:
  /// **'Noch {seconds} Sekunden'**
  String trainingTimeRemaining(int seconds);

  /// Voice asset content gate title
  ///
  /// In de, this message translates to:
  /// **'Sprachbegleitung noch nicht verfügbar'**
  String get trainingAudioContentUnavailableTitle;

  /// Transparent explanation when production voice assets are missing
  ///
  /// In de, this message translates to:
  /// **'Die geprüften Aufnahmen fehlen noch. Der Ablauf funktioniert visuell und haptisch; er ist derzeit nicht vollständig sprachgeführt.'**
  String get trainingAudioContentUnavailableBody;

  /// Universal professional exercise safety guidance
  ///
  /// In de, this message translates to:
  /// **'Stoppe bei Schmerzen, Schwindel, Übelkeit oder starkem Unwohlsein. Hole vor dem Fortsetzen fachlichen Rat ein.'**
  String get trainingSafetyStop;

  /// Lifecycle or audio interruption heading
  ///
  /// In de, this message translates to:
  /// **'Training pausiert'**
  String get trainingInterruptedTitle;

  /// Interruption recovery guidance
  ///
  /// In de, this message translates to:
  /// **'Die Zeit wurde angehalten. Prüfe deine Position und setze bewusst fort.'**
  String get trainingInterruptedBody;

  /// Atomic completion persistence in progress
  ///
  /// In de, this message translates to:
  /// **'Abschluss wird sicher gespeichert …'**
  String get trainingCompletionSaving;

  /// Recoverable completion persistence failure
  ///
  /// In de, this message translates to:
  /// **'Der Abschluss konnte noch nicht gespeichert werden. Deine Einheit bleibt lokal erhalten.'**
  String get trainingCompletionSaveFailed;

  /// Invalid or missing training content title
  ///
  /// In de, this message translates to:
  /// **'Training nicht verfügbar'**
  String get trainingContentUnavailableTitle;

  /// Safe empty-package explanation
  ///
  /// In de, this message translates to:
  /// **'Für dieses Paket liegt kein geprüfter Trainingsinhalt vor. Es wurde kein anderes Paket als Ersatz gestartet.'**
  String get trainingContentUnavailableBody;

  /// Checkpoint resume dialog title
  ///
  /// In de, this message translates to:
  /// **'Einheit fortsetzen?'**
  String get trainingResumeSessionTitle;

  /// Checkpoint resume dialog body
  ///
  /// In de, this message translates to:
  /// **'Eine unterbrochene Einheit wurde gefunden. Du kannst an derselben Stelle fortfahren oder neu beginnen.'**
  String get trainingResumeSessionBody;

  /// Resume checkpoint action
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get trainingResumeSession;

  /// Discard checkpoint and start over
  ///
  /// In de, this message translates to:
  /// **'Neu beginnen'**
  String get trainingStartOver;

  /// Training preflight authentication error
  ///
  /// In de, this message translates to:
  /// **'Melde dich an, bevor du eine Einheit startest.'**
  String get trainingSignInRequired;

  /// Training preflight enrollment error
  ///
  /// In de, this message translates to:
  /// **'Für dieses Paket wurde keine aktive Teilnahme gefunden. Starte oder aktiviere das Paket zuerst.'**
  String get trainingEnrollmentMissing;

  /// Training preflight progress error
  ///
  /// In de, this message translates to:
  /// **'Der Trainingsfortschritt ist noch nicht eingerichtet. Bitte synchronisiere erneut oder wende dich an den Support.'**
  String get trainingProgressMissing;

  /// Neutral side indicator
  ///
  /// In de, this message translates to:
  /// **'Seite {number}'**
  String trainingSideNumber(int number);

  /// Arm-cross indicator
  ///
  /// In de, this message translates to:
  /// **'Armkreuz {number}'**
  String trainingArmCrossNumber(int number);

  /// Honest empty state when no bundled music tracks exist
  ///
  /// In de, this message translates to:
  /// **'Für diese Version sind noch keine geprüften internen Musiktitel verfügbar.'**
  String get trainingMusicUnavailable;

  /// Exercise orientation heading
  ///
  /// In de, this message translates to:
  /// **'Orientierung'**
  String get trainingOrientationLabel;

  /// Exercise breathing heading
  ///
  /// In de, this message translates to:
  /// **'Atmung'**
  String get trainingBreathingLabel;

  /// Concise routine-mode instruction heading
  ///
  /// In de, this message translates to:
  /// **'Kurzhinweis'**
  String get trainingRoutineCueLabel;

  /// Exercise safety heading
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get trainingSafetyLabel;

  /// Reason routine mode is still locked
  ///
  /// In de, this message translates to:
  /// **'Nach zwei begleiteten Einheiten'**
  String get trainingRoutineLocked;

  /// First-session familiarity guidance title
  ///
  /// In de, this message translates to:
  /// **'Erster Durchlauf: in Ruhe kennenlernen'**
  String get trainingLearningFirstTitle;

  /// First-session familiarity guidance body
  ///
  /// In de, this message translates to:
  /// **'Der Lernmodus zeigt dir Position, Bewegung, Atmung und Sicherheit vollständig.'**
  String get trainingLearningFirstBody;

  /// Second-session familiarity guidance title
  ///
  /// In de, this message translates to:
  /// **'Zweiter Durchlauf: sicher festigen'**
  String get trainingLearningSecondTitle;

  /// Second-session familiarity guidance body
  ///
  /// In de, this message translates to:
  /// **'Du erhältst eine kompaktere Anleitung. Danach steht dir der Routinemodus zur Verfügung.'**
  String get trainingLearningSecondBody;

  /// Routine-mode recommendation title
  ///
  /// In de, this message translates to:
  /// **'Routinemodus ist verfügbar'**
  String get trainingRoutineReadyTitle;

  /// Routine-mode recommendation body
  ///
  /// In de, this message translates to:
  /// **'Du kennst den Ablauf. Nutze die automatische Führung oder bleibe bei der ausführlichen Anleitung.'**
  String get trainingRoutineReadyBody;

  /// Safe bundled snapshot while cache validation is pending
  ///
  /// In de, this message translates to:
  /// **'Der geprüfte Offline-Inhalt ist bereit. Aktualisierungen werden im Hintergrund geprüft.'**
  String get trainingContentChecking;

  /// Visible fallback notice for invalid, empty, or failed cache
  ///
  /// In de, this message translates to:
  /// **'Der lokale oder entfernte Cache war nicht verwendbar. Du trainierst mit dem geprüften Offline-Inhalt dieser Version.'**
  String get trainingOfflineSnapshotNotice;

  /// Invite screen app bar title
  ///
  /// In de, this message translates to:
  /// **'Einladen'**
  String get inviteTitle;

  /// Impact tree headline when no activations yet
  ///
  /// In de, this message translates to:
  /// **'Verschenke einen guten Start'**
  String get inviteTreeHeadlineZero;

  /// Impact tree headline with activation count
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Mensch ist über deine Einladung gestartet.} other{{count} Menschen sind über deine Einladung gestartet.}}'**
  String inviteTreeHeadline(int count);

  /// Hint under empty impact tree
  ///
  /// In de, this message translates to:
  /// **'Wenn jemand über deine Einladung sein erstes Training abschließt, wächst hier ein Zweig.'**
  String get inviteTreeEmptyHint;

  /// Explainer under the impact tree
  ///
  /// In de, this message translates to:
  /// **'Der Selbstcheck ist kostenlos, dauert fünf Minuten und braucht kein Konto. Du kannst ihn weitergeben.'**
  String get inviteWhy;

  /// Primary share button
  ///
  /// In de, this message translates to:
  /// **'Einladung teilen'**
  String get inviteShareAction;

  /// Label above personal invite code
  ///
  /// In de, this message translates to:
  /// **'Dein Code'**
  String get inviteCodeLabel;

  /// Snackbar after copying invite code
  ///
  /// In de, this message translates to:
  /// **'Code kopiert'**
  String get inviteCodeCopied;

  /// Privacy footnote on invite screen
  ///
  /// In de, this message translates to:
  /// **'Du erfährst nur, wie viele Menschen begonnen haben. Nie wer.'**
  String get invitePrivacyFootnote;

  /// Editable share sheet body including invite link
  ///
  /// In de, this message translates to:
  /// **'Falls du dich fragst, ob frühkindliche Reflexe bei euch eine Rolle spielen: Hier gibt es einen kostenlosen 5-Minuten-Check – ohne Anmeldung und ohne App. {link}'**
  String inviteShareMessage(String link);

  /// Semantics label for impact tree card; no branch count
  ///
  /// In de, this message translates to:
  /// **'Wachsender Baum. {count} Menschen sind über deine Einladung gestartet.'**
  String inviteTreeSemantics(int count);

  /// Offline error when invite overview or redeem needs network
  ///
  /// In de, this message translates to:
  /// **'Dafür braucht es kurz Internet. Versuch es später noch einmal.'**
  String get inviteErrorOffline;

  /// Settings entry title for invite feature
  ///
  /// In de, this message translates to:
  /// **'Freunde einladen'**
  String get inviteEntryTitle;

  /// Settings entry subtitle for invite feature
  ///
  /// In de, this message translates to:
  /// **'Den kostenlosen Selbstcheck weitergeben'**
  String get inviteEntrySubtitle;

  /// Invite impulse card title (I1/I2)
  ///
  /// In de, this message translates to:
  /// **'Verschenke einen guten Start'**
  String get impulseInviteTitle;

  /// Invite impulse card body
  ///
  /// In de, this message translates to:
  /// **'Kennst du jemanden, der sich dieselbe Frage stellt? Der 5-Minuten-Check ist kostenlos.'**
  String get impulseInviteBody;

  /// Onboarding / redeem screen headline
  ///
  /// In de, this message translates to:
  /// **'Hat dich jemand eingeladen?'**
  String get inviteRedeemQuestion;

  /// Paste invite code from clipboard
  ///
  /// In de, this message translates to:
  /// **'Aus Zwischenablage einfügen'**
  String get inviteRedeemPaste;

  /// Skip invite redeem during onboarding
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get inviteRedeemSkip;

  /// Confirm sheet title before redeem RPC
  ///
  /// In de, this message translates to:
  /// **'Einladung annehmen?'**
  String get inviteConfirmTitle;

  /// Confirm sheet privacy body
  ///
  /// In de, this message translates to:
  /// **'Die Person, die dich eingeladen hat, sieht später nur, dass eine weitere Person über ihre Einladung mit dem Training begonnen hat – niemals deinen Namen.'**
  String get inviteConfirmBody;

  /// Confirm sheet accept button
  ///
  /// In de, this message translates to:
  /// **'Einladung annehmen'**
  String get inviteConfirmAccept;

  /// Confirm sheet decline button
  ///
  /// In de, this message translates to:
  /// **'Nicht jetzt'**
  String get inviteConfirmDecline;

  /// Snackbar after successful redeem
  ///
  /// In de, this message translates to:
  /// **'Einladung angenommen.'**
  String get inviteRedeemSuccess;

  /// Redeem error: unknown_code
  ///
  /// In de, this message translates to:
  /// **'Diesen Code kennen wir nicht. Prüf bitte die Schreibweise.'**
  String get inviteErrorUnknownCode;

  /// Redeem error: code_inactive
  ///
  /// In de, this message translates to:
  /// **'Dieser Code ist nicht mehr gültig.'**
  String get inviteErrorCodeInactive;

  /// Redeem error: own_code
  ///
  /// In de, this message translates to:
  /// **'Das ist dein eigener Code.'**
  String get inviteErrorOwnCode;

  /// Redeem error: already_referred
  ///
  /// In de, this message translates to:
  /// **'Zu deinem Konto gehört schon eine Einladung.'**
  String get inviteErrorAlreadyReferred;

  /// Redeem error: account_too_old
  ///
  /// In de, this message translates to:
  /// **'Eine Einladung lässt sich nur in den ersten 30 Tagen eines Kontos annehmen.'**
  String get inviteErrorAccountTooOld;

  /// Neutral message for unexpected redeem/contract failures (not offline)
  ///
  /// In de, this message translates to:
  /// **'Das hat gerade nicht geklappt. Versuch es bitte später noch einmal.'**
  String get inviteErrorUnexpected;

  /// Text field label for invite code entry
  ///
  /// In de, this message translates to:
  /// **'Einladungscode'**
  String get inviteCodeFieldLabel;
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
