import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../consent/presentation/providers/consent_provider.dart';

class AnalysisPlaceholderScreen extends ConsumerWidget {
  const AnalysisPlaceholderScreen({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool(analysisPlaceholderPrefKey(userId), true);
        ref.invalidate(hasSeenAnalysisPlaceholderProvider);
      } catch (_) {
        // Do not block the consent gate if the local marker cannot be written.
      }
    }

    if (context.mounted) {
      context.go(Routes.consent);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDE = ref.watch(settingsProvider).languageCode == 'de';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDE ? 'Analyse' : 'Analysis'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ElevatedButton(
          onPressed: () => _continue(context, ref),
          child: Text(
            isDE ? 'Weiter zur Zustimmung' : 'Continue to consent',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isDE
                    ? 'Hier startet bald deine persönliche Standortanalyse.'
                    : 'Your personal baseline analysis will start here soon.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isDE
                    ? 'Vor dem ersten Training wird hier ein kurzer Fragebogen stehen. Damit kann Reflex Journey deinen aktuellen Stand besser einordnen und die Empfehlung sauberer machen.'
                    : 'Before your first training, this will become a short questionnaire. It will help Reflex Journey understand your current baseline and improve the recommendation.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 24),
              _PlaceholderStep(
                icon: Icons.assignment_outlined,
                title: isDE ? 'Fragebogen' : 'Questionnaire',
                body: isDE
                    ? 'Symptome, Belastung, Trainingsziel und bisherige Erfahrung.'
                    : 'Symptoms, load, training goal and prior experience.',
              ),
              const SizedBox(height: 12),
              _PlaceholderStep(
                icon: Icons.insights_outlined,
                title: isDE ? 'Auswertung' : 'Assessment',
                body: isDE
                    ? 'Eine ruhige Einschätzung deines aktuellen Ausgangspunkts.'
                    : 'A calm assessment of your current starting point.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderStep extends StatelessWidget {
  const _PlaceholderStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
