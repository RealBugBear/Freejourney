import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/premium_glassmorphic_card.dart';

class TrainingPreparationScreen extends StatelessWidget {
  final int exerciseNumber;
  final String title;
  final String text;
  final VoidCallback onContinue;

  const TrainingPreparationScreen({
    super.key,
    required this.exerciseNumber,
    required this.title,
    required this.text,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingExerciseOfTotal(exerciseNumber, 7)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Progress Indicator - Sleek
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: exerciseNumber / 7,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    minHeight: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary),
                  ),
                ),

                const SizedBox(height: 40),

                // Icon - Larger and more prominent
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title - Bold and clear
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Glassmorphic Content Card
                Expanded(
                  child: PremiumGlassmorphicCard(
                    blur: 25,
                    opacity: 0.15,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Continue Button - Prominent
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      l10n.next,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
