/// Snapshot returned by `get_my_invite_overview`.
///
/// [activatedCount] counts only referrals with status `activated`.
class InviteOverview {
  const InviteOverview({
    required this.code,
    required this.activatedCount,
  });

  /// Same alphabet as `referral_codes_code_shape_check` / `_referral_code()`.
  static final RegExp codePattern =
      RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$');

  final String code;
  final int activatedCount;

  factory InviteOverview.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    if (code == null || !codePattern.hasMatch(code)) {
      throw FormatException('InviteOverview invalid code: $json');
    }

    final activatedCount = _parseActivatedCount(json['activated_count'], json);
    return InviteOverview(code: code, activatedCount: activatedCount);
  }

  static int _parseActivatedCount(Object? raw, Map<String, dynamic> json) {
    final int value;
    switch (raw) {
      case final int n:
        value = n;
      case final num n when n % 1 == 0:
        value = n.toInt();
      default:
        throw FormatException(
          'InviteOverview missing or non-integer activated_count: $json',
        );
    }
    if (value < 0) {
      throw FormatException('InviteOverview negative activated_count: $json');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InviteOverview &&
          code == other.code &&
          activatedCount == other.activatedCount;

  @override
  int get hashCode => Object.hash(code, activatedCount);
}
