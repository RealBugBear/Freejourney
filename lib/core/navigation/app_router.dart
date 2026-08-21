import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/launch_flags.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/consent/presentation/providers/consent_provider.dart';
import '../settings/settings_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/consent/presentation/screens/consent_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/assessment/presentation/screens/analysis_placeholder_screen.dart';
import '../../features/assessment/presentation/screens/reflex_profile_demo_screen.dart';
import '../../features/assessment/presentation/screens/reflex_profile_screen.dart';
import '../../features/assessment/presentation/screens/reflex_profile_result_screen.dart';
import '../../features/assessment/presentation/screens/intake_assessment_screen.dart';
import '../../features/assessment/presentation/screens/duration_recommendation_screen.dart';
import '../../features/assessment/presentation/screens/trainer_onboarding_prompt_screen.dart';
import '../../features/assessment/presentation/screens/completion_questionnaire_screen.dart';
import '../../features/training/presentation/screens/training_session_screen.dart';
import '../../features/training/presentation/screens/training_start_flow_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/language_selection_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/trainer/presentation/screens/trainer_clients_screen.dart';
import '../../features/trainer/presentation/screens/trainer_client_detail_screen.dart';
import '../../features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import '../../features/trainer/presentation/screens/appointment_scheduler_screen.dart';
import '../../features/trainer/presentation/screens/appointment_proposal_screen.dart';
import '../../features/trainer/domain/models/trainer_client.dart';
import '../../features/trainer/presentation/screens/trainer_discovery_screen.dart';
import '../../features/trainer/presentation/screens/trainer_profile_setup_screen.dart';
import '../../features/trainer/presentation/screens/trainer_profile_pending_screen.dart';
import '../../features/trainer/presentation/screens/trainer_application_intro_screen.dart';
import '../../features/trainer/presentation/screens/trainer_application_form_screen.dart';
import '../../features/trainer/presentation/screens/trainer_application_status_screen.dart';
import '../../features/trainer/presentation/screens/trainer_public_profile_screen.dart';
import '../../features/trainer/presentation/screens/trainer_requests_screen.dart';
import '../../features/trainer/domain/models/trainer_profile.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/progress/presentation/screens/progress_overview_screen.dart';
import '../../features/dev_tools/presentation/screens/dev_tools_screen.dart';
import '../../features/premium/presentation/screens/paywall_screen.dart';
import '../../features/invite/presentation/screens/invite_screen.dart';
import '../../features/invite/presentation/screens/invite_redeem_screen.dart';
import '../../features/chat/domain/models/chat_channel.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../features/accompaniment/presentation/screens/accompaniment_screen.dart';
import '../../features/chat/presentation/screens/chat_channel_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/chat/presentation/screens/dm_screen.dart';
import '../../features/experience/presentation/screens/experience_feed_screen.dart';
import '../../features/packages/presentation/screens/packages_screen.dart';
import '../../features/onboarding/presentation/screens/for_whom_screen.dart';
import '../../features/onboarding/presentation/screens/entry_points_screen.dart';
import '../../features/profile/presentation/screens/username_setup_screen.dart';
import 'app_shell.dart';

// Route name constants
class Routes {
  static const login = '/login';
  static const languageSelection = '/language';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/profile/change-password';
  static const devTools = '/dev-tools';
  static const consent = '/consent';
  static const analysisPlaceholder = '/onboarding/analysis';
  static const reflexProfileDemo = '/reflex-profile/demo';
  static const reflexProfile = '/reflex-profile';
  static const reflexProfileResult = '/reflex-profile/result';
  static const dashboard = '/dashboard';
  static const progress = '/verlauf';
  static const accompaniment = '/begleitung';
  static const intakeAssessment = '/intake-assessment';
  static const trainingStart = '/training/start';
  static const trainerOnboardingPrompt = '/intake-assessment/trainer';
  static const durationRecommendation = '/intake-assessment/duration';
  static const completionQuestionnaire = '/completion-questionnaire';
  static const trainingSession = '/training/session';
  static const journal = '/journal';
  static const packages = '/packages';
  static const settings = '/settings';
  static const profile = '/profile';
  static const trainerClients = '/trainer/clients';
  static const trainerClientDetail = '/trainer/clients/:clientId';
  static const trainerDashboard = '/trainer/dashboard';
  static const appointmentScheduler = '/trainer/appointment/:clientId';
  static const appointmentProposals = '/appointments/proposals';
  static const community = '/community';
  static const dm = '/dm';
  static const dmChannel = '/dm/:channelId';
  static const adminPanel = '/admin';
  static const trainerDiscovery = '/trainers';
  static const trainerProfileSetup = '/trainer/profile-setup';
  static const trainerProfilePending = '/trainer/profile-pending';
  static const trainerApplicationIntro = '/trainer/apply';
  static const trainerApplicationForm = '/trainer/application';
  static const trainerApplicationStatus = '/trainer/application/status';
  static const trainerPublicProfile = '/trainers/:trainerId';
  static const trainerRequests = '/trainer/requests';
  static const usernameSetup = '/username-setup';
  static const onboardingForWhom = '/onboarding/for-whom';
  static const onboardingEntryPoints = '/onboarding/entry-points';
  static const experienceFeed = '/experience/:channelId';
  static const paywall = '/paywall';
  static const invite = '/einladen';
  static const inviteAccept = '/einladung';
}

