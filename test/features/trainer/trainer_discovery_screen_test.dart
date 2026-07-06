// T13 — Trainer-Discovery „make it work“: sichert die Launch-Anforderungen,
// dass (1) der Standort NIE beim Screen-Öffnen abgerufen wird, sondern nur
// nach explizitem Nutzer-Tap, (2) jeder Permission-Zweig in einem gestalteten
// Zustand endet statt in Sackgasse/Roh-Exception, (3) die beiden Empty-States
// (global „noch keine Trainer freigeschaltet“ vs. „keine in deiner Nähe“)
// unterschieden werden und (4) RPC-Fehler einen Retry anbieten.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:go_router/go_router.dart';

import 'package:corejourney/features/trainer/data/services/location_service.dart';
import 'package:corejourney/features/trainer/domain/models/trainer_profile.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_discovery_provider.dart';
import 'package:corejourney/features/trainer/presentation/screens/trainer_discovery_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);

  LocationResult result;
  int getPositionCalls = 0;
  bool openedAppSettings = false;
  bool openedLocationSettings = false;

  @override
  Future<LocationResult> getCurrentPosition() async {
    getPositionCalls++;
    return result;
  }

  @override
  Future<void> openAppSettings() async => openedAppSettings = true;

  @override
  Future<void> openLocationSettings() async => openedLocationSettings = true;
}

