import '../../../config/launch_flags.dart';

/// Adult safety notice copy helpers (expert draft v0, Phase 6).
///
/// The German body is the literal Textentwurf from
/// `Reflexprofil_Sicherheitspruefung_Experten.docx` §6. Marked
/// `expertPending` until the expert sign-off sheet is completed.
abstract final class AdultSafetyNotice {
  /// Draft stand of the expert document. After acceptance → `_v1` so older
  /// confirmations are not treated as assent to the final wording.
  static const messageVersion = 'adult_safety_expertdraft_v0';

  /// Content is expert-draft, not founder-accepted.
  static const contentApprovalStatus = 'expertPending';

  /// Closing sentence that assumes marked exercises exist — only when
  /// [kAdultMovementChecksEnabled] is true.
  static const movementAppendixDe =
      'Führe die gekennzeichneten Übungen nicht ohne die hier empfohlene '
      'Rücksprache durch.';

  static const movementAppendixEn =
      'Do not perform the marked exercises without the consultation '
      'recommended here.';

  /// Body without the movement appendix (DE expert draft, EN faithful).
  static const bodyCoreDe =
      'Deine Angabe kann bedeuten, dass einzelne Bewegungen oder '
      'Trainingsübungen angepasst oder vorher fachlich besprochen werden '
      'sollten. Dieses Ergebnis bewertet deine Diagnose nicht.';

  static const bodyCoreEn =
      'Your answer may mean that individual movements or training exercises '
      'should be adapted or discussed with a professional first. This result '
      'does not evaluate your diagnosis.';

  /// Full notice body for the given locale and movement flag.
  static String body({
    required String languageCode,
    bool movementChecksEnabled = kAdultMovementChecksEnabled,
  }) {
    final isDe = languageCode.toLowerCase().startsWith('de');
    final core = isDe ? bodyCoreDe : bodyCoreEn;
    if (!movementChecksEnabled) return core;
    final appendix = isDe ? movementAppendixDe : movementAppendixEn;
    return '$core $appendix';
  }
}
