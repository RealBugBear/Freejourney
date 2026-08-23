import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../adult_reflex_profile_scoring.dart';
import '../reflex_questionnaire.dart';

/// Matches [AppColors.primary] — kept here to avoid a Flutter import in domain.
const _kPdfPrimaryArgb = 0xFF009E6B;

/// Matches [AppColors.primaryLight] — solid fill (PDF alpha is unreliable here).
const _kPdfPrimaryFillArgb = 0xFF6FD4A8;

PdfColor get _pdfPrimary => PdfColor.fromInt(_kPdfPrimaryArgb);

PdfColor get _pdfPrimaryFill => PdfColor.fromInt(_kPdfPrimaryFillArgb);

/// One axis on the PDF reflex radar (excludes amphibian).
class ReflexPdfRadarScore {
  const ReflexPdfRadarScore({
    required this.label,
    required this.shortLabel,
    required this.percent,
  });

  /// Full reflex name. The PDF draws [shortLabel]; the in-app radar, which
  /// reuses these axes, needs the long form.
  final String label;
  final String shortLabel;
  final double percent;
}

/// Default radar block height in summary PDFs (must match [reflexPdfRadarChart]).
const kReflexPdfRadarHeight = 265.0;

/// Fixed-height radar widget drawn with [pw.CustomPaint] polygons.
pw.Widget reflexPdfRadarChart({
  required List<ReflexPdfRadarScore> scores,
  double height = kReflexPdfRadarHeight,
}) {
  if (scores.length < 3) {
    return pw.SizedBox(height: height);
  }

  const width = 500.0;
  final centerX = width / 2;
  final centerY = height / 2;
  const labelGap = 24.0;
  final radius = math.min(width, height) * 0.36;
  final count = scores.length;

  return pw.ClipRect(
    child: pw.SizedBox(
      height: height,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.CustomPaint(
              size: PdfPoint(width, height),
              painter: (canvas, size) {
                _paintReflexPdfRadar(canvas, size, scores);
              },
            ),
          ),
          for (var i = 0; i < count; i++)
            _radarLabel(
              scores[i].shortLabel,
              centerX: centerX,
              centerY: centerY,
              radius: radius + labelGap,
              index: i,
              count: count,
            ),
        ],
      ),
    ),
  );
}

pw.Widget _radarLabel(
  String label, {
  required double centerX,
  required double centerY,
  required double radius,
  required int index,
  required int count,
}) {
  final angle = -math.pi / 2 + (math.pi * 2 * index / count);
  final x = centerX + math.cos(angle) * radius;
  final y = centerY + math.sin(angle) * radius;
  const boxWidth = 52.0;

  return pw.Positioned(
    left: x - boxWidth / 2,
    top: y - 5,
    child: pw.SizedBox(
      width: boxWidth,
      child: pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
        textAlign: pw.TextAlign.center,
        maxLines: 2,
      ),
    ),
  );
}

void _paintReflexPdfRadar(
  PdfGraphics canvas,
  PdfPoint size,
  List<ReflexPdfRadarScore> scores,
) {
  canvas
    ..saveContext()
    ..drawRect(0, 0, size.x, size.y)
    ..clipPath();

  final centerX = size.x / 2;
  final centerY = size.y / 2;
  final radius = math.min(size.x, size.y) * 0.36;
  final count = scores.length;

  const gridColor = PdfColors.grey300;

  canvas.setStrokeColor(gridColor);
  canvas.setLineWidth(0.6);
  for (var ring = 1; ring <= 4; ring++) {
    _strokePolygon(canvas, centerX, centerY, radius * ring / 4, count);
  }
  for (var i = 0; i < count; i++) {
    final pt = _point(centerX, centerY, radius, i, count);
    canvas.drawLine(centerX, centerY, pt.x, pt.y);
  }

  canvas.setFillColor(_pdfPrimaryFill);
  _strokeDataPolygon(canvas, centerX, centerY, radius, scores, fill: true);
  canvas.setStrokeColor(_pdfPrimary);
  canvas.setLineWidth(2.2);
  _strokeDataPolygon(canvas, centerX, centerY, radius, scores);

  canvas.restoreContext();
}

void _strokePolygon(
  PdfGraphics canvas,
  double cx,
  double cy,
  double r,
  int count, {
  bool fill = false,
}) {
  for (var i = 0; i < count; i++) {
    final pt = _point(cx, cy, r, i, count);
    if (i == 0) {
      canvas.moveTo(pt.x, pt.y);
    } else {
      canvas.lineTo(pt.x, pt.y);
    }
  }
  canvas.closePath();
  if (fill) {
    canvas.fillPath();
  } else {
    canvas.strokePath();
  }
}

void _strokeDataPolygon(
  PdfGraphics canvas,
  double cx,
  double cy,
  double radius,
  List<ReflexPdfRadarScore> scores, {
  bool fill = false,
}) {
  for (var i = 0; i < scores.length; i++) {
    final vr = radius * (scores[i].percent.clamp(0, 100) / 100);
    final pt = _point(cx, cy, vr, i, scores.length);
    if (i == 0) {
      canvas.moveTo(pt.x, pt.y);
    } else {
      canvas.lineTo(pt.x, pt.y);
    }
  }
  canvas.closePath();
  if (fill) {
    canvas.fillPath();
  } else {
    canvas.strokePath();
  }
}

