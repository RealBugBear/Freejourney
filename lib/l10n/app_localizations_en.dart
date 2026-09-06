// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Reflex Journey';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutInProgress => 'Saving and signing out…';

  @override
  String get signOutFailed => 'Could not sign out. Please try again.';

  @override
  String get signOutPendingTitle => 'Changes are not saved online';

  @override
  String get signOutPendingBody =>
      'Some changes are only saved on this device. Stay signed in and try again when you are online. If you sign out now, these unsent changes will be permanently deleted from this device.';

  @override
  String get signOutKeepChanges => 'Stay signed in';

  @override
  String get signOutDiscardChanges => 'Discard and sign out';

  @override
  String get languageSelectionTitle => 'Choose your language';

  @override
  String get languageSelectionSubtitle =>
      'You can change this later in Settings.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageContinue => 'Continue';

  @override
  String get tryShortAssessment =>
      'Try the short assessment without an account';

  @override
  String get signInWithAlternativeDivider => 'or';

  @override
  String get signInWithApple => 'Continue with Apple';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get authErrorSocialConfiguration =>
      'Social login is not configured correctly yet. Please contact support.';

  @override
  String get authErrorSocialCancelled => 'Sign-in was canceled.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSent => 'We\'ve sent you a password reset email.';

  @override
  String get signUpConfirmEmailSent =>
      'Almost there! We\'ve sent you an email to confirm your account. Please tap the link inside, then you can sign in.';

  @override
  String get loginDiscoverLead =>
      'Next, you\'ll discover your personal Reflex Profile — at your own pace.';

  @override
  String get consentShortTitle => 'A quick agreement';

  @override
  String get consentDiscoverLead =>
      'Then you\'ll discover your personal Reflex Profile — at your own pace.';

  @override
  String get consentRowSafety => 'Safety';

  @override
  String get consentRowTerms => 'Terms';

  @override
  String get consentRowPrivacy => 'Privacy';

  @override
  String get consentReadLinkHint => 'Read';

  @override
  String get consentCheckboxLabel =>
      'I have read the notices and agree to the Terms of Use and Privacy Policy.';

  @override
  String get consentDiscoverCta => 'Discover Reflex Profile';

  @override
  String get profileContactNameDiscoverBody =>
      'Your contact name is visible to trainers — then you\'ll discover your Reflex Profile.';

  @override
  String get profileContactNameDiscoverBodyWithCommunity =>
      'Your contact name is visible to trainers and can differ from your community name — then you\'ll discover your Reflex Profile.';

  @override
  String get authErrorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse => 'This email address is already registered.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 8 characters.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get startTraining => 'Start Session';

  @override
  String currentDay(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get dailyStreak => 'Regularity';

  @override
  String weeklyProgress(int count, int goal) {
    return '$count of $goal this week';
  }

  @override
  String get goldenDay => 'Golden Day';

  @override
  String daysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get trainingMode => 'Session Mode';

  @override
  String get tutorialMode => 'Learning Mode';

  @override
  String get routineMode => 'Routine Mode';

  @override
  String get silentMode => 'Silent';

  @override
  String get hapticMode => 'Haptic';

  @override
  String get voiceCuesMode => 'Voice & Cues';

  @override
  String get exercisePosition => 'Starting Position';

  @override
  String get exerciseMovement => 'Movement';

  @override
  String get exerciseHints => 'Tips';

  @override
  String exerciseReps(int count) {
    return '$count repetitions';
  }

  @override
  String get sessionComplete => 'Session Complete';

  @override
  String get sessionCompleteSubtitle => 'You\'ve completed today\'s session.';

  @override
  String get moodCheckIn => 'How are you feeling?';

  @override
  String get moodLabel => 'Mood';

  @override
  String get energyLabel => 'Energy';

  @override
  String get stressLabel => 'Stress';

  @override
  String get moodSkip => 'Skip';

  @override
  String get moodSubmit => 'Save';

  @override
  String get moodChartEmpty => 'Log a session to see your wellbeing over time.';

  @override
  String get intakeAssessmentTitle => 'Getting Started';

  @override
  String get intakeWelcomeTitle => 'Welcome to your Reflex Integration Program';

  @override
  String get intakeWelcomeBody =>
      'Reflex Journey guides you through the integration of prenatal reflexes — a process that can help transform deeply rooted physical and emotional patterns.';

  @override
  String get intakeTrainerTitle => 'Recommendation: Start with a Trainer';

  @override
  String get intakeTrainerBody =>
      'We recommend beginning and accompanying this program with a certified trainer. A trainer guides isometric partner exercises that support clear perception of direction, movement, and resistance. Without this guidance, the body usually needs more calm repetition.';

  @override
  String get intakeQuestionLabel => 'One question about your start';

  @override
  String get questionIsometricWithTrainer =>
      'Have you already completed isometric partner exercises with a trainer?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String durationRecommendation(int weeks) {
    return 'Recommended duration: $weeks weeks';
  }

  @override
  String get adjustDuration => 'Adjust Duration';

  @override
  String get confirm => 'Confirm';

  @override
  String get durationWithoutTrainerInfo =>
      'Without trainer guidance, we recommend about 8 weeks so the body has more time for integration.';

  @override
  String get durationTrainerMinimumInfo =>
      'With trainer guidance, we recommend at least 4 weeks. You can extend the duration if you want more integration time.';

  @override
  String get trainerOnboardingTitle => 'Trainer Guidance';

  @override
  String get trainerOnboardingFindTitle => 'Start with a trainer near you';

  @override
  String get trainerOnboardingFindBody =>
      'Because you have not completed isometric activation with a trainer yet, we recommend finding a suitable trainer first. You can still continue directly if you prefer.';

  @override
  String get trainerOnboardingConnectTitle => 'Connect with your trainer';

  @override
  String get trainerOnboardingConnectBody =>
      'If you have already worked with a trainer, you can connect now. This lets your trainer follow your progress and coordinate appointments when needed.';

  @override
  String get trainerOnboardingSearchCta => 'Find trainers nearby';

  @override
  String get trainerOnboardingInviteCta => 'Enter invite code';

  @override
  String get trainerOnboardingSkipCta => 'Do this later';

  @override
  String get trainerOnboardingInviteTitle => 'Connect with trainer';

  @override
  String get trainerOnboardingInviteBody =>
      'Enter the 6-character invite code you received from your trainer.';

  @override
  String get trainerOnboardingInviteInvalid =>
      'Please enter the 6-character code.';

  @override
  String get trainerOnboardingInviteFailed => 'Could not connect with trainer.';

  @override
  String get trainerOnboardingContinueAfterRequest =>
      'Continue to duration recommendation';

  @override
  String get completionQuestionnaireTitle => 'Final Reflection';

  @override
  String get completionCelebrationTitle => 'Package Complete';

  @override
  String get completionCelebrationSubtitle =>
      'You have followed this package for the planned time.';

  @override
  String get completionNextPackage => 'Continue to next package';

  @override
  String get completionBackToDashboard => 'Back to Dashboard';

  @override
  String get completionReachedTitle => 'Package duration reached';

  @override
  String get completionReachedBody =>
      'You have reached the planned package duration. Today now shows a short reflection so you can complete this package or repeat it for 7 more days.';

  @override
  String get completionPlaceholderQuestion =>
      'Placeholder reflection: Does this package feel ready to complete?';

  @override
  String get completionPass => 'Complete package';

  @override
  String get completionInsufficient => 'Repeat 7 more days';

  @override
  String get completionMoroReturnSubtitle =>
      'The repeated Moro cycle is complete. You will now return to the interrupted package and restart it at day 1.';

  @override
  String get completionBackToInterruptedPackage =>
      'Back to interrupted package';

  @override
  String get completionExtendedTitle => 'One more week';

  @override
  String get completionExtendedSubtitle =>
      'You have 7 more days in this package.';

  @override
  String get completionQuestion =>
      'Since starting this package, have you noticed stronger emotional or stress-related reactions, and could you understand or regulate them a little more clearly?';

  @override
  String get completionYes => 'Yes, I\'m ready';

  @override
  String get completionNotYet => 'Not yet';

  @override
  String get packages => 'Program';

  @override
  String get packageLocked => 'Locked';

  @override
  String get packageCurrent => 'Current';

  @override
  String get packageCompleted => 'Completed';

  @override
  String get paywallTitle => 'Unlock all packages';

  @override
  String get paywallSubtitle =>
      'Package 1 stays free forever. Premium unlocks every further reflex package — for you and your family profiles.';

  @override
  String get paywallDurationNote =>
      'The full program typically takes 10–12 months — at your pace, pauses included.';

  @override
  String get paywallMonthlyTitle => 'Monthly';

  @override
  String get paywallPerMonth => 'per month';

  @override
  String get paywallYearlyTitle => 'Yearly';

  @override
  String get paywallPerYear => 'per year';

  @override
  String get paywallYearlyBadge => '2 months free';

  @override
  String get paywallLifetimeTitle => 'One-time';

  @override
  String get paywallOnce => 'one-time, forever';

  @override
  String get paywallUnlock => 'Unlock';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallNotAvailable =>
      'Purchases are not available in this version yet.';

  @override
  String get paywallCancelNote => 'Subscriptions can be canceled anytime.';

  @override
  String get packageAvailable => 'Available';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTraining => 'Sessions';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsWeeklyGoal => 'Weekly Goal';

  @override
  String get settingsChildAssist => 'Child-Assist Mode';

  @override
  String get settingsConnectTrainer => 'Connect to Trainer';

  @override
  String get moroRestartSettingsTitle => 'Back to Moro';

  @override
  String get moroRestartSettingsSubtitle =>
      'Restart Moro for 4 weeks and interrupt the current package.';

  @override
  String get moroRestartTitle => 'Return to Moro?';

  @override
  String get moroRestartBody =>
      'Unlike many other reflexes, the Moro reflex can be reactivated by highly stressful or traumatic events, for example a car accident, the death of a loved one, or other intense shock experiences.\n\nIf you continue, your current package will be interrupted. You will restart Moro for 4 weeks. After completing Moro, you will return to the interrupted package and begin there again at day 1.';

  @override
  String get moroRestartConfirm => 'Restart Moro';

  @override
  String get reminderEnabled => 'Reminders enabled';

  @override
  String get reminderWindow => 'Reminder window';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get reminderFrom => 'From';

  @override
  String get reminderTo => 'To';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String weeklyGoalSessions(int goal) {
    return '$goal sessions/week';
  }

  @override
  String get settingsFeedback => 'Session Feedback';

  @override
  String get settingsAccount => 'Account';

  @override
  String get disclaimer => 'Health Notice';

  @override
  String get disclaimerText =>
      'These units do not replace medical treatment. Please consult a doctor if you have health concerns. Listen to your body and take breaks when needed.';

  @override
  String get disclaimerAccept => 'Understood, continue';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoNetwork => 'No internet connection.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get trainerClients => 'My Clients';

  @override
  String get trainerNoClients => 'No clients linked yet.';

  @override
  String get trainerNoClientsHint =>
      'Generate an invite code and share it with your client.';

  @override
  String get trainerInviteCode => 'Invite Code';

  @override
  String get trainerInviteCodeHint =>
      'Share this code with your client. It can be used once.';

  @override
  String get trainerGenerateCode => 'New Invite';

  @override
  String get trainerCopyCode => 'Copy Code';

  @override
  String get trainerCodeCopied => 'Code copied to clipboard.';

  @override
  String get trainerAtRisk => 'at risk';

  @override
  String trainerLastActive(int days) {
    return '${days}d ago';
  }

  @override
  String get trainerNotes => 'Trainer Notes';

  @override
  String get trainerNotesHint => 'Private notes about this client...';

  @override
  String get trainerNotesSaved => 'Notes saved.';

  @override
  String get trainerRecentSessions => 'Recent Sessions (30 days)';

  @override
  String get trainerNoSessions => 'No sessions in the last 30 days.';

  @override
  String get trainerView => 'Trainer View';

  @override
  String get connectToTrainer => 'Connect to Trainer';

  @override
  String get enterInviteCode => 'Enter invite code';

  @override
  String get connectToTrainerSuccess => 'Connected to trainer!';

  @override
  String get connectToTrainerError => 'Invalid or expired invite code.';

  @override
  String get loading => 'Loading...';

  @override
  String get skip => 'Skip';

  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String weeksCount(int count) {
    return '$count weeks';
  }

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get thisWeek => 'This Week';

  @override
  String get journal => 'Journal';

  @override
  String get journalEmptyTitle => 'No entries yet.';

  @override
  String get journalEmptySubtitle =>
      'Write down what you observe in daily life — after a session or whenever you like.';

  @override
  String get journalEmptyHint =>
      'Keep track of what changes in your daily life.';

  @override
  String get journalNewEntry => 'New Note';

  @override
  String get journalPostTrainingTitle => 'Changes in everyday life?';

  @override
  String get journalPostTrainingHint =>
      'Have you noticed anything — in your sleep, your reactions, your body awareness?';

  @override
  String get journalPlaceholder => 'Write your observation here...';

  @override
  String get journalLoadFailed => 'Could not load entries.';

  @override
  String get moodHistory => 'Mood History';

  @override
  String get profile => 'Profile';

  @override
  String get completionBannerTitle => 'Package ready for assessment';

  @override
  String get completionBannerSubtitle =>
      'Answer the short questionnaire to complete this package or extend it by 7 days.';

  @override
  String get settingsDataSync => 'Data & Sync';

  @override
  String get settingsTrainingModeDescription =>
      'Tutorial is ideal when you\'re getting started. Routine is more compact.';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsResetIntroductions => 'Show introductions again';

  @override
  String get settingsResetIntroductionsDescription =>
      'Shows the short tips for Today, Progress, Guidance, and Profile again.';

  @override
  String get settingsResetIntroductionsSuccess =>
      'Introductions will be shown again.';

  @override
  String get syncStatusOk => 'All synced';

  @override
  String syncStatusPending(int count) {
    return '$count entries pending';
  }

  @override
  String syncStatusFailed(int count) {
    return '$count entries failed';
  }

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get syncNow => 'Sync now';

  @override
  String get errorSaveFailed => 'Save failed. Please try again.';

  @override
  String get errorLoadFailed => 'Failed to load data.';

  @override
  String get errorLoadFailedInline => 'Failed to load';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationInvalidEmail => 'Please enter a valid email address.';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileChangePasswordSent => 'Password reset email sent.';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordConfirm => 'Confirm password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get passwordChanged => 'Password changed successfully.';

  @override
  String get passwordSet => 'Password set. Please log in.';

  @override
  String get authErrorSamePassword =>
      'New password must differ from the current one.';

  @override
  String get authErrorInvalidCurrentPassword =>
      'Current password is incorrect.';

  @override
  String get validationPasswordMismatch => 'Passwords do not match.';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteAccountTitle => 'Delete Account?';

  @override
  String get profileDeleteAccountBody =>
      'This permanently deletes your account and all your data. This cannot be undone.';

  @override
  String get profileDeleteAccountConfirm => 'Delete permanently';

  @override
  String get profileDeleteAccountSuccess => 'Account deleted.';

  @override
  String get profileDeleteAccountError =>
      'Could not delete account. Please contact support.';

  @override
  String get redeemAccessCodeTitle => 'Redeem access code';

  @override
  String get redeemAccessCodeSubtitle =>
      'Use a benefit code for Premium or Studio.';

  @override
  String get redeemAccessCodeDialogBody =>
      'A code may grant Premium or Studio access directly or identify a store offer.';

  @override
  String get redeemAccessCodeHint => 'Enter code';

  @override
  String get redeemAccessCodeAction => 'Redeem';

  @override
  String get redeemAccessCodeSuccess =>
      'Code redeemed. Premium access is active. This is not a subscription and there is no automatic charge.';

  @override
  String get redeemAccessCodeBenefitPremium => 'Premium';

  @override
  String get redeemAccessCodeBenefitStudio => 'Studio';

  @override
  String redeemAccessCodeInternalGrantSuccess(String benefit) {
    return 'Code redeemed. $benefit access is active. This is not a subscription and there is no automatic charge.';
  }

  @override
  String redeemAccessCodeInternalGrantUntil(String benefit, String date) {
    return 'Code redeemed. $benefit access is active until $date. This is not a subscription and there is no automatic charge.';
  }

  @override
  String get redeemAccessCodeStoreOfferPending =>
      'Store offer recognized. Access is not active yet. The offer flow will be available in a later version.';

  @override
  String get redeemAccessCodeUnknownBenefit =>
      'The code was recognized, but access could not be confirmed. No access was activated. Please contact support.';

  @override
  String get redeemAccessCodeErrorInvalid => 'This code is invalid.';

  @override
  String get redeemAccessCodeErrorUsed =>
      'This code has already been redeemed.';

  @override
  String get redeemAccessCodeErrorExpired => 'This code has expired.';

  @override
  String get redeemAccessCodeErrorUnsupported =>
      'This code type is not supported yet.';

  @override
  String get redeemAccessCodeErrorCampaignInactive =>
      'This benefit campaign is no longer active.';

  @override
  String get redeemAccessCodeErrorRoleNotEligible =>
      'This code is not available for your account role.';

  @override
  String get redeemAccessCodeErrorLimitReached =>
      'This code has reached its redemption limit.';

  @override
  String get redeemAccessCodeErrorOfferUnavailable =>
      'No store offer is available for this code on your device.';

  @override
  String get redeemAccessCodeErrorInvalidPlatform =>
      'This code cannot be redeemed on this device.';

  @override
  String get redeemAccessCodeErrorServiceUnavailable =>
      'Code redemption is temporarily unavailable. Please try again later.';

  @override
  String get redeemAccessCodeErrorUnauthorized =>
      'Please sign in again and try once more.';

  @override
  String get redeemAccessCodeErrorUnknown =>
      'Code redemption failed. Please try again.';

  @override
  String get trainerDashboard => 'Trainer Dashboard';

  @override
  String get trainerTabTrainees => 'Clients';

  @override
  String get trainerTabCalendar => 'Calendar';

  @override
  String get trainerMyLink => 'My Invite Link';

  @override
  String get trainerCopyLink => 'Copy Link';

  @override
  String get trainerLinkCopied => 'Link copied.';

  @override
  String get trainerScheduleAppointment => 'Schedule';

  @override
  String get trainerBookNow => 'Book Now';

  @override
  String get trainerAppointmentMissing => 'Appointment Missing';

  @override
  String get trainerNoAppointments => 'No appointments scheduled.';

  @override
  String get appointmentSchedulerTitle => 'Book Appointment';

  @override
  String appointmentWith(String name) {
    return 'Appointment with $name';
  }

  @override
  String get appointmentSessionTitle => 'Isometric Partner Exercise';

  @override
  String get appointmentFreeSlotsTitle => 'Free slots (next 14 days):';

  @override
  String get appointmentBook => 'Book';

  @override
  String get appointmentOtherTime => 'Choose different time';

  @override
  String get appointmentLocationLabel => 'Location (optional)';

  @override
  String get appointmentNotesLabel => 'Note';

  @override
  String get appointmentConfirmButton => 'Book Appointment';

  @override
  String get appointmentLoadingSlots => 'Searching for free slots...';

  @override
  String get appointmentNoFreeSlots => 'No free slots found.';

  @override
  String get appointmentNoCalendars => 'No calendars found.';

  @override
  String get appointmentSelectCalendarTitle => 'Select Work Calendar';

  @override
  String get appointmentSelectCalendarSubtitle =>
      'Select the calendar for Reflex Journey appointments.';

  @override
  String get appointmentStatusPlanned => 'Planned';

  @override
  String get appointmentStatusConfirmed => 'Confirmed';

  @override
  String get appointmentStatusCancelled => 'Canceled';

  @override
  String get appointmentStatusDone => 'Completed';

  @override
  String get appointmentOpenInCalendar => 'Open in Calendar';

  @override
  String get trainerRequestsTitle => 'Requests';

  @override
  String get trainerRequestNoRequests => 'No pending requests.';

  @override
  String get trainerRequestAccept => 'Accept';

  @override
  String get trainerRequestDecline => 'Decline';

  @override
  String get trainerDiscoveryTitle => 'Find Trainer';

  @override
  String trainerDiscoveryRadiusLabel(int radius) {
    return '$radius km';
  }

  @override
  String get trainerDiscoveryAll => 'All';

  @override
  String get trainerDiscoveryNearby => 'Nearby';

  @override
  String get trainerDiscoveryTabMap => 'Map';

  @override
  String get trainerDiscoveryTabList => 'List';

  @override
  String get trainerDiscoverySearchHint => 'Search trainers';

  @override
  String get trainerDiscoveryNoMatches => 'No matches.';

  @override
  String get trainerDiscoveryLocationCtaText =>
      'Find trainers near you. Your location is only used for this search and never stored.';

  @override
  String get trainerDiscoveryLocationCtaButton => 'Use my location';

  @override
  String get trainerDiscoveryServiceDisabled =>
      'Your device\'s location services are turned off. Turn them on to find trainers near you.';

  @override
  String get trainerDiscoveryOpenLocationSettings => 'Location settings';

  @override
  String get trainerDiscoveryDenied =>
      'Without location access we show all trainers without a distance filter.';

  @override
  String get trainerDiscoveryDeniedForever =>
      'Location access is disabled for the app. You can allow it again in Settings.';

  @override
  String get trainerDiscoveryOpenAppSettings => 'Open settings';

  @override
  String get trainerDiscoveryLocationError =>
      'We couldn\'t determine your location. Please try again in a moment.';

  @override
  String get trainerDiscoveryRetry => 'Try again';

  @override
  String get trainerDiscoveryEmptyGlobalTitle => 'No trainers approved yet';

  @override
  String get trainerDiscoveryEmptyGlobalBody =>
      'We\'re reviewing and approving the first trainers right now. Check back soon — your training continues without a trainer.';

  @override
  String get trainerDiscoveryEmptyGlobalCta => 'Back to training';

  @override
  String get trainerDiscoveryEmptyNearbyTitle => 'No trainers near you';

  @override
  String get trainerDiscoveryEmptyNearbyBody =>
      'Widen the radius or view all trainers.';

  @override
  String get trainerDiscoveryEmptyNearbyCta => 'Show all trainers';

  @override
  String get trainerDiscoveryLoadErrorTitle => 'Couldn\'t load trainers';

  @override
  String get trainerDiscoveryLoadErrorBody =>
      'Check your internet connection and try again.';

  @override
  String get trainerDiscoveryOfflineBanner =>
      'You\'re offline — the map needs an internet connection.';

  @override
  String trainerDiscoveryDistanceLabel(double distance) {
    return '$distance km away';
  }

  @override
  String get trainerDiscoveryRequestAlreadySent => 'Request already sent.';

  @override
  String get trainerDiscoveryRequestAlreadyConnected =>
      'You are already connected with this trainer.';

  @override
  String get trainerDiscoveryRequestSent => 'Request sent.';

  @override
  String get trainerDiscoverySendRequest => 'Send request';

  @override
  String get trainerPublicProfileTitle => 'Trainer Profile';

  @override
  String get trainerPublicProfileVerified => 'Verified trainer';

  @override
  String get trainerSetupTitle => 'Trainer Profile';

  @override
  String get trainerSetupDisplayNameLabel => 'Display name';

  @override
  String get trainerSetupBioLabel => 'Bio';

  @override
  String get trainerSetupEmailLabel => 'Email';

  @override
  String get trainerSetupPhoneLabel => 'Phone';

  @override
  String get trainerSetupLocationTitle => 'Location';

  @override
  String get trainerSetupLocationHint =>
      'Choose your trainer location so clients can find you nearby.';

  @override
  String get trainerSetupLocationMissing => 'Please choose a location.';

  @override
  String get trainerSetupSubmit => 'Submit for review';

  @override
  String get trainerSetupPendingTitle => 'Profile under review';

  @override
  String get trainerSetupPendingBody =>
      'We will notify you once your trainer profile is approved.';

  @override
  String get adminTrainerReviewTab => 'Trainer Review';

  @override
  String get adminTrainerNoPending => 'No trainer profiles pending review.';

  @override
  String get adminTrainerApproveSuccess => 'Trainer approved.';

  @override
  String get adminTrainerSuspendSuccess => 'Trainer suspended.';

  @override
  String get adminTrainerApprove => 'Approve';

  @override
  String get adminTrainerSuspend => 'Suspend';

  @override
  String get saving => 'Saving…';

  @override
  String get entryPointsTitle => 'Many Paths Lead Here';

  @override
  String get entryPointsSubtitle =>
      'Reflex integration matters to very different people. See what sounds like you.';

  @override
  String get entryPointsChipQuestion =>
      'What sounds familiar to you? (optional, choose any)';

  @override
  String get entryPointsSelectionNote =>
      'Your selection doesn\'t change your training — it helps us understand who uses the app.';

  @override
  String get entryPointsShowMore => 'More';

  @override
  String get entryPointsShowLess => 'Less';

  @override
  String get entryPointsBodyTitle => 'Body & Tension';

  @override
  String get entryPointsBodyTeaser =>
      'Muscle tension, posture patterns, a therapist\'s recommendation';

  @override
  String get entryPointsBodyDetail =>
      'Active reflex patterns can keep muscles in constant tension — independent of outside triggers. Physical and occupational therapists often recommend reflex integration exercises alongside their own work when recurring patterns don\'t fully release.\n\nTypical signs: chronic back or neck tension, jaw tension, posture patterns that keep coming back.';

  @override
  String get entryPointsBodyChip => 'Body';

  @override
  String get entryPointsBodySource =>
      'See Goddard Blythe: Reflexes, Learning and Behavior';

  @override
  String get entryPointsCoordinationTitle => 'Coordination & Performance';

  @override
  String get entryPointsCoordinationTeaser =>
      'Movement quality, balance, athletic coordination';

  @override
  String get entryPointsCoordinationDetail =>
      'Unintegrated reflexes tie up motor resources — which can show up as limited coordination, slower reactions, or balance difficulties. Athletes use reflex integration to move past coordination limits that regular training alone doesn\'t reach.\n\nTypical signs: movements feel harder than they should, asymmetries, balance under pressure.';

  @override
  String get entryPointsCoordinationChip => 'Coordination';

  @override
  String get entryPointsCoordinationSource =>
      'See Blomberg: Movements That Heal';

  @override
  String get entryPointsEmotionTitle => 'Emotional Regulation & Inner Life';

  @override
  String get entryPointsEmotionTeaser =>
      'Stress responses, sensory sensitivity, self-awareness';

  @override
  String get entryPointsEmotionDetail =>
      'Some reflex patterns directly influence how the nervous system responds to stimulation — stress sensitivity, emotional reactivity, sensory overload. Rhythmic movement can help the nervous system settle and open access to inner states.\n\nTypical signs: quick emotional flooding, difficulty winding down, body tension under stress. This varies greatly from person to person.';

  @override
  String get entryPointsEmotionChip => 'Emotional Regulation';

  @override
  String get entryPointsEmotionSource => 'See Blomberg: Movements That Heal';

  @override
  String get entryPointsChildTitle => 'My Child: School & Development';

  @override
  String get entryPointsChildTeaser => 'Focus, learning, school — as a parent';

  @override
  String get entryPointsChildDetail =>
      'Early reflex patterns that were never fully integrated can show up later as difficulties with reading, writing, or concentration — often without a clear physical cause.\n\nTypical signs: your child struggles to keep up at school, finds it hard to focus, is restless in class, or finds fine motor tasks or reading a real effort.';

  @override
  String get entryPointsChildChip => 'My Child';

  @override
  String get entryPointsChildSource =>
      'See Goddard Blythe: Reflexes, Learning and Behavior';

  @override
  String get entryPointsCuriosityTitle => 'Curiosity & Exploration';

  @override
  String get entryPointsCuriosityTeaser =>
      'No specific concern — just exploring';

  @override
  String get entryPointsCuriosityDetail =>
      'Some people arrive without a specific symptom — they\'ve heard about reflex integration and are curious what several weeks of rhythmic movement will change. That is a completely valid way to start.\n\nYou don\'t need to name a \"problem\" to begin the training.';

  @override
  String get entryPointsCuriosityChip => 'Just Curious';

  @override
  String get forWhomTitle => 'Who Are You Training For?';

  @override
  String get forWhomSubtitle => 'You can add more profiles at any time.';

  @override
  String get forWhomSelfTitle => 'For Myself';

  @override
  String get forWhomSelfSubtitle => 'Create your own adult profile';

  @override
  String get forWhomChildTitle => 'For My Child';

  @override
  String get forWhomChildSubtitle => 'Create a child profile';

  @override
  String get forWhomChildNameLabel => 'Name or nickname';

  @override
  String get forWhomBirthDateLabel => 'Date of birth *';

  @override
  String get forWhomBirthDateHelper => 'Required — used for age-based results';

  @override
  String get forWhomBirthDatePickerHelp => 'Select date of birth';

  @override
  String get forWhomSelectDate => 'Select date';

  @override
  String get forWhomCreateChildProfile => 'Create Child Profile';

  @override
  String get forWhomMissingFields => 'Please enter a name and date of birth.';

  @override
  String forWhomCreateError(String error) {
    return 'Could not create the profile: $error';
  }

  @override
  String forWhomReflexProfileSheetTitle(String name) {
    return 'Create a reflex profile for $name?';
  }

  @override
  String get forWhomReflexProfileSheetBody =>
      'The questionnaire takes about 10–15 minutes and helps us recommend the right training.';

  @override
  String get forWhomStartReflexProfile => 'Start the Reflex Profile Now';

  @override
  String get forWhomLaterToTraining => 'Later — Straight to Training';

  @override
  String get gotIt => 'Got It';

  @override
  String get today => 'Today';

  @override
  String get packageShortMoro => 'Moro';

  @override
  String get packageShortSpinalGalant => 'Spinal Galant';

  @override
  String get packageShortTlr => 'TLR';

  @override
  String get packageShortBabkin => 'Babkin';

  @override
  String get packageShortSuchSaug => 'Rooting-Sucking';

  @override
  String get packageShortAtnr => 'ATNR';

  @override
  String get packageShortStnr => 'STNR';

  @override
  String get packageShortBabinski => 'Babinski';

  @override
  String get packageShortLandau => 'Landau';

  @override
  String get dashboardRoutineTipTitle => 'You Know the Exercises Now';

  @override
  String get dashboardRoutineTipBody =>
      'Try Routine Mode — it guides you through the whole training hands-free, by audio.';

  @override
  String get dashboardLogUnitTitle => 'Log Session';

  @override
  String get dashboardLogUnitBody =>
      'Today\'s session will be logged. Right after, you can tune in and note down what you observe.';

  @override
  String get dashboardLogUnitConfirm => 'Log Today\'s Practice';

  @override
  String get dashboardLogUnitSuccess => 'Today\'s session has been logged.';

  @override
  String dashboardLogUnitError(String error) {
    return 'The session could not be logged: $error';
  }

  @override
  String get reminderSessionTitle => 'Time for Your Session';

  @override
  String get reminderSessionBody => 'Take a moment for today\'s session.';

  @override
  String get dashboardJointTrainingTitle => 'Train Together?';

  @override
  String get dashboardJointTrainingBody =>
      'These children have the same active package. After training, should the session be logged for them as well?';

  @override
  String get dashboardJointTrainingOnlyThis => 'Only This Profile';

  @override
  String get dashboardJointTrainingTogether => 'Log Together';

  @override
  String get dashboardVorrunde => 'Warm-Up Round';

  @override
  String dashboardPackageHeadline(String name) {
    return '$name Package';
  }

  @override
  String get dashboardNoActivePackage => 'No Active Package Yet';

  @override
  String get dashboardCompletedToday => 'Completed Today';

  @override
  String get dashboardVorrundeReady =>
      'You\'ve reached the four weeks of warm-up rounds. You can start Moro now.';

  @override
  String get dashboardVorrundeIntro =>
      'The warm-up round prepares you rhythmically for Moro. You can continue it or start Moro whenever you\'re ready.';

  @override
  String get dashboardStartMoroNow => 'Start Moro Now';

  @override
  String get dashboardContinueVorrunde => 'Continue Warm-Up';

  @override
  String get dashboardStartMoroAnyway => 'Start Moro Anyway';

  @override
  String dashboardDayOfTotal(int current, int total) {
    return 'Day $current of $total';
  }

  @override
  String dashboardMovementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movements',
      one: '1 movement',
    );
    return '$_temp0';
  }

  @override
  String dashboardEstimatedMinutes(int minutes) {
    return 'approx. $minutes min';
  }

  @override
  String get dashboardRegularityNote =>
      'The movements deliberately stay the same. Regularity matters more than intensity.';

  @override
  String get dashboardBeginUnit => 'Begin Session';

  @override
  String get dashboardDocumentExperience => 'Log Your Experience';

  @override
  String get dashboardDoneToday => 'Done Today';

  @override
  String get dashboardRoutineModeButton => 'Routine Mode';

  @override
  String get dashboardVorrundeCalm => 'Calming Warm-Up';

  @override
  String get dashboardDidBothToday => 'Package training and warm-up done today';

  @override
  String get dashboardDidVorrundeToday => 'Warm-up done today';

  @override
  String get dashboardCreateFirstProfileHint =>
      'Create your first reflex profile to get started.';

  @override
  String get dashboardCreateFirstProfile => 'Create First Profile';

  @override
  String get dashboardStartPackageHint =>
      'Your profile is ready. Start a package now to build your rhythm.';

  @override
  String get dashboardStartPackage => 'Start Package';

  @override
  String get dashboardImpulseRegularity =>
      'Today isn\'t about perfection — it\'s about regularity.';

  @override
  String get dashboardImpulseObserve => 'Observe without judging.';

  @override
  String get dashboardImpulseSlowIsEnough => 'Slow and regular is enough.';

  @override
  String get dashboardImpulseNextStep => 'Here is your next calm step.';

  @override
  String get dashboardImpulsePerceive => 'Notice what is here today.';

  @override
  String get dashboardImpulseRhythm =>
      'A calm rhythm gives the body something to hold on to.';

  @override
  String get dashboardImpulseShortUnit => 'A short session beats pressure.';

  @override
  String dashboardPracticedOfWeek(int count) {
    return '$count/7 practiced';
  }

  @override
  String dashboardProposalsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open appointment proposals',
      one: '1 open appointment proposal',
    );
    return '$_temp0';
  }

  @override
  String dashboardNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String dashboardProposalBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count New Appointment Proposals',
      one: 'New Appointment Proposal',
    );
    return '$_temp0';
  }

  @override
  String dashboardProposalBannerBody(String name) {
    return '$name suggested appointment times for you.';
  }

  @override
  String get dashboardSwitchProfile => 'Switch Profile';

  @override
  String get profileBadgeSelf => 'Me';

  @override
  String get profileBadgeChild => 'Child';

  @override
  String get dashboardAddProfile => 'Add Profile';

  @override
  String get trainingIntroTitle => 'Welcome to Your Session';

  @override
  String get trainingIntroDescription =>
      'Today, you\'ll practice seven movements at a calm pace.';

  @override
  String get trainingIntroRegularity =>
      'Consistency matters more than intensity.';

  @override
  String get trainingIntroMovementCount => '7 movements';

  @override
  String get trainingIntroDuration => 'About 15–20 minutes';

  @override
  String get trainingIntroClothing => 'Comfortable clothing recommended';

  @override
  String trainingProgressSemantics(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Progress: step $current of $total.',
      one: 'Progress: step $current of 1.',
    );
    return '$_temp0';
  }

  @override
  String get trainingExitTooltip => 'Exit Session';

  @override
  String get trainingContinueToMovement => 'Continue to Movement';

  @override
  String get trainingHintTitle => 'Tip';

  @override
  String trainingRepetitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repetitions',
      one: '1 repetition',
    );
    return '$_temp0';
  }

  @override
  String get trainingStartExercise => 'Start Exercise';

  @override
  String get trainingAbortTitle => 'Exit Session?';

  @override
  String get trainingAbortBody =>
      'Are you sure you want to exit this session? Your progress will be lost.';

  @override
  String get trainingAbortStay => 'Keep Training';

  @override
  String get trainingAbortConfirm => 'Exit Session';

  @override
  String trainingFeedbackModeActivated(String label) {
    return '$label mode enabled.';
  }

  @override
  String get trainingFeedbackVoice => 'Voice';

  @override
  String get trainingFeedbackSounds => 'Sounds';

  @override
  String get trainingFeedbackHaptics => 'Haptics';

  @override
  String get trainingFeedbackSilent => 'Silent';

  @override
  String trainingTempoAnnouncement(String seconds) {
    return 'Tempo: $seconds seconds.';
  }

  @override
  String trainingExerciseDurationSemantics(int seconds, int repetitions) {
    return 'Exercise duration: $seconds seconds and $repetitions repetitions.';
  }

  @override
  String trainingRepeatCount(int count) {
    return 'Repeat $count×';
  }

  @override
  String get trainingAnimationSemantics =>
      'Exercise animation. It starts automatically and can be paused or restarted.';

  @override
  String get trainingAutoplayHint => 'Starts automatically. Pause if needed.';

  @override
  String trainingTempoFeedbackSummary(String seconds, String feedback) {
    return 'Tempo: ${seconds}s  •  Feedback: $feedback';
  }

  @override
  String get trainingFastTempoWarning =>
      'Very fast tempo active. Focus on controlled movement.';

  @override
  String get trainingAdaptiveSuggestion => 'Adaptive suggestion active';

  @override
  String get trainingTempoSlowerSemantics => 'Slow Down Tempo';

  @override
  String get trainingTempoFasterSemantics => 'Speed Up Tempo';

  @override
  String trainingSecondsValue(String seconds) {
    return '$seconds seconds';
  }

  @override
  String get trainingSlower => 'Slower';

  @override
  String get trainingFaster => 'Faster';

  @override
  String get trainingFeedbackChangeSemantics => 'Change Feedback Mode';

  @override
  String get trainingControlsHint =>
      'Adjust tempo and feedback here with a tap.';

  @override
  String get trainingCompleteExercise => 'Complete Exercise';

  @override
  String get trainingContinueNextExercise => 'Continue to the Next Exercise';

  @override
  String get trainingSwitchCueUpper => 'SWITCH!';

  @override
  String get trainingPauseCue => 'Rest...';

  @override
  String get trainingHoldCueUpper => 'HOLD';

  @override
  String trainingExerciseOfTotalCompact(int current, int total) {
    return 'Exercise $current · $total total';
  }

  @override
  String get trainingPause => 'Pause';

  @override
  String get trainingRest => 'Rest';

  @override
  String get trainingResume => 'Resume';

  @override
  String get trainingRestart => 'Restart';

  @override
  String trainingSecondsOf(int count) {
    return 'of $count sec.';
  }

  @override
  String trainingBeatsOf(int count) {
    return 'of $count beats';
  }

  @override
  String trainingHoldTime(int seconds) {
    return '${seconds}s hold';
  }

  @override
  String trainingSecondsPerBeat(String seconds) {
    return '${seconds}s / beat';
  }

  @override
  String get trainingMusic => 'Music';

  @override
  String get trainingMusicOn => 'Music On';

  @override
  String get trainingSessionExitUnsaved =>
      'Your current position is saved on this device. Do you want to leave the session?';

  @override
  String get trainingReminderSessionBody =>
      'Take a moment for today\'s reflex integration session.';

  @override
  String get trainingProfileSkipTitle => 'Skip the Reflex Profile?';

  @override
  String get trainingProfileSkipBody =>
      'Continue without a personal reflex profile to assess your current starting point?';

  @override
  String get trainingContinue => 'Continue';

  @override
  String get trainingActiveProfile => 'Active Profile';

  @override
  String get trainingStartPackage => 'Start Package';

  @override
  String trainingStartForProfile(String name) {
    return 'Starting for $name';
  }

  @override
  String get trainingWarmupBeforeMoroTitle => 'Warm-Up Before Moro';

  @override
  String get trainingWarmupBeforeMoroBody =>
      'The warm-up round offers a calm, rhythmic way to prepare for the upcoming reflex integration exercises.\n\nYou can return to these exercises later whenever you want to settle and unwind.';

  @override
  String get trainingStartWarmup => 'Start Warm-Up';

  @override
  String get trainingContinueWithPackage => 'Continue Directly to the Package';

  @override
  String get trainingUseReflexProfile => 'Use a Reflex Profile';

  @override
  String trainingReflexProfileMissingBody(String name) {
    return '$name doesn\'t have completed reflex profile results yet. A completed profile makes the duration recommendation more specific and easier to understand.';
  }

  @override
  String get trainingStartReflexProfile => 'Start Reflex Profile';

  @override
  String get trainingSkipDeliberately => 'Skip for Now';

  @override
  String get trainingIsometricPartnerTitle => 'Isometric Partner Exercises';

  @override
  String trainingIsometricPartnerQuestion(String name) {
    return 'Has $name already done isometric partner exercises with a professional?';
  }

  @override
  String get trainingWarmupStillRunning =>
      'The warm-up phase is still in progress. You can start Moro anyway; it is a recommendation, not a requirement.';

  @override
  String get trainingWarmupReady =>
      'The warm-up is ready. You can start Moro now.';

  @override
  String trainingConnectedWithoutIsometric(String name) {
    return 'You\'re connected with $name. If you haven\'t done isometric partner exercises, the answer remains “No.”';
  }

  @override
  String trainingTrainerRequestPending(String name) {
    return 'Your trainer request to $name is pending.';
  }

  @override
  String get trainingFindTrainer => 'Find a Trainer';

  @override
  String get trainingWarmupWhileWaitingBody =>
      'While you wait for a response or an appointment, you can use the warm-up round. It provides rhythmic preparation and is independent of the isometric partner exercises.';

  @override
  String get trainingUseWarmup => 'Use the Warm-Up';

  @override
  String get trainingBeforeYouStart => 'Before You Start';

  @override
  String get trainingWarmupInterstitialBody =>
      'The warm-up round helps you settle into the reflex training. Many people find it easier to focus on the exercises afterward.';

  @override
  String get trainingStartWarmupNow => 'Start the Warm-Up Now';

  @override
  String get trainingRecommended => 'recommended';

  @override
  String get trainingWarmupSummary =>
      '4 weeks · 6 daily exercises · about 8 min.';

  @override
  String get trainingStartFirstPackageDirectly =>
      'Start the First Package Directly';

  @override
  String get trainingWarmupAvailableLater =>
      'You can complete the warm-up at any time.';

  @override
  String get trainingCongratulations => 'Congratulations!';

  @override
  String get trainingCompletedTodayBody =>
      'You\'ve successfully completed\ntoday\'s training.';

  @override
  String get trainingCompletedToday => 'Completed Today';

  @override
  String get trainingExercisesLabel => 'Exercises';

  @override
  String get trainingMinutesLabel => 'Minutes';

  @override
  String get trainingKeepGoing => 'Keep going! Consistency makes a difference.';

  @override
  String trainingExerciseOfTotal(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String trainingProgressStepCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String trainingProgressPercentComplete(int percent) {
    return '$percent% complete! 🎉';
  }

  @override
  String get trainingProgressAlmostThere =>
      'Fantastic! You\'re almost there! 🏆';

  @override
  String get trainingProgressGreat => 'Great work! You\'ve got this! 💪';

  @override
  String get trainingProgressHalfway => 'Nice! You\'re past halfway! 🎯';

  @override
  String get trainingProgressKeepGoing => 'Well done! Keep going! ⭐';

  @override
  String get trainingProgressLetsGo => 'Let\'s go! You\'ve got this! 🚀';

  @override
  String get trainingVideo => 'Video';

  @override
  String trainingRepetitionsAbbreviated(int count) {
    return '$count× reps';
  }

  @override
  String trainingSecondsPerRep(int seconds) {
    return '$seconds sec / rep';
  }

  @override
  String get trainingPositionLabel => 'Position';

  @override
  String trainingStartsInSeconds(int seconds) {
    return 'Starts in $seconds s';
  }

  @override
  String get trainingStartNow => 'Start Now';

  @override
  String get trainingAnnouncementPlaying => 'Announcement playing...';

  @override
  String get trainingVideoPreparing => 'Preparing video...';

  @override
  String get trainingMusicOff => 'Off';

  @override
  String get trainingMusicVolume => 'Volume';

  @override
  String get trainingMusicAmbientFlow => 'Ambient Flow';

  @override
  String get trainingMusicQuietNature => 'Quiet Nature';

  @override
  String get trainingMusicDeepTones => 'Deep Tones';

  @override
  String get trainingOwnMusicMixNote =>
      'External music is not controlled or ducked by the app in this release.';

  @override
  String get trainingShortBreak => 'Short Break';

  @override
  String get trainingNextExercise => 'Next Exercise:';

  @override
  String get trainingTutorialSubtitle => 'Guided';

  @override
  String get trainingRoutineSubtitle => 'Automatic flow';

  @override
  String trainingDurationAndRepetitions(int seconds, int repetitions) {
    return '${seconds}s · $repetitions reps';
  }

  @override
  String trainingCompletedExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get trainingSecondsAbbreviation => 'sec';

  @override
  String get trainingAndAgain => 'And again';

  @override
  String get trainingSwitchArmCross => 'Switch arm cross';

  @override
  String get trainingSwitchCue => 'Switch';

  @override
  String get delete => 'Delete';

  @override
  String get packagesNameMoro => 'Moro Reflex';

  @override
  String get packagesNameSpinalGalant => 'Spinal Galant + Amphibian';

  @override
  String get packagesNameTlr => 'Tonic Labyrinthine Reflex (TLR)';

  @override
  String get packagesNameBabkin => 'Babkin + Plantar + Grasp';

  @override
  String get packagesNameSuchSaug => 'Rooting-Sucking Reflex';

  @override
  String get packagesNameAtnr => 'ATNR';

  @override
  String get packagesNameStnr => 'STNR';

  @override
  String get packagesNameBabinski => 'Babinski Reflex';

  @override
  String get packagesNameLandau => 'Landau Reflex';

  @override
  String get packagesDevSelectionAvailable => 'Developer selection available';

  @override
  String get packagesFixedSequenceStatus =>
      'Part of your fixed package sequence';

  @override
  String get journalMoodAndEntry => 'Mood + Entry';

  @override
  String get journalEntryOnly => 'Entry Only';

  @override
  String get journalEntriesHeading => 'Entries';

  @override
  String journalEntrySummary(int entryCount, int entriesThisWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      entriesThisWeek,
      locale: localeName,
      other: '$entriesThisWeek this week',
      one: '1 this week',
      zero: '0 this week',
    );
    return '$entryCount total · $_temp0';
  }

  @override
  String get journalTimelineEmptyTitle => 'No Entries Yet';

  @override
  String get journalTimelineEmptyBody =>
      'Your notes appear here in a compact timeline. Your history stays on the dashboard.';

  @override
  String get journalDeleteEntryTitle => 'Delete Entry?';

  @override
  String get journalDeleteEntryBody =>
      'This entry will be permanently deleted.';

  @override
  String get journalEntryTypeNote => 'Note';

  @override
  String get journalShowLess => 'Show Less';

  @override
  String get journalShowMore => 'Show More';

  @override
  String get progressTitle => 'History';

  @override
  String get progressLoadFailed => 'Could not load history.';

  @override
  String get progressAddObservation => 'Add Observation';

  @override
  String get progressWellbeingTitle => 'Wellbeing Over Time';

  @override
  String get progressWellbeingDescription =>
      'A calm view of mood, energy, and stress over time.';

  @override
  String get progressWellbeingSeries => 'Wellbeing';

  @override
  String get progressWellbeingEmpty => 'No entries in the selected period yet.';

  @override
  String get progressRange30Days => '30d';

  @override
  String get progressRange90Days => '90d';

  @override
  String get progressRangeOneYear => '1y';

  @override
  String get progressRangeAll => 'All';

  @override
  String get progressReflexProfilesTitle => 'Reflex Profiles';

  @override
  String progressReflexProfilesLoadFailed(String error) {
    return 'Could not load reflex profiles: $error';
  }

  @override
  String get progressNoReflexProfileBody =>
      'No reflex profile yet. It shows indication levels at a glance.';

  @override
  String get progressStartReflexProfile => 'Start Reflex Profile';

  @override
  String get progressProfileDetails => 'Details';

  @override
  String get progressAdultLegacyCardBody =>
      'Created with an older method. Tap to open the notice.';

  @override
  String get progressAdultNoPatternsYet => 'No answer patterns yet';

  @override
  String progressProfileAgeYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '$years year',
    );
    return '$_temp0';
  }

  @override
  String get progressNoAssessmentProfile => 'No Profile\nYet';

  @override
  String get progressAddAnotherProfile => 'Another\nProfile';

  @override
  String get progressCurrentPackageTitle => 'Current Package';

  @override
  String progressCurrentPackageDay(
      String packageName, int currentDay, int totalDays) {
    return '$packageName · Day $currentDay of $totalDays';
  }

  @override
  String get progressNoNextFixedPackage => 'No fixed package follows this one.';

  @override
  String progressNextFixedPackage(String packageName) {
    return 'Next fixed package: $packageName';
  }

  @override
  String get progressViewPackageSequence => 'View Package Sequence';

  @override
  String get progressObservationsTitle => 'Observations';

  @override
  String get progressObservationsEmptySummary =>
      'No observations recorded yet.';

  @override
  String progressObservationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries in the current period',
      one: '1 entry in the current period',
    );
    return '$_temp0';
  }

  @override
  String get progressObservationsEmptyBody =>
      'After a session or anytime in between, you can record observations about your body, mood, energy, and sleep.';

  @override
  String get goldenDayTitle => 'Golden Day 🎉';

  @override
  String get goldenDayCongratulations => 'Congratulations!';

  @override
  String get goldenDayCompletionMessage => 'You completed the 4-week training!';

  @override
  String get goldenDayFeelingPrompt => 'How do you feel?';

  @override
  String get goldenDayReadyForMore => 'Ready for More!';

  @override
  String get goldenDayPracticeMore => 'Practice a Little More';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get edit => 'Edit';

  @override
  String get submit => 'Submit';

  @override
  String get noThanks => 'No, Thanks';

  @override
  String get continueAction => 'Continue';

  @override
  String get accompanimentTitle => 'Guidance';

  @override
  String get accompanimentConnectBody =>
      'Paste the invite link or enter the 6-character code you received from your trainer.';

  @override
  String get accompanimentInviteLinkOrCodeLabel => 'Invite Link or Code';

  @override
  String get accompanimentInviteLinkOrCodeHint => 'A1B2C3 or https://...';

  @override
  String get accompanimentConnectInvalidInvite =>
      'Enter a valid 6-character code or invite link.';

  @override
  String accompanimentConnectFailed(String error) {
    return 'Could not connect: $error';
  }

  @override
  String get accompanimentConnectAction => 'Connect';

  @override
  String get accompanimentConnectedSuccess =>
      'You\'re now connected to your trainer.';

  @override
  String get accompanimentSwitchTitle => 'Switch Trainers';

  @override
  String get accompanimentSwitchBody =>
      'After you switch, your new trainer will see your history. Your previous trainer will no longer see you in their client list.';

  @override
  String get accompanimentSwitchInvalidInvite =>
      'Enter a valid invite link or code.';

  @override
  String get accompanimentSwitchConfirm => 'Confirm Switch';

  @override
  String get accompanimentSwitchUpdated => 'Guidance updated.';

  @override
  String accompanimentSwitchFailed(String error) {
    return 'Could not save the change: $error';
  }

  @override
  String get accompanimentEndAction => 'End accompaniment';

  @override
  String get accompanimentEndDialogTitle => 'Really end this accompaniment?';

  @override
  String get accompanimentEndConsequenceProfiles =>
      'Your trainer will no longer see your reflex profiles.';

  @override
  String get accompanimentEndConsequenceChat =>
      'You will no longer be able to message each other. Your existing history stays.';

  @override
  String get accompanimentEndConsequenceAppointments =>
      'All open appointments will be canceled.';

  @override
  String get accompanimentEndTrainerNotice => 'Your trainer will be informed.';

  @override
  String get accompanimentEndReconnectHint =>
      'You can connect again later with a new code.';

  @override
  String get accompanimentEndConfirm => 'End accompaniment';

  @override
  String get accompanimentEnded => 'Accompaniment ended.';

  @override
  String accompanimentEndFailed(String error) {
    return 'Couldn\'t end the accompaniment: $error';
  }

  @override
  String get chatWriteLockedNoRelationship =>
      'This accompaniment has ended. You can still read the history, but you can no longer send messages.';

  @override
  String get accompanimentWithdrawTitle => 'Withdraw Request?';

  @override
  String accompanimentWithdrawBody(String name) {
    return 'Your request to $name will be withdrawn. You can request another trainer later.';
  }

  @override
  String get accompanimentWithdrawAction => 'Withdraw Request';

  @override
  String get accompanimentWithdrawSuccess => 'Request withdrawn.';

  @override
  String accompanimentWithdrawFailed(String error) {
    return 'Could not withdraw request: $error';
  }

  @override
  String get accompanimentSharedExperiencesTitle => 'Shared Experiences';

  @override
  String get accompanimentSharedExperiencesBody =>
      'View moderated observations from ongoing packages.';

  @override
  String get accompanimentSharedExperiencesAction => 'View Experiences';

  @override
  String get accompanimentProfessionalTitle => 'Professional Guidance';

  @override
  String get accompanimentProfessionalBody =>
      'Some exercises are done with a partner. The focus is not strength training, but clearly noticing direction, movement, and resistance. A qualified trainer can guide you through these exercises.';

  @override
  String get accompanimentPackageStartNote =>
      'Especially relevant at the start of a package.';

  @override
  String get accompanimentDailySessionsNote =>
      'Your daily rhythmic sessions remain self-guided.';

  @override
  String get accompanimentNoTrainerTitle => 'No Trainer Connected Yet';

  @override
  String get accompanimentNoTrainerBody =>
      'You can keep practicing your package on your own and find professional guidance for partner exercises or conversations when you need it.';

  @override
  String get accompanimentEnterInviteLink => 'Enter Invite Link';

  @override
  String get accompanimentContinueWithoutTrainer =>
      'Continue Without a Trainer';

  @override
  String get accompanimentProfileSharingTitle => 'Reflex Profile Sharing';

  @override
  String get accompanimentProfileSharingBody =>
      'You decide whether your connected trainer can see completed reflex profiles. Access lasts only while this guidance connection is active.';

  @override
  String accompanimentProfileSharingLoadFailed(String error) {
    return 'Could not load sharing: $error';
  }

  @override
  String get accompanimentProfileShared =>
      'Your connected trainer can see this reflex profile.';

  @override
  String get accompanimentProfileNotShared =>
      'Not shared with your connected trainer.';

  @override
  String accompanimentProfileSharingSaveFailed(String error) {
    return 'Could not save reflex profile sharing: $error';
  }

  @override
  String accompanimentProposalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Open Appointment Proposals',
      one: '1 Open Appointment Proposal',
    );
    return '$_temp0';
  }

  @override
  String get accompanimentProposalsLoading =>
      'Loading appointment proposals...';

  @override
  String get accompanimentProposalsBody => 'Choose a time that works for you.';

  @override
  String get accompanimentViewProposals => 'View Proposals';

  @override
  String accompanimentPendingRequestTitle(String name) {
    return 'Request Pending with $name';
  }

  @override
  String accompanimentExtraPendingRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more requests pending',
      one: '$count more request pending',
    );
    return '$_temp0';
  }

  @override
  String get accompanimentPendingRequestAcceptedNotice =>
      'We\'ll let you know when the request is accepted.';

  @override
  String get accompanimentMoreTrainers => 'More Trainers';

  @override
  String get accompanimentInviteLinkShort => 'Invite Link';

  @override
  String get accompanimentActiveGuidance => 'Active Guidance';

  @override
  String get accompanimentMessage => 'Message';

  @override
  String get accompanimentAppointmentProposals => 'Appointment Proposals';

  @override
  String get accompanimentNextAppointments => 'Upcoming Appointments';

  @override
  String get accompanimentNoAppointments => 'No appointments scheduled yet.';

  @override
  String get accompanimentSwitchAccessBody =>
      'When you switch, your new trainer can see your history. Your previous trainer loses access to your client profile.';

  @override
  String get accompanimentEnterCode => 'Enter Code';

  @override
  String accompanimentAppointmentForProfile(String profileName) {
    return 'for $profileName';
  }

  @override
  String get moodWriteNote => 'Write a Note';

  @override
  String get moodNoActiveProgram => 'No active program found.';

  @override
  String get moodCommunityShareTitle => 'Submit a Shared Experience?';

  @override
  String get moodCommunityShareBody =>
      'Would you like to submit this observation as a shared experience?';

  @override
  String get moodEditEntry => 'Edit Entry';

  @override
  String get moodLogMood => 'Log Mood';

  @override
  String get moodForWhom => 'Who Is This For?';

  @override
  String get moodGeneral => 'General';

  @override
  String get moodMetricSelectionHint =>
      'Tap a value to select it, or leave it blank.';

  @override
  String get moodNoteBody =>
      'Whatever your mood, write down what\'s on your mind right now.';

  @override
  String get moodNoteHint => 'Your thoughts...';

  @override
  String moodExperienceSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String moodExperienceSessionNote(String values) {
    return 'Session: $values';
  }

  @override
  String moodExperienceSinceLastSessionNote(String values) {
    return 'Since the last session: $values';
  }

  @override
  String get moodExperienceTitle => 'How Did the Session Feel?';

  @override
  String get moodExperienceDescription =>
      'What did you notice during this session or since your last one?';

  @override
  String get moodExperienceImpressionCalm => 'calm';

  @override
  String get moodExperienceImpressionPleasant => 'pleasant';

  @override
  String get moodExperienceImpressionTired => 'tired';

  @override
  String get moodExperienceImpressionRestless => 'restless';

  @override
  String get moodExperienceImpressionEmotional => 'emotional';

  @override
  String get moodExperienceImpressionPhysicallyUncomfortable =>
      'physically uncomfortable';

  @override
  String get moodExperienceImpressionUnsure => 'hard to tell';

  @override
  String get moodExperienceSinceLastTitle =>
      'What Have You Noticed Since Your Last Session?';

  @override
  String get moodExperienceSinceMoreCalm => 'calmer';

  @override
  String get moodExperienceSinceMoreEnergy => 'more energy';

  @override
  String get moodExperienceSinceLessEnergy => 'less energy';

  @override
  String get moodExperienceSinceMoodChanged => 'mood fluctuated';

  @override
  String get moodExperienceSinceMoreEmotional => 'more emotional than usual';

  @override
  String get moodExperienceSinceMoreSensitive => 'more sensitive to stimuli';

  @override
  String get moodExperienceSinceBetterSleep => 'better sleep';

  @override
  String get moodExperienceSinceRestlessSleep => 'restless sleep';

  @override
  String get moodExperienceSinceBodyTension => 'physical tension';

  @override
  String get moodExperienceSinceNothingNotable => 'nothing notable';

  @override
  String get moodExperienceOwnObservationHint =>
      'Add your own observation... (optional)';

  @override
  String get moodExperienceShare => 'Submit as a Shared Experience';

  @override
  String get moodExperienceShareAnonymously => 'Submit Anonymously';

  @override
  String get themeSystemDescription => 'Follows your system setting';

  @override
  String get themeLightDescription => 'Always use the light theme';

  @override
  String get themeDarkDescription => 'Always use the dark theme';

  @override
  String themeChanged(String title) {
    return 'Theme changed to “$title”';
  }

  @override
  String get profileTrainingProfilesSection => 'Training Profiles';

  @override
  String get profileJournalItemTitle => 'Journal';

  @override
  String get profileJournalSubtitle => 'Your entries and reflections';

  @override
  String get profileTrainerSection => 'Trainer';

  @override
  String get profileManageGuidance => 'Manage Guidance';

  @override
  String profileConnectedWith(String name) {
    return 'Connected to $name';
  }

  @override
  String get profileFindManageTrainer =>
      'Find trainers and manage requests and appointments';

  @override
  String get profileWorkspaceSection => 'Workspace';

  @override
  String get profileAdminPanel => 'Admin Panel';

  @override
  String get profileMessages => 'Messages';

  @override
  String get profileReviewChannels =>
      'Trainer applications and review channels';

  @override
  String get profileTrainerArea => 'Trainer Area';

  @override
  String get profileProfessionalAccessSection => 'Professional Access';

  @override
  String get profileBecomeTrainer => 'Become a Trainer';

  @override
  String get profileApplicationSubtitle => 'Submit your application for review';

  @override
  String get profileAccountSection => 'Account';

  @override
  String profileSubjectProfilesLoadFailed(String error) {
    return 'Could not load profiles: $error';
  }

  @override
  String get profileCreateFirst => 'Create Your First Profile';

  @override
  String get profileEditTooltip => 'Edit Profile';

  @override
  String get profileActivate => 'Activate';

  @override
  String get profileViewReflexProfile => 'View reflex profile';

  @override
  String get profileStartReflexProfile => 'Fill out reflex profile';

  @override
  String get profileAdd => 'Add Profile';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String profileSaveFailed(String error) {
    return 'Could not save profile: $error';
  }

  @override
  String get profileAdult => 'Adult Profile';

  @override
  String get profileChild => 'Child Profile';

  @override
  String profileAgeYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years old',
      one: '$years year old',
    );
    return '$_temp0';
  }

  @override
  String get profileSelectBirthDateHelp => 'Select Date of Birth';

  @override
  String get profileNameRequired => 'Enter a name.';

  @override
  String get profileBirthDateRequired => 'Enter a date of birth.';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileChildNameLabel => 'Name or Nickname';

  @override
  String get profileNameLabel => 'Profile Name';

  @override
  String get profileBirthDateLabel => 'Date of Birth';

  @override
  String get profileSelectDate => 'Select Date';

  @override
  String get profileDisplayNameLabel => 'Display Name';

  @override
  String get profileCommunityDisplayNameHint =>
      'Shown in the community feed when you share experiences.';

  @override
  String get profileTrainerDisplayNameHint =>
      'Visible to your trainer, for example in chat.';

  @override
  String profileMinimumCharacters(int count) {
    return 'At least $count characters';
  }

  @override
  String profileMaximumCharacters(int count) {
    return 'No more than $count characters';
  }

  @override
  String get profileAtNotAllowed => '@ is not allowed';

  @override
  String get profileSaveFailedShort => 'Could not save';

  @override
  String get profileContactNameRequired => 'Enter a contact name.';

  @override
  String get profileContactNameQuestion => 'What Should We Call You?';

  @override
  String get profileContactNameBody =>
      'Your contact name is visible to trainers and in the training area.';

  @override
  String get profileContactNameBodyWithCommunity =>
      'Your contact name is visible to trainers and in the training area. It can be different from your community name.';

  @override
  String get profileContactNameHint => 'e.g., Maria or the Miller family';

  @override
  String get tabTrainer => 'Trainer';

  @override
  String get tabAdmin => 'Admin';

  @override
  String routeNotFound(String error) {
    return 'Page not found: $error';
  }

  @override
  String get startupCouldNotStart =>
      'Reflex Journey could not start. Please restart the app or reinstall.';

  @override
  String get startupBootstrapFailedTitle => 'Bootstrap failed';

  @override
  String get clientFallbackName => 'Client';

  @override
  String get appointmentCalendarFallbackTitle => 'Isometric partner exercise';

  @override
  String appointmentCalendarEventTitle(String title, String name) {
    return '$title (with $name)';
  }

  @override
  String appointmentCalendarAdded(String name) {
    return 'The appointment with $name was added to your calendar.';
  }

  @override
  String appointmentCalendarOpenFailed(String error) {
    return 'Could not open the calendar: $error';
  }

  @override
  String get hintDashboardBody =>
      'This is where you manage your daily rhythm and record what you notice.';

  @override
  String get hintDashboardItemStart =>
      'Start your guided session or routine mode.';

  @override
  String get hintDashboardItemLog => 'Log a session if you practiced today.';

  @override
  String get hintDashboardItemNote =>
      'Capture your experiences right after the session.';

  @override
  String get hintProgressBody =>
      'Your history helps you spot patterns without overrating individual days.';

  @override
  String get hintProgressItemOverview =>
      'See training days, observations, and entries together.';

  @override
  String get hintProgressItemObserve =>
      'Add observations whenever you notice something.';

  @override
  String get hintProgressItemJournal =>
      'Open individual journal entries for more context.';

  @override
  String get hintAccompanimentBody =>
      'Everything related to trainers, communication, and appointments lives here.';

  @override
  String get hintAccompanimentItemTrainer =>
      'Find trainers or manage your active guidance.';

  @override
  String get hintAccompanimentItemChat =>
      'Open messages and stay in touch with your trainer.';

  @override
  String get hintAccompanimentItemAppointments =>
      'See appointment proposals and scheduled appointments.';

  @override
  String get hintProfileBody =>
      'Your profile holds your account, settings, and administrative access.';

  @override
  String get hintProfileItemSettings =>
      'Adjust language, appearance, and reminders.';

  @override
  String get hintProfileItemAccount =>
      'Manage your account, password, and profile information.';

  @override
  String get hintProfileItemRoles =>
      'Open the trainer or admin areas if they are enabled for you.';

  @override
  String get hintDontShowAgain => 'Don\'t show this again';

  @override
  String get hintGotIt => 'Got it';

  @override
  String get hintShowLater => 'Show me again later';

  @override
  String get notificationChannelTrainingReminders => 'Training Reminders';

  @override
  String get pushVideoCallTitle => 'Incoming video call';

  @override
  String get pushVideoCallBody => 'Tap to open the call.';

  @override
  String get pushCallRequestTitle => 'Video call request';

  @override
  String get pushCallRequestBody => 'A client wants to start a video call.';

  @override
  String get pushAppointmentProposalTitle => 'New appointment proposals';

  @override
  String get pushAppointmentProposalBody => 'Choose a time that works for you.';

  @override
  String get pushAppointmentConfirmedTitle => 'Appointment confirmed';

  @override
  String get pushAppointmentConfirmedBody =>
      'Tap to add the appointment to your calendar.';

  @override
  String get pushTrainingReminderTitle => 'Training reminder';

  @override
  String get pushTrainingReminderBody => 'Tap to open your training.';

  @override
  String trainerAlertPrepareTitle(String traineeName) {
    return 'Prepare appointment — $traineeName';
  }

  @override
  String trainerAlertPrepareBody(String traineeName) {
    return '$traineeName is at day 25. The isometric partner exercise is due in about 3 days.';
  }

  @override
  String trainerAlertDay28Title(String traineeName) {
    return '$traineeName has reached day 28!';
  }

  @override
  String get trainerAlertDay28Body =>
      'Book the appointment for the isometric partner exercise now.';

  @override
  String get traineeFallbackName => 'Your trainee';

  @override
  String get answerUnknown => 'I don\'t know';

  @override
  String get scoreBandStrong => 'strong';

  @override
  String get scoreBandElevated => 'elevated';

  @override
  String get scoreBandIndication => 'indication';

  @override
  String get scoreBandInconspicuous => 'inconspicuous';

  @override
  String get scoreBandInsufficientData => 'not enough data';

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '$count month',
    );
    return '$_temp0';
  }

  @override
  String yearsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String get leave => 'Leave';

  @override
  String get resume => 'Resume';

  @override
  String get finish => 'Finish';

  @override
  String get switchAction => 'Switch';

  @override
  String get selfName => 'Me';

  @override
  String get analysisPlaceholderTitle => 'Analysis';

  @override
  String get analysisPlaceholderContinue => 'Continue to Consent';

  @override
  String get analysisPlaceholderHeadline =>
      'Your personal baseline analysis will start here soon.';

  @override
  String get analysisPlaceholderBody =>
      'Before your first training, this will become a short questionnaire. It will help Reflex Journey understand your current baseline and improve the recommendation.';

  @override
  String get analysisPlaceholderStepQuestionnaireTitle => 'Questionnaire';

  @override
  String get analysisPlaceholderStepQuestionnaireBody =>
      'Symptoms, load, training goal and prior experience.';

  @override
  String get analysisPlaceholderStepAssessmentTitle => 'Assessment';

  @override
  String get analysisPlaceholderStepAssessmentBody =>
      'A calm assessment of your current starting point.';

  @override
  String get durationRecAccept => 'Use Recommendation';

  @override
  String get durationRecSkippedBody =>
      'You skipped the reflex profile, or there is no results summary for this profile yet. The recommendation therefore uses the standard logic based on your answer about isometric partner training.';

  @override
  String get durationRecRangeWithTrainer => '4 to 6';

  @override
  String get durationRecRangeWithoutTrainer => '6 to 8';

  @override
  String get durationRecTrainerAlready => 'already';

  @override
  String get durationRecTrainerNotYet => 'not yet';

  @override
  String durationRecMoroBody(
      String percent, String trainerStatus, String range) {
    return 'This recommendation is based on your personal reflex profile results.\n\nFor the Moro package we look at both Moro and FPR, because both matter in this summary. The stronger indication is at $percent and sets the duration level.\n\nBecause you have $trainerStatus done isometric partner training with a professional, we use the $range-week recommendation range. You can use the recommendation or adjust the duration manually.';
  }

  @override
  String durationRecGenericBody(int weeks, String trainerStatus, String range) {
    return 'This recommendation is based on your personal reflex profile results. Based on your assessed reflex tendency, we recommend $weeks weeks for this package.\n\nBecause you have $trainerStatus done isometric partner training with a professional, we use the $range-week recommendation range.';
  }

  @override
  String durationRecTendency(String label, String percent) {
    return '$label tendency: $percent';
  }

  @override
  String get durationRecStrongerHint =>
      'The stronger indication determines the duration.';

  @override
  String get durationRecNoData => 'insufficient data';

  @override
  String get radarNotEnoughData => 'Not enough data';

  @override
  String get reflexProfileNameBirthRequired =>
      'Please enter a name and date of birth.';

  @override
  String get reflexProfileBirthFuture =>
      'The date of birth cannot be in the future.';

  @override
  String reflexProfileCreateChildFailed(String error) {
    return 'Couldn\'t create the child profile: $error';
  }

  @override
  String get reflexProfileClearanceTitle => 'Consultation Required';

  @override
  String reflexProfileClearanceBody(String question) {
    return 'For this answer, we strongly recommend training only after consultation and with the explicit approval of a doctor, therapist, or psychologist who cares for you.\n\nBy continuing, you confirm that you will take this consultation into account on your own responsibility and train with appropriate accompaniment or clearance.\n\nQuestion: $question';
  }

  @override
  String get reflexProfileClearanceConfirm => 'Understood and Confirmed';

  @override
  String get reflexProfileAnswerAllChoice =>
      'Please answer all choice and number questions.';

  @override
  String reflexProfileCompleteFailed(String error) {
    return 'Couldn\'t complete the reflex profile: $error';
  }

  @override
  String get reflexProfileLeaveTitle => 'Leave Questionnaire?';

  @override
  String get reflexProfileLeaveBody =>
      'Your progress will be saved. You can continue anytime.';

  @override
  String get reflexProfileResumeTitle => 'Resume Questionnaire?';

  @override
  String get reflexProfileResumeBody =>
      'You already started this questionnaire. Do you want to continue where you left off?';

  @override
  String get reflexProfileStartOver => 'Start Over';

  @override
  String reflexProfileLoadProfilesFailed(String error) {
    return 'Couldn\'t load profiles: $error';
  }

  @override
  String get reflexProfileForWhomTitle => 'Who is this questionnaire for?';

  @override
  String get reflexProfileForWhomBody =>
      'The questionnaire differs depending on whether it is filled out for a child or for yourself.';

  @override
  String get reflexProfileForMyChild => 'For My Child';

  @override
  String get reflexProfileParentQuestionnaire => 'Parent questionnaire';

  @override
  String get reflexProfileForMyself => 'For Me';

  @override
  String get reflexProfileForMyselfComingSoon => 'For myself · coming soon';

  @override
  String get reflexProfileAdultComingSoonTitle =>
      'Adult Questionnaire Coming Soon';

  @override
  String get reflexProfileAdultComingSoonBody =>
      'The adult questionnaire is still in development. You\'ll soon be able to fill it out here.';

  @override
  String get answerNotApplicable => 'Not applicable';

  @override
  String get reflexProfileAdultSelfReport => 'Adult self-report questionnaire';

  @override
  String get reflexProfileAdultOrientationTitle =>
      'Your answer patterns — not a finding';

  @override
  String get reflexProfileAdultOrientationBody =>
      'This questionnaire collects your own observations. It shows answer patterns only. It does not establish a reflex finding and does not replace a personal assessment.';

  @override
  String get reflexProfileSelectAdultProfile => 'Select profile';

  @override
  String get reflexProfileNewAdultProfile => 'New adult profile';

  @override
  String get reflexProfileAdultAgeHelper =>
      'From age 16. Under 16, please use the child questionnaire (parent report).';

  @override
  String get reflexProfileAdultUnder16Hint =>
      'This adult questionnaire is for age 16 and older. For younger people, please use the child questionnaire — it is a parent report about a child, not a self-report.';

  @override
  String reflexProfileAdultItemProgress(int answered, int visible) {
    return '$answered of $visible visible items answered';
  }

  @override
  String get reflexProfileAdultContinueToSummary => 'Review answers';

  @override
  String get reflexProfileAdultSummaryTitle => 'Before you submit';

  @override
  String get reflexProfileAdultSummaryDisclaimer =>
      'Your profile will show answer patterns only — not a diagnosis or reflex proof.';

  @override
  String reflexProfileAdultSummaryAnswered(int count) {
    return 'Answered: $count';
  }

  @override
  String reflexProfileAdultSummarySkipped(int count) {
    return 'Skipped (? / not applicable): $count';
  }

  @override
  String reflexProfileAdultSummaryHidden(int count) {
    return 'Hidden by filters: $count';
  }

  @override
  String get reflexProfileAdultSummaryOpenHeading => 'Open questions';

  @override
  String get reflexProfileAdultSafetyNoticeTitle => 'Notice';

  @override
  String get reflexProfileAdultSafetyNoticeBody =>
      'Your answer may mean that individual movements or training exercises should be adapted or discussed with a professional first. This result does not evaluate your diagnosis.';

  @override
  String get reflexProfileAdultSafetyNoticeMovementAppendix =>
      'Do not perform the marked exercises without the consultation recommended here.';

  @override
  String get reflexProfileAdultSafetyNoticeConfirm => 'Notice read.';

  @override
  String get adultResultTitle => 'Your Reflex Profile';

  @override
  String adultResultSubline(
      String date, String questionnaireVersion, String scoringVersion) {
    return 'Adult profile · $date · $questionnaireVersion / $scoringVersion';
  }

  @override
  String get adultResultDisclaimer =>
      'These are your subjective answer patterns only. They are not a reflex finding and not a diagnosis.';

  @override
  String get adultResultHintListTitle => 'Answer patterns by reflex';

  @override
  String adultResultFeaturesAnswered(int answered, int possible) {
    return '$answered of $possible features answered';
  }

  @override
  String get adultResultDetailHintStrength => 'Hint strength';

  @override
  String get adultResultDetailDataBasis => 'Data basis';

  @override
  String get adultResultDetailMatchingAnswers => 'Matching answers';

  @override
  String get adultResultDetailAlternatives => 'Alternative explanations';

  @override
  String get adultResultDetailLimits => 'Limits';

  @override
  String get adultResultLegacyTitle => 'Created with an older method';

  @override
  String get adultResultLegacyBody =>
      'This adult profile was created with a previous questionnaire version. Values are not shown and are not compared with current profiles.';

  @override
  String adultResultLegacyVersion(
      String questionnaireVersion, String scoringVersion) {
    return 'Version: $questionnaireVersion · Scoring: $scoringVersion';
  }

  @override
  String get adultHintBandFewMatching => 'Few matching answers';

  @override
  String get adultHintBandSomeMatching => 'Some matching answers';

  @override
  String get adultHintBandClusteredPattern => 'Clustered answer pattern';

  @override
  String get adultHintBandStronglyClustered => 'Strongly clustered pattern';

  @override
  String get adultHintBandInsufficientData => 'Not enough data';

  @override
  String get adultAmphibianInsufficientData => 'No answers';

  @override
  String get adultAmphibianNoneMatching => 'No matching single hint';

  @override
  String get adultAmphibianSingleHint => 'Single hint';

  @override
  String get adultAmphibianClearSingleHint => 'Clear single hint';

  @override
  String get reflexProfileOrientationTitle => 'Guidance Only — Not a Verdict';

  @override
  String get reflexProfileOrientationBody =>
      'The reflex profile gathers observations and shows indication strengths. It is not a substitute for advice from a qualified professional.';

  @override
  String get reflexProfileSelectChild => 'Select Child Profile';

  @override
  String get reflexProfileStartQuestionnaire => 'Start Questionnaire';

  @override
  String get reflexProfileNewChild => 'New Child Profile';

  @override
  String get reflexProfileNameOrNickname => 'Name or nickname';

  @override
  String get reflexProfilePickBirthDate => 'Select date of birth';

  @override
  String get reflexProfileBirthDateRequired => 'Date of birth *';

  @override
  String get reflexProfileBirthDateHelper =>
      'Required – needed for the age assessment';

  @override
  String get reflexProfileSelectDate => 'Select date';

  @override
  String get reflexProfileCreateAndStart => 'Create Profile and Start';

  @override
  String get reflexProfileAnswerRequiredSection =>
      'Please answer all required questions in this section.';

  @override
  String get reflexProfileChildFallback => 'Child profile';

  @override
  String reflexProfileSectionOf(int current, int total) {
    return 'Section $current of $total';
  }

  @override
  String get reflexProfileWhatIsMeant => 'What does this mean?';

  @override
  String get reflexProfileMonthsLabel => 'Months';

  @override
  String get reflexProfileFreeTextLabel => 'Free text';

  @override
  String get reflexProfileOtherLabel => 'Other / notes';

  @override
  String get reflexResultTitle => 'Reflex Profile Results';

  @override
  String reflexResultLoadFailed(String error) {
    return 'Couldn\'t load results: $error';
  }

  @override
  String get reflexResultIndicationStrengths => 'Indication Strengths';

  @override
  String get reflexResultDisclaimer =>
      'These results show answer patterns and are not a substitute for advice from a qualified professional.';

  @override
  String get reflexResultChartCaption =>
      'The chart shows the strongest reflex areas from your answer pattern.';

  @override
  String reflexResultWarningNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You confirmed $count indications where we strongly recommend consulting a doctor, therapist, or psychologist. Trainer guidance is especially helpful in your case.',
      one:
          'You confirmed 1 indication where we strongly recommend consulting a doctor, therapist, or psychologist. Trainer guidance is especially helpful in your case.',
    );
    return '$_temp0';
  }

  @override
  String get reflexResultAreasTitle => 'Reflex Areas';

  @override
  String get reflexResultAdditionalInfo => 'Additional Details';

  @override
  String get reflexResultSharePdf => 'Share PDF Summary';

  @override
  String get reflexResultToDashboard => 'Go to Dashboard';

  @override
  String get reflexResultShareSubject => 'Reflex Journey Reflex Profile';

  @override
  String get reflexResultShareText => 'Reflex Journey Reflex Profile Summary';

  @override
  String reflexResultPdfFailed(String error) {
    return 'Couldn\'t create the PDF: $error';
  }

  @override
  String get reflexResultShareWithTrainer => 'Share with Trainer';

  @override
  String reflexResultShareWithTrainerBody(String trainerName) {
    return 'You can share your full reflex profile with $trainerName. This supports your shared guidance and can be revoked later.';
  }

  @override
  String reflexResultShareLoadFailed(String error) {
    return 'Couldn\'t load sharing status: $error';
  }

  @override
  String get reflexResultShareRevoked => 'Sharing was revoked.';

  @override
  String reflexResultShareRevokeFailed(String error) {
    return 'Couldn\'t revoke sharing: $error';
  }

  @override
  String get reflexResultRevokeShare => 'Revoke Sharing';

  @override
  String get reflexResultShareGranted => 'Reflex profile was shared.';

  @override
  String reflexResultShareGrantFailed(String error) {
    return 'Couldn\'t share the reflex profile: $error';
  }

  @override
  String get reflexResultAllowTrainer => 'Allow Trainer to See Results';

  @override
  String reflexResultYesOfAnswered(int yesCount, int answeredCount) {
    return '$yesCount of $answeredCount answered linked questions were answered yes.';
  }

  @override
  String get reflexResultNoAdditional => 'No additional details available.';

  @override
  String get reflexResultNoCompleted => 'No completed results yet.';

  @override
  String get reflexResultStartProfile => 'Start Reflex Profile';

  @override
  String get reflexDemoAnswerAll => 'Please answer all questions.';

  @override
  String get reflexDemoFullTest => 'Full Assessment';

  @override
  String get reflexDemoForWhomTitle => 'Who is the short assessment for?';

  @override
  String get reflexDemoForWhomBody =>
      'This short assessment shows an example of what reflex profile results can look like. It is not saved.';

  @override
  String get reflexDemoSelfComingSoonTitle =>
      'Short Assessment for Myself Coming Soon';

  @override
  String get reflexDemoSelfComingSoonBody =>
      'The questionnaire for yourself is still in development.';

  @override
  String get reflexDemoTitle => 'Short Assessment';

  @override
  String get reflexDemoIntro =>
      'This demo shows an example of what reflex profile results can look like. It is not saved and does not replace a full questionnaire.';

  @override
  String get reflexDemoEvaluate => 'See Demo Results';

  @override
  String get reflexDemoSignInForFull => 'Sign In for Full Questionnaire';

  @override
  String get reflexDemoStartFull => 'Start Full Questionnaire';

  @override
  String get reflexDemoGuestHint =>
      'After signing up you can create child profiles, save the full questionnaire, and review the results later.';

  @override
  String get reflexDemoSignedInHint =>
      'The full questionnaire covers all categories and the results can be saved.';

  @override
  String get reflexDemoOpenFullTest => 'Open Full Assessment';

  @override
  String get reflexDemoSignInOrRegister => 'Sign In or Sign Up';

  @override
  String get reflexDemoResultTitle => 'Demo Results';

  @override
  String get reflexDemoResultHeadline => 'Your Demo Result';

  @override
  String get reflexDemoResultDisclaimer =>
      'These results are based only on the short assessment and are an illustrative snapshot, not a professional evaluation. They show answer patterns — a complete reflex profile needs all 112 questions.';

  @override
  String get reflexDemoNotEnoughChartData => 'Not enough data for the chart.';

  @override
  String get reflexDemoChartCaption =>
      'The chart shows the strongest reflex areas from your short-assessment answers.';

  @override
  String get reflexDemoAccountBenefitGuest =>
      'With an account you can complete the full questionnaire, save your result, and share it with your trainer.';

  @override
  String get reflexDemoAccountBenefitSignedIn =>
      'The full questionnaire covers all categories and saves the result permanently.';

  @override
  String get reflexPdfTitle => 'Reflex Profile Summary';

  @override
  String reflexPdfHeaderMeta(
      String date, String questionnaireVersion, String scoringVersion) {
    return 'Created on $date · $questionnaireVersion / $scoringVersion';
  }

  @override
  String get reflexPdfSummaryNotice =>
      'These results show answer patterns and indication strengths. They are not a substitute for advice from a qualified professional.';

  @override
  String reflexPdfSafetyNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count safety/consultation notices were confirmed. Training should only happen after explicit consultation with a doctor, therapist, or psychologist.',
      one:
          '1 safety/consultation notice was confirmed. Training should only happen after explicit consultation with a doctor, therapist, or psychologist.',
    );
    return '$_temp0';
  }

  @override
  String get reflexPdfOverviewTitle => 'Reflex areas';

  @override
  String get reflexPdfFileNameStem => 'reflexjourney_reflex_profile';

  @override
  String get reflexProfileNameRequired => 'Please enter a name.';

  @override
  String get trainerWorkOverview => 'Work Overview';

  @override
  String get trainerWorkOverviewSubtitle =>
      'Prioritized by package transitions, requests, appointments, and observations.';

  @override
  String get trainerPackageTransitions => 'Package Transitions';

  @override
  String get trainerOpenInvites => 'Open Invites';

  @override
  String get trainerNewRequests => 'New Requests';

  @override
  String get trainerAppointmentsMetric => 'Appointments';

  @override
  String get trainerNewObservations => 'New Observations';

  @override
  String trainerMoreInvitesOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more invites open',
      one: '1 more invite open',
    );
    return '$_temp0';
  }

  @override
  String get trainerReviewSharedExperiences => 'Review Shared Experiences';

  @override
  String get trainerReviewSharedExperiencesBody =>
      'Keep moderated experience posts from active packages in view.';

  @override
  String get trainerConnectionCheck => 'Check Trainer Connection';

  @override
  String get trainerConnectionChecking => 'Checking database…';

  @override
  String get trainerConnectionCheckError => 'Check failed';

  @override
  String get trainerConnectionTapToOpen => 'Tap to open';

  @override
  String get trainerConnectionRefresh => 'Refresh Check';

  @override
  String trainerConnectionCheckFailed(String error) {
    return 'Check error: $error';
  }

  @override
  String get trainerInviteCodeOnce =>
      'One-time code — share it with your client';

  @override
  String get trainerInviteNew => 'New';

  @override
  String get trainerInviteCreating => 'Creating…';

  @override
  String trainerCodeCopiedWithValue(String code) {
    return 'Code $code copied!';
  }

  @override
  String get trainerLocationMissingTitle => 'Location Missing';

  @override
  String get trainerLocationMissingBody =>
      'Your trainer profile is active, but it only appears in trainer search after a location is set. Only an approximate pin is shown publicly.';

  @override
  String get trainerSetLocation => 'Set Location';

  @override
  String get trainerLocationSaved => 'Location saved';

  @override
  String trainerLocationSaveFailed(String error) {
    return 'Couldn\'t save the location: $error';
  }

  @override
  String get trainerDay28Badge => 'Day 28 ✓';

  @override
  String trainerDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get trainerProposeAppointment => 'Propose Appointment';

  @override
  String trainerProposeNextPackage(int days) {
    return '$days days left: propose an appointment for the next package\'s isometric training.';
  }

  @override
  String get trainerOpenDetail => 'Open Details';

  @override
  String get trainerOpenChat => 'Open Chat';

  @override
  String get trainerClientFallback => 'Client';

  @override
  String get trainerSharedReflexProfiles => 'Shared Reflex Profiles';

  @override
  String trainerProfilesLoadFailed(String error) {
    return 'Couldn\'t load profiles: $error';
  }

  @override
  String get trainerNoProfilesShared => 'No profiles shared.';

  @override
  String trainerNoCompletedReflexProfile(String name) {
    return '$name: No completed reflex profile yet.';
  }

  @override
  String get trainerObservations => 'Observations';

  @override
  String get trainerNoSharedObservations => 'No shared observations yet.';

  @override
  String get trainerReflexNoteSaved => 'Reflex profile note saved.';

  @override
  String trainerNoteSaveFailed(String error) {
    return 'Couldn\'t save the note: $error';
  }

  @override
  String get trainerReflexNotesTitle => 'Reflex Profile Notes';

  @override
  String get trainerReflexNotesBody =>
      'These notes stay with the profile and, while sharing is active, remain visible to later trainers as a handoff.';

  @override
  String get trainerReflexNoteHint => 'Note for guidance or handoff';

  @override
  String get trainerSaveNote => 'Save Note';

  @override
  String trainerNotesLoadFailed(String error) {
    return 'Couldn\'t load notes: $error';
  }

  @override
  String get trainerNoReflexNotes => 'No reflex profile notes yet.';

  @override
  String get trainerMessageAction => 'Message';

  @override
  String get trainerAppointmentAction => 'Appointment';

  @override
  String trainerDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get trainerNoPlannedAppointments => 'No planned appointments yet.';

  @override
  String get trainerAppointmentProposed => 'Appointment proposed';

  @override
  String trainerAppointmentFor(String name) {
    return 'for $name';
  }

  @override
  String get appointmentStatusProposal => 'Proposal';

  @override
  String get appointmentStatusCompletedShort => 'Done';

  @override
  String trainerDayNumber(int day) {
    return 'Day $day';
  }

  @override
  String trainerAgeYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String get trainerBandStrongNoticeable => 'strongly elevated';

  @override
  String appointmentProposalSent(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointment proposals sent to $name.',
      one: '1 appointment proposal sent to $name.',
    );
    return '$_temp0';
  }

  @override
  String get appointmentProposalSentHint =>
      'The other person picks a suitable slot.';

  @override
  String appointmentVideoWith(String name) {
    return 'Video appointment with $name';
  }

  @override
  String get appointmentPickSlotsInterview =>
      'Pick 2–4 open slots for the application interview.';

  @override
  String get appointmentPickSlotsClient =>
      'Pick 2–4 open slots — your client will choose one.';

  @override
  String appointmentSlotsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slots selected',
      one: '1 slot selected',
    );
    return '$_temp0';
  }

  @override
  String get appointmentResetSlots => 'Reset';

  @override
  String get appointmentLocationOrVideo => 'Location or video call';

  @override
  String get appointmentSelectSlots => 'Select Slots';

  @override
  String appointmentSendProposal(int count) {
    return 'Send Proposal ($count)';
  }

  @override
  String get appointmentForOptional => 'Appointment for (optional)';

  @override
  String get appointmentForOptionalHint =>
      'Select profiles if this appointment is for specific children.';

  @override
  String get trainerApplicationTitle => 'Trainer Application';

  @override
  String get trainerApplicationSubmittedStep => 'Application submitted';

  @override
  String get trainerApplicationBgCheckStep =>
      'Enhanced background check (level 2) verified by visual review';

  @override
  String get trainerApplicationCodeStep => 'Activation code created';

  @override
  String get trainerApplicationOpenReview => 'Open Review Channel';

  @override
  String get trainerApplicationActivate => 'Activate Trainer';

  @override
  String get trainerApplicationApprovedTitle => 'Approved';

  @override
  String get trainerApplicationApprovedBody =>
      'Your application was approved. Activate your verified trainer profile now.';

  @override
  String get trainerApplicationRejectedTitle => 'Rejected';

  @override
  String get trainerApplicationRejectedBody =>
      'Your application was rejected. See details in the review channel.';

  @override
  String get trainerApplicationNeedsInfoTitle => 'More Info Needed';

  @override
  String get trainerApplicationNeedsInfoBody =>
      'Admins need more information. Please check the review channel.';

  @override
  String get trainerApplicationInReviewBody =>
      'Your application is in review. Admins will follow up in the review channel.';

  @override
  String get trainerApplicationNoneTitle => 'No Trainer Application Yet';

  @override
  String get trainerApplicationStart => 'Start Application';

  @override
  String get trainerApplicationFieldRequired => 'This field is required.';

  @override
  String get trainerApplicationFullName => 'Full name';

  @override
  String get trainerApplicationEmail => 'Email';

  @override
  String get trainerApplicationEmailInvalid => 'A valid email is required.';

  @override
  String get trainerApplicationPhoneOptional => 'Phone optional';

  @override
  String get trainerApplicationCityRegion => 'City / region';

  @override
  String get trainerApplicationBackground => 'Professional background';

  @override
  String get trainerApplicationMotivationOptional => 'Motivation optional';

  @override
  String get trainerApplicationPublicProfile => 'Public trainer profile';

  @override
  String get trainerApplicationDisplayNameOptional => 'Display name optional';

  @override
  String get trainerApplicationBioOptional => 'Bio optional';

  @override
  String get trainerApplicationLocationOptional => 'Location optional';

  @override
  String get trainerApplicationLocationHint =>
      'If you set a location, your profile can appear in trainer search after approval. Only an approximate pin is shown publicly.';

  @override
  String get trainerApplicationSubmit => 'Submit Application';

  @override
  String get trainerBecomeTitle => 'Become a Trainer';

  @override
  String get trainerBecomeHeadline => 'Application and Review';

  @override
  String get trainerBecomeBody =>
      'Reflex Journey trainers work in a sensitive setting. That is why we review every application manually before a trainer profile is activated.';

  @override
  String get trainerBecomeBackgroundTitle => 'Professional Background';

  @override
  String get trainerBecomeBackgroundBody =>
      'Describe your training, experience, or practice in the relevant field.';

  @override
  String get trainerBecomeBgCheckTitle => 'Enhanced Background Check (Level 2)';

  @override
  String get trainerBecomeBgCheckBody =>
      'In the review channel, admins request a visual check. The document is not uploaded or stored.';

  @override
  String get trainerBecomeReviewTitle => 'Admin Review Channel';

  @override
  String get trainerBecomeReviewBody =>
      'After submitting, a protected communication channel with admins opens.';

  @override
  String get trainerBecomeImportant =>
      'Important: The activation code is created only after a successful review.';

  @override
  String get appointmentProposalsTitle => 'Appointment Proposals';

  @override
  String get appointmentNoOpenProposals => 'No open appointment proposals.';

  @override
  String get appointmentAddToCalendarTitle => 'Add to Calendar?';

  @override
  String appointmentAddToCalendarBody(String when) {
    return 'Should the appointment on $when be added to your calendar?';
  }

  @override
  String get appointmentAddToCalendarConfirm => 'Yes, Add';

  @override
  String get appointmentConfirmedSnack => 'Appointment confirmed!';

  @override
  String get appointmentChooseSlot => 'Choose a suitable time:';

  @override
  String get appointmentConfirmSlot => 'Confirm Appointment';

  @override
  String get trainerRequestAccepted =>
      'Request accepted. The client now appears in your overview.';

  @override
  String get trainerRequestDeclined => 'Request declined.';

  @override
  String trainerClientRegularDays(
      String packageName, String dayLabel, int days) {
    return '$packageName · $dayLabel · $days days consistent';
  }

  @override
  String get trainerAppStatusSubmitted => 'Submitted';

  @override
  String get trainerAppStatusInReview => 'In Review';

  @override
  String get trainerAppStatusNeedsInfo => 'More Info Needed';

  @override
  String get trainerAppStatusApproved => 'Approved';

  @override
  String get trainerAppStatusRejected => 'Rejected';

  @override
  String get trainerAppStatusWithdrawn => 'Withdrawn';

  @override
  String calendarImportTitle(String title) {
    return 'Import calendar entry for $title';
  }

  @override
  String get osmAttribution => 'OpenStreetMap contributors';

  @override
  String get trainerMapTapHint => 'Tap the map';

  @override
  String get trainerFallbackName => 'Trainer';

  @override
  String get trainerYourTrainer => 'Your Trainer';

  @override
  String get trainerYourClient => 'Your Client';

  @override
  String get trainerChatFallback => 'Chat';

  @override
  String get trainerDiagNotSignedIn => 'auth.uid: not signed in';

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
    return '$scope: error $error';
  }

  @override
  String trainerDiagRelationshipsTotal(int count) {
    return 'relationships total: $count';
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
    return 'appointments as trainer: $count';
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
    return 'Couldn\'t activate: $error';
  }

  @override
  String get trainerNotSignedIn => 'Not signed in.';

  @override
  String get trainerPkgMoro => 'Moro';

  @override
  String get trainerPkgSpinalGalant => 'Spinal Galant';

  @override
  String get trainerPkgTlr => 'TLR';

  @override
  String get trainerPkgBabkin => 'Babkin';

  @override
  String get trainerPkgSuchSaug => 'Root/Suck';

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
  String get chatChannelTypeApplicationReview => 'Trainer application';

  @override
  String get chatUserFallback => 'User';

  @override
  String get chatApplicantFallback => 'Applicant';

  @override
  String get chatInboxTitle => 'Trainer Communication';

  @override
  String get chatInboxSectionMyTrainer => 'MY TRAINER';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatInboxEmptyBody =>
      'Your chats will show up here.\nConnect with your trainer to use messages and video calls.';

  @override
  String get dmChatWithTrainer => 'Chat with Trainer';

  @override
  String get dmEmptyBody =>
      'Your direct messages with your trainer will show up here.';

  @override
  String chatWithName(String name) {
    return 'Chat with $name';
  }

  @override
  String get chatStartCall => 'Start Call';

  @override
  String get chatRequestVideoCall => 'Request Video Call';

  @override
  String get chatRequestVideoCallTitle => 'Request a video call?';

  @override
  String get chatRequestVideoCallBody =>
      'You\'ll send your trainer a request for a video call. Your trainer decides whether and when to start the call.';

  @override
  String get chatSendRequest => 'Send Request';

  @override
  String get chatMessagesLoadFailed =>
      'Messages couldn\'t be loaded right now. Please check your connection.';

  @override
  String get chatEmptyThread => 'No messages yet.\nSend the first one!';

  @override
  String get chatDeleteMessageTitle => 'Remove message?';

  @override
  String get chatDeleteMessageBody =>
      'The message will show as removed for everyone.';

  @override
  String get chatRemove => 'Remove';

  @override
  String get chatCameraMicPermissionRequired =>
      'Camera and microphone access is required. Please allow access in Settings.';

  @override
  String chatCallStartFailed(String error) {
    return 'Couldn\'t start the call: $error';
  }

  @override
  String get chatAppointmentOpenFailed =>
      'Couldn\'t open appointment scheduling.';

  @override
  String chatOpenFailed(String error) {
    return 'Couldn\'t open chat: $error';
  }

  @override
  String get chatAppointmentProposal => 'Appointment proposal';

  @override
  String get chatViewProposal => 'View proposal';

  @override
  String get chatMessageRemoved => 'This message was removed.';

  @override
  String get chatAssistantName => 'Reflex Journey Assistant';

  @override
  String get chatCallRequestSentAsTrainer => 'Trainer request sent';

  @override
  String get chatCallRequestSentAsClient => 'Video call request sent';

  @override
  String get chatCallRequestIncomingAsTrainer => 'A client wants a video call';

  @override
  String get chatCallRequestIncomingAsClient =>
      'Your trainer wants a video call';

  @override
  String get chatMessageHint => 'Write a message…';

  @override
  String chatTyping(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count typing…',
      one: 'typing…',
    );
    return '$_temp0';
  }

  @override
  String get chatCallRequestMessageContent => '📹 Video call requested';

  @override
  String get trainingReadyForMovement => 'Ready for the movement?';

  @override
  String get trainingReadyBody =>
      'Check your position. Start only when you feel safe and stable.';

  @override
  String get trainingRepeatInstruction => 'Repeat instructions';

  @override
  String trainingPreparationCountdown(int seconds) {
    return 'Starting in $seconds seconds';
  }

  @override
  String trainingRepetitionOf(int current, int total) {
    return 'Repetition $current of $total';
  }

  @override
  String trainingPhaseOf(int current, int total) {
    return 'Phase $current of $total';
  }

  @override
  String trainingTimeRemaining(int seconds) {
    return '$seconds seconds remaining';
  }

  @override
  String get trainingAudioContentUnavailableTitle =>
      'Voice guidance is not available yet';

  @override
  String get trainingAudioContentUnavailableBody =>
      'The approved recordings are still missing. The visual and haptic flow works, but the session is not yet fully voice-guided.';

  @override
  String get trainingSafetyStop =>
      'Stop if you feel pain, dizziness, nausea, or marked discomfort. Seek professional guidance before continuing.';

  @override
  String get trainingInterruptedTitle => 'Training paused';

  @override
  String get trainingInterruptedBody =>
      'The timer is stopped. Check your position and resume deliberately.';

  @override
  String get trainingCompletionSaving => 'Saving your completion securely…';

  @override
  String get trainingCompletionSaveFailed =>
      'Your completion could not be saved yet. The session remains stored on this device.';

  @override
  String get trainingContentUnavailableTitle => 'Training unavailable';

  @override
  String get trainingContentUnavailableBody =>
      'No verified training content is available for this package. A different package was not started as a substitute.';

  @override
  String get trainingResumeSessionTitle => 'Resume your session?';

  @override
  String get trainingResumeSessionBody =>
      'An interrupted session was found. Continue from the same point or start again.';

  @override
  String get trainingResumeSession => 'Resume';

  @override
  String get trainingStartOver => 'Start again';

  @override
  String get trainingSignInRequired => 'Sign in before starting a session.';

  @override
  String get trainingEnrollmentMissing =>
      'No active enrollment was found for this package. Start or reactivate the package first.';

  @override
  String get trainingProgressMissing =>
      'Training progress has not been set up yet. Sync again or contact support.';

  @override
  String trainingSideNumber(int number) {
    return 'Side $number';
  }

  @override
  String trainingArmCrossNumber(int number) {
    return 'Arm cross $number';
  }

  @override
  String get trainingMusicUnavailable =>
      'No verified in-app music tracks are available in this release yet.';

  @override
  String get trainingOrientationLabel => 'Orientation';

  @override
  String get trainingBreathingLabel => 'Breathing';

  @override
  String get trainingRoutineCueLabel => 'Short cue';

  @override
  String get trainingSafetyLabel => 'Safety';

  @override
  String get trainingRoutineLocked => 'After two guided sessions';

  @override
  String get trainingLearningFirstTitle => 'First pass: learn at your own pace';

  @override
  String get trainingLearningFirstBody =>
      'Learning Mode shows the full position, movement, breathing, and safety guidance.';

  @override
  String get trainingLearningSecondTitle => 'Second pass: build confidence';

  @override
  String get trainingLearningSecondBody =>
      'You will see a more compact guide. Routine Mode becomes available afterward.';

  @override
  String get trainingRoutineReadyTitle => 'Routine Mode is available';

  @override
  String get trainingRoutineReadyBody =>
      'You know the flow. Use automatic guidance or stay with the detailed instructions.';

  @override
  String get trainingContentChecking =>
      'Verified offline content is ready while updates are checked in the background.';

  @override
  String get trainingOfflineSnapshotNotice =>
      'The local or remote cache could not be used. This session uses the verified offline content for this version.';

  @override
  String get inviteTitle => 'Invite';

  @override
  String get inviteTreeHeadlineZero => 'Give someone a good start';

  @override
  String inviteTreeHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people have started through your invitation.',
      one: '1 person has started through your invitation.',
    );
    return '$_temp0';
  }

  @override
  String get inviteTreeEmptyHint =>
      'When someone completes their first training through your invitation, a branch grows here.';

  @override
  String get inviteWhy =>
      'The self-check is free, takes five minutes and needs no account. You can pass it on.';

  @override
  String get inviteShareAction => 'Share invitation';

  @override
  String get inviteCodeLabel => 'Your code';

  @override
  String get inviteCodeCopied => 'Code copied';

  @override
  String get invitePrivacyFootnote =>
      'You only learn how many people have started. Never who.';

  @override
  String inviteShareMessage(String link) {
    return 'If you are wondering whether retained primitive reflexes play a role for you: here is a free 5-minute check – no sign-up, no app. $link';
  }

  @override
  String inviteTreeSemantics(int count) {
    return 'Growing tree. $count people have started through your invitation.';
  }

  @override
  String get inviteErrorOffline =>
      'This needs a moment of internet. Please try again later.';

  @override
  String get inviteEntryTitle => 'Invite friends';

  @override
  String get inviteEntrySubtitle => 'Pass on the free self-check';

  @override
  String get impulseInviteTitle => 'Give someone a good start';

  @override
  String get impulseInviteBody =>
      'Do you know someone asking the same question? The 5-minute check is free.';

  @override
  String get inviteRedeemQuestion => 'Did someone invite you?';

  @override
  String get inviteRedeemPaste => 'Paste from clipboard';

  @override
  String get inviteRedeemSkip => 'Skip';

  @override
  String get inviteConfirmTitle => 'Accept invitation?';

  @override
  String get inviteConfirmBody =>
      'The person who invited you will later only see that one more person has started training through their invitation – never your name.';

  @override
  String get inviteConfirmAccept => 'Accept invitation';

  @override
  String get inviteConfirmDecline => 'Not now';

  @override
  String get inviteRedeemSuccess => 'Invitation accepted.';

  @override
  String get inviteErrorUnknownCode =>
      'We do not know this code. Please check the spelling.';

  @override
  String get inviteErrorCodeInactive => 'This code is no longer valid.';

  @override
  String get inviteErrorOwnCode => 'That is your own code.';

  @override
  String get inviteErrorAlreadyReferred =>
      'Your account already has an invitation.';

  @override
  String get inviteErrorAccountTooOld =>
      'An invitation can only be accepted within an account\'s first 30 days.';

  @override
  String get inviteErrorUnexpected =>
      'That did not work just now. Please try again later.';

  @override
  String get inviteCodeFieldLabel => 'Invitation code';

  @override
  String streakTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Streak · $days days',
      one: 'Streak · 1 day',
    );
    return '$_temp0';
  }

  @override
  String streakCreditsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passes',
      one: '1 pass',
      zero: 'no passes',
    );
    return '$_temp0';
  }

  @override
  String get streakRescueNotice => 'A pass saved your streak.';

  @override
  String get streakLegendTrained => 'trained';

  @override
  String get streakLegendRescued => 'pass';

  @override
  String get streakNoticeTitle => 'Reflex Journey';

  @override
  String streakNoticeWithCredits(int count) {
    return 'No practice yet today. If the day ends without training, a pass steps in — you have $count left.';
  }

  @override
  String get streakNoticeWithoutCredits =>
      'No practice yet today. Without a pass, your streak ends today.';

  @override
  String get trainingAnchorTitle => 'When should we remind you?';

  @override
  String get trainingAnchorBody =>
      'It works most reliably when the training has a fixed place in the day.';

  @override
  String get trainingAnchorRecommended => 'Recommended';

  @override
  String get trainingAnchorLater => 'Later';

  @override
  String get trainingAnchorConfirm => 'Remind me';

  @override
  String get trainingAnchorTimeLabel => 'Remind me at';

  @override
  String get trainingAnchorEveningHint =>
      'Many find it harder to fall asleep after the exercises. Leave some room before bedtime.';

  @override
  String get trainingAnchorSettingsLabel => 'Training time';

  @override
  String get trainingAnchorWakeUpAdult => 'Right after waking';

  @override
  String get trainingAnchorWakeUpAdultDetail => 'works lying down';

  @override
  String get trainingAnchorWakeUpChild => 'In the morning after waking';

  @override
  String get trainingAnchorAfterBreakfast => 'After breakfast';

  @override
  String get trainingAnchorMidday => 'Midday or during a break';

  @override
  String get trainingAnchorEvening => 'In the evening';

  @override
  String get trainingAnchorAfterSchool => 'After nursery or school';

  @override
  String get trainingAnchorAfterDinner => 'After dinner';

  @override
  String get trainingAnchorFixedTime => 'At a fixed time';
}