/// T04 (D1=A): Solange Community/Feed deaktiviert sind, landet jede direkte
/// Navigation dorthin (Deep Link, alter Push-Payload, programmatischer
/// Aufruf) sauber auf dem Dashboard statt in einem Crash oder 404.
String? communityGateRedirect(BuildContext context, GoRouterState state) =>
    kCommunityEnabled ? null : Routes.dashboard;

/// T23 (D4): Solange die Paywall deaktiviert ist, leitet jede direkte
/// Navigation zu `/paywall` aufs Dashboard um — der Screen existiert im
/// Code, ist aber vor der Aktivierung (R8-Trigger + AGB + T25) unerreichbar.
String? paywallGateRedirect(BuildContext context, GoRouterState state) =>
    kPaywallEnabled ? null : Routes.dashboard;

/// Einladungen: Solange [kInviteEnabled] aus ist, leiten `/einladen` und
/// `/einladung` aufs Dashboard um. Flag gated nur die App-Oberfläche.
String? inviteGateRedirect(BuildContext context, GoRouterState state) =>
    kInviteEnabled ? null : Routes.dashboard;

/// Bridges a Stream into a [Listenable] so GoRouter can react to auth changes.
class _StreamRefreshListenable extends ChangeNotifier {
  _StreamRefreshListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _SimpleNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Combines multiple [Listenable]s into one so GoRouter reacts to any of them.
class _CombinedListenable extends ChangeNotifier {
  _CombinedListenable(List<Listenable> listenables) {
    for (final l in listenables) {
      l.addListener(notifyListeners);
    }
    _listenables = listenables;
  }
  late final List<Listenable> _listenables;

