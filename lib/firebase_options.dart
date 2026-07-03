import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'config/app_config.dart';

/// Firebase app records live in the `corejourney-prod` project (all
/// environments — dev/staging separation happens via the `environment`
/// column on `device_tokens`, not via separate Firebase projects).
///
/// One record exists per applicationId/bundleId (`de.reflexjourney.app`,
/// `.dev`, `.staging`; created 2026-07-03). The API keys are project-wide,
/// so only appId and iosBundleId differ between environments.
class DefaultFirebaseOptions {
  /// Environment-aware options — use this from app bootstrap, where the
  /// entry point's [AppEnvironment] is known.
  ///
  /// The staging flavor boots as [AppEnvironment.production] and therefore
  /// uses the production record; its own records
  /// (…android:735b5547f2b54efae657bd / …ios:5bfce08bbcda5784e657bd) exist
  /// in Firebase should staging ever become a separate environment.
  static FirebaseOptions currentPlatformFor(AppEnvironment environment) {
    final dev = environment == AppEnvironment.development;
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return dev ? androidDev : android;
      case TargetPlatform.iOS:
        return dev ? iosDev : ios;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  /// Environment-agnostic fallback (production records). Only meant for the
  /// Android background-message isolate, which has no bootstrap context —
  /// background delivery works with any valid record of the project.
  static FirebaseOptions get currentPlatform =>
      currentPlatformFor(AppEnvironment.production);

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhyhMSeKeohmJfbKus6qWgX10_SZiwr-Q',
    appId: '1:673501917704:android:b154a14e7ca8b3dee657bd',
    messagingSenderId: '673501917704',
    projectId: 'corejourney-prod',
    storageBucket: 'corejourney-prod.firebasestorage.app',
  );

  static const FirebaseOptions androidDev = FirebaseOptions(
    apiKey: 'AIzaSyBhyhMSeKeohmJfbKus6qWgX10_SZiwr-Q',
    appId: '1:673501917704:android:3f343eda660ea89de657bd',
    messagingSenderId: '673501917704',
    projectId: 'corejourney-prod',
    storageBucket: 'corejourney-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAK9_s9KUMTSG3p9NOKebWRenxjjbuKPeU',
    appId: '1:673501917704:ios:888079dabe52dff4e657bd',
    messagingSenderId: '673501917704',
    projectId: 'corejourney-prod',
    storageBucket: 'corejourney-prod.firebasestorage.app',
    iosBundleId: 'de.reflexjourney.app',
  );

  static const FirebaseOptions iosDev = FirebaseOptions(
    apiKey: 'AIzaSyAK9_s9KUMTSG3p9NOKebWRenxjjbuKPeU',
    appId: '1:673501917704:ios:bb8b7ba947e1646ce657bd',
    messagingSenderId: '673501917704',
    projectId: 'corejourney-prod',
    storageBucket: 'corejourney-prod.firebasestorage.app',
    iosBundleId: 'de.reflexjourney.app.dev',
  );
}
