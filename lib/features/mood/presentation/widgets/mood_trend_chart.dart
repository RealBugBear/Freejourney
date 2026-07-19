import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/app_languages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/mood_daily_aggregate.dart';
import '../../domain/models/mood_view_settings.dart';

class MoodTrendChart extends StatelessWidget {
  final List<MoodDailyAggregate> aggregates;
  final List<MoodCheckinsTableData> notes;
  final MoodViewSettings settings;
  final void Function(MoodCheckinsTableData)? onNoteTap;

  const MoodTrendChart({
    super.key,
    required this.aggregates,
    required this.notes,
    required this.settings,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (aggregates.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).progressWellbeingEmpty,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final moodSpots = <FlSpot>[];
    final energySpots = <FlSpot>[];
    final stressSpots = <FlSpot>[];

    for (var i = 0; i < aggregates.length; i++) {
      final aggregate = aggregates[i];
      final x = i.toDouble();
      if (aggregate.mood != null) moodSpots.add(FlSpot(x, aggregate.mood!));
      if (aggregate.energy != null) {
        energySpots.add(FlSpot(x, aggregate.energy!));
      }
      if (aggregate.stress != null) {
        stressSpots.add(FlSpot(x, aggregate.stress!));
      }
    }

    final dayIndexByKey = <int, int>{
      for (var i = 0; i < aggregates.length; i++) aggregates[i].dayKey: i,
    };

    // Deduplicate: one marker per day (first note wins for tap)
    final notesByDayIndex = <int, MoodCheckinsTableData>{};
    for (final note in notes) {
      final idx = dayIndexByKey[note.dayKey];
      if (idx != null && !notesByDayIndex.containsKey(idx)) {
        notesByDayIndex[idx] = note;
      }
    }

    final noteLines = notesByDayIndex.keys
        .map(
          (xIndex) => VerticalLine(
            x: xIndex.toDouble(),
            color: AppColors.primary.withValues(alpha: 0.45),
            strokeWidth: 1.4,
            dashArray: [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              labelResolver: (_) => '✏️',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        )
        .toList();

    final maxX =
        aggregates.length <= 1 ? 1.0 : (aggregates.length - 1).toDouble();

    final chart = LineChart(
      LineChartData(
        extraLinesData: ExtraLinesData(verticalLines: noteLines),
        minY: 0.8,
        maxY: 5.2,
        minX: 0,
        maxX: maxX,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
          horizontalInterval: 1,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: aggregates.length > 1,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  final day = aggregates[value.toInt()].day;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formatMoodChartDate(
                        day,
                        Localizations.localeOf(context),
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          if (settings.showMood && moodSpots.isNotEmpty)
            _line(moodSpots, AppColors.moodRose),
          if (settings.showEnergy && energySpots.isNotEmpty)
            _line(energySpots, AppColors.moodTeal),
          if (settings.showStress && stressSpots.isNotEmpty)
            _line(stressSpots, AppColors.moodGold),
        ],
      ),
    );

    if (onNoteTap == null || notesByDayIndex.isEmpty) return chart;

    // Overlay invisible tap targets on each pencil marker.
    // Left reserved (Y-axis labels) = 20px, bottom reserved = 22px.
    const leftReserved = 20.0;
    const bottomReserved = 22.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - leftReserved;
        final chartHeight = constraints.maxHeight - bottomReserved;

        return Stack(
          children: [
            chart,
            ...notesByDayIndex.entries.map((entry) {
              final xIndex = entry.key;
              final note = entry.value;
              final frac = maxX == 0 ? 0.0 : xIndex / maxX;
              final pixelX = leftReserved + frac * chartWidth;

              return Positioned(
                left: (pixelX - 16).clamp(0.0, constraints.maxWidth - 32),
                top: 0,
                width: 32,
                height: chartHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onNoteTap!(note),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

String formatMoodChartDate(DateTime value, Locale locale) {
  final localeName = locale.toLanguageTag();
  // DE keeps its fixed compact format (15.7); other locales inherit Md.
  if (locale.languageCode == AppLanguages.sourceCode) {
    return DateFormat('d.M', localeName).format(value);
  }
  return DateFormat.Md(localeName).format(value);
}
