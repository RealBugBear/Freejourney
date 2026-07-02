import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerDiscoveryScreen extends ConsumerStatefulWidget {
  const TrainerDiscoveryScreen({super.key, this.onboardingExtra});

  final Map<String, dynamic>? onboardingExtra;

  @override
  ConsumerState<TrainerDiscoveryScreen> createState() =>
      _TrainerDiscoveryScreenState();
}

class _TrainerDiscoveryScreenState
    extends ConsumerState<TrainerDiscoveryScreen> {
  double _radiusKm = 25;
  Position? _userPosition;
  String? _locationError;
  bool _loadingLocation = true;
  bool _showAllTrainers = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError =
              AppLocalizations.of(context).trainerDiscoveryLocationDenied;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final canUseNearby = _userPosition != null;
    final asyncTrainers = _showAllTrainers || !canUseNearby
        ? ref.watch(publicTrainersProvider)
        : ref.watch(
            nearbyTrainersProvider(
              NearbyParams(
                lat: _userPosition!.latitude,
                lng: _userPosition!.longitude,
                radiusKm: _radiusKm,
              ),
            ),
          );

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
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.public_outlined),
                      label: Text('Alle'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.near_me_outlined),
                      label: Text('Umkreis'),
                    ),
                  ],
                  selected: {_showAllTrainers || !canUseNearby},
                  onSelectionChanged: canUseNearby
                      ? (selection) {
                          setState(() => _showAllTrainers = selection.first);
                        }
                      : null,
                ),
                if (!_showAllTrainers && canUseNearby)
                  Row(
                    children: [
                      Text(l10n.trainerDiscoveryRadiusLabel(
                        _radiusKm.round(),
                      )),
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
                  )
                else if (_loadingLocation)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _LocationNotice(
                      message:
                          'Standort ist nicht aktiv. Alle Trainer werden ohne Umkreisfilter angezeigt.',
                      onRetry: () {
                        setState(() {
                          _loadingLocation = true;
                          _locationError = null;
                        });
                        _fetchLocation();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncTrainers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (trainers) => _TrainerResults(
                trainers: trainers,
                userLat: _userPosition?.latitude,
                userLng: _userPosition?.longitude,
                l10n: l10n,
                onboardingExtra: widget.onboardingExtra,
                globalMode: _showAllTrainers || !canUseNearby,
              ),
            ),
          ),
        ],
      ),
    );
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

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.location_off_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Erneut'),
            ),
          ],
        ),
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
  });

  final List<TrainerProfile> trainers;
  final double? userLat;
  final double? userLng;
  final AppLocalizations l10n;
  final Map<String, dynamic>? onboardingExtra;
  final bool globalMode;

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
    final filtered = _filterTrainers(widget.trainers, _query);

    if (widget.trainers.isEmpty) {
      return Center(
        child: Text(
          widget.globalMode
              ? 'Keine Trainer gefunden.'
              : widget.l10n.trainerDiscoveryEmpty,
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Karte'),
            Tab(icon: Icon(Icons.list_outlined), text: 'Liste'),
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
                        hintText: 'Trainer suchen',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Keine Treffer.'))
                        : _ListView(
                            trainers: filtered,
                            l10n: widget.l10n,
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

class _MapView extends StatelessWidget {
  const _MapView({
    required this.trainers,
    required this.userLat,
    required this.userLng,
    required this.onboardingExtra,
    required this.globalMode,
  });

  final List<TrainerProfile> trainers;
  final double? userLat;
  final double? userLng;
  final Map<String, dynamic>? onboardingExtra;
  final bool globalMode;

  @override
  Widget build(BuildContext context) {
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

    return FlutterMap(
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
