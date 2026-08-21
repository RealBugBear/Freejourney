import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/app_languages.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../assessment/presentation/widgets/adult_progress_profile_card.dart';
import '../../../assessment/presentation/widgets/reflex_radar_chart.dart';
import '../../../mood/domain/models/mood_daily_aggregate.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../../../journal/presentation/providers/journal_provider.dart';
import '../../../journal/presentation/widgets/journal_entry_tile.dart';
import '../providers/progress_provider.dart';

@visibleForTesting
String formatProgressChartDate(DateTime date, Locale locale) {
  final localeName = locale.toLanguageTag();
  // DE keeps its fixed compact format (15.7); every other locale inherits
  // the locale-aware default (7/15 for en-US).
  final format = locale.languageCode == AppLanguages.sourceCode
      ? DateFormat('d.M', localeName)
      : DateFormat.Md(localeName);
  return format.format(date);
}

class ProgressOverviewScreen extends ConsumerWidget {
  const ProgressOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final journal = ref.watch(journalProvider);
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final progress = ref.watch(activeProgressProvider).valueOrNull;
    final packageId = ref.watch(selectedPackageIdProvider);
    final subjectProfileId = ref.watch(selectedSubjectProfileProvider)?.id;

    final onAddEntry = enrollment == null
        ? null
        : () => showMoodCheckinSheet(
              context,
              enrollmentId: enrollment.id,
              subjectProfileId: subjectProfileId,
              onSaved: () {
                ref.read(journalProvider.notifier).load();
                ref.invalidate(moodDailyAggregatesProvider);
                ref.invalidate(moodNotesProvider);
              },
            );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progressTitle),
        actions: [
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: OnboardingHintGate(
        hint: AppOnboardingHint.progress,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(journalProvider.notifier).load();
            ref.invalidate(activeProgressProvider);
            ref.invalidate(thisWeekSessionsProvider);
            ref.invalidate(moodDailyAggregatesProvider);
            ref.invalidate(moodNotesProvider);
          },
          child: journal.isLoading
              ? const Center(child: CircularProgressIndicator())
              : journal.error != null
                  ? ErrorRetryWidget(
                      message: l10n.progressLoadFailed,
                      onRetry: () => ref.read(journalProvider.notifier).load(),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        _NewEntryButton(onPressed: onAddEntry),
                        const SizedBox(height: 14),
                        const _WellbeingSection(),
                        const SizedBox(height: 14),
                        const _ReflexProfileCard(),
                        const SizedBox(height: 14),
                        _PackageStatusCard(
                          packageId: packageId,
                          enrollment: enrollment,
                          currentDay: progress?.currentDay ?? 1,
                        ),
                        const SizedBox(height: 14),
                        _ObservationTimeline(
                          entries: journal.entries,
                          onDeleted: (id) => ref
                              .read(journalProvider.notifier)
                              .deleteEntry(id),
                          onChanged: () =>
                              ref.read(journalProvider.notifier).load(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _NewEntryButton extends StatelessWidget {
  const _NewEntryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_comment_outlined, size: 18),
        label: Text(l10n.progressAddObservation),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wellbeing section — multi-profile overlay chart
// ---------------------------------------------------------------------------

// Each profile gets a unique combination of colour + line pattern + dot shape
// so the chart is readable even with colour-blindness.
class _ProfileStyle {
  const _ProfileStyle(
      {required this.color, required this.dashArray, required this.dotShape});
  final Color color;
  final List<int>? dashArray; // null = solid, [8,4] = dashed, [3,4] = dotted
  final _DotShape dotShape;
}

enum _DotShape { circle, square, diamond }

const _profileStyles = [
  _ProfileStyle(
      color: Color(0xFF5B8AF0), dashArray: null, dotShape: _DotShape.circle),
  _ProfileStyle(
      color: Color(0xFFE97356), dashArray: [8, 4], dotShape: _DotShape.square),
  _ProfileStyle(
      color: Color(0xFF00C882), dashArray: [3, 4], dotShape: _DotShape.diamond),
  _ProfileStyle(
      color: Color(0xFFA855F7), dashArray: null, dotShape: _DotShape.square),
  _ProfileStyle(
      color: Color(0xFFEC4899), dashArray: [8, 4], dotShape: _DotShape.diamond),
];

class _WellbeingSection extends ConsumerStatefulWidget {
  const _WellbeingSection();

  @override
  ConsumerState<_WellbeingSection> createState() => _WellbeingSectionState();
}

class _WellbeingSectionState extends ConsumerState<_WellbeingSection> {
  int _rangeDays = 30;
  // 0=mood 1=energy 2=stress
  int _metric = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = [l10n.moodLabel, l10n.energyLabel, l10n.stressLabel];
    final profilesAsync = ref.watch(reflexSubjectProfilesProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.progressWellbeingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _RangeChips(
                  selected: _rangeDays,
                  onSelect: (v) => setState(() => _rangeDays = v),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.progressWellbeingDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            // Metric toggle
            Row(
              children: List.generate(metrics.length, (i) {
                final sel = _metric == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _metric = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metrics[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              sel ? AppColors.textPrimary : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            profilesAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(height: 200),
              data: (profiles) => _ProfileOverlayChart(
                profiles: profiles,
                rangeDays: _rangeDays,
                metric: _metric,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOverlayChart extends ConsumerWidget {
  const _ProfileOverlayChart({
    required this.profiles,
    required this.rangeDays,
    required this.metric,
  });

  final List<ReflexSubjectProfile> profiles;
  final int rangeDays;
  final int metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Load aggregates for each profile + one enrollment-wide (null profile)
    final allSeries = <_ChartSeries>[];

    if (profiles.isEmpty) {
      // No profiles: use enrollment-wide data with primary color
      final agg = ref.watch(moodDailyAggregatesProvider(rangeDays));
      return agg.when(
        loading: () => const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => const SizedBox(height: 200),
        data: (aggregates) => _buildChart(
          context,
          [
            _ChartSeries(
                name: l10n.progressWellbeingSeries,
                style: _profileStyles[0],
                aggregates: aggregates)
          ],
        ),
      );
    }

    // Build series per profile
    final asyncList = profiles.asMap().entries.map((e) {
      final style = _profileStyles[e.key % _profileStyles.length];
      final agg = ref.watch(profileMoodAggregatesProvider(
        ProfileMoodLookup(
          days: rangeDays,
          subjectProfileId: e.value.id,
        ),
      ));
      return (profile: e.value, style: style, async: agg);
    }).toList();

    // Collect loaded series
    for (final entry in asyncList) {
      final data = entry.async.valueOrNull;
      if (data != null) {
        allSeries.add(_ChartSeries(
          name: entry.profile.displayName,
          style: entry.style,
          aggregates: data,
        ));
      }
    }

    // Show loading if any are still loading
    final anyLoading = asyncList.any((e) => e.async.isLoading);
    if (anyLoading && allSeries.isEmpty) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return _buildChart(context, allSeries);
  }

  Widget _buildChart(BuildContext context, List<_ChartSeries> series) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    if (series.isEmpty || series.every((s) => s.aggregates.isEmpty)) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.progressWellbeingEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Normalise x-axis: use dayKey so all series share the same time axis
    final allDayKeys = series
        .expand((s) => s.aggregates.map((a) => a.dayKey))
        .toSet()
        .toList()
      ..sort();
    if (allDayKeys.isEmpty) return const SizedBox(height: 200);

    final dayIndexMap = {
      for (var i = 0; i < allDayKeys.length; i++) allDayKeys[i]: i
    };
    final maxX = (allDayKeys.length - 1).toDouble().clamp(1.0, double.infinity);

    List<FlSpot> spotsFor(_ChartSeries s) {
      return s.aggregates
          .map((a) {
            final x = dayIndexMap[a.dayKey]!.toDouble();
            final y = switch (metric) {
              0 => a.mood,
              1 => a.energy,
              _ => a.stress,
            };
            return y == null ? null : FlSpot(x, y);
          })
          .whereType<FlSpot>()
          .toList();
    }

    final bars = series
        .map((s) {
          final spots = spotsFor(s);
          if (spots.isEmpty) return null;
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: s.style.color,
            barWidth: 2.5,
            dashArray: s.style.dashArray,
            dotData: FlDotData(
              show: spots.length <= 14,
              getDotPainter: (_, __, ___, ____) => _a11yDotPainter(s.style),
            ),
            belowBarData: BarAreaData(
                show: true, color: s.style.color.withValues(alpha: 0.07)),
          );
        })
        .whereType<LineChartBarData>()
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0.8,
              maxY: 5.2,
              minX: 0,
              maxX: maxX,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
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
                    getTitlesWidget: (v, _) {
                      if (v != v.roundToDouble()) return const SizedBox();
                      return Text(v.toInt().toString(),
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: allDayKeys.length > 1,
                    reservedSize: 22,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.min || v == meta.max) {
                        final idx = v.toInt().clamp(0, allDayKeys.length - 1);
                        final day =
                            DateTime(1970).add(Duration(days: allDayKeys[idx]));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(formatProgressChartDate(day, locale),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: bars,
            ),
          ),
        ),
        // Accessible legend: colour + pattern sample + label
        if (series.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: series
                .map((s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 14,
                          child: CustomPaint(
                            painter: _LegendLinePainter(style: s.style),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(s.name,
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ChartSeries {
  const _ChartSeries(
      {required this.name, required this.style, required this.aggregates});
  final String name;
  final _ProfileStyle style;
  final List<MoodDailyAggregate> aggregates;
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const options = [30, 90, 365, 0];
    final labels = [
      l10n.progressRange30Days,
      l10n.progressRange90Days,
      l10n.progressRangeOneYear,
      l10n.progressRangeAll,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final sel = selected == options[i];
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onSelect(options[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.textPrimary : AppColors.primary)),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Reflex profile card — horizontal scroll of mini radar cards, filter chips
// ---------------------------------------------------------------------------

class _ReflexProfileCard extends ConsumerStatefulWidget {
  const _ReflexProfileCard();

  @override
  ConsumerState<_ReflexProfileCard> createState() => _ReflexProfileCardState();
}

class _ReflexProfileCardState extends ConsumerState<_ReflexProfileCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedProfile = ref.watch(selectedSubjectProfileProvider);
    final summariesAsync = ref.watch(profilesWithAssessmentsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.progressReflexProfilesTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            summariesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                l10n.progressReflexProfilesLoadFailed(e.toString()),
                style: const TextStyle(color: AppColors.error),
              ),
              data: (summaries) =>
                  _buildContent(context, summaries, selectedProfile?.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context,
      List<ReflexProfileSummary> summaries, String? selectedProfileId) {
    if (summaries.isEmpty) {
      return _NoProfilesState(
          onStart: () => context.push(Routes.reflexProfile));
    }

    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length + 1, // +1 for "add" card
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == summaries.length) {
            return _AddProfileCard(
              onTap: () => context.push(Routes.reflexProfile),
            );
          }
          final summary = summaries[i];
          final assessment = summary.latestAssessment;
          if (assessment != null && isAdultProgressAssessment(assessment)) {
            return AdultProgressProfileCard(
              summary: summary,
              isSelected: summary.profile.id == selectedProfileId,
              onTap: () {
                ref
                    .read(selectedSubjectProfileIdProvider.notifier)
                    .select(summary.profile.id);
                context.push(
                  Routes.reflexProfileResult,
                  extra: {'assessment': assessment},
                );
              },
            );
          }
          return _ProfileRadarCard(
            summary: summary,
            isSelected: summary.profile.id == selectedProfileId,
            onTap: () {
              ref
                  .read(selectedSubjectProfileIdProvider.notifier)
                  .select(summary.profile.id);
              if (assessment != null) {
                context.push(
                  Routes.reflexProfileResult,
                  extra: {'assessment': assessment},
                );
              } else {
                context.push(Routes.reflexProfile);
              }
            },
          );
        },
      ),
    );
  }
}

class _NoProfilesState extends StatelessWidget {
  const _NoProfilesState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.progressNoReflexProfileBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.assignment_outlined),
          label: Text(l10n.progressStartReflexProfile),
        ),
      ],
    );
  }
}

class _ProfileRadarCard extends StatelessWidget {
  const _ProfileRadarCard({
    required this.summary,
    required this.onTap,
    this.isSelected = false,
  });

  final ReflexProfileSummary summary;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assessment = summary.latestAssessment;
    final hasAssessment = assessment != null;
    final locale = Localizations.localeOf(context).languageCode;
    final radarScores = hasAssessment
        ? radarScoresFromAssessment(assessment.scores, locale)
        : <ReflexRadarScore>[];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.profile.displayName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _ageLabel(l10n, summary.profile),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: hasAssessment
                    ? ReflexRadarChart(scores: radarScores, mini: true)
                    : _NoAssessmentPlaceholder(onTap: onTap),
              ),
              const SizedBox(height: 8),
              if (hasAssessment) ...[
                Text(
                  _dateLabel(context, assessment.completedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bar_chart_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      l10n.progressProfileDetails,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _ageLabel(
    AppLocalizations l10n,
    ReflexSubjectProfile profile,
  ) {
    final years = profile.ageYears;
    if (years == null) return '';
    return l10n.progressProfileAgeYears(years);
  }

  String _dateLabel(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(dt);
  }
}

class _NoAssessmentPlaceholder extends StatelessWidget {
  const _NoAssessmentPlaceholder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 28,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.progressNoAssessmentProfile,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 32,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.progressAddAnotherProfile,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageStatusCard extends StatelessWidget {
  const _PackageStatusCard({
    required this.packageId,
    required this.enrollment,
    required this.currentDay,
  });

  final String packageId;
  final EnrollmentsTableData? enrollment;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalDays =
        ((enrollment?.assignedDurationWeeks ?? 8) * 7).clamp(1, 3650);
    final nextPackage = nextPackageIdAfter(packageId);
    final progress = (currentDay / totalDays).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.progressCurrentPackageTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              enrollment == null
                  ? l10n.dashboardNoActivePackage
                  : l10n.progressCurrentPackageDay(
                      _packageName(l10n, packageId),
                      currentDay,
                      totalDays,
                    ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: enrollment == null ? 0 : progress,
                minHeight: 7,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nextPackage == null
                  ? l10n.progressNoNextFixedPackage
                  : l10n.progressNextFixedPackage(
                      _packageName(l10n, nextPackage),
                    ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.packages),
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(l10n.progressViewPackageSequence),
            ),
          ],
        ),
      ),
    );
  }

  static String _packageName(AppLocalizations l10n, String packageId) {
    switch (packageId) {
      case 'spinal_galant':
        return l10n.packageShortSpinalGalant;
      case 'tlr':
        return l10n.packageShortTlr;
      case 'babkin':
        return l10n.packageShortBabkin;
      case 'such_saug':
        return l10n.packageShortSuchSaug;
      case 'atnr':
        return l10n.packageShortAtnr;
      case 'stnr':
        return l10n.packageShortStnr;
      case 'babinski':
        return l10n.packageShortBabinski;
      case 'landau':
        return l10n.packageShortLandau;
      case 'moro':
      default:
        return l10n.packageShortMoro;
    }
  }
}

class _ObservationTimeline extends StatelessWidget {
  const _ObservationTimeline({
    required this.entries,
    required this.onDeleted,
    required this.onChanged,
  });

  final List<JournalEntriesTableData> entries;
  final ValueChanged<String> onDeleted;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.progressObservationsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              entries.isEmpty
                  ? l10n.progressObservationsEmptySummary
                  : l10n.progressObservationCount(entries.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const _EmptyObservationState()
            else
              ...entries.take(12).map(
                    (entry) => JournalEntryTile(
                      entry: entry,
                      onDeleted: () => onDeleted(entry.id),
                      onChanged: onChanged,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _EmptyObservationState extends StatelessWidget {
  const _EmptyObservationState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          l10n.progressObservationsEmptyBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accessibility chart helpers
// ---------------------------------------------------------------------------

/// Returns the right [FlDotPainter] for a given profile style.
FlDotPainter _a11yDotPainter(_ProfileStyle style) {
  return switch (style.dotShape) {
    _DotShape.circle =>
      FlDotCirclePainter(radius: 3.5, color: style.color, strokeWidth: 0),
    _DotShape.square => _SquareDotPainter(color: style.color, size: 7),
    _DotShape.diamond => _DiamondDotPainter(color: style.color, size: 8),
  };
}

class _SquareDotPainter extends FlDotPainter {
  const _SquareDotPainter({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    canvas.drawRect(
      Rect.fromCenter(center: offsetInCanvas, width: size, height: size),
      Paint()..color = color,
    );
  }

  @override
  Size getSize(FlSpot spot) => Size(size, size);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _SquareDotPainter && b is _SquareDotPainter) {
      return _SquareDotPainter(
        color: Color.lerp(a.color, b.color, t)!,
        size: a.size + (b.size - a.size) * t,
      );
    }
    return b;
  }

  @override
  List<Object?> get props => [color, size];
}

class _DiamondDotPainter extends FlDotPainter {
  const _DiamondDotPainter({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final half = size / 2;
    final cx = offsetInCanvas.dx;
    final cy = offsetInCanvas.dy;
    final path = Path()
      ..moveTo(cx, cy - half)
      ..lineTo(cx + half, cy)
      ..lineTo(cx, cy + half)
      ..lineTo(cx - half, cy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  Size getSize(FlSpot spot) => Size(size, size);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _DiamondDotPainter && b is _DiamondDotPainter) {
      return _DiamondDotPainter(
        color: Color.lerp(a.color, b.color, t)!,
        size: a.size + (b.size - a.size) * t,
      );
    }
    return b;
  }

  @override
  List<Object?> get props => [color, size];
}

/// Draws a short line segment + centre dot matching the profile's dash pattern and dot shape,
/// used in the chart legend.
class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.style});
  final _ProfileStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cy = size.height / 2;

    // Draw line with dash pattern
    switch (style.dashArray) {
      case null:
        canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
      case [final on, final off]:
        var x = 0.0;
        while (x < size.width) {
          final end = (x + on).clamp(0.0, size.width);
          canvas.drawLine(Offset(x, cy), Offset(end, cy), paint);
          x += on + off;
        }
      default:
        canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
    }

    // Draw dot shape at centre
    final cx = size.width / 2;
    final dotPaint = Paint()..color = style.color;
    switch (style.dotShape) {
      case _DotShape.circle:
        canvas.drawCircle(Offset(cx, cy), 3.5, dotPaint);
      case _DotShape.square:
        canvas.drawRect(
            Rect.fromCenter(center: Offset(cx, cy), width: 7, height: 7),
            dotPaint);
      case _DotShape.diamond:
        final p = Path()
          ..moveTo(cx, cy - 4)
          ..lineTo(cx + 4, cy)
          ..lineTo(cx, cy + 4)
          ..lineTo(cx - 4, cy)
          ..close();
        canvas.drawPath(p, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) => old.style != style;
}
