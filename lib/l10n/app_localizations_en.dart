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
  String get authErrorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse => 'This email address is already registered.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 8 characters.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get startTraining => 'Begin Unit';

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
  String get trainingMode => 'Unit Mode';

  @override
  String get tutorialMode => 'Tutorial';

  @override
  String get routineMode => 'Routine';

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
  String get sessionComplete => 'Unit Complete';

  @override
  String get sessionCompleteSubtitle => 'You have completed today\'s unit.';

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
  String get moodChartEmpty => 'Log a unit to see your wellbeing over time.';

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
  String get packageAvailable => 'Available';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTraining => 'Units';

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
  String get settingsFeedback => 'Unit Feedback';

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
      'Write down what you observe in daily life — after a unit or whenever you like.';

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
  String get appointmentStatusCancelled => 'Cancelled';

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
  String get trainerDiscoveryLocationDenied =>
      'Location permission is required to find trainers nearby.';

  @override
  String trainerDiscoveryRadiusLabel(int radius) {
    return '$radius km';
  }

  @override
  String get trainerDiscoveryEmpty => 'No trainers found nearby.';

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
}
