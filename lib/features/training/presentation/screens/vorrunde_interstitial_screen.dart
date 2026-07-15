import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/vorrunde_status_settings.dart';
import '../../../../l10n/app_localizations.dart';

class VorrundeInterstitialScreen extends StatelessWidget {
  final VoidCallback onStartVorrunde;
  final VoidCallback onSkip;

  const VorrundeInterstitialScreen({
    super.key,
    required this.onStartVorrunde,
    required this.onSkip,
  });

  Future<void> _handleStart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await VorrundeStatusSettings.setStatus(prefs, 'started');
    onStartVorrunde();
  }

  Future<void> _handleSkip(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await VorrundeStatusSettings.setStatus(prefs, 'skipped');
    onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.trainingBeforeYouStart,
                style: const TextStyle(
                  color: AppColors.textDisabledDark,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.dashboardVorrunde,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.trainingWarmupInterstitialBody,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Primary card: start Vorrunde
              GestureDetector(
                onTap: () => _handleStart(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.trainingStartWarmupNow,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.trainingRecommended,
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.trainingWarmupSummary,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary card: skip
              GestureDetector(
                onTap: () => _handleSkip(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceDarkElevated),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trainingStartFirstPackageDirectly,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.trainingWarmupAvailableLater,
                        style: const TextStyle(
                          color: AppColors.textDisabledDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
