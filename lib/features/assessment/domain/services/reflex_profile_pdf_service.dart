import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/reflex_profile_assessment.dart';
import '../reflex_questionnaire.dart';
import '../reflex_questionnaire_definitions.dart';

class ReflexProfilePdfService {
  const ReflexProfilePdfService();

  Future<File> createSummaryPdf(ReflexProfileAssessment assessment) async {
    final document = pw.Document(
      title: 'Reflexprofil Zusammenfassung',
      author: 'Reflex Journey',
    );
    final scores = _scoreRows(assessment);
    final answers = _answerRows(assessment);
    final completedAt = assessment.completedAt ?? assessment.createdAt;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Reflexprofil Zusammenfassung',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Erstellt am ${DateFormat('dd.MM.yyyy', 'de_DE').format(completedAt)}',
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
              'Diese Auswertung zeigt Antwortmuster und Hinweisstärken. '
              'Sie ersetzt keine medizinische oder therapeutische Diagnose.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          if (assessment.warningConfirmations.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.orange400),
              ),
              child: pw.Text(
                '${assessment.warningConfirmations.length} Sicherheits-/Rücksprache-Hinweise wurden bestätigt. '
                'Training sollte nur nach ausdrücklicher Rücksprache mit Arzt, Therapeut oder Psychologe erfolgen.',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Übersicht Reflexbereiche',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Reflexbereich',
              'Prozent',
              'Einordnung',
              'Ja / Beantwortet',
            ],
            data: scores
                .map(
                  (score) => [
                    score.label,
                    '${score.percent.round()}%',
                    _bandLabel(score.band),
                    '${score.yesCount} / ${score.answeredCount}',
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
            'Antwortübersicht',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Frage', 'Antwort'],
            data: answers
                .map(
                  (answer) => [
                    answer.question,
                    answer.answer,
                  ],
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
    final fileName =
        'reflexjourney_reflexprofil_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }
}

class _PdfScoreRow {
  const _PdfScoreRow({
    required this.label,
    required this.percent,
    required this.band,
    required this.yesCount,
    required this.answeredCount,
  });

  final String label;
  final double percent;
  final ReflexScoreBand band;
  final int yesCount;
  final int answeredCount;
}

class _PdfAnswerRow {
  const _PdfAnswerRow({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

List<_PdfScoreRow> _scoreRows(ReflexProfileAssessment assessment) {
  final rows = <_PdfScoreRow>[];
  for (final entry in assessment.scores.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    rows.add(
      _PdfScoreRow(
        label: _reflexLabel(entry.key),
        percent: (raw['percent'] as num?)?.toDouble() ?? 0,
        band: _scoreBandFromName(raw['band'] as String? ?? ''),
        yesCount: (raw['yes_count'] as num?)?.toInt() ?? 0,
        answeredCount: (raw['answered_count'] as num?)?.toInt() ?? 0,
      ),
    );
  }
  rows.sort((a, b) => b.percent.compareTo(a.percent));
  return rows;
}

List<_PdfAnswerRow> _answerRows(ReflexProfileAssessment assessment) {
  final questionById = {
    for (final question in childParentQuestionnaireV1.questions)
      question.id: '${question.number}. ${question.text}',
  };
  return assessment.answers.entries
      .map(
        (entry) => _PdfAnswerRow(
          question: questionById[entry.key] ?? entry.key,
          answer: _formatAnswer(entry.value),
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

String _bandLabel(ReflexScoreBand band) => switch (band) {
      ReflexScoreBand.strong => 'stark ausgeprägt',
      ReflexScoreBand.elevated => 'auffällig',
      ReflexScoreBand.indication => 'Anzeichen',
      ReflexScoreBand.inconspicuous => 'unauffällig',
      ReflexScoreBand.insufficientData => 'zu wenig Daten',
    };

String _formatAnswer(dynamic value) {
  if (value is! Map) return value.toString();
  final parts = <String>[];
  final answer = value['answer'];
  if (answer == 'yes') parts.add('Ja');
  if (answer == 'no') parts.add('Nein');
  if (answer == 'unknown') parts.add('Weiß ich nicht');
  if (value['months'] != null) parts.add('${value['months']} Monate');
  final selected = value['selected_options'];
  if (selected is List && selected.isNotEmpty) parts.add(selected.join(', '));
  final text = value['text'];
  if (text is String && text.trim().isNotEmpty) parts.add(text.trim());
  return parts.isEmpty ? '-' : parts.join(' - ');
}

String _reflexLabel(String key) => switch (key) {
      'delay' => 'Entwicklungsverzögerung',
      'flr' => 'FLR',
      'moro' => 'Moro',
      'spinalGalant' => 'Spinaler Galant',
      'tlr' => 'TLR',
      'atnr' => 'ATNR',
      'stnr' => 'STNR',
      'landau' => 'Landau',
      'babinski' => 'Babinski',
      'babkin' => 'Babkin',
      'plantar' => 'Plantar',
      'palmar' => 'Palmar',
      'righting' => 'Aufricht',
      'rootingSucking' => 'Such-Saug',
      _ => key,
    };
