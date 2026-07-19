import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/domain/reflex_questionnaire_definitions.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';
import '../../../trainer/domain/models/trainer_application.dart';
import '../../../trainer/presentation/providers/trainer_application_provider.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          actions: [
            const DirectMessagesAction(),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                ref.invalidate(adminUsersProvider);
                ref.invalidate(adminTrainerProfilesProvider);
                ref.invalidate(adminExperienceSharesProvider);
                ref.invalidate(adminReflexProfileRollupProvider);
                ref.invalidate(trainerApplicationsForReviewProvider);
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Bewerbungen'),
              Tab(text: 'Trainer'),
              Tab(text: 'Rollen'),
              Tab(text: 'Zugriff'),
              Tab(text: 'Reflexprofil'),
              Tab(text: 'Erfahrungen'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TrainerApplicationsTab(),
            _TrainerVisibilityTab(),
            _RolesTab(),
            _AccessTab(),
            _ReflexAnalyticsTab(),
            _SharedExperienceAdminTab(),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(String role) {
  return switch (role) {
    'admin' => 'Admin',
    'trainer' => 'Trainer',
    _ => 'Nutzer',
  };
}

Future<bool> _confirmRemoveShare(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Beitrag entfernen?'),
      content: const Text(
        'Der Beitrag wird aus den geteilten Erfahrungen entfernt. Diese Aktion sollte nur bei unpassenden oder sensiblen Inhalten genutzt werden.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Entfernen'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _AdminInfoCard extends StatelessWidget {
  const _AdminInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Temporary Access Tab ──────────────────────────────────────────────────────

class _AccessTab extends ConsumerWidget {
  const _AccessTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('Keine Nutzer gefunden.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _AdminInfoCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Temporärer Zugriff',
                body:
                    'Manueller Premium-Zugriff ist ein Admin-Override. Langfristig wird das durch Paywall und Kaufprozess ersetzt.',
              );
            }
            final user = users[index - 1];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(user.displayName),
              subtitle: Text(
                  '${_roleLabel(user.role)} · ${user.isPremium ? 'Premium' : 'Free'}'),
              trailing: Switch(
                value: user.isPremium,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(adminUsersProvider.notifier)
                        .setTier(user.id, value ? 'premium' : 'free');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler: $e')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── Roles Tab ────────────────────────────────────────────────────────────────

class _RolesTab extends ConsumerWidget {
  const _RolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('Keine Nutzer gefunden.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _AdminInfoCard(
                icon: Icons.manage_accounts_outlined,
                title: 'Rollenverwaltung',
                body:
                    'Rollen steuern App-Rechte. Öffentliche Trainer-Sichtbarkeit wird separat im Trainer-Tab verwaltet.',
              );
            }
            final user = users[index - 1];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(user.displayName),
              subtitle: Text(user.id),
              trailing: DropdownButton<String>(
                value: user.role,
                items: const [
                  DropdownMenuItem(
                    value: 'practitioner',
                    child: Text('Nutzer'),
                  ),
                  DropdownMenuItem(
                    value: 'trainer',
                    child: Text('Trainer'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (role) async {
                  if (role == null || role == user.role) return;
                  try {
                    await ref
                        .read(adminUsersProvider.notifier)
                        .setRole(user.id, role);
                    ref.invalidate(adminTrainerProfilesProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Rolle konnte nicht geändert werden: $e')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── Trainer Applications Tab ──────────────────────────────────────────────────

class _TrainerApplicationsTab extends ConsumerWidget {
  const _TrainerApplicationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncApplications = ref.watch(trainerApplicationsForReviewProvider);

    return asyncApplications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (applications) {
        final openApplications = applications.where((a) => a.isOpen).toList();
        if (openApplications.isEmpty) {
          return const Center(child: Text('Keine Trainer-Bewerbungen.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: openApplications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _TrainerApplicationCard(application: openApplications[i]),
        );
      },
    );
  }
}

class _TrainerVisibilityTab extends ConsumerWidget {
  const _TrainerVisibilityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainersAsync = ref.watch(adminTrainerProfilesProvider);

    return trainersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (trainers) {
        if (trainers.isEmpty) {
          return const Center(child: Text('Noch keine Trainerprofile.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: trainers.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _AdminInfoCard(
                icon: Icons.travel_explore_outlined,
                title: 'Öffentliche Trainer-Sichtbarkeit',
                body:
                    'Trainerrolle und öffentliche Sichtbarkeit sind getrennt. Nur aktive Profile erscheinen in der Suche.',
              );
            }
            final trainer = trainers[index - 1];
            return ListTile(
              leading: CircleAvatar(
                child: Icon(
                  trainer.isPublic
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              title: Text(trainer.displayName),
              subtitle: Text(
                [
                  trainer.isPublic ? 'Öffentlich sichtbar' : 'Nicht sichtbar',
                  trainer.hasLocation ? 'Standort gesetzt' : 'Standort fehlt',
                ].join(' · '),
              ),
              trailing: Switch(
                value: trainer.isPublic,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(adminTrainerProfilesProvider.notifier)
                        .setPublicStatus(trainer.id, value);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sichtbarkeit konnte nicht geändert werden: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ReflexAnalyticsTab extends ConsumerWidget {
  const _ReflexAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollupAsync = ref.watch(adminReflexProfileRollupProvider);

    return rollupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Text('Noch keine abgeschlossenen Reflexprofile.'),
          );
        }
        final summary = _ReflexAnalyticsSummary.fromRollup(rows);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _AdminInfoCard(
              icon: Icons.analytics_outlined,
              title: 'Reflexprofil-Auswertung',
              body:
                  'Die Auswertung ist pseudonymisiert und enthält keine Namen. Demo-Fragebögen sind hier ausgeschlossen.',
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _copyReflexAnalyticsCsv(context, summary),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('CSV kopieren'),
              ),
            ),
            const SizedBox(height: 12),
            _ReflexOverviewCard(summary: summary),
            const SizedBox(height: 12),
            _MetricListCard(
              title: 'Auffälligste Reflexbereiche',
              icon: Icons.radar_outlined,
              metrics: summary.topReflexes,
              valueSuffix: '% Ø',
            ),
            const SizedBox(height: 12),
            _MetricListCard(
              title: 'Häufigste Ja-Antworten',
              icon: Icons.check_circle_outline,
              metrics: summary.topQuestions,
              valueSuffix: 'x Ja',
            ),
            const SizedBox(height: 12),
            _MetricListCard(
              title: 'Sicherheitsrelevante Angaben',
              icon: Icons.warning_amber_outlined,
              metrics: summary.safetyFlags,
              valueSuffix: 'x Ja',
              emptyText: 'Keine Sicherheitsangaben vorhanden.',
            ),
            const SizedBox(height: 12),
            _DevelopmentMonthsCard(summary: summary),
          ],
        );
      },
    );
  }
}

Future<void> _copyReflexAnalyticsCsv(
  BuildContext context,
  _ReflexAnalyticsSummary summary,
) async {
  final lines = <List<String>>[
    ['bereich', 'label', 'wert', 'detail'],
    ['gesamt', 'fragebögen', summary.totalAssessments.toString(), ''],
    for (final metric in summary.ageGroups)
      [
        'altersgruppe',
        metric.label,
        metric.value.toStringAsFixed(metric.decimals),
        metric.detail ?? '',
      ],
    for (final metric in summary.topReflexes)
      [
        'reflex_durchschnitt',
        metric.label,
        metric.value.toStringAsFixed(metric.decimals),
        metric.detail ?? '',
      ],
    for (final metric in summary.topQuestions)
      [
        'ja_antwort',
        metric.label,
        metric.value.toStringAsFixed(metric.decimals),
        metric.detail ?? '',
      ],
    for (final metric in summary.safetyFlags)
      [
        'sicherheit',
        metric.label,
        metric.value.toStringAsFixed(metric.decimals),
        metric.detail ?? '',
      ],
    [
      'entwicklung_monate',
      'Krabbeln',
      summary.crawlingMonths.average.toStringAsFixed(1),
      '${summary.crawlingMonths.count} Angaben',
    ],
    [
      'entwicklung_monate',
      'Erstes Laufen',
      summary.walkingMonths.average.toStringAsFixed(1),
      '${summary.walkingMonths.count} Angaben',
    ],
  ];

  await Clipboard.setData(
    ClipboardData(
      text: lines.map((line) => line.map(_csvCell).join(',')).join('\n'),
    ),
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reflexprofil-CSV kopiert.')),
    );
  }
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

class _ReflexOverviewCard extends StatelessWidget {
  const _ReflexOverviewCard({required this.summary});

  final _ReflexAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${summary.totalAssessments} abgeschlossene Fragebögen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metric in summary.ageGroups)
                  Chip(
                    label: Text('${metric.label}: ${metric.value.toInt()}'),
                    side: BorderSide.none,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricListCard extends StatelessWidget {
  const _MetricListCard({
    required this.title,
    required this.icon,
    required this.metrics,
    required this.valueSuffix,
    this.emptyText = 'Noch keine Daten.',
  });

  final String title;
  final IconData icon;
  final List<_AdminMetric> metrics;
  final String valueSuffix;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (metrics.isEmpty)
              Text(
                emptyText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              )
            else
              for (final metric in metrics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric.label,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (metric.detail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                metric.detail!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${metric.value.toStringAsFixed(metric.decimals)} $valueSuffix',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentMonthsCard extends StatelessWidget {
  const _DevelopmentMonthsCard({required this.summary});

  final _ReflexAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.child_care_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Entwicklung in Monaten',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MonthRow(label: 'Krabbeln', stats: summary.crawlingMonths),
            const SizedBox(height: 8),
            _MonthRow(label: 'Erstes Laufen', stats: summary.walkingMonths),
          ],
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.label, required this.stats});

  final String label;
  final _MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final value = stats.count == 0
        ? 'Keine Daten'
        : '${stats.average.toStringAsFixed(1)} Monate Ø · ${stats.count} Angaben';
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ReflexAnalyticsSummary {
  const _ReflexAnalyticsSummary({
    required this.totalAssessments,
    required this.ageGroups,
    required this.topReflexes,
    required this.topQuestions,
    required this.safetyFlags,
    required this.crawlingMonths,
    required this.walkingMonths,
  });

  final int totalAssessments;
  final List<_AdminMetric> ageGroups;
  final List<_AdminMetric> topReflexes;
  final List<_AdminMetric> topQuestions;
  final List<_AdminMetric> safetyFlags;
  final _MonthStats crawlingMonths;
  final _MonthStats walkingMonths;

  factory _ReflexAnalyticsSummary.fromRollup(
    List<AdminReflexProfileRollup> rows,
  ) {
    final questionTextById = {
      for (final question in childParentQuestionnaireV1.questions)
        question.id: '${question.number}. ${question.text('de')}',
    };
    final safetyFlagLabelById = {
      for (final question in childParentQuestionnaireV1.questions)
        if (question.trainerFlagLabel('de') case final label?)
          question.id: label,
    };
    final totalAssessments = rows.fold<int>(
      0,
      (sum, row) => sum + row.assessmentCount,
    );
    final ageGroups = rows
        .map((row) => _AdminMetric(
              label: _ageGroupLabel(row.ageGroup),
              value: row.assessmentCount.toDouble(),
            ))
        .toList()
      ..sort((a, b) => _ageSort(a.label).compareTo(_ageSort(b.label)));

    final reflexSums = <String, double>{};
    final reflexCounts = <String, int>{};
    final yesCounts = <String, int>{};
    final crawling = _MonthStatsBuilder();
    final walking = _MonthStatsBuilder();

    for (final row in rows) {
      for (final scoreSet in row.scores) {
        for (final entry in scoreSet.entries) {
          final value = entry.value;
          if (value is! Map) continue;
          final percent = value['percent'];
          if (percent is! num) continue;
          reflexSums.update(
            entry.key,
            (current) => current + percent.toDouble(),
            ifAbsent: () => percent.toDouble(),
          );
          reflexCounts.update(entry.key, (current) => current + 1,
              ifAbsent: () => 1);
        }
      }

      for (final answerSet in row.answers) {
        for (final entry in answerSet.entries) {
          final value = entry.value;
          if (value is! Map) continue;
          if (value['answer'] == 'yes') {
            yesCounts.update(entry.key, (current) => current + 1,
                ifAbsent: () => 1);
          }
          final months = value['months'];
          if (months is num && entry.key == 'q032') {
            crawling.add(months.toDouble());
          }
          if (months is num && entry.key == 'q033') {
            walking.add(months.toDouble());
          }
        }
      }
    }

    final topReflexes = reflexSums.entries
        .map((entry) => _AdminMetric(
              label: _reflexLabel(entry.key),
              value: entry.value / (reflexCounts[entry.key] ?? 1),
              decimals: 1,
              detail: '${reflexCounts[entry.key] ?? 0} Fragebögen',
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final safetyFlags = safetyFlagLabelById.entries
        .map((e) => _AdminMetric(
              label: e.value,
              value: (yesCounts[e.key] ?? 0).toDouble(),
              decimals: 0,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topQuestions = yesCounts.entries
        .where((e) => !safetyFlagLabelById.containsKey(e.key))
        .map((entry) => _AdminMetric(
              label: questionTextById[entry.key] ?? entry.key,
              value: entry.value.toDouble(),
              decimals: 0,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ReflexAnalyticsSummary(
      totalAssessments: totalAssessments,
      ageGroups: ageGroups,
      topReflexes: topReflexes.take(8).toList(),
      topQuestions: topQuestions.take(12).toList(),
      safetyFlags: safetyFlags,
      crawlingMonths: crawling.build(),
      walkingMonths: walking.build(),
    );
  }
}

class _AdminMetric {
  const _AdminMetric({
    required this.label,
    required this.value,
    this.detail,
    this.decimals = 0,
  });

  final String label;
  final double value;
  final String? detail;
  final int decimals;
}

class _MonthStats {
  const _MonthStats({
    required this.count,
    required this.average,
  });

  final int count;
  final double average;
}

class _MonthStatsBuilder {
  double _sum = 0;
  int _count = 0;

  void add(double value) {
    _sum += value;
    _count += 1;
  }

  _MonthStats build() => _MonthStats(
        count: _count,
        average: _count == 0 ? 0 : _sum / _count,
      );
}

String _ageGroupLabel(String ageGroup) {
  if (ageGroup == 'unknown') return 'Ohne Alter';
  return ageGroup;
}

int _ageSort(String label) {
  const order = ['0-2', '3-4', '5-7', '8-10', '11-13', '14-17', '18+'];
  final index = order.indexOf(label);
  if (index == -1) return 99;
  return index;
}

String _reflexLabel(String reflex) {
  return switch (reflex) {
    'delay' => 'Verzögerung',
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
    _ => reflex,
  };
}

class _SharedExperienceAdminTab extends ConsumerWidget {
  const _SharedExperienceAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sharesAsync = ref.watch(adminExperienceSharesProvider);
    return sharesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (shares) {
        if (shares.isEmpty) {
          return const Center(child: Text('Keine geteilten Erfahrungen.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: shares.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _AdminInfoCard(
                icon: Icons.rate_review_outlined,
                title: 'Geteilte Erfahrungen',
                body:
                    'Admin-Review bleibt moderierend: auffällige Beiträge können entfernt werden, ohne daraus einen offenen Social Feed zu machen.',
              );
            }
            final share = shares[index - 1];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.forum_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${share.authorLabel} · ${share.packageId}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(share.content),
                    const SizedBox(height: 8),
                    Text(
                      share.createdAt.toLocal().toString().substring(0, 16),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await _confirmRemoveShare(context);
                          if (!confirmed) return;
                          try {
                            await ref
                                .read(adminExperienceSharesProvider.notifier)
                                .deleteShare(share.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Beitrag konnte nicht entfernt werden: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Entfernen'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainerApplicationCard extends ConsumerWidget {
  const _TrainerApplicationCard({required this.application});

  final TrainerApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(trainerApplicationsForReviewProvider.notifier);

    Future<void> markSeen() async {
      await notifier.markBackgroundCheckSeen(application.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sichtprüfung dokumentiert.')),
        );
      }
    }

    Future<void> approve() async {
      if (!application.canApprove) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vor der Genehmigung muss die Sichtprüfung dokumentiert sein.',
            ),
          ),
        );
        return;
      }

      String code;
      try {
        code = await notifier.approve(application.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Code konnte nicht erzeugt werden: $e')),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Aktivierungscode erzeugt'),
            content: SelectableText(
              code,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Kopieren'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        );
      }
    }

    Future<void> needsMoreInfo() async {
      await notifier.needsMoreInfo(application.id);
      if (context.mounted) {
        if (application.reviewChannelId != null) {
          context.push(
            Routes.dmChannel.replaceFirst(
              ':channelId',
              application.reviewChannelId!,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rückfrage-Status gesetzt.')),
          );
        }
      }
    }

    Future<void> reject() async {
      await notifier.reject(application.id);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.assignment_ind_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.fullName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(application.statusLabel(AppLocalizations.of(context)),
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(application.email,
                          style: Theme.of(context).textTheme.bodySmall),
                      if (application.phone != null)
                        Text(application.phone!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (application.city != null) ...[
              const SizedBox(height: 8),
              Text('Region: ${application.city}'),
            ],
            const SizedBox(height: 8),
            Text(application.professionalBackground),
            if (application.motivation != null) ...[
              const SizedBox(height: 8),
              Text(application.motivation!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  application.hasBackgroundCheck
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: application.hasBackgroundCheck
                      ? AppColors.success
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Führungszeugnis Stufe 2 per Sichtprüfung'),
                ),
              ],
            ),
            if (application.activationCode != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Code: ${application.activationCode}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Eingereicht: ${application.createdAt.toLocal().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: application.hasBackgroundCheck ? null : markSeen,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Sichtprüfung erledigt'),
                ),
                OutlinedButton(
                  onPressed: application.isOpen ? needsMoreInfo : null,
                  child: const Text('Infos anfordern'),
                ),
                OutlinedButton.icon(
                  onPressed: application.reviewChannelId == null
                      ? null
                      : () => context.push(
                            Routes.dmChannel.replaceFirst(
                              ':channelId',
                              application.reviewChannelId!,
                            ),
                          ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Review-Kanal'),
                ),
                OutlinedButton(
                  onPressed: application.isOpen ? reject : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Ablehnen'),
                ),
                FilledButton(
                  onPressed: application.isOpen ? approve : null,
                  child: const Text('Genehmigen & Code erzeugen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