PdfPoint _point(double cx, double cy, double r, int index, int count) {
  final angle = -math.pi / 2 + (math.pi * 2 * index / count);
  return PdfPoint(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
}

String _reflexLabel(String key, String localeCode) {
  for (final reflex in PrimitiveReflex.values) {
    if (reflex.name == key) return reflex.label(localeCode);
  }
  return key;
}

/// Radar axes from assessment scores (amphibian excluded).
///
/// Axis order follows [PrimitiveReflex] declaration order so profiles stay
/// comparable over time. The PDF list below the chart remains percent-sorted.
List<ReflexPdfRadarScore> radarScoresForPdf(
  Map<String, dynamic> scores, {
  required String localeCode,
}) {
  final adult = AdultQuestionnaireScore.tryParse(scores);
  if (adult != null) {
    final rows = <ReflexPdfRadarScore>[];
    for (final reflex in PrimitiveReflex.values) {
      if (reflex == PrimitiveReflex.amphibian) continue;
      final score = adult.reflexScores[reflex];
      if (score == null || score.percent == null) continue;
      rows.add(
        ReflexPdfRadarScore(
          label: reflex.label(localeCode),
          shortLabel: reflex.shortLabel(localeCode),
          percent: score.percent!,
        ),
      );
    }
    return rows;
  }

  final rows = <ReflexPdfRadarScore>[];
  for (final reflex in PrimitiveReflex.values) {
    if (reflex == PrimitiveReflex.amphibian) continue;
    final raw = scores[reflex.name];
    if (raw is! Map) continue;
    final answeredCount = (raw['answered_count'] as num?)?.toInt() ?? 0;
    if (answeredCount == 0) continue;
    final percent = (raw['percent'] as num?)?.toDouble();
    if (percent == null) continue;
    rows.add(
      ReflexPdfRadarScore(
        label: reflex.label(localeCode),
        shortLabel: reflex.shortLabel(localeCode),
        percent: percent,
      ),
    );
  }
  return rows;
}

/// One row in the PDF reflex list (includes amphibian for adult profiles).
class ReflexProfilePdfListRow {
  const ReflexProfilePdfListRow({
    required this.label,
    required this.percent,
    required this.band,
    required this.dataBasis,
    this.isAmphibian = false,
  });

  final String label;
  final String percent;
  final String band;
  final String dataBasis;
  final bool isAmphibian;
}

List<ReflexProfilePdfListRow> listRowsForPdf({
  required Map<String, dynamic> scores,
  required String localeCode,
  required String Function(ReflexScoreBand band) childBandLabel,
  required String Function(AdultHintBand band) adultBandLabel,
  required String Function(AmphibianDisplay display) amphibianBandLabel,
  required String Function(int yesCount, int answeredCount) childDataBasis,
  required String Function(int answeredCount, int possibleCount) adultDataBasis,
}) {
  final adult = AdultQuestionnaireScore.tryParse(scores);
  if (adult != null) {
    final rows = adult.reflexScores.values
        .map(
          (score) => ReflexProfilePdfListRow(
            label: score.reflex.label(localeCode),
            percent: score.percentDisplay == null
                ? '-'
                : '${score.percentDisplay} %',
            band: adultBandLabel(score.band),
            dataBasis: adultDataBasis(score.answeredCount, score.possibleCount),
          ),
        )
        .toList()
      ..sort((a, b) {
        final ap = _parsePercentSortKey(a.percent);
        final bp = _parsePercentSortKey(b.percent);
        return bp.compareTo(ap);
      });

    final amph = adult.amphibian;
    rows.add(
      ReflexProfilePdfListRow(
        label: PrimitiveReflex.amphibian.label(localeCode),
        percent: '',
        band: amphibianBandLabel(amph.display),
        dataBasis: adultDataBasis(amph.answeredCount, 2),
        isAmphibian: true,
      ),
    );
    return rows;
  }

  final parsed = <({String key, double sortKey, ReflexProfilePdfListRow row})>[];
  for (final entry in scores.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    final percent = (raw['percent'] as num?)?.toDouble() ?? 0;
    final bandName = raw['band'] as String? ?? '';
    final band = ReflexScoreBand.values.firstWhere(
      (value) => value.name == bandName,
      orElse: () => ReflexScoreBand.insufficientData,
    );
    final insufficient = band == ReflexScoreBand.insufficientData;
    parsed.add(
      (
        key: entry.key,
        // Insufficient data sorts below real zeros (same as adult '-').
        sortKey: insufficient ? -1 : percent,
        row: ReflexProfilePdfListRow(
          label: _reflexLabel(entry.key, localeCode),
          percent: insufficient ? '-' : '${percent.round()}%',
          band: childBandLabel(band),
          dataBasis: childDataBasis(
            (raw['yes_count'] as num?)?.toInt() ?? 0,
            (raw['answered_count'] as num?)?.toInt() ?? 0,
          ),
        ),
      ),
    );
  }
  parsed.sort((a, b) => b.sortKey.compareTo(a.sortKey));
  return parsed.map((entry) => entry.row).toList();
}

double _parsePercentSortKey(String percent) {
  final digits = RegExp(r'\d+').firstMatch(percent)?.group(0);
  return digits == null ? -1 : double.tryParse(digits) ?? -1;
}
