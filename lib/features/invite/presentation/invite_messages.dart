import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../domain/models/invite_overview.dart';
import '../domain/models/invite_redeem_result.dart';
import '../../../l10n/app_localizations.dart';

/// Strips separators and uppercases; does not invent missing characters.
String normalizeInviteCodeInput(String raw) {
  return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

/// True when the normalized value matches the referral code alphabet/length.
bool isWellFormedInviteCode(String normalized) {
  return InviteOverview.codePattern.hasMatch(normalized);
}

/// Maps every redeem outcome to its dedicated copy — never a generic error.
String inviteRedeemUserMessage(
  AppLocalizations l10n,
  InviteRedeemResult result,
) {
  return switch (result) {
    InviteRedeemResult.accepted => l10n.inviteRedeemSuccess,
    InviteRedeemResult.unknownCode => l10n.inviteErrorUnknownCode,
    InviteRedeemResult.codeInactive => l10n.inviteErrorCodeInactive,
    InviteRedeemResult.ownCode => l10n.inviteErrorOwnCode,
    InviteRedeemResult.alreadyReferred => l10n.inviteErrorAlreadyReferred,
    InviteRedeemResult.accountTooOld => l10n.inviteErrorAccountTooOld,
  };
}

/// Network / PostgREST transport failures → offline copy.
/// Contract drift ([FormatException]) and other surprises → unexpected copy.
bool isInviteConnectivityError(Object error) {
  if (error is SocketException || error is PostgrestException) {
    return true;
  }
  // http.ClientException without a direct http dependency.
  return error.runtimeType.toString() == 'ClientException';
}

String inviteRedeemFailureMessage(AppLocalizations l10n, Object error) {
  if (isInviteConnectivityError(error)) {
    return l10n.inviteErrorOffline;
  }
  return l10n.inviteErrorUnexpected;
}
