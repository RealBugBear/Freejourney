import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class TrainerApplicationIntroScreen extends StatelessWidget {
  const TrainerApplicationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainer werden')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Bewerbung und Prüfung',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Reflex Journey-Trainer arbeiten in einem sensiblen Umfeld. Deshalb '
            'prüfen wir jede Bewerbung manuell, bevor ein Trainerprofil '
            'freigeschaltet wird.',
          ),
          const SizedBox(height: 20),
          const _RequirementTile(
            icon: Icons.work_outline,
            title: 'Fachlicher Hintergrund',
            body:
                'Beschreibe deine Ausbildung, Erfahrung oder Praxis im relevanten Bereich.',
          ),
          const _RequirementTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Erweitertes Führungszeugnis Stufe 2',
            body:
                'Im Review-Kanal fordern Admins die Sichtprüfung an. Das Dokument wird nicht hochgeladen oder gespeichert.',
          ),
          const _RequirementTile(
            icon: Icons.chat_bubble_outline,
            title: 'Admin-Review-Kanal',
            body:
                'Nach dem Absenden öffnet sich ein geschützter Kommunikationskanal mit den Admins.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Wichtig: Der Aktivierungscode wird erst nach erfolgreicher Prüfung erzeugt.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(Routes.trainerApplicationForm),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Bewerbung starten'),
          ),
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
