import 'dart:io';
import 'dart:ui' show Locale;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/l10n/app_languages.dart';
import '../models/reflex_profile_assessment.dart';
import '../reflex_questionnaire.dart';
import '../reflex_questionnaire_definitions.dart';

typedef ReflexProfilePdfDateCopy = String Function(String formattedDate);
typedef ReflexProfilePdfCountCopy = String Function(int count);

/// All translated copy needed to create a reflex-profile summary PDF.
///
/// [generatedOn], [safetyNotice], and [months] accept complete ICU-formatted
/// messages from the caller. This keeps sentence structure and plural rules in
/// the localization layer instead of assembling translated fragments here.
class ReflexProfilePdfCopy {
  const ReflexProfilePdfCopy({
    required this.title,
    required this.author,
    required this.generatedOn,
    required this.summaryNotice,
    required this.safetyNotice,
    required this.reflexOverviewTitle,
    required this.reflexAreaHeader,
    required this.percentHeader,
    required this.classificationHeader,
    required this.yesAnsweredHeader,
    required this.answerOverviewTitle,
    required this.questionHeader,
    required this.answerHeader,
    required this.bandStrong,
    required this.bandElevated,
    required this.bandIndication,
    required this.bandInconspicuous,
    required this.bandInsufficientData,
    required this.answerYes,
    required this.answerNo,
    required this.answerUnknown,
    required this.months,
    required this.emptyAnswer,
    required this.fileNameStem,
  });

  final String title;
  final String author;
  final ReflexProfilePdfDateCopy generatedOn;
  final String summaryNotice;
  final ReflexProfilePdfCountCopy safetyNotice;
  final String reflexOverviewTitle;
  final String reflexAreaHeader;
  final String percentHeader;
  final String classificationHeader;
  final String yesAnsweredHeader;
  final String answerOverviewTitle;
  final String questionHeader;
  final String answerHeader;
  final String bandStrong;
  final String bandElevated;
  final String bandIndication;
  final String bandInconspicuous;
  final String bandInsufficientData;
  final String answerYes;
  final String answerNo;
  final String answerUnknown;
  final ReflexProfilePdfCountCopy months;
  final String emptyAnswer;
  final String fileNameStem;
}

/// Locale-resolved, render-ready content for a reflex-profile summary PDF.
///
/// Keeping content preparation separate from PDF layout makes locale behavior
/// deterministic and directly testable without parsing generated PDF bytes.
class ReflexProfilePdfContent {
  const ReflexProfilePdfContent({
    required this.title,
    required this.author,
    required this.generatedOn,
    required this.summaryNotice,
    required this.safetyNotice,
    required this.reflexOverviewTitle,
    required this.scoreHeaders,
    required this.scoreRows,
    required this.answerOverviewTitle,
    required this.answerHeaders,
    required this.answerRows,
    required this.fileNameStem,
  });

  final String title;
  final String author;
  final String generatedOn;
  final String summaryNotice;
  final String? safetyNotice;
  final String reflexOverviewTitle;
  final List<String> scoreHeaders;
  final List<ReflexProfilePdfScoreRow> scoreRows;
  final String answerOverviewTitle;
  final List<String> answerHeaders;
  final List<ReflexProfilePdfAnswerRow> answerRows;
  final String fileNameStem;
}

class ReflexProfilePdfScoreRow {
  const ReflexProfilePdfScoreRow({
    required this.label,
    required this.percent,
    required this.band,
    required this.yesAnswered,
  });

  final String label;
  final String percent;
  final String band;
  final String yesAnswered;
}