Position _position() => Position(
      latitude: 48.1351,
      longitude: 11.5820,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

TrainerProfile _trainer({String id = 't1', String name = 'Anna Beispiel'}) =>
    TrainerProfile(
      id: id,
      displayName: name,
      verified: true,
      status: TrainerProfileStatus.active,
      submittedAt: DateTime(2026),
    );

Widget _app({
  required _FakeLocationService location,
  required Future<List<TrainerProfile>> Function() public,
  Future<List<TrainerProfile>> Function(NearbyParams params)? nearby,
}) {
  final router = GoRouter(
    initialLocation: '/trainers',
    routes: [
      GoRoute(
        path: '/trainers',
        builder: (_, __) => const TrainerDiscoveryScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const Scaffold(body: Text('dashboard-stub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      locationServiceProvider.overrideWithValue(location),
      publicTrainersProvider.overrideWith((ref) => public()),
      nearbyTrainersProvider.overrideWith(
        (ref, params) =>
            nearby?.call(params) ?? Future.value(<TrainerProfile>[]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('Öffnen ruft KEINEN Standort ab und zeigt alle Trainer',
      (tester) async {
    final location = _FakeLocationService(LocationSuccess(_position()));
    await tester.pumpWidget(
      _app(location: location, public: () async => [_trainer()]),
    );
    await tester.pumpAndSettle();

    expect(location.getPositionCalls, 0,
        reason: 'Standort darf nur nach Nutzer-Tap abgerufen werden (T13)');
    expect(find.text('Alle'), findsOneWidget);
    // Liste-Tab öffnen, damit der Name ohne Karte sichtbar ist.
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('Anna Beispiel'), findsOneWidget);
  });

  testWidgets('Global-Empty-State: „noch keine Trainer freigeschaltet“ + CTA',
      (tester) async {
    final location = _FakeLocationService(LocationSuccess(_position()));
    await tester.pumpWidget(
      _app(location: location, public: () async => []),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Trainer freigeschaltet'), findsOneWidget);
    // CTA führt aus dem Screen (hier: Dashboard-Fallback, da nichts zu poppen).
    await tester.tap(find.text('Zurück zum Training'));
    await tester.pumpAndSettle();
    expect(find.text('dashboard-stub'), findsOneWidget);
  });

  testWidgets('Umkreis-Tap zeigt CTA-Karte — noch immer kein Auto-Abruf',
      (tester) async {
    final location = _FakeLocationService(LocationSuccess(_position()));
    await tester.pumpWidget(
      _app(location: location, public: () async => [_trainer()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Umkreis'));
    await tester.pumpAndSettle();

    expect(location.getPositionCalls, 0);
    expect(find.text('Standort verwenden'), findsOneWidget);
    expect(
      find.textContaining('nicht gespeichert'),
      findsOneWidget,
      reason: 'CTA erklärt die Datenverwendung vor dem System-Dialog',
    );
  });

  testWidgets('„Standort verwenden“ mit Freigabe → Radius-Slider + Umkreissuche',
      (tester) async {
    final location = _FakeLocationService(LocationSuccess(_position()));
    NearbyParams? seenParams;
    await tester.pumpWidget(
      _app(
        location: location,
        public: () async => [_trainer()],
        nearby: (params) async {
          seenParams = params;
          return [_trainer(id: 't2', name: 'Bernd Nah')];
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Umkreis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standort verwenden'));
    await tester.pumpAndSettle();

    expect(location.getPositionCalls, 1);
    expect(find.byType(Slider), findsOneWidget);
    expect(seenParams?.lat, 48.1351);
    expect(seenParams?.radiusKm, 25);
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('Bernd Nah'), findsOneWidget);
  });

  testWidgets('Abgelehnt → Hinweis, Fallback-Liste bleibt nutzbar',
      (tester) async {
    final location = _FakeLocationService(
      const LocationFailure(LocationFailureReason.denied),
    );
    await tester.pumpWidget(
      _app(location: location, public: () async => [_trainer()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Umkreis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standort verwenden'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ohne Standort-Freigabe'),
      findsOneWidget,
    );
    // Kein Dead-End: alle Trainer sind weiterhin erreichbar.
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('Anna Beispiel'), findsOneWidget);
  });

  testWidgets('Dauerhaft abgelehnt → „Einstellungen öffnen“ öffnet App-Settings',
      (tester) async {
    final location = _FakeLocationService(
      const LocationFailure(LocationFailureReason.deniedForever),
    );
    await tester.pumpWidget(
      _app(location: location, public: () async => [_trainer()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Umkreis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standort verwenden'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Einstellungen öffnen'));
    await tester.pumpAndSettle();
    expect(location.openedAppSettings, isTrue);
  });

  testWidgets('Ortungsdienste aus → Hinweis mit Ortungs-Einstellungen',
      (tester) async {
    final location = _FakeLocationService(
      const LocationFailure(LocationFailureReason.serviceDisabled),
    );
    await tester.pumpWidget(
      _app(location: location, public: () async => [_trainer()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Umkreis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standort verwenden'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ortungsdienste'), findsWidgets);
    await tester.tap(find.text('Ortungs-Einstellungen'));
    await tester.pumpAndSettle();
    expect(location.openedLocationSettings, isTrue);
  });

  testWidgets('Umkreis leer → eigener Empty-State, CTA wechselt zu „Alle“',
      (tester) async {
    final location = _FakeLocationService(LocationSuccess(_position()));
    await tester.pumpWidget(
      _app(
        location: location,
        public: () async => [_trainer()],
        nearby: (_) async => [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Umkreis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standort verwenden'));
    await tester.pumpAndSettle();

    expect(find.text('Keine Trainer in deiner Nähe'), findsOneWidget);
    await tester.tap(find.text('Alle Trainer anzeigen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('Anna Beispiel'), findsOneWidget);
  });

  testWidgets('Ladefehler → gestalteter Error-State, Retry lädt neu',
      (tester) async {
    final location = _FakeLocationService(LocationSuccess(_position()));
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        location: location,
        public: () {
          attempts++;
          if (attempts == 1) {
            return Future<List<TrainerProfile>>.error(Exception('offline'));
          }
          return Future.value([_trainer()]);
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trainer konnten nicht geladen werden'), findsOneWidget);
    expect(find.text('Exception: offline'), findsNothing,
        reason: 'Keine Roh-Exception im UI');

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('Anna Beispiel'), findsOneWidget);
  });
}
