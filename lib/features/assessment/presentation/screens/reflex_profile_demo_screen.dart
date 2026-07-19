import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/reflex_profile_scoring.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/reflex_questionnaire_definitions.dart';
import '../reflex_score_band_l10n.dart';

class ReflexProfileDemoScreen extends StatefulWidget {
  const ReflexProfileDemoScreen({super.key});

  @override
  State<ReflexProfileDemoScreen> createState() =>
      _ReflexProfileDemoScreenState();
}

class _ReflexProfileDemoScreenState extends State<ReflexProfileDemoScreen> {
  final _scoringService = const ReflexProfileScoringService();
  final _answers = <String, ReflexAnswerValue>{};

  String? _selectedFor; // 'child' or 'adult'

  ReflexQuestionnaireDefinition get _definition =>
      demoChildShortQuestionnaireV1;

  void _setAnswer(ReflexQuestion question, ReflexAnswerValue answer) {
    setState(() => _answers[question.id] = answer);
  }

  void _submit() {
    final missing = _definition.questions
        .where((question) => _answers[question.id]?.isAnswered != true)
        .toList();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reflexDemoAnswerAll)),
      );
      return;
    }

    final score = _scoringService.score(
      definition: _definition,
      answers: _answers,
    );
    final rankedScores = score.reflexScores.values.toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DemoResultScreen(scores: rankedScores),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_definition.screenTitle(locale)),
        actions: [
          TextButton(
            onPressed: () =>
                context.go(user == null ? Routes.login : Routes.reflexProfile),
            child: Text(user == null
                ? AppLocalizations.of(context).signIn
                : AppLocalizations.of(context).reflexDemoFullTest),
          ),
        ],
      ),
      body: _selectedFor == null
          ? _buildForWhom()
          : _selectedFor == 'adult'
              ? _buildAdultComingSoon()
              : _buildQuestionnaire(user),
    );
  }

  Widget _buildForWhom() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const Icon(Icons.insights_outlined, size: 44, color: AppColors.primary),
        const SizedBox(height: 18),
        Text(
          l10n.reflexDemoForWhomTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.reflexDemoForWhomBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 28),
        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.child_care_outlined,
                color: AppColors.primary, size: 28),
            title: Text(
              l10n.reflexProfileForMyChild,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(l10n.reflexProfileParentQuestionnaire),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedFor = 'child'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(Icons.person_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 28),
            title: Text(
              l10n.reflexProfileForMyself,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(l10n.reflexProfileForMyselfComingSoon),
            trailing: const Icon(Icons.lock_outline, size: 16),
            onTap: () => setState(() => _selectedFor = 'adult'),
          ),
        ),
      ],
    );
  }

  Widget _buildAdultComingSoon() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.reflexDemoSelfComingSoonTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.reflexDemoSelfComingSoonBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedFor = null),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaire(User? user) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          l10n.reflexDemoTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.reflexDemoIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 18),
        for (final question in _definition.questions)
          _DemoQuestionTile(
            question: question,
            answer: _answers[question.id],
            onChanged: (answer) => _setAnswer(question, answer),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.insights_outlined),
          label: Text(l10n.reflexDemoEvaluate),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user == null
                      ? l10n.reflexDemoSignInForFull
                      : l10n.reflexDemoStartFull,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  user == null
                      ? l10n.reflexDemoGuestHint
                      : l10n.reflexDemoSignedInHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => context
                        .go(user == null ? Routes.login : Routes.reflexProfile),
                    child: Text(user == null
                        ? l10n.reflexDemoSignInOrRegister
                        : l10n.reflexDemoOpenFullTest),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Demo Result Screen (Navigator.push, no route needed — data is local)
// ---------------------------------------------------------------------------

class _DemoResultScreen extends StatelessWidget {
  const _DemoResultScreen({required this.scores});

