import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/location_service.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';
import '../widgets/osm_attribution.dart';

/// Standort-Regel (docs/STANDORT_DATENFLUSS_T13.md): Der Gerätestandort wird
/// ausschließlich nach explizitem Nutzer-Tap abgerufen — nie beim Öffnen des
/// Screens — und nur im Umkreis-Modus an `find_trainers_nearby` übergeben.
class TrainerDiscoveryScreen extends ConsumerStatefulWidget {
  const TrainerDiscoveryScreen({super.key, this.onboardingExtra});

  final Map<String, dynamic>? onboardingExtra;

  @override
  ConsumerState<TrainerDiscoveryScreen> createState() =>
      _TrainerDiscoveryScreenState();
}

enum _LocationStatus {
  idle,
  loading,
  granted,
  serviceDisabled,
  denied,
  deniedForever,
  error,
}

class _TrainerDiscoveryScreenState
    extends ConsumerState<TrainerDiscoveryScreen> {
  double _radiusKm = 25;
  Position? _userPosition;
  _LocationStatus _locationStatus = _LocationStatus.idle;
  bool _showAllTrainers = true;

  Future<void> _requestLocation() async {
    setState(() => _locationStatus = _LocationStatus.loading);
    final result =
        await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case LocationSuccess(:final position):
          _userPosition = position;
          _locationStatus = _LocationStatus.granted;
        case LocationFailure(:final reason):
          _locationStatus = switch (reason) {
            LocationFailureReason.serviceDisabled =>
              _LocationStatus.serviceDisabled,
            LocationFailureReason.denied => _LocationStatus.denied,
            LocationFailureReason.deniedForever =>
              _LocationStatus.deniedForever,
            LocationFailureReason.error => _LocationStatus.error,
          };
      }
    });
  }

  bool get _nearbyActive => !_showAllTrainers && _userPosition != null;

  void _leaveScreen() {
    if (context.canPop()) {
      context.pop();
    } else if (widget.onboardingExtra != null) {
      context.go('/intake-assessment/trainer', extra: widget.onboardingExtra);
    } else {
      context.go(Routes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final asyncTrainers = _nearbyActive
        ? ref.watch(
            nearbyTrainersProvider(
              NearbyParams(
                lat: _userPosition!.latitude,
                lng: _userPosition!.longitude,
                radiusKm: _radiusKm,
              ),
            ),
          )
        : ref.watch(publicTrainersProvider);

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.public_outlined),
                      label: Text(l10n.trainerDiscoveryAll),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.near_me_outlined),
                      label: Text(l10n.trainerDiscoveryNearby),
                    ),
                  ],
                  selected: {_showAllTrainers},
                  onSelectionChanged: (selection) {
                    setState(() => _showAllTrainers = selection.first);
                  },
                ),
                if (!_showAllTrainers) _buildNearbyHeader(l10n),
              ],
            ),
          ),
          Expanded(
            child: asyncTrainers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                l10n: l10n,
                onRetry: () => _nearbyActive
                    ? ref.invalidate(nearbyTrainersProvider)
                    : ref.invalidate(publicTrainersProvider),
              ),
              data: (trainers) => _TrainerResults(
                trainers: trainers,
                userLat: _userPosition?.latitude,
                userLng: _userPosition?.longitude,
                l10n: l10n,
                onboardingExtra: widget.onboardingExtra,
                globalMode: !_nearbyActive,
                onShowAll: () => setState(() => _showAllTrainers = true),
                onLeave: _leaveScreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kopfbereich im Umkreis-Modus: Slider bei vorhandener Position, sonst
  /// CTA/Hinweis je Permission-Zweig. Die Ergebnisliste darunter zeigt in
  /// jedem Zweig weiterhin alle Trainer — kein Zustand endet in einer
  /// Sackgasse.
  Widget _buildNearbyHeader(AppLocalizations l10n) {
    if (_userPosition != null) {
      return Row(
        children: [
          Text(l10n.trainerDiscoveryRadiusLabel(_radiusKm.round())),
          Expanded(
            child: Slider(
              value: _radiusKm,
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
          ),
        ],
      );
    }
    switch (_locationStatus) {
      case _LocationStatus.loading:
        return const Padding(
          padding: EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(),
        );
      case _LocationStatus.idle:
      case _LocationStatus.granted:
        return _LocationCta(l10n: l10n, onUseLocation: _requestLocation);
      case _LocationStatus.serviceDisabled:
        return _LocationNotice(
          message: l10n.trainerDiscoveryServiceDisabled,
          actionLabel: l10n.trainerDiscoveryOpenLocationSettings,
          onAction: () =>
              ref.read(locationServiceProvider).openLocationSettings(),
          onRetry: _requestLocation,
          retryLabel: l10n.trainerDiscoveryRetry,
        );
      case _LocationStatus.denied:
        return _LocationNotice(
          message: l10n.trainerDiscoveryDenied,
          onRetry: _requestLocation,
          retryLabel: l10n.trainerDiscoveryRetry,
        );
      case _LocationStatus.deniedForever:
        return _LocationNotice(
          message: l10n.trainerDiscoveryDeniedForever,
          actionLabel: l10n.trainerDiscoveryOpenAppSettings,
          onAction: () => ref.read(locationServiceProvider).openAppSettings(),
          onRetry: _requestLocation,
          retryLabel: l10n.trainerDiscoveryRetry,
        );
      case _LocationStatus.error:
        return _LocationNotice(
          message: l10n.trainerDiscoveryLocationError,
          onRetry: _requestLocation,
          retryLabel: l10n.trainerDiscoveryRetry,
        );
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final isOnboarding = widget.onboardingExtra != null;
    return AppBar(
      title: Text(l10n.trainerDiscoveryTitle),
      leading: isOnboarding || context.canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/intake-assessment/trainer',
                      extra: widget.onboardingExtra);
                }
              },
            )
          : null,
    );
  }
}

