import 'package:equatable/equatable.dart';

import '../../../../l10n/app_localizations.dart';

enum ChannelType { direct, community, applicationReview }

enum MemberRole { member, moderator }

class ChatChannel extends Equatable {
  const ChatChannel({
    required this.id,
    required this.type,
    this.packageId,
    required this.createdAt,
    required this.currentUserRole,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final ChannelType type;
  final String? packageId; // non-null for community channels
  final DateTime createdAt;
  final MemberRole currentUserRole;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get isModerator => currentUserRole == MemberRole.moderator;

  String channelDisplayName(AppLocalizations l10n, {String? packageName}) {
    return switch (type) {
      ChannelType.direct => l10n.trainerFallbackName,
      ChannelType.community =>
        packageName ?? packageId ?? l10n.chatChannelTypeCommunity,
      ChannelType.applicationReview => l10n.chatChannelTypeApplicationReview,
    };
  }

  factory ChatChannel.fromJson(
    Map<String, dynamic> json, {
    required MemberRole currentUserRole,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int unreadCount = 0,
  }) {
    return ChatChannel(
      id: json['id'] as String,
      type: switch (json['type']) {
        'direct' => ChannelType.direct,
        'application_review' => ChannelType.applicationReview,
        _ => ChannelType.community,
      },
      packageId: json['package_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentUserRole: currentUserRole,
      lastMessageContent: lastMessageContent,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, packageId, createdAt, currentUserRole, unreadCount];
}