  @override
  void dispose() {
    for (final l in _listenables) {
      l.removeListener(notifyListeners);
    }
    super.dispose();
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Sync local-prefs consent check for GoRouter (avoids painting Dashboard
/// before the async consent gate can redirect).
bool _hasLocalConsent(Ref ref, String userId) {
  return ref.read(sharedPreferencesProvider).getBool(consentPrefKey(userId)) ==
      true;
}

bool _isConsentExemptRoute(String loc) {
  return loc == Routes.consent ||
      loc == Routes.login ||
      loc == Routes.resetPassword ||
      loc == Routes.changePassword ||
      loc == Routes.languageSelection ||
      loc == Routes.reflexProfileDemo;
}

String _postAuthHome(Ref ref, String userId) {
  return _hasLocalConsent(ref, userId) ? Routes.dashboard : Routes.consent;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _StreamRefreshListenable(
    Supabase.instance.client.auth.onAuthStateChange,
  );

  // Notifies GoRouter whenever the password-recovery flag changes so the
  // redirect logic re-runs immediately — without waiting for a Supabase event.
  final recoveryRefresh = _SimpleNotifier();
  ref.listen(
      passwordRecoveryActiveProvider, (_, __) => recoveryRefresh.notify());

  final combined = _CombinedListenable([authRefresh, recoveryRefresh]);

  ref.onDispose(() {
    authRefresh.dispose();
    recoveryRefresh.dispose();
    combined.dispose();
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.login,
    refreshListenable: combined,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isPasswordRecovery = ref.read(passwordRecoveryActiveProvider);
      final hasSelectedLanguage = ref.read(hasSelectedLanguageProvider);
      final loc = state.matchedLocation;
      // languageSelection is public: a fresh install is logged-out AND has no
      // saved language, so it must be reachable without a session — otherwise
      // the "user == null -> /login" rule below bounces it back to /login, which
      // re-redirects to /language (no language yet): an infinite loop (P1.2).
      final isPublicRoute = loc == Routes.login ||
          loc == Routes.resetPassword ||
          loc == Routes.languageSelection ||
          loc == Routes.reflexProfileDemo;

      // Password-Recovery Deep Link: Vorrang vor allem anderen
      if (isPasswordRecovery && loc != Routes.resetPassword) {
        return Routes.resetPassword;
      }
      if (!hasSelectedLanguage && loc != Routes.languageSelection) {
        return Routes.languageSelection;
      }
      if (hasSelectedLanguage && loc == Routes.languageSelection) {
        if (user == null) return Routes.login;
        return _postAuthHome(ref, user.id);
      }
      // Nicht eingeloggt → Login (außer während Recovery)
      if (user == null && !isPublicRoute) {
        return Routes.login;
      }
      // Eingeloggt: never paint Dashboard (or other app chrome) before Consent.
      if (user != null && !isPasswordRecovery) {
        final consented = _hasLocalConsent(ref, user.id);
        if (!consented && !_isConsentExemptRoute(loc)) {
          return Routes.consent;
        }
        if (loc == Routes.login) {
          return _postAuthHome(ref, user.id);
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.languageSelection,
        name: 'language-selection',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.consent,
        name: 'consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: Routes.analysisPlaceholder,
        name: 'analysis-placeholder',
        builder: (context, state) => const AnalysisPlaceholderScreen(),
      ),
      GoRoute(
        path: Routes.reflexProfileDemo,
        name: 'reflex-profile-demo',
        builder: (context, state) => const ReflexProfileDemoScreen(),
      ),
      GoRoute(
        path: Routes.reflexProfile,
        name: 'reflex-profile',
        builder: (context, state) => const ReflexProfileScreen(),
      ),
      GoRoute(
        path: Routes.reflexProfileResult,
        name: 'reflex-profile-result',
        builder: (context, state) => const ReflexProfileResultScreen(),
      ),
      GoRoute(
        path: Routes.trainingStart,
        name: 'training-start',
        builder: (context, state) => const TrainingStartFlowScreen(),
      ),
      GoRoute(
        path: Routes.intakeAssessment,
        name: 'intake-assessment',
        builder: (context, state) => const IntakeAssessmentScreen(),
      ),
      GoRoute(
        path: Routes.trainerOnboardingPrompt,
        name: 'trainer-onboarding-prompt',
        builder: (context, state) => const TrainerOnboardingPromptScreen(),
      ),
      GoRoute(
        path: Routes.durationRecommendation,
        name: 'duration-recommendation',
        builder: (context, state) => const DurationRecommendationScreen(),
      ),
      GoRoute(
        path: Routes.completionQuestionnaire,
        name: 'completion-questionnaire',
        builder: (context, state) {
          final enrollmentId = state.extra as String? ?? '';
          return CompletionQuestionnaireScreen(enrollmentId: enrollmentId);
        },
      ),
      GoRoute(
        path: Routes.trainingSession,
        name: 'training-session',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is TrainingSessionLaunchArgs) {
            return TrainingSessionScreen(
              packageId: extra.packageId,
              companionSubjectProfileIds: extra.companionSubjectProfileIds,
            );
          }
          final packageId = extra as String? ?? 'moro';
          return TrainingSessionScreen(packageId: packageId);
        },
      ),
      GoRoute(
        path: Routes.journal,
        name: 'journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.trainerClients,
        name: 'trainer-clients',
        builder: (context, state) => const TrainerClientsScreen(),
      ),
      GoRoute(
        path: Routes.trainerClientDetail,
        name: 'trainer-client-detail',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return TrainerClientDetailScreen(clientId: clientId);
        },
      ),
      GoRoute(
        path: Routes.appointmentScheduler,
        name: 'appointment-scheduler',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final extra = state.extra;
          final TrainerClient? client;
          final String? reviewChannelId;
          if (extra is Map<String, Object?>) {
            client = extra['client'] as TrainerClient?;
            reviewChannelId = extra['reviewChannelId'] as String?;
          } else {
            client = extra as TrainerClient?;
            reviewChannelId = null;
          }
          // Fallback minimal client if navigated without extra
          return AppointmentSchedulerScreen(
            client: client ??
                TrainerClient(
                  relationshipId: '',
                  clientId: clientId,
                  displayName: AppLocalizations.of(context).clientFallbackName,
                  currentDay: 1,
                  dailyStreak: 0,
                ),
            reviewChannelId: reviewChannelId,
          );
        },
      ),
      GoRoute(
        path: Routes.usernameSetup,
        name: 'username-setup',
        builder: (context, state) => const UsernameSetupScreen(),
      ),
      GoRoute(
        path: Routes.onboardingForWhom,
        name: 'onboarding-for-whom',
        builder: (context, state) => const ForWhomScreen(),
      ),
      GoRoute(
        path: Routes.onboardingEntryPoints,
        name: 'onboarding-entry-points',
        builder: (context, state) => const EntryPointsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: Routes.experienceFeed,
        name: 'experience-feed',
        redirect: communityGateRedirect,
        builder: (context, state) {
          final channel = state.extra as ChatChannel;
          return ExperienceFeedScreen(channel: channel);
        },
      ),
      GoRoute(
        path: Routes.devTools,
        name: 'dev-tools',
        builder: (context, state) => const DevToolsScreen(),
      ),
      GoRoute(
        path: Routes.paywall,
        name: 'paywall',
        redirect: paywallGateRedirect,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: Routes.invite,
        name: 'invite',
        redirect: inviteGateRedirect,
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: Routes.inviteAccept,
        name: 'invite-accept',
        redirect: inviteGateRedirect,
        builder: (context, state) => InviteRedeemScreen(
          initialCode: state.uri.queryParameters['c'],
          isOnboarding: state.uri.queryParameters['onboarding'] == '1',
        ),
      ),
      GoRoute(
        path: Routes.trainerDiscovery,
        name: 'trainer-discovery',
        builder: (context, state) => TrainerDiscoveryScreen(
          onboardingExtra:
              (state.extra as Map<String, Object?>?)?['onboardingExtra']
                  as Map<String, dynamic>?,
        ),
      ),
      // ── Shell: persists bottom navigation bar ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.progress,
            name: 'progress',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProgressOverviewScreen(),
            ),
          ),
          GoRoute(
            path: Routes.accompaniment,
            name: 'accompaniment',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AccompanimentScreen(),
            ),
          ),
          GoRoute(
            path: Routes.community,
            name: 'community',
            redirect: communityGateRedirect,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CommunityScreen(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: Routes.trainerDashboard,
            name: 'trainer-dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TrainerDashboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.adminPanel,
            name: 'admin-panel',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AdminPanelScreen(),
            ),
          ),
          GoRoute(
            path: Routes.dm,
            name: 'dm',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DmScreen(),
            ),
            routes: [
              GoRoute(
                path: ':channelId',
                name: 'dm-channel',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  final channel = state.extra as ChatChannel?;
                  return ChatChannelScreen(
                    channelId: channelId,
                    channel: channel,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.appointmentProposals,
            name: 'appointment-proposals',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AppointmentProposalScreen(),
            ),
          ),
          GoRoute(
            path: Routes.packages,
            name: 'packages',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PackagesScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.trainerProfileSetup,
        name: 'trainer-profile-setup',
        redirect: (context, state) => Routes.trainerApplicationForm,
        builder: (context, state) => const TrainerProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.trainerProfilePending,
        name: 'trainer-profile-pending',
        redirect: (context, state) => Routes.trainerApplicationStatus,
        builder: (context, state) => const TrainerProfilePendingScreen(),
      ),
      GoRoute(
        path: Routes.trainerApplicationIntro,
        name: 'trainer-application-intro',
        builder: (context, state) => const TrainerApplicationIntroScreen(),
      ),
      GoRoute(
        path: Routes.trainerApplicationForm,
        name: 'trainer-application-form',
        builder: (context, state) => const TrainerApplicationFormScreen(),
      ),
      GoRoute(
        path: Routes.trainerApplicationStatus,
        name: 'trainer-application-status',
        builder: (context, state) => const TrainerApplicationStatusScreen(),
      ),
      GoRoute(
        path: Routes.trainerPublicProfile,
        name: 'trainer-public-profile',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, Object?>) {
            final trainer = extra['trainer'] as TrainerProfile;
            final onboardingExtra =
                extra['onboardingExtra'] as Map<String, dynamic>?;
            return TrainerPublicProfileScreen(
              trainer: trainer,
              onboardingExtra: onboardingExtra,
            );
          }
          final trainer = extra as TrainerProfile;
          return TrainerPublicProfileScreen(trainer: trainer);
        },
      ),
      GoRoute(
        path: Routes.trainerRequests,
        name: 'trainer-requests',
        builder: (context, state) => const TrainerRequestsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).routeNotFound('${state.error}'),
        ),
      ),
    ),
  );
});
