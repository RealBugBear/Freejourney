import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/trainer/presentation/providers/trainer_provider.dart';
import '../../l10n/app_localizations.dart';
import 'app_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  List<String> _buildTabRoutes({
    required bool isTrainer,
    required bool isAdmin,
  }) =>
      [
        Routes.dashboard,
        Routes.progress,
        Routes.accompaniment,
        if (isTrainer) Routes.trainerDashboard,
        if (isAdmin) Routes.adminPanel,
        Routes.profile,
      ];

  int _currentIndex(BuildContext context, List<String> tabRoutes) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < tabRoutes.length; i++) {
      if (location.startsWith(tabRoutes[i])) return i;
    }
    if (location.startsWith(Routes.trainerDiscovery) ||
        location.startsWith(Routes.dm) ||
        location.startsWith(Routes.appointmentProposals) ||
        location.startsWith(Routes.community)) {
      return tabRoutes.indexOf(Routes.accompaniment);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(userRoleProvider).valueOrNull ?? 'practitioner';
    final isAdmin = role == 'admin';
    final isTrainer = role == 'trainer' || isAdmin;
    final unreadDm = ref.watch(unreadDmCountProvider);
    final tabRoutes = _buildTabRoutes(isTrainer: isTrainer, isAdmin: isAdmin);
    final currentIndex = _currentIndex(context, tabRoutes);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(tabRoutes[index]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.progressTitle,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadDm > 0,
              label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
              child: const Icon(Icons.handshake_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadDm > 0,
              label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
              child: const Icon(Icons.handshake),
            ),
            label: l10n.accompanimentTitle,
          ),
          if (isTrainer)
            NavigationDestination(
              icon: const Icon(Icons.supervisor_account_outlined),
              selectedIcon: const Icon(Icons.supervisor_account),
              label: l10n.tabTrainer,
            ),
          if (isAdmin)
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings),
              label: l10n.tabAdmin,
            ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
