import 'dart:io';
import 'dart:ui' show Locale;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/l10n/app_languages.dart';
import '../models/reflex_profile_assessment.dart';
import '../reflex_questionnaire.dart';
import 'reflex_profile_pdf_radar.dart';

/// Subject header block height before the radar background is drawn.
const _kPdfHeaderBlockHeight = 49.0;

typedef ReflexProfilePdfCountCopy = String Function(int count);
typedef ReflexProfilePdfHeaderMetaCopy = String Function(
  String formattedDate,
  String questionnaireVersion,
  String scoringVersion,
);
typedef ReflexProfilePdfChildDataBasisCopy = String Function(
  int yesCount,
  int answeredCount,
);
typedef ReflexProfilePdfAdultDataBasisCopy = String Function(
  int answeredCount,
  int possibleCount,
);

/// All translated copy needed to create a reflex-profile summary PDF.
class ReflexProfilePdfCopy {
  const ReflexProfilePdfCopy({
    required this.title,
    required this.author,
    required this.headerMeta,
    required this.summaryNotice,
    required this.safetyNotice,
    required this.reflexListTitle,
    required this.bandStrong,
    required this.bandElevated,
    required this.bandIndication,
    required this.bandInconspicuous,
    required this.bandInsufficientData,
    required this.adultBandFewMatching,
    required this.adultBandSomeMatching,
    required this.adultBandClusteredPattern,
    required this.adultBandStronglyClustered,
    required this.adultBandInsufficientData,
    required this.amphibianInsufficientData,
    required this.amphibianNoneMatching,
    required this.amphibianSingleHint,
    required this.amphibianClearSingleHint,
    required this.childDataBasis,
    required this.adultDataBasis,
    required this.fileNameStem,
  });

  final String title;
  final String author;
  final ReflexProfilePdfHeaderMetaCopy headerMeta;
  final String summaryNotice;
  final ReflexProfilePdfCountCopy safetyNotice;
  final String reflexListTitle;
  final String bandStrong;
  final String bandElevated;
  final String bandIndication;
  final String bandInconspicuous;
  final String bandInsufficientData;
  final String adultBandFewMatching;
  final String adultBandSomeMatching;
  final String adultBandClusteredPattern;
  final String adultBandStronglyClustered;
  final String adultBandInsufficientData;
  final String amphibianInsufficientData;
  final String amphibianNoneMatching;
  final String amphibianSingleHint;
  final String amphibianClearSingleHint;
  final ReflexProfilePdfChildDataBasisCopy childDataBasis;
  final ReflexProfilePdfAdultDataBasisCopy adultDataBasis;
  final String fileNameStem;

  String childBandLabel(ReflexScoreBand band) => switch (band) {
        ReflexScoreBand.strong => bandStrong,
        ReflexScoreBand.elevated => bandElevated,
        ReflexScoreBand.indication => bandIndication,
        ReflexScoreBand.inconspicuous => bandInconspicuous,
        ReflexScoreBand.insufficientData => bandInsufficientData,
      };

  String adultBandLabel(AdultHintBand band) => switch (band) {
        AdultHintBand.fewMatching => adultBandFewMatching,
        AdultHintBand.someMatching => adultBandSomeMatching,
        AdultHintBand.clusteredPattern => adultBandClusteredPattern,
        AdultHintBand.stronglyClustered => adultBandStronglyClustered,
        AdultHintBand.insufficientData => adultBandInsufficientData,
      };

  String amphibianBandLabel(AmphibianDisplay display) => switch (display) {
        AmphibianDisplay.insufficientData => amphibianInsufficientData,
        AmphibianDisplay.noneMatching => amphibianNoneMatching,
        AmphibianDisplay.singleHint => amphibianSingleHint,
        AmphibianDisplay.clearSingleHint => amphibianClearSingleHint,
      };
}

/// Locale-resolved, render-ready content for a reflex-profile summary PDF.
class ReflexProfilePdfContent {
  const ReflexProfilePdfContent({
    required this.title,
    required this.author,
    required this.subjectName,
    required this.headerMeta,
    required this.summaryNotice,
    required this.safetyNotice,
    required this.reflexListTitle,
    required this.radarScores,
    required this.listRows,
    required this.fileNameStem,
  });

  final String title;
  final String author;
  final String subjectName;
  final String headerMeta;
  final String summaryNotice;
  final String? safetyNotice;
  final String reflexListTitle;
  final List<ReflexPdfRadarScore> radarScores;
  final List<ReflexProfilePdfListRow> listRows;
  final String fileNameStem;
}

class ReflexProfilePdfService {
  const ReflexProfilePdfService();

