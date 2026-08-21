/// Machine-readable outcomes of `redeem_invite_code` (`result` field).
enum InviteRedeemResult {
  accepted,
  unknownCode,
  codeInactive,
  ownCode,
  alreadyReferred,
  accountTooOld;

  /// Parses the RPC `result` string.
  ///
  /// Only the explicit server value `unknown_code` maps to [unknownCode].
  /// Missing or unrecognized values throw [FormatException] so a contract
  /// drift is not shown to the user as an invalid invite code.
  static InviteRedeemResult fromRpc(String? raw) {
    return switch (raw) {
      'accepted' => InviteRedeemResult.accepted,
      'unknown_code' => InviteRedeemResult.unknownCode,
      'code_inactive' => InviteRedeemResult.codeInactive,
      'own_code' => InviteRedeemResult.ownCode,
      'already_referred' => InviteRedeemResult.alreadyReferred,
      'account_too_old' => InviteRedeemResult.accountTooOld,
      _ => throw FormatException('Unexpected redeem_invite_code result: $raw'),
    };
  }
}
