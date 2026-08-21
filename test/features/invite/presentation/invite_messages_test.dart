import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/domain/models/invite_redeem_result.dart';
import 'package:corejourney/features/invite/presentation/invite_messages.dart';
import 'package:corejourney/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('de'));
  });

  test('normalizeInviteCodeInput strips separators and uppercases', () {
    expect(normalizeInviteCodeInput('ab-cd ef'), 'ABCDEF');
    expect(normalizeInviteCodeInput('  xyz '), 'XYZ');
  });

  test('isWellFormedInviteCode accepts alphabet and length only', () {
    expect(isWellFormedInviteCode('ABCDEFGH'), isTrue);
    expect(isWellFormedInviteCode('ABCD2345'), isTrue);
    expect(isWellFormedInviteCode('ABCDEFG'), isFalse);
    expect(isWellFormedInviteCode('ABCDEFGHI'), isFalse);
    expect(isWellFormedInviteCode('ABCDEFG0'), isFalse); // 0 not in alphabet
    expect(isWellFormedInviteCode('ABCD1234'), isFalse); // 1 not in alphabet
  });

  test('each redeem result maps to its dedicated message', () {
    expect(
      inviteRedeemUserMessage(l10n, InviteRedeemResult.accepted),
      l10n.inviteRedeemSuccess,
    );
    expect(
      inviteRedeemUserMessage(l10n, InviteRedeemResult.unknownCode),
      l10n.inviteErrorUnknownCode,
    );
    expect(
      inviteRedeemUserMessage(l10n, InviteRedeemResult.codeInactive),
      l10n.inviteErrorCodeInactive,
    );
    expect(
      inviteRedeemUserMessage(l10n, InviteRedeemResult.ownCode),
      l10n.inviteErrorOwnCode,
    );
    expect(
      inviteRedeemUserMessage(l10n, InviteRedeemResult.alreadyReferred),
      l10n.inviteErrorAlreadyReferred,
    );
    expect(
      inviteRedeemUserMessage(l10n, InviteRedeemResult.accountTooOld),
      l10n.inviteErrorAccountTooOld,
    );
  });

  test('error messages are distinct — no generic collapse', () {
    final messages = InviteRedeemResult.values
        .where((r) => r != InviteRedeemResult.accepted)
        .map((r) => inviteRedeemUserMessage(l10n, r))
        .toSet();
    expect(messages.length, 5);
  });
}
