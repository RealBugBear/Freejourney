enum TrainerProfileStatus { pending, active, suspended }

class TrainerProfile {
  const TrainerProfile({
    required this.id,
    required this.displayName,
    this.bio,
    this.photoUrl,
    this.distanceKm,
    this.publicLatitude,
    this.publicLongitude,
    required this.verified,
    required this.status,
    required this.submittedAt,
    this.contactEmail,
    this.contactPhone,
    this.adminNotes,
    this.hasLocation = false,
  });

  final String id;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final double? distanceKm;
  final double? publicLatitude;
  final double? publicLongitude;
  final bool verified;
  final TrainerProfileStatus status;
  final DateTime submittedAt;
  final String? contactEmail;
  final String? contactPhone;
  final String? adminNotes;
  final bool hasLocation;

  static TrainerProfileStatus _parseStatus(String? s) {
    switch (s) {
      case 'active':
        return TrainerProfileStatus.active;
      case 'suspended':
        return TrainerProfileStatus.suspended;
      default:
        return TrainerProfileStatus.pending;
    }
  }

  factory TrainerProfile.fromJson(Map<String, dynamic> json) {
    final submittedAtRaw = json['submitted_at'] as String?;

    return TrainerProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      publicLatitude: (json['public_latitude'] as num?)?.toDouble(),
      publicLongitude: (json['public_longitude'] as num?)?.toDouble(),
      verified: json['verified'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      submittedAt: submittedAtRaw != null
          ? DateTime.parse(submittedAtRaw)
          : DateTime.fromMillisecondsSinceEpoch(0),
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      adminNotes: json['admin_notes'] as String?,
      hasLocation: json['has_location'] as bool? ?? false,
    );
  }
}
