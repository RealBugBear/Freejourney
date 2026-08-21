/// Adult safety notice metadata (expert draft v0, Phase 6).
///
/// User-visible copy lives only in `app_de.arb` / `app_en.arb`
/// (`reflexProfileAdultSafetyNoticeBody` /
/// `reflexProfileAdultSafetyNoticeMovementAppendix`). This class holds the
/// wire/version constants used when recording `warning_confirmations`.
abstract final class AdultSafetyNotice {
  /// Draft stand of the expert document. After acceptance → `_v1` so older
  /// confirmations are not treated as assent to the final wording.
  static const messageVersion = 'adult_safety_expertdraft_v0';

  /// Content is expert-draft, not founder-accepted.
  static const contentApprovalStatus = 'expertPending';
}