class ReflexProfilePdfAnswerRow {
  const ReflexProfilePdfAnswerRow({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

class ReflexProfilePdfService {
  const ReflexProfilePdfService();

  ReflexProfilePdfContent buildSummaryContent(
    ReflexProfileAssessment assessment, {
    required Locale locale,
    required ReflexProfilePdfCopy copy,
  }) {
    final completedAt = assessment.completedAt ?? assessment.createdAt;
    final localeCode = AppLanguages.normalize(locale.languageCode);
    final datePattern =
        localeCode == AppLanguages.sourceCode ? 'dd.MM.yyyy' : 'MM/dd/yyyy';
    final formattedDate = DateFormat(datePattern).format(completedAt);

    return ReflexProfilePdfContent(
      title: copy.title,
      author: copy.author,
      generatedOn: copy.generatedOn(formattedDate),
      summaryNotice: copy.summaryNotice,
      safetyNotice: assessment.warningConfirmations.isEmpty
          ? null
          : copy.safetyNotice(assessment.warningConfirmations.length),
      reflexOverviewTitle: copy.reflexOverviewTitle,
      scoreHeaders: [
        copy.reflexAreaHeader,
        copy.percentHeader,
        copy.classificationHeader,
        copy.yesAnsweredHeader,
      ],
      scoreRows: _scoreRows(
        assessment,
        localeCode: localeCode,
        copy: copy,
      ),
      answerOverviewTitle: copy.answerOverviewTitle,
      answerHeaders: [copy.questionHeader, copy.answerHeader],
      answerRows: _answerRows(
        assessment,
        localeCode: localeCode,
        copy: copy,
      ),
      fileNameStem: copy.fileNameStem,
    );
  }

  Future<File> createSummaryPdf(
    ReflexProfileAssessment assessment, {
    required Locale locale,
    required ReflexProfilePdfCopy copy,
    DateTime? generatedAt,
  }) async {
    final content = buildSummaryContent(
      assessment,
      locale: locale,
      copy: copy,
    );
    final document = pw.Document(
      title: content.title,
      author: content.author,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            content.title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            content.generatedOn,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              content.summaryNotice,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          if (content.safetyNotice case final safetyNotice?) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.orange400),
              ),
              child: pw.Text(
                safetyNotice,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            content.reflexOverviewTitle,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: content.scoreHeaders,
            data: content.scoreRows
                .map(
                  (score) => [
                    score.label,
                    score.percent,
                    score.band,
                    score.yesAnswered,
                  ],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            content.answerOverviewTitle,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: content.answerHeaders,
            data: content.answerRows
                .map(
                  (answer) => [answer.question, answer.answer],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1),
            },
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(
      generatedAt ?? DateTime.now(),
    );
    final file = File('${directory.path}/${content.fileNameStem}_$timestamp.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }
}

class _RawPdfScoreRow {
  const _RawPdfScoreRow({
    required this.key,
    required this.percent,
    required this.band,
    required this.yesCount,
    required this.answeredCount,
  });

  final String key;
  final double percent;
  final ReflexScoreBand band;
  final int yesCount;
  final int answeredCount;
}

List<ReflexProfilePdfScoreRow> _scoreRows(
  ReflexProfileAssessment assessment, {
  required String localeCode,
  required ReflexProfilePdfCopy copy,
}) {
  final rows = <_RawPdfScoreRow>[];
  for (final entry in assessment.scores.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    rows.add(
      _RawPdfScoreRow(
        key: entry.key,
        percent: (raw['percent'] as num?)?.toDouble() ?? 0,
        band: _scoreBandFromName(raw['band'] as String? ?? ''),
        yesCount: (raw['yes_count'] as num?)?.toInt() ?? 0,
        answeredCount: (raw['answered_count'] as num?)?.toInt() ?? 0,
      ),
    );
  }
  rows.sort((a, b) => b.percent.compareTo(a.percent));

  return rows
      .map(
        (row) => ReflexProfilePdfScoreRow(
          label: _reflexLabel(row.key, localeCode),
          percent: '${row.percent.round()}%',
          band: _bandLabel(row.band, copy),
          yesAnswered: '${row.yesCount} / ${row.answeredCount}',
        ),
      )
      .toList();
}

List<ReflexProfilePdfAnswerRow> _answerRows(
  ReflexProfileAssessment assessment, {
  required String localeCode,
  required ReflexProfilePdfCopy copy,
}) {
  final questionById = {
    for (final question in childParentQuestionnaireV1.questions)
      question.id: '${question.number}. ${question.text(localeCode)}',
  };
  return assessment.answers.entries
      .map(
        (entry) => ReflexProfilePdfAnswerRow(
          question: questionById[entry.key] ?? entry.key,
          answer: _formatAnswer(entry.value, copy),
        ),
      )
      .toList();
}

ReflexScoreBand _scoreBandFromName(String name) {
  return ReflexScoreBand.values.firstWhere(
    (band) => band.name == name,
    orElse: () => ReflexScoreBand.insufficientData,
  );
}

String _bandLabel(ReflexScoreBand band, ReflexProfilePdfCopy copy) {
  return switch (band) {
    ReflexScoreBand.strong => copy.bandStrong,
    ReflexScoreBand.elevated => copy.bandElevated,
    ReflexScoreBand.indication => copy.bandIndication,
    ReflexScoreBand.inconspicuous => copy.bandInconspicuous,
    ReflexScoreBand.insufficientData => copy.bandInsufficientData,
  };
}

String _formatAnswer(dynamic value, ReflexProfilePdfCopy copy) {
  if (value is! Map) return value.toString();
  final parts = <String>[];
  final answer = value['answer'];
  if (answer == 'yes') parts.add(copy.answerYes);
  if (answer == 'no') parts.add(copy.answerNo);
  if (answer == 'unknown') parts.add(copy.answerUnknown);

  final rawMonths = value['months'];
  if (rawMonths != null) {
    final months = rawMonths is num
        ? rawMonths.toInt()
        : int.tryParse(rawMonths.toString());
    if (months != null) parts.add(copy.months(months));
  }

  final selected = value['selected_options'];
  if (selected is List && selected.isNotEmpty) parts.add(selected.join(', '));
  final text = value['text'];
  if (text is String && text.trim().isNotEmpty) parts.add(text.trim());
  return parts.isEmpty ? copy.emptyAnswer : parts.join(' - ');
}

String _reflexLabel(String key, String localeCode) {
  for (final reflex in PrimitiveReflex.values) {
    if (reflex.name == key) return reflex.label(localeCode);
  }
  return key;
}
