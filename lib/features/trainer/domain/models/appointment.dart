class Appointment {
  final String id;
  final String trainerId;
  final String traineeId;
  final String traineeName;
  final String title;
  final DateTime? scheduledFor; // null when status == 'proposed'
  final List<DateTime> proposedSlots; // non-empty when status == 'proposed'
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String status; // proposed | planned | confirmed | cancelled | done
  final String? trigger;
  final int? traineeDayNumber;
  final String? calendarEventId;
  final String? calendarId;
  final DateTime createdAt;
  // Subject profiles this appointment targets; empty = whole-account (legacy).
  final List<String> subjectProfileIds;
  final List<String> subjectProfileNames;

  const Appointment({
    required this.id,
    required this.trainerId,
    required this.traineeId,
    required this.traineeName,
    required this.title,
    this.scheduledFor,
    this.proposedSlots = const [],
    required this.durationMinutes,
    this.location,
    this.notes,
    required this.status,
    this.trigger,
    this.traineeDayNumber,
    this.calendarEventId,
    this.calendarId,
    required this.createdAt,
    this.subjectProfileIds = const [],
    this.subjectProfileNames = const [],
  });

  bool get isProposed => status == 'proposed';

  /// Display label for the targeted profile(s), or null if account-wide.
  String? get profileLabel {
    if (subjectProfileNames.isEmpty) return null;
    return subjectProfileNames.join(' + ');
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['proposed_slots'];
    final proposedSlots = rawSlots is List
        ? rawSlots.whereType<String>().map(_parseLocalDateTime).toList()
        : <DateTime>[];

    final scheduledRaw = json['scheduled_for'] as String?;

    final rawProfileIds = json['subject_profile_ids'];
    final subjectProfileIds = rawProfileIds is List
        ? rawProfileIds.whereType<String>().toList()
        : <String>[];

    final rawProfileNames = json['subject_profile_names'];
    final subjectProfileNames = rawProfileNames is List
        ? rawProfileNames.whereType<String>().toList()
        : <String>[];

    return Appointment(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      traineeId: json['trainee_id'] as String,
      traineeName: json['trainee_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledFor:
          scheduledRaw != null ? _parseLocalDateTime(scheduledRaw) : null,
      proposedSlots: proposedSlots,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'planned',
      trigger: json['trigger'] as String?,
      traineeDayNumber: (json['trainee_day_number'] as num?)?.toInt(),
      calendarEventId: json['calendar_event_id'] as String?,
      calendarId: json['calendar_id'] as String?,
      createdAt: _parseLocalDateTime(json['created_at'] as String),
      subjectProfileIds: subjectProfileIds,
      subjectProfileNames: subjectProfileNames,
    );
  }

  static DateTime _parseLocalDateTime(String value) {
    return DateTime.parse(value).toLocal();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'trainee_id': traineeId,
        'title': title,
        if (scheduledFor != null)
          'scheduled_for': scheduledFor!.toUtc().toIso8601String(),
        if (proposedSlots.isNotEmpty)
          'proposed_slots':
              proposedSlots.map((d) => d.toUtc().toIso8601String()).toList(),
        'duration_minutes': durationMinutes,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
        'status': status,
        if (trigger != null) 'trigger': trigger,
        if (traineeDayNumber != null) 'trainee_day_number': traineeDayNumber,
        if (calendarEventId != null) 'calendar_event_id': calendarEventId,
        if (calendarId != null) 'calendar_id': calendarId,
      };

  Appointment copyWith({
    String? status,
    DateTime? scheduledFor,
    String? calendarEventId,
    String? calendarId,
    List<String>? subjectProfileIds,
    List<String>? subjectProfileNames,
  }) {
    return Appointment(
      id: id,
      trainerId: trainerId,
      traineeId: traineeId,
      traineeName: traineeName,
      title: title,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      proposedSlots: proposedSlots,
      durationMinutes: durationMinutes,
      location: location,
      notes: notes,
      status: status ?? this.status,
      trigger: trigger,
      traineeDayNumber: traineeDayNumber,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      calendarId: calendarId ?? this.calendarId,
      createdAt: createdAt,
      subjectProfileIds: subjectProfileIds ?? this.subjectProfileIds,
      subjectProfileNames: subjectProfileNames ?? this.subjectProfileNames,
    );
  }
}
