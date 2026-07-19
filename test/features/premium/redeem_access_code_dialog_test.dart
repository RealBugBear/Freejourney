import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/premium/data/premium_repository.dart';
import 'package:corejourney/features/premium/domain/entitlement.dart';
import 'package:corejourney/features/profile/presentation/screens/profile_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';

Widget _app(Locale locale, TextEditingController controller) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.5),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RedeemAccessCodeDialog(controller: controller),
      ),
    );

void main() {
  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets(
      'redemption dialog renders ${locale.languageCode} at 150% text scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_app(locale, controller));
        await tester.pumpAndSettle();

        final expectedTitle = locale.languageCode == 'de'
            ? 'Zugangscode einlösen'
            : 'Redeem access code';
        final expectedBody = locale.languageCode == 'de'
            ? 'Ein Code kann Premium- oder Studio-Zugang direkt freischalten '
                'oder auf ein Store-Angebot verweisen.'
            : 'A code may grant Premium or Studio access directly or identify '
                'a store offer.';
        final action = locale.languageCode == 'de' ? 'Einlösen' : 'Redeem';

        expect(find.text(expectedTitle), findsOneWidget);
        expect(find.text(expectedBody), findsOneWidget);
        expect(find.text(action), findsOneWidget);
        expect(tester.takeException(), isNull);

        final actionSize =
            tester.getSize(find.widgetWithText(FilledButton, action));
        expect(actionSize.height, greaterThanOrEqualTo(44));
      },
    );
  }

  test('benefit-aware copy distinguishes internal grants and store offers', () {
    const internalStudio = RedeemAccessCodeResult(
      benefitKind: BenefitKind.internalGrant,
      entitlementKey: EntitlementKey.studio,
      isPermanent: true,
    );
    const storeOffer = RedeemAccessCodeResult(
      benefitKind: BenefitKind.storeOffer,
      entitlementKey: EntitlementKey.premium,
      appleOfferRef: 'offer-ref',
    );

    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));

    expect(
      redeemAccessCodeSuccessMessage(en, internalStudio, const Locale('en')),
      contains('not a subscription'),
    );
    expect(
      redeemAccessCodeSuccessMessage(de, internalStudio, const Locale('de')),
      contains('kein Abo'),
    );
    expect(
      redeemAccessCodeSuccessMessage(en, storeOffer, const Locale('en')),
      contains('Access is not active yet'),
    );
    expect(
      redeemAccessCodeSuccessMessage(de, storeOffer, const Locale('de')),
      contains('Zugang ist noch nicht aktiv'),
    );
  });

  test('new campaign, role, limit, offer and service errors are localized', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));
    const errors = [
      RedeemAccessCodeError.campaignInactive,
      RedeemAccessCodeError.roleNotEligible,
      RedeemAccessCodeError.redemptionLimitReached,
      RedeemAccessCodeError.offerUnavailable,
      RedeemAccessCodeError.invalidPlatform,
      RedeemAccessCodeError.benefitCodeSecretMissing,
    ];

    for (final error in errors) {
      expect(
        redeemAccessCodeErrorMessage(en, error),
        isNot(en.redeemAccessCodeErrorUnknown),
        reason: '$error needs specific English copy',
      );
      expect(
        redeemAccessCodeErrorMessage(de, error),
        isNot(de.redeemAccessCodeErrorUnknown),
        reason: '$error needs specific German copy',
      );
    }
    expect(
      redeemAccessCodeErrorMessage(
        en,
        RedeemAccessCodeError.roleNotEligible,
      ),
      contains('account role'),
    );
    expect(
      redeemAccessCodeErrorMessage(
        de,
        RedeemAccessCodeError.roleNotEligible,
      ),
      contains('Kontorolle'),
    );
    expect(
      redeemAccessCodeErrorMessage(
        en,
        RedeemAccessCodeError.benefitCodeSecretMissing,
      ),
      isNot(contains('secret')),
    );
  });
}
