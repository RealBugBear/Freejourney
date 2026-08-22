import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../invite/presentation/widgets/invite_impulse_i1_slot.dart';
import '../../domain/adult_reflex_profile_scoring.dart';
import '../../domain/adult_reflex_questionnaire_definitions.dart';
import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_answer_json.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/services/reflex_profile_pdf_service.dart';
import '../providers/reflex_profile_provider.dart';
import '../reflex_profile_pdf_copy.dart';
import 'adult_amphibian_detail_tile.dart';
import 'adult_reflex_detail_tile.dart';

/// Adult_v3 result body (§10.1–10.2a).
class AdultReflexProfileResultView extends ConsumerWidget {
  const AdultReflexProfileResultView({
    super.key,
    required this.assessment,
    required this.packageId,
    required this.isFirstResultDisplay,
  });

  final ReflexProfileAssessment assessment;
  final String packageId;
  final bool isFirstResultDisplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final parsed = AdultQuestionnaireScore.tryParse(assessment.scores);
    if (parsed == null) {
      return AdultReflexProfileLegacyNotice(assessment: assessment);
    }

    final sorted = parsed.reflexScores.values.toList()
      ..sort((a, b) {
        final ap = a.percent ?? -1;
        final bp = b.percent ?? -1;
        return bp.compareTo(ap);
      });

    final dateLabel = assessment.completedAt != null
        ? MaterialLocalizations.of(context).formatShortDate(
            assessment.completedAt!,
          )
        : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          l10n.adultResultTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adultResultSubline(
            dateLabel,
            assessment.questionnaireVersion,
            assessment.scoringVersion,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.adultResultDisclaimer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.adultResultHintListTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        for (final score in sorted)
          AdultReflexDetailTile(
            score: score,
            matchingAnswers: _matchingAnswerTexts(
              assessment: assessment,
              reflex: score.reflex,
              locale: locale,
            ),
          ),
        AdultAmphibianDetailTile(
          score: parsed.amphibian,
          itemMatched: _amphibianItemMatched(
            assessment: assessment,
            hiddenItemIds: parsed.meta.hiddenItemIds,
          ),
          possibleCount: _amphibianPossibleCount(
            hiddenItemIds: parsed.meta.hiddenItemIds,
          ),
          matchingAnswers: _matchingAnswerTexts(
            assessment: assessment,
            reflex: PrimitiveReflex.amphibian,
            locale: locale,
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _sharePdf(context, ref, assessment),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.reflexResultSharePdf),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.go(Routes.dashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: Text(l10n.reflexResultToDashboard),
        ),
        // §10.2a: invite below export/share, clearly separated from scores.
        const SizedBox(height: 28),
        Divider(color: cs.outlineVariant),
        const SizedBox(height: 12),
        InviteImpulseI1Slot(isFirstResultDisplay: isFirstResultDisplay),
      ],
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref,
    ReflexProfileAssessment assessment,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final screenSize = MediaQuery.of(context).size;
      final locale = Localizations.localeOf(context);
      final profile = ref.read(selectedSubjectProfileProvider);
      final subjectName = profile?.displayName.trim().isNotEmpty == true
          ? profile!.displayName.trim()
          : l10n.selfName;
      final file = await const ReflexProfilePdfService().createSummaryPdf(
        assessment,
        locale: locale,
        copy: reflexProfilePdfCopyFromL10n(l10n),
        subjectName: subjectName,
      );
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromLTWH(
              screenSize.width / 4,
              screenSize.height * 0.75,
              screenSize.width / 2,
              50,
            );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: l10n.reflexResultShareSubject,
        text: l10n.reflexResultShareText,
        sharePositionOrigin: origin,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reflexResultPdfFailed('$error'))),
        );
      }
    }
  }
}

/// Banner for adult_self_report rows that are not adult_v3 (§10.3 / §10.4).
class AdultReflexProfileLegacyNotice extends StatelessWidget {
  const AdultReflexProfileLegacyNotice({
    super.key,
    required this.assessment,
  });

  final ReflexProfileAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Icon(Icons.history_edu_outlined, size: 42, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          l10n.adultResultLegacyTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.adultResultLegacyBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.adultResultLegacyVersion(
            assessment.questionnaireVersion,
            assessment.scoringVersion,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.go(Routes.dashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: Text(l10n.reflexResultToDashboard),
        ),
      ],
    );
  }
}

List<String> _matchingAnswerTexts({
  required ReflexProfileAssessment assessment,
  required PrimitiveReflex reflex,
  required String locale,
}) {
  final texts = <String>[];
  for (final question in adultSelfQuestionnaireV3.questions) {
    if (!question.reflexes.contains(reflex)) continue;
    final raw = assessment.answers[question.id];
    if (raw is! Map) continue;
    final answer = reflexAnswerFromJson(Map<String, dynamic>.from(raw));
    if (!answer.isAnswered || answer.isUnknown || answer.isNotApplicable) {
      continue;
    }
    if (!isAdultPositiveIndication(question, answer)) continue;
    texts.add(question.text(locale));
  }
  return texts;
}

List<ReflexQuestion> _amphibianQuestions({
  required List<String> hiddenItemIds,
}) {
  final hidden = hiddenItemIds.toSet();
  return adultSelfQuestionnaireV3.questions
      .where((q) => q.reflexes.contains(PrimitiveReflex.amphibian))
      .where((q) => !hidden.contains(q.id))
      .toList(growable: false);
}

int _amphibianPossibleCount({required List<String> hiddenItemIds}) =>
    _amphibianQuestions(hiddenItemIds: hiddenItemIds).length;

List<bool> _amphibianItemMatched({
  required ReflexProfileAssessment assessment,
  required List<String> hiddenItemIds,
}) {
  return [
    for (final question in _amphibianQuestions(hiddenItemIds: hiddenItemIds))
      _isPositiveAmphibianAnswer(assessment, question),
  ];
}

bool _isPositiveAmphibianAnswer(
  ReflexProfileAssessment assessment,
  ReflexQuestion question,
) {
  final raw = assessment.answers[question.id];
  if (raw is! Map) return false;
  final answer = reflexAnswerFromJson(Map<String, dynamic>.from(raw));
  if (!answer.isAnswered || answer.isUnknown || answer.isNotApplicable) {
    return false;
  }
  return isAdultPositiveIndication(question, answer);
}
