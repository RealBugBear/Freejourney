import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/entry_points_provider.dart';

class EntryPointsScreen extends ConsumerStatefulWidget {
  const EntryPointsScreen({super.key});

  @override
  ConsumerState<EntryPointsScreen> createState() => _EntryPointsScreenState();
}

class _EntryPointsScreenState extends ConsumerState<EntryPointsScreen> {
  final Set<String> _expanded = {};

  void _toggleCard(String key) => setState(() {
        _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key);
      });

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(entryPointsProvider);
    final l10n = AppLocalizations.of(context);
    final areas = _areas(l10n);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.entryPointsTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.entryPointsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 20),
              ...areas.map(
                (a) => _AreaCard(
                  area: a,
                  expanded: _expanded.contains(a.key),
                  onToggle: () => _toggleCard(a.key),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.entryPointsChipQuestion,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: areas.map((a) {
                  return FilterChip(
                    label: Text(a.chipLabel),
                    selected: selected.contains(a.key),
                    onSelected: (_) =>
                        ref.read(entryPointsProvider.notifier).toggle(a.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.entryPointsSelectionNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (kInviteEnabled) {
                      context.go(
                        '${Routes.inviteAccept}?onboarding=1',
                      );
                    } else {
                      context.go(Routes.dashboard);
                    }
                  },
                  child: Text(l10n.next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaData {
  const _AreaData({
    required this.key,
    required this.title,
    required this.teaser,
    required this.detail,
    required this.chipLabel,
    this.source,
  });
  final String key;
  final String title;
  final String teaser;
  final String detail;
  final String chipLabel;
  final String? source;
}

/// The five entry-point areas. Keys are stable analytics identifiers and must
/// not change; all visible text comes from [AppLocalizations].
List<_AreaData> _areas(AppLocalizations l10n) => [
      _AreaData(
        key: 'koerper_therapie',
        title: l10n.entryPointsBodyTitle,
        teaser: l10n.entryPointsBodyTeaser,
        detail: l10n.entryPointsBodyDetail,
        chipLabel: l10n.entryPointsBodyChip,
        source: l10n.entryPointsBodySource,
      ),
      _AreaData(
        key: 'koordination_leistung',
        title: l10n.entryPointsCoordinationTitle,
        teaser: l10n.entryPointsCoordinationTeaser,
        detail: l10n.entryPointsCoordinationDetail,
        chipLabel: l10n.entryPointsCoordinationChip,
        source: l10n.entryPointsCoordinationSource,
      ),
      _AreaData(
        key: 'emotionale_regulation',
        title: l10n.entryPointsEmotionTitle,
        teaser: l10n.entryPointsEmotionTeaser,
        detail: l10n.entryPointsEmotionDetail,
        chipLabel: l10n.entryPointsEmotionChip,
        source: l10n.entryPointsEmotionSource,
      ),
      _AreaData(
        key: 'mein_kind',
        title: l10n.entryPointsChildTitle,
        teaser: l10n.entryPointsChildTeaser,
        detail: l10n.entryPointsChildDetail,
        chipLabel: l10n.entryPointsChildChip,
        source: l10n.entryPointsChildSource,
      ),
      _AreaData(
        key: 'neugierde',
        title: l10n.entryPointsCuriosityTitle,
        teaser: l10n.entryPointsCuriosityTeaser,
        detail: l10n.entryPointsCuriosityDetail,
        chipLabel: l10n.entryPointsCuriosityChip,
      ),
    ];

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.expanded,
    required this.onToggle,
  });
  final _AreaData area;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(area.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(area.teaser,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expanded
                        ? '${AppLocalizations.of(context).entryPointsShowLess} ↑'
                        : '${AppLocalizations.of(context).entryPointsShowMore} ↓',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.55,
                        ),
                  ),
                  if (area.source != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      area.source!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
