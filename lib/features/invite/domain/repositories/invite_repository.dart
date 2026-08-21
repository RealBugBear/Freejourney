import '../models/invite_overview.dart';
import '../models/invite_redeem_result.dart';

abstract class InviteRepository {
  /// Creates the caller's code on first use and returns overview counts.
  Future<InviteOverview> getMyInviteOverview();

  /// Redeems an invite code after explicit user confirmation.
  Future<InviteRedeemResult> redeemInviteCode(String code);

  /// Counts a share-button press (not a completed OS share).
  Future<void> logShareActionTapped();

  /// Counts a landing-page view for a form-valid, active code.
  Future<void> logLandingView(String code);
}