  ReflexProfilePdfContent buildSummaryContent(
    ReflexProfileAssessment assessment, {
    required Locale locale,
    required ReflexProfilePdfCopy copy,
    required String subjectName,
  }) {
    final completedAt = assessment.completedAt ?? assessment.createdAt;
    final localeCode = AppLanguages.normalize(locale.languageCode);
    final datePattern =
        localeCode == AppLanguages.sourceCode ? 'dd.MM.yyyy' : 'MM/dd/yyyy';
    final formattedDate = DateFormat(datePattern).format(completedAt);

    return ReflexProfilePdfContent(
      title: copy.title,
      author: copy.author,
      subjectName: subjectName,
      headerMeta: copy.headerMeta(
        formattedDate,
        assessment.questionnaireVersion,
        assessment.scoringVersion,
      ),
      summaryNotice: copy.summaryNotice,
      safetyNotice: assessment.warningConfirmations.isEmpty
          ? null
          : copy.safetyNotice(assessment.warningConfirmations.length),
      reflexListTitle: copy.reflexListTitle,
      radarScores: radarScoresForPdf(
        assessment.scores,
        localeCode: localeCode,
      ),
      listRows: listRowsForPdf(
        scores: assessment.scores,
        localeCode: localeCode,
        childBandLabel: copy.childBandLabel,
        adultBandLabel: copy.adultBandLabel,
        amphibianBandLabel: copy.amphibianBandLabel,
        childDataBasis: copy.childDataBasis,
        adultDataBasis: copy.adultDataBasis,
      ),
      fileNameStem: copy.fileNameStem,
    );
  }

  Future<File> createSummaryPdf(
    ReflexProfileAssessment assessment, {
    required Locale locale,
    required ReflexProfilePdfCopy copy,
    required String subjectName,
    DateTime? generatedAt,
  }) async {
    final bytes = await renderSummaryPdfBytes(
      assessment,
      locale: locale,
      copy: copy,
      subjectName: subjectName,
    );

    final content = buildSummaryContent(
      assessment,
      locale: locale,
      copy: copy,
      subjectName: subjectName,
    );
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(
      generatedAt ?? DateTime.now(),
    );
    final file =
        File('${directory.path}/${content.fileNameStem}_$timestamp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<List<int>> renderSummaryPdfBytes(
    ReflexProfileAssessment assessment, {
    required Locale locale,
    required ReflexProfilePdfCopy copy,
    required String subjectName,
  }) async {
    final content = buildSummaryContent(
      assessment,
      locale: locale,
      copy: copy,
      subjectName: subjectName,
    );
    final document = pw.Document(
      title: content.title,
      author: content.author,
    );

    final listMetrics = _listMetricsForRowCount(content.listRows.length);

    document.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          buildBackground: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(top: _kPdfHeaderBlockHeight),
              child: pw.Align(
                alignment: pw.Alignment.topCenter,
                child: reflexPdfRadarChart(scores: content.radarScores),
              ),
            );
          },
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                content.subjectName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                content.headerMeta,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),
              pw.SizedBox(height: kReflexPdfRadarHeight + 8),
              pw.Container(
                color: PdfColors.white,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(
                      content.reflexListTitle,
                      style: pw.TextStyle(
                        fontSize: listMetrics.titleSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    for (final row in content.listRows)
                      pw.Padding(
                        padding:
                            pw.EdgeInsets.only(bottom: listMetrics.rowGap),
                        child: _listRowWidget(row, listMetrics),
                      ),
                    if (content.safetyNotice case final safetyNotice?) ...[
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.orange100,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColors.orange400),
                        ),
                        child: pw.Text(
                          safetyNotice,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        content.summaryNotice,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }
}

class _ListMetrics {
  const _ListMetrics({
    required this.titleSize,
    required this.nameSize,
    required this.detailSize,
    required this.rowGap,
  });

  final double titleSize;
  final double nameSize;
  final double detailSize;
  final double rowGap;
}

_ListMetrics _listMetricsForRowCount(int rowCount) {
  if (rowCount >= 14) {
    return const _ListMetrics(
      titleSize: 11,
      nameSize: 8.5,
      detailSize: 7.5,
      rowGap: 3.5,
    );
  }
  if (rowCount >= 11) {
    return const _ListMetrics(
      titleSize: 12,
      nameSize: 9,
      detailSize: 8,
      rowGap: 4.5,
    );
  }
  return const _ListMetrics(
    titleSize: 13,
    nameSize: 9.5,
    detailSize: 8.5,
    rowGap: 6,
  );
}

pw.Widget _listRowWidget(ReflexProfilePdfListRow row, _ListMetrics metrics) {
  if (row.isAmphibian) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                row.label,
                style: pw.TextStyle(
                  fontSize: metrics.nameSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 96,
              child: pw.Text(
                row.band,
                style: pw.TextStyle(
                  fontSize: metrics.detailSize,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          row.dataBasis,
          style: pw.TextStyle(
            fontSize: metrics.detailSize,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: metrics.rowGap * 0.4),
      ],
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              row.label,
              style: pw.TextStyle(
                fontSize: metrics.nameSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(
            width: 42,
            child: pw.Text(
              row.percent,
              style: pw.TextStyle(fontSize: metrics.detailSize),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 1),
      pw.Text(
        '${row.band} · ${row.dataBasis}',
        style: pw.TextStyle(
          fontSize: metrics.detailSize,
          color: PdfColors.grey800,
        ),
      ),
      pw.SizedBox(height: metrics.rowGap * 0.4),
    ],
  );
}

/// Counts pages in raw PDF bytes (for tests).
int countPdfPages(List<int> bytes) {
  final source = String.fromCharCodes(bytes);
  return RegExp(r'/Type\s*/Page(?!s)').allMatches(source).length;
}

/// Returns true when [needle] appears in the PDF (for tests).
bool pdfBytesContain(List<int> bytes, String needle) {
  return String.fromCharCodes(bytes).contains(needle);
}
