class Profile {
  final String userId;
  final String? displayName;
  final bool isAnonymousDefault;

  const Profile({
    required this.userId,
    this.displayName,
    this.isAnonymousDefault = false,
  });

  /// Returns the display name, or the caller-provided localized fallback.
  String effectiveDisplayName(String anonymousLabel) =>
      displayName ?? anonymousLabel;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: json['id'] as String,
        displayName: json['display_name'] as String?,
        isAnonymousDefault: (json['is_anonymous_default'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': userId,
        'display_name': displayName,
        'is_anonymous_default': isAnonymousDefault,
      };

  Profile copyWith({String? displayName, bool? isAnonymousDefault}) => Profile(
        userId: userId,
        displayName: displayName ?? this.displayName,
        isAnonymousDefault: isAnonymousDefault ?? this.isAnonymousDefault,
      );
}