/// Nutzerinitiierter Standort-Einstieg (T13): erklärt VOR dem System-Dialog,
/// wofür der Standort gebraucht wird und dass er nicht gespeichert wird.
class _LocationCta extends StatelessWidget {
  const _LocationCta({required this.l10n, required this.onUseLocation});

  final AppLocalizations l10n;
  final VoidCallback onUseLocation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.near_me_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.trainerDiscoveryLocationCtaText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onUseLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: Text(l10n.trainerDiscoveryLocationCtaButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_off_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              children: [
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                TextButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerResults extends StatefulWidget {
  const _TrainerResults({
    required this.trainers,
    required this.userLat,
    required this.userLng,
    required this.l10n,
    required this.onboardingExtra,
    required this.globalMode,
    required this.onShowAll,
    required this.onLeave,
  });

  final List<TrainerProfile> trainers;
  final double? userLat;
  final double? userLng;
  final AppLocalizations l10n;
  final Map<String, dynamic>? onboardingExtra;
  final bool globalMode;
  final VoidCallback onShowAll;
  final VoidCallback onLeave;

  @override
  State<_TrainerResults> createState() => _TrainerResultsState();
}

class _TrainerResultsState extends State<_TrainerResults>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final filtered = _filterTrainers(widget.trainers, _query);

    if (widget.trainers.isEmpty) {
      // Zwei ehrlich getrennte Fälle: Launch-Realität „noch keine Trainer
      // freigeschaltet“ (global) vs. „keine im Umkreis“ (nearby).
      return widget.globalMode
          ? _EmptyState(
              icon: Icons.groups_outlined,
              title: l10n.trainerDiscoveryEmptyGlobalTitle,
              body: l10n.trainerDiscoveryEmptyGlobalBody,
              ctaLabel: l10n.trainerDiscoveryEmptyGlobalCta,
              onCta: widget.onLeave,
            )
          : _EmptyState(
              icon: Icons.location_searching,
              title: l10n.trainerDiscoveryEmptyNearbyTitle,
              body: l10n.trainerDiscoveryEmptyNearbyBody,
              ctaLabel: l10n.trainerDiscoveryEmptyNearbyCta,
              onCta: widget.onShowAll,
            );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.map_outlined),
              text: l10n.trainerDiscoveryTabMap,
            ),
            Tab(
              icon: const Icon(Icons.list_outlined),
              text: l10n.trainerDiscoveryTabList,
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MapView(
                trainers: widget.trainers,
                userLat: widget.userLat,
                userLng: widget.userLng,
                l10n: l10n,
                onboardingExtra: widget.onboardingExtra,
                globalMode: widget.globalMode,
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.trainerDiscoverySearchHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(l10n.trainerDiscoveryNoMatches),
                          )
                        : _ListView(
                            trainers: filtered,
                            l10n: l10n,
                            onboardingExtra: widget.onboardingExtra,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<TrainerProfile> _filterTrainers(
    List<TrainerProfile> trainers,
    String query,
  ) {
    if (query.isEmpty) return trainers;
    return trainers.where((trainer) {
      final haystack = [
        trainer.displayName,
        trainer.bio ?? '',
        trainer.contactEmail ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onCta, child: Text(ctaLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.trainerDiscoveryLoadErrorTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trainerDiscoveryLoadErrorBody,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(l10n.trainerDiscoveryRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends ConsumerWidget {
  const _MapView({
    required this.trainers,
    required this.userLat,
    required this.userLng,
    required this.l10n,
    required this.onboardingExtra,
    required this.globalMode,
  });

  final List<TrainerProfile> trainers;
  final double? userLat;
  final double? userLng;
  final AppLocalizations l10n;
  final Map<String, dynamic>? onboardingExtra;
  final bool globalMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerPoints = trainers
        .where((t) => t.publicLatitude != null && t.publicLongitude != null)
        .map((t) => LatLng(t.publicLatitude!, t.publicLongitude!))
        .toList();
    final userLatLng =
        userLat == null || userLng == null ? null : LatLng(userLat!, userLng!);
    final initialCenter = userLatLng ??
        (trainerPoints.isNotEmpty
            ? trainerPoints.first
            : const LatLng(51.1657, 10.4515));
    // Tiles brauchen Netz — die App ist sonst offline-first, deshalb ein
    // expliziter Hinweis statt grauer Kachelwüste (T13 Punkt 6).
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: globalMode ? 5 : 10,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.reflexjourney.app',
            ),
            MarkerLayer(
              markers: [
                // User location
                if (userLatLng != null)
                  Marker(
                    point: userLatLng,
                    width: 20,
                    height: 20,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                // Trainer pins (approximate)
                for (final t in trainers)
                  if (t.publicLatitude != null && t.publicLongitude != null)
                    Marker(
                      point: LatLng(t.publicLatitude!, t.publicLongitude!),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => context.push('/trainers/${t.id}',
                            extra: onboardingExtra == null
                                ? t
                                : {
                                    'trainer': t,
                                    'onboardingExtra': onboardingExtra,
                                  }),
                        child: const Icon(Icons.person_pin_circle,
                            color: AppColors.primary, size: 36),
                      ),
                    ),
              ],
            ),
            const OsmAttribution(),
          ],
        ),
        if (!isOnline)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.trainerDiscoveryOfflineBanner,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.trainers,
    required this.l10n,
    required this.onboardingExtra,
  });

  final List<TrainerProfile> trainers;
  final AppLocalizations l10n;
  final Map<String, dynamic>? onboardingExtra;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: trainers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = trainers[i];
        return ListTile(
          leading: t.photoUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(t.photoUrl!))
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Row(
            children: [
              Text(t.displayName),
              if (t.verified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: AppColors.primary, size: 16),
              ],
            ],
          ),
          subtitle: t.distanceKm != null
              ? Text(l10n.trainerDiscoveryDistanceLabel(t.distanceKm!))
              : null,
          onTap: () => context.push('/trainers/${t.id}',
              extra: onboardingExtra == null
                  ? t
                  : {
                      'trainer': t,
                      'onboardingExtra': onboardingExtra,
                    }),
        );
      },
    );
  }
}
