import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/reflex_questionnaire.dart';

/// Adult 2×2 answer grid: Ja / Nein / ? / n. z.
///
/// Primary answers (yes/no) use stronger accents; unknown and not-applicable
/// are visually secondary but equally large and reachable.
class AdultAnswerChoiceGrid extends StatelessWidget {
  const AdultAnswerChoiceGrid({
    super.key,
    required this.value,
    required this.onSelected,
    required this.yesLabel,
    required this.noLabel,
    required this.unknownLabel,
    required this.notApplicableLabel,
  });

  final ReflexAnswerValue? value;
  final ValueChanged<ReflexAnswerChoice> onSelected;
  final String yesLabel;
  final String noLabel;
  final String unknownLabel;
  final String notApplicableLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AdultAnswerCell(
                label: yesLabel,
                semanticsLabel: yesLabel,
                selected: value?.choice == ReflexAnswerChoice.yes,
                primary: true,
                accentColor: const Color(0xFF00C882),
                icon: Icons.check,
                onTap: () => onSelected(ReflexAnswerChoice.yes),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdultAnswerCell(
                label: noLabel,
                semanticsLabel: noLabel,
                selected: value?.choice == ReflexAnswerChoice.no,
                primary: true,
                accentColor: AppColors.error,
                icon: Icons.close,
                onTap: () => onSelected(ReflexAnswerChoice.no),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdultAnswerCell(
                label: unknownLabel,
                semanticsLabel: unknownLabel,
                selected: value?.choice == ReflexAnswerChoice.unknown,
                primary: false,
                accentColor: const Color(0xFF5B8AF0),
                icon: Icons.help_outline,
                onTap: () => onSelected(ReflexAnswerChoice.unknown),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdultAnswerCell(
                label: notApplicableLabel,
                semanticsLabel: notApplicableLabel,
                selected: value?.choice == ReflexAnswerChoice.notApplicable,
                primary: false,
                accentColor: const Color(0xFF8A8F98),
                icon: Icons.not_interested,
                onTap: () => onSelected(ReflexAnswerChoice.notApplicable),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdultAnswerCell extends StatelessWidget {
  const _AdultAnswerCell({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.primary,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final bool primary;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? accentColor
        : accentColor.withValues(alpha: primary ? 0.14 : 0.08);
    final borderAlpha = selected ? 1.0 : (primary ? 0.55 : 0.35);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: borderAlpha),
                width: selected ? 2.0 : 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: primary ? 20 : 18,
                  color: selected ? Colors.white : accentColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: primary ? 15 : 14,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
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
