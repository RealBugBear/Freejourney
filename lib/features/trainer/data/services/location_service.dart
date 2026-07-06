import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Warum der Standort-Abruf fehlgeschlagen ist — jede Variante hat im
/// Discovery-Screen einen eigenen, gestalteten UI-Zweig (T13).
enum LocationFailureReason {
  /// Ortungsdienste sind systemweit ausgeschaltet.
  serviceDisabled,

  /// Nutzer hat die Berechtigung (auch nach Nachfrage) abgelehnt.
  denied,

  /// Berechtigung dauerhaft abgelehnt — nur über die Systemeinstellungen
  /// wieder aktivierbar.
  deniedForever,

  /// Zeitüberschreitung oder Plattformfehler beim Positionsabruf.
  error,
}

sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  const LocationSuccess(this.position);
  final Position position;
}

class LocationFailure extends LocationResult {
  const LocationFailure(this.reason);
  final LocationFailureReason reason;
}

/// Kapselt die statische Geolocator-API, damit der Screen testbar bleibt.
///
/// Datenschutz-Vertrag (siehe docs/STANDORT_DATENFLUSS_T13.md): Aufrufer
/// dürfen [getCurrentPosition] nur nach einer expliziten Nutzer-Aktion
/// auslösen; die Position wird nirgends persistiert.
abstract class LocationService {
  Future<LocationResult> getCurrentPosition();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static const _timeout = Duration(seconds: 15);

  @override
  Future<LocationResult> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationFailure(LocationFailureReason.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.deniedForever:
          return const LocationFailure(LocationFailureReason.deniedForever);
        case LocationPermission.denied:
          return const LocationFailure(LocationFailureReason.denied);
        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          break;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _timeout),
      );
      return LocationSuccess(position);
    } catch (_) {
      return const LocationFailure(LocationFailureReason.error);
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
