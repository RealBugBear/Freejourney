import '../../../../l10n/app_localizations.dart';

enum TrainerApplicationStatus {
  submitted,
  inReview,
  needsMoreInfo,
  approved,
  rejected,
  withdrawn,
}

class TrainerApplication {
  const TrainerApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.city,
    required this.professionalBackground,
    this.motivation,
    this.desiredDisplayName,
    this.desiredBio,
    required this.status,
    required this.backgroundCheckRequired,
    this.backgroundCheckVerifiedAt,
    this.backgroundCheckVerifiedBy,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.adminNotes,
    this.activationCodeId,
    this.activationCode,
    this.activationCodeExpiresAt,
    this.reviewChannelId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? city;
  final String professionalBackground;
  final String? motivation;
  final String? desiredDisplayName;
  final String? desiredBio;
  final TrainerApplicationStatus status;
  final bool backgroundCheckRequired;
  final DateTime? backgroundCheckVerifiedAt;
  final String? backgroundCheckVerifiedBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? adminNotes;
  final String? activationCodeId;
  final String? activationCode;
  final DateTime? activationCodeExpiresAt;
  final String? reviewChannelId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasBackgroundCheck => backgroundCheckVerifiedAt != null;
  bool get isOpen =>
      status == TrainerApplicationStatus.submitted ||
      status == TrainerApplicationStatus.inReview ||
      status == TrainerApplicationStatus.needsMoreInfo;
  bool get canApprove =>
      isOpen && (!backgroundCheckRequired || hasBackgroundCheck);

  String statusLabel(AppLocalizations l10n) {
    return switch (status) {
      TrainerApplicationStatus.submitted => l10n.trainerAppStatusSubmitted,
      TrainerApplicationStatus.inReview => l10n.trainerAppStatusInReview,
      TrainerApplicationStatus.needsMoreInfo => l10n.trainerAppStatusNeedsInfo,
      TrainerApplicationStatus.approved => l10n.trainerAppStatusApproved,
      TrainerApplicationStatus.rejected => l10n.trainerAppStatusRejected,
      TrainerApplicationStatus.withdrawn => l10n.trainerAppStatusWithdrawn,
    };
  }

  static TrainerApplicationStatus parseStatus(String? value) {
    return switch (value) {
      'in_review' => TrainerApplicationStatus.inReview,
      'needs_more_info' => TrainerApplicationStatus.needsMoreInfo,
      'approved' => TrainerApplicationStatus.approved,
      'rejected' => TrainerApplicationStatus.rejected,
      'withdrawn' => TrainerApplicationStatus.withdrawn,
      _ => TrainerApplicationStatus.submitted,
    };
  }

  static DateTime? _date(String? value) =>
      value == null ? null : DateTime.parse(value);

  factory TrainerApplication.fromJson(Map<String, dynamic> json) {
    return TrainerApplication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      professionalBackground: json['professional_background'] as String? ?? '',
      motivation: json['motivation'] as String?,
      desiredDisplayName: json['desired_display_name'] as String?,
      desiredBio: json['desired_bio'] as String?,
      status: parseStatus(json['status'] as String?),
      backgroundCheckRequired:
          json['background_check_required'] as bool? ?? true,
      backgroundCheckVerifiedAt:
          _date(json['background_check_verified_at'] as String?),
      backgroundCheckVerifiedBy:
          json['background_check_verified_by'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: _date(json['reviewed_at'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      activationCodeId: json['activation_code_id'] as String?,
      activationCode: json['activation_code'] as String?,
      activationCodeExpiresAt:
          _date(json['activation_code_expires_at'] as String?),
      reviewChannelId: json['review_channel_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