  final List<ReflexScoreResult> scores;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final locale = Localizations.localeOf(context).languageCode;
    final topScores = scores.take(8).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reflexDemoResultTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.reflexDemoResultHeadline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.reflexDemoResultDisclaimer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: topScores.length >= 3
                        ? CustomPaint(
                            painter: _DemoRadarPainter(
                              scores: topScores,
                              gridColor: AppColors.divider,
                              fillColor:
                                  AppColors.primary.withValues(alpha: 0.13),
                              strokeColor: AppColors.primary,
                              locale: locale,
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          )
                        : Center(
                            child: Text(l10n.reflexDemoNotEnoughChartData)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.reflexDemoChartCaption,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.reflexResultAreasTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          for (final score in scores) _DemoScoreTile(score: score),
          const SizedBox(height: 20),
          Card(
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user == null
                        ? l10n.reflexDemoStartFull
                        : l10n.reflexDemoOpenFullTest,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user == null
                        ? l10n.reflexDemoAccountBenefitGuest
                        : l10n.reflexDemoAccountBenefitSignedIn,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => context.go(
                          user == null ? Routes.login : Routes.reflexProfile),
                      child: Text(user == null
                          ? l10n.reflexDemoSignInOrRegister
                          : l10n.reflexDemoOpenFullTest),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoScoreTile extends StatelessWidget {
  const _DemoScoreTile({required this.score});

  final ReflexScoreResult score;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _bandColor(score.band);
    final locale = Localizations.localeOf(context).languageCode;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    score.reflex.label(locale),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${score.percent.round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              scoreBandLabel(l10n, score.band),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (score.percent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoRadarPainter extends CustomPainter {
  const _DemoRadarPainter({
    required this.scores,
    required this.gridColor,
    required this.fillColor,
    required this.strokeColor,
    required this.locale,
    required this.labelStyle,
  });

  final List<ReflexScoreResult> scores;
  final Color gridColor;
  final Color fillColor;
  final Color strokeColor;
  final String locale;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;

    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      final ringRadius = radius * ring / 4;
      for (var i = 0; i < scores.length; i++) {
        final point = _point(center, ringRadius, i, scores.length);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < scores.length; i++) {
      final point = _point(center, radius, i, scores.length);
      canvas.drawLine(center, point, gridPaint);
    }

    final scorePath = Path();
    for (var i = 0; i < scores.length; i++) {
      final valueRadius = radius * (scores[i].percent.clamp(0, 100) / 100);
      final point = _point(center, valueRadius, i, scores.length);
      if (i == 0) {
        scorePath.moveTo(point.dx, point.dy);
      } else {
        scorePath.lineTo(point.dx, point.dy);
      }
    }
    scorePath.close();
    canvas.drawPath(scorePath, fillPaint);
    canvas.drawPath(scorePath, strokePaint);

    for (var i = 0; i < scores.length; i++) {
      final labelPoint = _point(center, radius + 30, i, scores.length);
      final label = scores[i].reflex.shortLabel(locale);
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: 74);
      painter.paint(
        canvas,
        labelPoint - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  Offset _point(Offset center, double radius, int index, int count) {
    final angle = -math.pi / 2 + (math.pi * 2 * index / count);
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _DemoRadarPainter oldDelegate) =>
      oldDelegate.scores != scores || oldDelegate.locale != locale;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DemoQuestionTile extends StatelessWidget {
  const _DemoQuestionTile({
    required this.question,
    required this.answer,
    required this.onChanged,
  });

  final ReflexQuestion question;
  final ReflexAnswerValue? answer;
  final ValueChanged<ReflexAnswerValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text(locale),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              segments: [
                ButtonSegment(value: 'yes', label: Text(l10n.yes)),
                ButtonSegment(value: 'no', label: Text(l10n.no)),
                ButtonSegment(value: 'unknown', label: Text(l10n.answerUnknown)),
              ],
              selected: {
                if (answer?.yesNoUnknown == true)
                  'yes'
                else if (answer?.yesNoUnknown == false)
                  'no'
                else if (answer?.isUnknown == true)
                  'unknown',
              },
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                final value = values.first;
                onChanged(
                  ReflexAnswerValue(
                    yesNoUnknown: value == 'unknown' ? null : value == 'yes',
                    isUnknown: value == 'unknown',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Color _bandColor(ReflexScoreBand band) => switch (band) {
      ReflexScoreBand.strong => AppColors.error,
      ReflexScoreBand.elevated => AppColors.warning,
      ReflexScoreBand.indication => AppColors.primary,
      ReflexScoreBand.inconspicuous => AppColors.success,
      ReflexScoreBand.insufficientData => const Color(0xFF9E9E9E),
    };

