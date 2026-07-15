import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';

class ExerciseRestWidget extends StatefulWidget {
  final Exercise nextExercise;
  final VoidCallback onContinue;

  const ExerciseRestWidget({
    super.key,
    required this.nextExercise,
    required this.onContinue,
  });

  @override
  State<ExerciseRestWidget> createState() => _ExerciseRestWidgetState();
}

class _ExerciseRestWidgetState extends State<ExerciseRestWidget> {
  int _countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        _timer?.cancel();
        widget.onContinue();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.self_improvement, color: Colors.white54, size: 64),
          const SizedBox(height: 32),
          Text(
            '$_countdown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trainingShortBreak,
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Text(
            l10n.trainingNextExercise,
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.nextExercise.title(locale),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              widget.onContinue();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: Text(l10n.next,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
