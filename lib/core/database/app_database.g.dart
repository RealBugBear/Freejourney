// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EnrollmentsTableTable extends EnrollmentsTable
    with TableInfo<$EnrollmentsTableTable, EnrollmentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnrollmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _packageIdMeta =
      const VerificationMeta('packageId');
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
      'package_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _assignedDurationWeeksMeta =
      const VerificationMeta('assignedDurationWeeks');
  @override
  late final GeneratedColumn<int> assignedDurationWeeks = GeneratedColumn<int>(
      'assigned_duration_weeks', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _targetCompletionDateMeta =
      const VerificationMeta('targetCompletionDate');
  @override
  late final GeneratedColumn<DateTime> targetCompletionDate =
      GeneratedColumn<DateTime>('target_completion_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pausedAtMeta =
      const VerificationMeta('pausedAt');
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
      'paused_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _precedingEnrollmentIdMeta =
      const VerificationMeta('precedingEnrollmentId');
  @override
  late final GeneratedColumn<String> precedingEnrollmentId =
      GeneratedColumn<String>('preceding_enrollment_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        subjectProfileId,
        packageId,
        status,
        assignedDurationWeeks,
        startDate,
        targetCompletionDate,
        completedAt,
        pausedAt,
        precedingEnrollmentId,
        needsSync,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enrollments';
  @override
  VerificationContext validateIntegrity(
      Insertable<EnrollmentsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    }
    if (data.containsKey('package_id')) {
      context.handle(_packageIdMeta,
          packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta));
    } else if (isInserting) {
      context.missing(_packageIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('assigned_duration_weeks')) {
      context.handle(
          _assignedDurationWeeksMeta,
          assignedDurationWeeks.isAcceptableOrUnknown(
              data['assigned_duration_weeks']!, _assignedDurationWeeksMeta));
    } else if (isInserting) {
      context.missing(_assignedDurationWeeksMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('target_completion_date')) {
      context.handle(
          _targetCompletionDateMeta,
          targetCompletionDate.isAcceptableOrUnknown(
              data['target_completion_date']!, _targetCompletionDateMeta));
    } else if (isInserting) {
      context.missing(_targetCompletionDateMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('paused_at')) {
      context.handle(_pausedAtMeta,
          pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta));
    }
    if (data.containsKey('preceding_enrollment_id')) {
      context.handle(
          _precedingEnrollmentIdMeta,
          precedingEnrollmentId.isAcceptableOrUnknown(
              data['preceding_enrollment_id']!, _precedingEnrollmentIdMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnrollmentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrollmentsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id']),
      packageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      assignedDurationWeeks: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}assigned_duration_weeks'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      targetCompletionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}target_completion_date'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      pausedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paused_at']),
      precedingEnrollmentId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}preceding_enrollment_id']),
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EnrollmentsTableTable createAlias(String alias) {
    return $EnrollmentsTableTable(attachedDatabase, alias);
  }
}

class EnrollmentsTableData extends DataClass
    implements Insertable<EnrollmentsTableData> {
  final String id;
  final String userId;
  final String? subjectProfileId;
  final String packageId;
  final String status;
  final int assignedDurationWeeks;
  final DateTime startDate;
  final DateTime targetCompletionDate;
  final DateTime? completedAt;
  final DateTime? pausedAt;
  final String? precedingEnrollmentId;
  final bool needsSync;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EnrollmentsTableData(
      {required this.id,
      required this.userId,
      this.subjectProfileId,
      required this.packageId,
      required this.status,
      required this.assignedDurationWeeks,
      required this.startDate,
      required this.targetCompletionDate,
      this.completedAt,
      this.pausedAt,
      this.precedingEnrollmentId,
      required this.needsSync,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || subjectProfileId != null) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId);
    }
    map['package_id'] = Variable<String>(packageId);
    map['status'] = Variable<String>(status);
    map['assigned_duration_weeks'] = Variable<int>(assignedDurationWeeks);
    map['start_date'] = Variable<DateTime>(startDate);
    map['target_completion_date'] = Variable<DateTime>(targetCompletionDate);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    if (!nullToAbsent || precedingEnrollmentId != null) {
      map['preceding_enrollment_id'] = Variable<String>(precedingEnrollmentId);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EnrollmentsTableCompanion toCompanion(bool nullToAbsent) {
    return EnrollmentsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      subjectProfileId: subjectProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectProfileId),
      packageId: Value(packageId),
      status: Value(status),
      assignedDurationWeeks: Value(assignedDurationWeeks),
      startDate: Value(startDate),
      targetCompletionDate: Value(targetCompletionDate),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      precedingEnrollmentId: precedingEnrollmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(precedingEnrollmentId),
      needsSync: Value(needsSync),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EnrollmentsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrollmentsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      subjectProfileId: serializer.fromJson<String?>(json['subjectProfileId']),
      packageId: serializer.fromJson<String>(json['packageId']),
      status: serializer.fromJson<String>(json['status']),
      assignedDurationWeeks:
          serializer.fromJson<int>(json['assignedDurationWeeks']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      targetCompletionDate:
          serializer.fromJson<DateTime>(json['targetCompletionDate']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      precedingEnrollmentId:
          serializer.fromJson<String?>(json['precedingEnrollmentId']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'subjectProfileId': serializer.toJson<String?>(subjectProfileId),
      'packageId': serializer.toJson<String>(packageId),
      'status': serializer.toJson<String>(status),
      'assignedDurationWeeks': serializer.toJson<int>(assignedDurationWeeks),
      'startDate': serializer.toJson<DateTime>(startDate),
      'targetCompletionDate': serializer.toJson<DateTime>(targetCompletionDate),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'precedingEnrollmentId':
          serializer.toJson<String?>(precedingEnrollmentId),
      'needsSync': serializer.toJson<bool>(needsSync),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EnrollmentsTableData copyWith(
          {String? id,
          String? userId,
          Value<String?> subjectProfileId = const Value.absent(),
          String? packageId,
          String? status,
          int? assignedDurationWeeks,
          DateTime? startDate,
          DateTime? targetCompletionDate,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<DateTime?> pausedAt = const Value.absent(),
          Value<String?> precedingEnrollmentId = const Value.absent(),
          bool? needsSync,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      EnrollmentsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        subjectProfileId: subjectProfileId.present
            ? subjectProfileId.value
            : this.subjectProfileId,
        packageId: packageId ?? this.packageId,
        status: status ?? this.status,
        assignedDurationWeeks:
            assignedDurationWeeks ?? this.assignedDurationWeeks,
        startDate: startDate ?? this.startDate,
        targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
        precedingEnrollmentId: precedingEnrollmentId.present
            ? precedingEnrollmentId.value
            : this.precedingEnrollmentId,
        needsSync: needsSync ?? this.needsSync,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EnrollmentsTableData copyWithCompanion(EnrollmentsTableCompanion data) {
    return EnrollmentsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      status: data.status.present ? data.status.value : this.status,
      assignedDurationWeeks: data.assignedDurationWeeks.present
          ? data.assignedDurationWeeks.value
          : this.assignedDurationWeeks,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      targetCompletionDate: data.targetCompletionDate.present
          ? data.targetCompletionDate.value
          : this.targetCompletionDate,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      precedingEnrollmentId: data.precedingEnrollmentId.present
          ? data.precedingEnrollmentId.value
          : this.precedingEnrollmentId,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('packageId: $packageId, ')
          ..write('status: $status, ')
          ..write('assignedDurationWeeks: $assignedDurationWeeks, ')
          ..write('startDate: $startDate, ')
          ..write('targetCompletionDate: $targetCompletionDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('precedingEnrollmentId: $precedingEnrollmentId, ')
          ..write('needsSync: $needsSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      subjectProfileId,
      packageId,
      status,
      assignedDurationWeeks,
      startDate,
      targetCompletionDate,
      completedAt,
      pausedAt,
      precedingEnrollmentId,
      needsSync,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrollmentsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.subjectProfileId == this.subjectProfileId &&
          other.packageId == this.packageId &&
          other.status == this.status &&
          other.assignedDurationWeeks == this.assignedDurationWeeks &&
          other.startDate == this.startDate &&
          other.targetCompletionDate == this.targetCompletionDate &&
          other.completedAt == this.completedAt &&
          other.pausedAt == this.pausedAt &&
          other.precedingEnrollmentId == this.precedingEnrollmentId &&
          other.needsSync == this.needsSync &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EnrollmentsTableCompanion extends UpdateCompanion<EnrollmentsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> subjectProfileId;
  final Value<String> packageId;
  final Value<String> status;
  final Value<int> assignedDurationWeeks;
  final Value<DateTime> startDate;
  final Value<DateTime> targetCompletionDate;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> pausedAt;
  final Value<String?> precedingEnrollmentId;
  final Value<bool> needsSync;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EnrollmentsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.packageId = const Value.absent(),
    this.status = const Value.absent(),
    this.assignedDurationWeeks = const Value.absent(),
    this.startDate = const Value.absent(),
    this.targetCompletionDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.precedingEnrollmentId = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnrollmentsTableCompanion.insert({
    required String id,
    required String userId,
    this.subjectProfileId = const Value.absent(),
    required String packageId,
    this.status = const Value.absent(),
    required int assignedDurationWeeks,
    required DateTime startDate,
    required DateTime targetCompletionDate,
    this.completedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.precedingEnrollmentId = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        packageId = Value(packageId),
        assignedDurationWeeks = Value(assignedDurationWeeks),
        startDate = Value(startDate),
        targetCompletionDate = Value(targetCompletionDate);
  static Insertable<EnrollmentsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? subjectProfileId,
    Expression<String>? packageId,
    Expression<String>? status,
    Expression<int>? assignedDurationWeeks,
    Expression<DateTime>? startDate,
    Expression<DateTime>? targetCompletionDate,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? pausedAt,
    Expression<String>? precedingEnrollmentId,
    Expression<bool>? needsSync,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (packageId != null) 'package_id': packageId,
      if (status != null) 'status': status,
      if (assignedDurationWeeks != null)
        'assigned_duration_weeks': assignedDurationWeeks,
      if (startDate != null) 'start_date': startDate,
      if (targetCompletionDate != null)
        'target_completion_date': targetCompletionDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (precedingEnrollmentId != null)
        'preceding_enrollment_id': precedingEnrollmentId,
      if (needsSync != null) 'needs_sync': needsSync,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnrollmentsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? subjectProfileId,
      Value<String>? packageId,
      Value<String>? status,
      Value<int>? assignedDurationWeeks,
      Value<DateTime>? startDate,
      Value<DateTime>? targetCompletionDate,
      Value<DateTime?>? completedAt,
      Value<DateTime?>? pausedAt,
      Value<String?>? precedingEnrollmentId,
      Value<bool>? needsSync,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return EnrollmentsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      packageId: packageId ?? this.packageId,
      status: status ?? this.status,
      assignedDurationWeeks:
          assignedDurationWeeks ?? this.assignedDurationWeeks,
      startDate: startDate ?? this.startDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      precedingEnrollmentId:
          precedingEnrollmentId ?? this.precedingEnrollmentId,
      needsSync: needsSync ?? this.needsSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (assignedDurationWeeks.present) {
      map['assigned_duration_weeks'] =
          Variable<int>(assignedDurationWeeks.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (targetCompletionDate.present) {
      map['target_completion_date'] =
          Variable<DateTime>(targetCompletionDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (precedingEnrollmentId.present) {
      map['preceding_enrollment_id'] =
          Variable<String>(precedingEnrollmentId.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('packageId: $packageId, ')
          ..write('status: $status, ')
          ..write('assignedDurationWeeks: $assignedDurationWeeks, ')
          ..write('startDate: $startDate, ')
          ..write('targetCompletionDate: $targetCompletionDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('precedingEnrollmentId: $precedingEnrollmentId, ')
          ..write('needsSync: $needsSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTableTable extends ExercisesTable
    with TableInfo<$ExercisesTableTable, ExercisesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _packageIdMeta =
      const VerificationMeta('packageId');
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
      'package_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sequenceNumberMeta =
      const VerificationMeta('sequenceNumber');
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
      'sequence_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleDeMeta =
      const VerificationMeta('titleDe');
  @override
  late final GeneratedColumn<String> titleDe = GeneratedColumn<String>(
      'title_de', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleEnMeta =
      const VerificationMeta('titleEn');
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
      'title_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionInstructionsDeMeta =
      const VerificationMeta('positionInstructionsDe');
  @override
  late final GeneratedColumn<String> positionInstructionsDe =
      GeneratedColumn<String>('position_instructions_de', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionInstructionsEnMeta =
      const VerificationMeta('positionInstructionsEn');
  @override
  late final GeneratedColumn<String> positionInstructionsEn =
      GeneratedColumn<String>('position_instructions_en', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _movementInstructionsDeMeta =
      const VerificationMeta('movementInstructionsDe');
  @override
  late final GeneratedColumn<String> movementInstructionsDe =
      GeneratedColumn<String>('movement_instructions_de', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _movementInstructionsEnMeta =
      const VerificationMeta('movementInstructionsEn');
  @override
  late final GeneratedColumn<String> movementInstructionsEn =
      GeneratedColumn<String>('movement_instructions_en', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hintsDeMeta =
      const VerificationMeta('hintsDe');
  @override
  late final GeneratedColumn<String> hintsDe = GeneratedColumn<String>(
      'hints_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hintsEnMeta =
      const VerificationMeta('hintsEn');
  @override
  late final GeneratedColumn<String> hintsEn = GeneratedColumn<String>(
      'hints_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _executionGuideDeMeta =
      const VerificationMeta('executionGuideDe');
  @override
  late final GeneratedColumn<String> executionGuideDe = GeneratedColumn<String>(
      'execution_guide_de', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _executionGuideEnMeta =
      const VerificationMeta('executionGuideEn');
  @override
  late final GeneratedColumn<String> executionGuideEn = GeneratedColumn<String>(
      'execution_guide_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repetitionsMeta =
      const VerificationMeta('repetitions');
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
      'repetitions', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _duoImagePathMeta =
      const VerificationMeta('duoImagePath');
  @override
  late final GeneratedColumn<String> duoImagePath = GeneratedColumn<String>(
      'duo_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _videoPathMeta =
      const VerificationMeta('videoPath');
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
      'video_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioCuePathMeta =
      const VerificationMeta('audioCuePath');
  @override
  late final GeneratedColumn<String> audioCuePath = GeneratedColumn<String>(
      'audio_cue_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _duoImageUrlMeta =
      const VerificationMeta('duoImageUrl');
  @override
  late final GeneratedColumn<String> duoImageUrl = GeneratedColumn<String>(
      'duo_image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _videoUrlMeta =
      const VerificationMeta('videoUrl');
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
      'video_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rhythmTypeMeta =
      const VerificationMeta('rhythmType');
  @override
  late final GeneratedColumn<String> rhythmType = GeneratedColumn<String>(
      'rhythm_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('holdRest'));
  static const VerificationMeta _phasesJsonMeta =
      const VerificationMeta('phasesJson');
  @override
  late final GeneratedColumn<String> phasesJson = GeneratedColumn<String>(
      'phases_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _hasRepSwitchMeta =
      const VerificationMeta('hasRepSwitch');
  @override
  late final GeneratedColumn<bool> hasRepSwitch = GeneratedColumn<bool>(
      'has_rep_switch', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_rep_switch" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _holdCueDeMeta =
      const VerificationMeta('holdCueDe');
  @override
  late final GeneratedColumn<String> holdCueDe = GeneratedColumn<String>(
      'hold_cue_de', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Halten'));
  static const VerificationMeta _holdCueEnMeta =
      const VerificationMeta('holdCueEn');
  @override
  late final GeneratedColumn<String> holdCueEn = GeneratedColumn<String>(
      'hold_cue_en', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Hold'));
  static const VerificationMeta _holdSecondsMeta =
      const VerificationMeta('holdSeconds');
  @override
  late final GeneratedColumn<int> holdSeconds = GeneratedColumn<int>(
      'hold_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(7));
  static const VerificationMeta _restSecondsMeta =
      const VerificationMeta('restSeconds');
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
      'rest_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _halfwaySwitchMeta =
      const VerificationMeta('halfwaySwitch');
  @override
  late final GeneratedColumn<bool> halfwaySwitch = GeneratedColumn<bool>(
      'halfway_switch', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("halfway_switch" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        packageId,
        sequenceNumber,
        titleDe,
        titleEn,
        positionInstructionsDe,
        positionInstructionsEn,
        movementInstructionsDe,
        movementInstructionsEn,
        hintsDe,
        hintsEn,
        executionGuideDe,
        executionGuideEn,
        durationSeconds,
        repetitions,
        imagePath,
        duoImagePath,
        videoPath,
        audioCuePath,
        imageUrl,
        duoImageUrl,
        videoUrl,
        rhythmType,
        phasesJson,
        hasRepSwitch,
        holdCueDe,
        holdCueEn,
        holdSeconds,
        restSeconds,
        halfwaySwitch
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<ExercisesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_id')) {
      context.handle(_packageIdMeta,
          packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta));
    } else if (isInserting) {
      context.missing(_packageIdMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
          _sequenceNumberMeta,
          sequenceNumber.isAcceptableOrUnknown(
              data['sequence_number']!, _sequenceNumberMeta));
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('title_de')) {
      context.handle(_titleDeMeta,
          titleDe.isAcceptableOrUnknown(data['title_de']!, _titleDeMeta));
    } else if (isInserting) {
      context.missing(_titleDeMeta);
    }
    if (data.containsKey('title_en')) {
      context.handle(_titleEnMeta,
          titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta));
    } else if (isInserting) {
      context.missing(_titleEnMeta);
    }
    if (data.containsKey('position_instructions_de')) {
      context.handle(
          _positionInstructionsDeMeta,
          positionInstructionsDe.isAcceptableOrUnknown(
              data['position_instructions_de']!, _positionInstructionsDeMeta));
    } else if (isInserting) {
      context.missing(_positionInstructionsDeMeta);
    }
    if (data.containsKey('position_instructions_en')) {
      context.handle(
          _positionInstructionsEnMeta,
          positionInstructionsEn.isAcceptableOrUnknown(
              data['position_instructions_en']!, _positionInstructionsEnMeta));
    } else if (isInserting) {
      context.missing(_positionInstructionsEnMeta);
    }
    if (data.containsKey('movement_instructions_de')) {
      context.handle(
          _movementInstructionsDeMeta,
          movementInstructionsDe.isAcceptableOrUnknown(
              data['movement_instructions_de']!, _movementInstructionsDeMeta));
    } else if (isInserting) {
      context.missing(_movementInstructionsDeMeta);
    }
    if (data.containsKey('movement_instructions_en')) {
      context.handle(
          _movementInstructionsEnMeta,
          movementInstructionsEn.isAcceptableOrUnknown(
              data['movement_instructions_en']!, _movementInstructionsEnMeta));
    } else if (isInserting) {
      context.missing(_movementInstructionsEnMeta);
    }
    if (data.containsKey('hints_de')) {
      context.handle(_hintsDeMeta,
          hintsDe.isAcceptableOrUnknown(data['hints_de']!, _hintsDeMeta));
    }
    if (data.containsKey('hints_en')) {
      context.handle(_hintsEnMeta,
          hintsEn.isAcceptableOrUnknown(data['hints_en']!, _hintsEnMeta));
    }
    if (data.containsKey('execution_guide_de')) {
      context.handle(
          _executionGuideDeMeta,
          executionGuideDe.isAcceptableOrUnknown(
              data['execution_guide_de']!, _executionGuideDeMeta));
    } else if (isInserting) {
      context.missing(_executionGuideDeMeta);
    }
    if (data.containsKey('execution_guide_en')) {
      context.handle(
          _executionGuideEnMeta,
          executionGuideEn.isAcceptableOrUnknown(
              data['execution_guide_en']!, _executionGuideEnMeta));
    } else if (isInserting) {
      context.missing(_executionGuideEnMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('repetitions')) {
      context.handle(
          _repetitionsMeta,
          repetitions.isAcceptableOrUnknown(
              data['repetitions']!, _repetitionsMeta));
    } else if (isInserting) {
      context.missing(_repetitionsMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('duo_image_path')) {
      context.handle(
          _duoImagePathMeta,
          duoImagePath.isAcceptableOrUnknown(
              data['duo_image_path']!, _duoImagePathMeta));
    }
    if (data.containsKey('video_path')) {
      context.handle(_videoPathMeta,
          videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta));
    }
    if (data.containsKey('audio_cue_path')) {
      context.handle(
          _audioCuePathMeta,
          audioCuePath.isAcceptableOrUnknown(
              data['audio_cue_path']!, _audioCuePathMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('duo_image_url')) {
      context.handle(
          _duoImageUrlMeta,
          duoImageUrl.isAcceptableOrUnknown(
              data['duo_image_url']!, _duoImageUrlMeta));
    }
    if (data.containsKey('video_url')) {
      context.handle(_videoUrlMeta,
          videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta));
    }
    if (data.containsKey('rhythm_type')) {
      context.handle(
          _rhythmTypeMeta,
          rhythmType.isAcceptableOrUnknown(
              data['rhythm_type']!, _rhythmTypeMeta));
    }
    if (data.containsKey('phases_json')) {
      context.handle(
          _phasesJsonMeta,
          phasesJson.isAcceptableOrUnknown(
              data['phases_json']!, _phasesJsonMeta));
    }
    if (data.containsKey('has_rep_switch')) {
      context.handle(
          _hasRepSwitchMeta,
          hasRepSwitch.isAcceptableOrUnknown(
              data['has_rep_switch']!, _hasRepSwitchMeta));
    }
    if (data.containsKey('hold_cue_de')) {
      context.handle(
          _holdCueDeMeta,
          holdCueDe.isAcceptableOrUnknown(
              data['hold_cue_de']!, _holdCueDeMeta));
    }
    if (data.containsKey('hold_cue_en')) {
      context.handle(
          _holdCueEnMeta,
          holdCueEn.isAcceptableOrUnknown(
              data['hold_cue_en']!, _holdCueEnMeta));
    }
    if (data.containsKey('hold_seconds')) {
      context.handle(
          _holdSecondsMeta,
          holdSeconds.isAcceptableOrUnknown(
              data['hold_seconds']!, _holdSecondsMeta));
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
          _restSecondsMeta,
          restSeconds.isAcceptableOrUnknown(
              data['rest_seconds']!, _restSecondsMeta));
    }
    if (data.containsKey('halfway_switch')) {
      context.handle(
          _halfwaySwitchMeta,
          halfwaySwitch.isAcceptableOrUnknown(
              data['halfway_switch']!, _halfwaySwitchMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExercisesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExercisesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      packageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_id'])!,
      sequenceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence_number'])!,
      titleDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_de'])!,
      titleEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_en'])!,
      positionInstructionsDe: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}position_instructions_de'])!,
      positionInstructionsEn: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}position_instructions_en'])!,
      movementInstructionsDe: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}movement_instructions_de'])!,
      movementInstructionsEn: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}movement_instructions_en'])!,
      hintsDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hints_de']),
      hintsEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hints_en']),
      executionGuideDe: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}execution_guide_de'])!,
      executionGuideEn: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}execution_guide_en'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      repetitions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repetitions'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      duoImagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}duo_image_path']),
      videoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_path']),
      audioCuePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_cue_path']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      duoImageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}duo_image_url']),
      videoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_url']),
      rhythmType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rhythm_type'])!,
      phasesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phases_json'])!,
      hasRepSwitch: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_rep_switch'])!,
      holdCueDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hold_cue_de'])!,
      holdCueEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hold_cue_en'])!,
      holdSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hold_seconds'])!,
      restSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_seconds'])!,
      halfwaySwitch: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}halfway_switch'])!,
    );
  }

  @override
  $ExercisesTableTable createAlias(String alias) {
    return $ExercisesTableTable(attachedDatabase, alias);
  }
}

class ExercisesTableData extends DataClass
    implements Insertable<ExercisesTableData> {
  final String id;
  final String packageId;
  final int sequenceNumber;
  final String titleDe;
  final String titleEn;
  final String positionInstructionsDe;
  final String positionInstructionsEn;
  final String movementInstructionsDe;
  final String movementInstructionsEn;
  final String? hintsDe;
  final String? hintsEn;
  final String executionGuideDe;
  final String executionGuideEn;
  final int durationSeconds;
  final int repetitions;
  final String imagePath;
  final String? duoImagePath;
  final String? videoPath;
  final String? audioCuePath;
  final String? imageUrl;
  final String? duoImageUrl;
  final String? videoUrl;
  final String rhythmType;
  final String phasesJson;
  final bool hasRepSwitch;
  final String holdCueDe;
  final String holdCueEn;
  final int holdSeconds;
  final int restSeconds;
  final bool halfwaySwitch;
  const ExercisesTableData(
      {required this.id,
      required this.packageId,
      required this.sequenceNumber,
      required this.titleDe,
      required this.titleEn,
      required this.positionInstructionsDe,
      required this.positionInstructionsEn,
      required this.movementInstructionsDe,
      required this.movementInstructionsEn,
      this.hintsDe,
      this.hintsEn,
      required this.executionGuideDe,
      required this.executionGuideEn,
      required this.durationSeconds,
      required this.repetitions,
      required this.imagePath,
      this.duoImagePath,
      this.videoPath,
      this.audioCuePath,
      this.imageUrl,
      this.duoImageUrl,
      this.videoUrl,
      required this.rhythmType,
      required this.phasesJson,
      required this.hasRepSwitch,
      required this.holdCueDe,
      required this.holdCueEn,
      required this.holdSeconds,
      required this.restSeconds,
      required this.halfwaySwitch});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_id'] = Variable<String>(packageId);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['title_de'] = Variable<String>(titleDe);
    map['title_en'] = Variable<String>(titleEn);
    map['position_instructions_de'] = Variable<String>(positionInstructionsDe);
    map['position_instructions_en'] = Variable<String>(positionInstructionsEn);
    map['movement_instructions_de'] = Variable<String>(movementInstructionsDe);
    map['movement_instructions_en'] = Variable<String>(movementInstructionsEn);
    if (!nullToAbsent || hintsDe != null) {
      map['hints_de'] = Variable<String>(hintsDe);
    }
    if (!nullToAbsent || hintsEn != null) {
      map['hints_en'] = Variable<String>(hintsEn);
    }
    map['execution_guide_de'] = Variable<String>(executionGuideDe);
    map['execution_guide_en'] = Variable<String>(executionGuideEn);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['repetitions'] = Variable<int>(repetitions);
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || duoImagePath != null) {
      map['duo_image_path'] = Variable<String>(duoImagePath);
    }
    if (!nullToAbsent || videoPath != null) {
      map['video_path'] = Variable<String>(videoPath);
    }
    if (!nullToAbsent || audioCuePath != null) {
      map['audio_cue_path'] = Variable<String>(audioCuePath);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || duoImageUrl != null) {
      map['duo_image_url'] = Variable<String>(duoImageUrl);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    map['rhythm_type'] = Variable<String>(rhythmType);
    map['phases_json'] = Variable<String>(phasesJson);
    map['has_rep_switch'] = Variable<bool>(hasRepSwitch);
    map['hold_cue_de'] = Variable<String>(holdCueDe);
    map['hold_cue_en'] = Variable<String>(holdCueEn);
    map['hold_seconds'] = Variable<int>(holdSeconds);
    map['rest_seconds'] = Variable<int>(restSeconds);
    map['halfway_switch'] = Variable<bool>(halfwaySwitch);
    return map;
  }

  ExercisesTableCompanion toCompanion(bool nullToAbsent) {
    return ExercisesTableCompanion(
      id: Value(id),
      packageId: Value(packageId),
      sequenceNumber: Value(sequenceNumber),
      titleDe: Value(titleDe),
      titleEn: Value(titleEn),
      positionInstructionsDe: Value(positionInstructionsDe),
      positionInstructionsEn: Value(positionInstructionsEn),
      movementInstructionsDe: Value(movementInstructionsDe),
      movementInstructionsEn: Value(movementInstructionsEn),
      hintsDe: hintsDe == null && nullToAbsent
          ? const Value.absent()
          : Value(hintsDe),
      hintsEn: hintsEn == null && nullToAbsent
          ? const Value.absent()
          : Value(hintsEn),
      executionGuideDe: Value(executionGuideDe),
      executionGuideEn: Value(executionGuideEn),
      durationSeconds: Value(durationSeconds),
      repetitions: Value(repetitions),
      imagePath: Value(imagePath),
      duoImagePath: duoImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(duoImagePath),
      videoPath: videoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoPath),
      audioCuePath: audioCuePath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioCuePath),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      duoImageUrl: duoImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(duoImageUrl),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      rhythmType: Value(rhythmType),
      phasesJson: Value(phasesJson),
      hasRepSwitch: Value(hasRepSwitch),
      holdCueDe: Value(holdCueDe),
      holdCueEn: Value(holdCueEn),
      holdSeconds: Value(holdSeconds),
      restSeconds: Value(restSeconds),
      halfwaySwitch: Value(halfwaySwitch),
    );
  }

  factory ExercisesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExercisesTableData(
      id: serializer.fromJson<String>(json['id']),
      packageId: serializer.fromJson<String>(json['packageId']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      titleDe: serializer.fromJson<String>(json['titleDe']),
      titleEn: serializer.fromJson<String>(json['titleEn']),
      positionInstructionsDe:
          serializer.fromJson<String>(json['positionInstructionsDe']),
      positionInstructionsEn:
          serializer.fromJson<String>(json['positionInstructionsEn']),
      movementInstructionsDe:
          serializer.fromJson<String>(json['movementInstructionsDe']),
      movementInstructionsEn:
          serializer.fromJson<String>(json['movementInstructionsEn']),
      hintsDe: serializer.fromJson<String?>(json['hintsDe']),
      hintsEn: serializer.fromJson<String?>(json['hintsEn']),
      executionGuideDe: serializer.fromJson<String>(json['executionGuideDe']),
      executionGuideEn: serializer.fromJson<String>(json['executionGuideEn']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      duoImagePath: serializer.fromJson<String?>(json['duoImagePath']),
      videoPath: serializer.fromJson<String?>(json['videoPath']),
      audioCuePath: serializer.fromJson<String?>(json['audioCuePath']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      duoImageUrl: serializer.fromJson<String?>(json['duoImageUrl']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      rhythmType: serializer.fromJson<String>(json['rhythmType']),
      phasesJson: serializer.fromJson<String>(json['phasesJson']),
      hasRepSwitch: serializer.fromJson<bool>(json['hasRepSwitch']),
      holdCueDe: serializer.fromJson<String>(json['holdCueDe']),
      holdCueEn: serializer.fromJson<String>(json['holdCueEn']),
      holdSeconds: serializer.fromJson<int>(json['holdSeconds']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      halfwaySwitch: serializer.fromJson<bool>(json['halfwaySwitch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageId': serializer.toJson<String>(packageId),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'titleDe': serializer.toJson<String>(titleDe),
      'titleEn': serializer.toJson<String>(titleEn),
      'positionInstructionsDe':
          serializer.toJson<String>(positionInstructionsDe),
      'positionInstructionsEn':
          serializer.toJson<String>(positionInstructionsEn),
      'movementInstructionsDe':
          serializer.toJson<String>(movementInstructionsDe),
      'movementInstructionsEn':
          serializer.toJson<String>(movementInstructionsEn),
      'hintsDe': serializer.toJson<String?>(hintsDe),
      'hintsEn': serializer.toJson<String?>(hintsEn),
      'executionGuideDe': serializer.toJson<String>(executionGuideDe),
      'executionGuideEn': serializer.toJson<String>(executionGuideEn),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'repetitions': serializer.toJson<int>(repetitions),
      'imagePath': serializer.toJson<String>(imagePath),
      'duoImagePath': serializer.toJson<String?>(duoImagePath),
      'videoPath': serializer.toJson<String?>(videoPath),
      'audioCuePath': serializer.toJson<String?>(audioCuePath),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'duoImageUrl': serializer.toJson<String?>(duoImageUrl),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'rhythmType': serializer.toJson<String>(rhythmType),
      'phasesJson': serializer.toJson<String>(phasesJson),
      'hasRepSwitch': serializer.toJson<bool>(hasRepSwitch),
      'holdCueDe': serializer.toJson<String>(holdCueDe),
      'holdCueEn': serializer.toJson<String>(holdCueEn),
      'holdSeconds': serializer.toJson<int>(holdSeconds),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'halfwaySwitch': serializer.toJson<bool>(halfwaySwitch),
    };
  }

  ExercisesTableData copyWith(
          {String? id,
          String? packageId,
          int? sequenceNumber,
          String? titleDe,
          String? titleEn,
          String? positionInstructionsDe,
          String? positionInstructionsEn,
          String? movementInstructionsDe,
          String? movementInstructionsEn,
          Value<String?> hintsDe = const Value.absent(),
          Value<String?> hintsEn = const Value.absent(),
          String? executionGuideDe,
          String? executionGuideEn,
          int? durationSeconds,
          int? repetitions,
          String? imagePath,
          Value<String?> duoImagePath = const Value.absent(),
          Value<String?> videoPath = const Value.absent(),
          Value<String?> audioCuePath = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          Value<String?> duoImageUrl = const Value.absent(),
          Value<String?> videoUrl = const Value.absent(),
          String? rhythmType,
          String? phasesJson,
          bool? hasRepSwitch,
          String? holdCueDe,
          String? holdCueEn,
          int? holdSeconds,
          int? restSeconds,
          bool? halfwaySwitch}) =>
      ExercisesTableData(
        id: id ?? this.id,
        packageId: packageId ?? this.packageId,
        sequenceNumber: sequenceNumber ?? this.sequenceNumber,
        titleDe: titleDe ?? this.titleDe,
        titleEn: titleEn ?? this.titleEn,
        positionInstructionsDe:
            positionInstructionsDe ?? this.positionInstructionsDe,
        positionInstructionsEn:
            positionInstructionsEn ?? this.positionInstructionsEn,
        movementInstructionsDe:
            movementInstructionsDe ?? this.movementInstructionsDe,
        movementInstructionsEn:
            movementInstructionsEn ?? this.movementInstructionsEn,
        hintsDe: hintsDe.present ? hintsDe.value : this.hintsDe,
        hintsEn: hintsEn.present ? hintsEn.value : this.hintsEn,
        executionGuideDe: executionGuideDe ?? this.executionGuideDe,
        executionGuideEn: executionGuideEn ?? this.executionGuideEn,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        repetitions: repetitions ?? this.repetitions,
        imagePath: imagePath ?? this.imagePath,
        duoImagePath:
            duoImagePath.present ? duoImagePath.value : this.duoImagePath,
        videoPath: videoPath.present ? videoPath.value : this.videoPath,
        audioCuePath:
            audioCuePath.present ? audioCuePath.value : this.audioCuePath,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        duoImageUrl: duoImageUrl.present ? duoImageUrl.value : this.duoImageUrl,
        videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
        rhythmType: rhythmType ?? this.rhythmType,
        phasesJson: phasesJson ?? this.phasesJson,
        hasRepSwitch: hasRepSwitch ?? this.hasRepSwitch,
        holdCueDe: holdCueDe ?? this.holdCueDe,
        holdCueEn: holdCueEn ?? this.holdCueEn,
        holdSeconds: holdSeconds ?? this.holdSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        halfwaySwitch: halfwaySwitch ?? this.halfwaySwitch,
      );
  ExercisesTableData copyWithCompanion(ExercisesTableCompanion data) {
    return ExercisesTableData(
      id: data.id.present ? data.id.value : this.id,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      titleDe: data.titleDe.present ? data.titleDe.value : this.titleDe,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      positionInstructionsDe: data.positionInstructionsDe.present
          ? data.positionInstructionsDe.value
          : this.positionInstructionsDe,
      positionInstructionsEn: data.positionInstructionsEn.present
          ? data.positionInstructionsEn.value
          : this.positionInstructionsEn,
      movementInstructionsDe: data.movementInstructionsDe.present
          ? data.movementInstructionsDe.value
          : this.movementInstructionsDe,
      movementInstructionsEn: data.movementInstructionsEn.present
          ? data.movementInstructionsEn.value
          : this.movementInstructionsEn,
      hintsDe: data.hintsDe.present ? data.hintsDe.value : this.hintsDe,
      hintsEn: data.hintsEn.present ? data.hintsEn.value : this.hintsEn,
      executionGuideDe: data.executionGuideDe.present
          ? data.executionGuideDe.value
          : this.executionGuideDe,
      executionGuideEn: data.executionGuideEn.present
          ? data.executionGuideEn.value
          : this.executionGuideEn,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      repetitions:
          data.repetitions.present ? data.repetitions.value : this.repetitions,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      duoImagePath: data.duoImagePath.present
          ? data.duoImagePath.value
          : this.duoImagePath,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      audioCuePath: data.audioCuePath.present
          ? data.audioCuePath.value
          : this.audioCuePath,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      duoImageUrl:
          data.duoImageUrl.present ? data.duoImageUrl.value : this.duoImageUrl,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      rhythmType:
          data.rhythmType.present ? data.rhythmType.value : this.rhythmType,
      phasesJson:
          data.phasesJson.present ? data.phasesJson.value : this.phasesJson,
      hasRepSwitch: data.hasRepSwitch.present
          ? data.hasRepSwitch.value
          : this.hasRepSwitch,
      holdCueDe: data.holdCueDe.present ? data.holdCueDe.value : this.holdCueDe,
      holdCueEn: data.holdCueEn.present ? data.holdCueEn.value : this.holdCueEn,
      holdSeconds:
          data.holdSeconds.present ? data.holdSeconds.value : this.holdSeconds,
      restSeconds:
          data.restSeconds.present ? data.restSeconds.value : this.restSeconds,
      halfwaySwitch: data.halfwaySwitch.present
          ? data.halfwaySwitch.value
          : this.halfwaySwitch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesTableData(')
          ..write('id: $id, ')
          ..write('packageId: $packageId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('titleDe: $titleDe, ')
          ..write('titleEn: $titleEn, ')
          ..write('positionInstructionsDe: $positionInstructionsDe, ')
          ..write('positionInstructionsEn: $positionInstructionsEn, ')
          ..write('movementInstructionsDe: $movementInstructionsDe, ')
          ..write('movementInstructionsEn: $movementInstructionsEn, ')
          ..write('hintsDe: $hintsDe, ')
          ..write('hintsEn: $hintsEn, ')
          ..write('executionGuideDe: $executionGuideDe, ')
          ..write('executionGuideEn: $executionGuideEn, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('repetitions: $repetitions, ')
          ..write('imagePath: $imagePath, ')
          ..write('duoImagePath: $duoImagePath, ')
          ..write('videoPath: $videoPath, ')
          ..write('audioCuePath: $audioCuePath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('duoImageUrl: $duoImageUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('rhythmType: $rhythmType, ')
          ..write('phasesJson: $phasesJson, ')
          ..write('hasRepSwitch: $hasRepSwitch, ')
          ..write('holdCueDe: $holdCueDe, ')
          ..write('holdCueEn: $holdCueEn, ')
          ..write('holdSeconds: $holdSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('halfwaySwitch: $halfwaySwitch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        packageId,
        sequenceNumber,
        titleDe,
        titleEn,
        positionInstructionsDe,
        positionInstructionsEn,
        movementInstructionsDe,
        movementInstructionsEn,
        hintsDe,
        hintsEn,
        executionGuideDe,
        executionGuideEn,
        durationSeconds,
        repetitions,
        imagePath,
        duoImagePath,
        videoPath,
        audioCuePath,
        imageUrl,
        duoImageUrl,
        videoUrl,
        rhythmType,
        phasesJson,
        hasRepSwitch,
        holdCueDe,
        holdCueEn,
        holdSeconds,
        restSeconds,
        halfwaySwitch
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExercisesTableData &&
          other.id == this.id &&
          other.packageId == this.packageId &&
          other.sequenceNumber == this.sequenceNumber &&
          other.titleDe == this.titleDe &&
          other.titleEn == this.titleEn &&
          other.positionInstructionsDe == this.positionInstructionsDe &&
          other.positionInstructionsEn == this.positionInstructionsEn &&
          other.movementInstructionsDe == this.movementInstructionsDe &&
          other.movementInstructionsEn == this.movementInstructionsEn &&
          other.hintsDe == this.hintsDe &&
          other.hintsEn == this.hintsEn &&
          other.executionGuideDe == this.executionGuideDe &&
          other.executionGuideEn == this.executionGuideEn &&
          other.durationSeconds == this.durationSeconds &&
          other.repetitions == this.repetitions &&
          other.imagePath == this.imagePath &&
          other.duoImagePath == this.duoImagePath &&
          other.videoPath == this.videoPath &&
          other.audioCuePath == this.audioCuePath &&
          other.imageUrl == this.imageUrl &&
          other.duoImageUrl == this.duoImageUrl &&
          other.videoUrl == this.videoUrl &&
          other.rhythmType == this.rhythmType &&
          other.phasesJson == this.phasesJson &&
          other.hasRepSwitch == this.hasRepSwitch &&
          other.holdCueDe == this.holdCueDe &&
          other.holdCueEn == this.holdCueEn &&
          other.holdSeconds == this.holdSeconds &&
          other.restSeconds == this.restSeconds &&
          other.halfwaySwitch == this.halfwaySwitch);
}

class ExercisesTableCompanion extends UpdateCompanion<ExercisesTableData> {
  final Value<String> id;
  final Value<String> packageId;
  final Value<int> sequenceNumber;
  final Value<String> titleDe;
  final Value<String> titleEn;
  final Value<String> positionInstructionsDe;
  final Value<String> positionInstructionsEn;
  final Value<String> movementInstructionsDe;
  final Value<String> movementInstructionsEn;
  final Value<String?> hintsDe;
  final Value<String?> hintsEn;
  final Value<String> executionGuideDe;
  final Value<String> executionGuideEn;
  final Value<int> durationSeconds;
  final Value<int> repetitions;
  final Value<String> imagePath;
  final Value<String?> duoImagePath;
  final Value<String?> videoPath;
  final Value<String?> audioCuePath;
  final Value<String?> imageUrl;
  final Value<String?> duoImageUrl;
  final Value<String?> videoUrl;
  final Value<String> rhythmType;
  final Value<String> phasesJson;
  final Value<bool> hasRepSwitch;
  final Value<String> holdCueDe;
  final Value<String> holdCueEn;
  final Value<int> holdSeconds;
  final Value<int> restSeconds;
  final Value<bool> halfwaySwitch;
  final Value<int> rowid;
  const ExercisesTableCompanion({
    this.id = const Value.absent(),
    this.packageId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.titleDe = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.positionInstructionsDe = const Value.absent(),
    this.positionInstructionsEn = const Value.absent(),
    this.movementInstructionsDe = const Value.absent(),
    this.movementInstructionsEn = const Value.absent(),
    this.hintsDe = const Value.absent(),
    this.hintsEn = const Value.absent(),
    this.executionGuideDe = const Value.absent(),
    this.executionGuideEn = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.duoImagePath = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.audioCuePath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.duoImageUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.rhythmType = const Value.absent(),
    this.phasesJson = const Value.absent(),
    this.hasRepSwitch = const Value.absent(),
    this.holdCueDe = const Value.absent(),
    this.holdCueEn = const Value.absent(),
    this.holdSeconds = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.halfwaySwitch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesTableCompanion.insert({
    required String id,
    required String packageId,
    required int sequenceNumber,
    required String titleDe,
    required String titleEn,
    required String positionInstructionsDe,
    required String positionInstructionsEn,
    required String movementInstructionsDe,
    required String movementInstructionsEn,
    this.hintsDe = const Value.absent(),
    this.hintsEn = const Value.absent(),
    required String executionGuideDe,
    required String executionGuideEn,
    required int durationSeconds,
    required int repetitions,
    required String imagePath,
    this.duoImagePath = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.audioCuePath = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.duoImageUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.rhythmType = const Value.absent(),
    this.phasesJson = const Value.absent(),
    this.hasRepSwitch = const Value.absent(),
    this.holdCueDe = const Value.absent(),
    this.holdCueEn = const Value.absent(),
    this.holdSeconds = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.halfwaySwitch = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        packageId = Value(packageId),
        sequenceNumber = Value(sequenceNumber),
        titleDe = Value(titleDe),
        titleEn = Value(titleEn),
        positionInstructionsDe = Value(positionInstructionsDe),
        positionInstructionsEn = Value(positionInstructionsEn),
        movementInstructionsDe = Value(movementInstructionsDe),
        movementInstructionsEn = Value(movementInstructionsEn),
        executionGuideDe = Value(executionGuideDe),
        executionGuideEn = Value(executionGuideEn),
        durationSeconds = Value(durationSeconds),
        repetitions = Value(repetitions),
        imagePath = Value(imagePath);
  static Insertable<ExercisesTableData> custom({
    Expression<String>? id,
    Expression<String>? packageId,
    Expression<int>? sequenceNumber,
    Expression<String>? titleDe,
    Expression<String>? titleEn,
    Expression<String>? positionInstructionsDe,
    Expression<String>? positionInstructionsEn,
    Expression<String>? movementInstructionsDe,
    Expression<String>? movementInstructionsEn,
    Expression<String>? hintsDe,
    Expression<String>? hintsEn,
    Expression<String>? executionGuideDe,
    Expression<String>? executionGuideEn,
    Expression<int>? durationSeconds,
    Expression<int>? repetitions,
    Expression<String>? imagePath,
    Expression<String>? duoImagePath,
    Expression<String>? videoPath,
    Expression<String>? audioCuePath,
    Expression<String>? imageUrl,
    Expression<String>? duoImageUrl,
    Expression<String>? videoUrl,
    Expression<String>? rhythmType,
    Expression<String>? phasesJson,
    Expression<bool>? hasRepSwitch,
    Expression<String>? holdCueDe,
    Expression<String>? holdCueEn,
    Expression<int>? holdSeconds,
    Expression<int>? restSeconds,
    Expression<bool>? halfwaySwitch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageId != null) 'package_id': packageId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (titleDe != null) 'title_de': titleDe,
      if (titleEn != null) 'title_en': titleEn,
      if (positionInstructionsDe != null)
        'position_instructions_de': positionInstructionsDe,
      if (positionInstructionsEn != null)
        'position_instructions_en': positionInstructionsEn,
      if (movementInstructionsDe != null)
        'movement_instructions_de': movementInstructionsDe,
      if (movementInstructionsEn != null)
        'movement_instructions_en': movementInstructionsEn,
      if (hintsDe != null) 'hints_de': hintsDe,
      if (hintsEn != null) 'hints_en': hintsEn,
      if (executionGuideDe != null) 'execution_guide_de': executionGuideDe,
      if (executionGuideEn != null) 'execution_guide_en': executionGuideEn,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (repetitions != null) 'repetitions': repetitions,
      if (imagePath != null) 'image_path': imagePath,
      if (duoImagePath != null) 'duo_image_path': duoImagePath,
      if (videoPath != null) 'video_path': videoPath,
      if (audioCuePath != null) 'audio_cue_path': audioCuePath,
      if (imageUrl != null) 'image_url': imageUrl,
      if (duoImageUrl != null) 'duo_image_url': duoImageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (rhythmType != null) 'rhythm_type': rhythmType,
      if (phasesJson != null) 'phases_json': phasesJson,
      if (hasRepSwitch != null) 'has_rep_switch': hasRepSwitch,
      if (holdCueDe != null) 'hold_cue_de': holdCueDe,
      if (holdCueEn != null) 'hold_cue_en': holdCueEn,
      if (holdSeconds != null) 'hold_seconds': holdSeconds,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (halfwaySwitch != null) 'halfway_switch': halfwaySwitch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? packageId,
      Value<int>? sequenceNumber,
      Value<String>? titleDe,
      Value<String>? titleEn,
      Value<String>? positionInstructionsDe,
      Value<String>? positionInstructionsEn,
      Value<String>? movementInstructionsDe,
      Value<String>? movementInstructionsEn,
      Value<String?>? hintsDe,
      Value<String?>? hintsEn,
      Value<String>? executionGuideDe,
      Value<String>? executionGuideEn,
      Value<int>? durationSeconds,
      Value<int>? repetitions,
      Value<String>? imagePath,
      Value<String?>? duoImagePath,
      Value<String?>? videoPath,
      Value<String?>? audioCuePath,
      Value<String?>? imageUrl,
      Value<String?>? duoImageUrl,
      Value<String?>? videoUrl,
      Value<String>? rhythmType,
      Value<String>? phasesJson,
      Value<bool>? hasRepSwitch,
      Value<String>? holdCueDe,
      Value<String>? holdCueEn,
      Value<int>? holdSeconds,
      Value<int>? restSeconds,
      Value<bool>? halfwaySwitch,
      Value<int>? rowid}) {
    return ExercisesTableCompanion(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      titleDe: titleDe ?? this.titleDe,
      titleEn: titleEn ?? this.titleEn,
      positionInstructionsDe:
          positionInstructionsDe ?? this.positionInstructionsDe,
      positionInstructionsEn:
          positionInstructionsEn ?? this.positionInstructionsEn,
      movementInstructionsDe:
          movementInstructionsDe ?? this.movementInstructionsDe,
      movementInstructionsEn:
          movementInstructionsEn ?? this.movementInstructionsEn,
      hintsDe: hintsDe ?? this.hintsDe,
      hintsEn: hintsEn ?? this.hintsEn,
      executionGuideDe: executionGuideDe ?? this.executionGuideDe,
      executionGuideEn: executionGuideEn ?? this.executionGuideEn,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      repetitions: repetitions ?? this.repetitions,
      imagePath: imagePath ?? this.imagePath,
      duoImagePath: duoImagePath ?? this.duoImagePath,
      videoPath: videoPath ?? this.videoPath,
      audioCuePath: audioCuePath ?? this.audioCuePath,
      imageUrl: imageUrl ?? this.imageUrl,
      duoImageUrl: duoImageUrl ?? this.duoImageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      rhythmType: rhythmType ?? this.rhythmType,
      phasesJson: phasesJson ?? this.phasesJson,
      hasRepSwitch: hasRepSwitch ?? this.hasRepSwitch,
      holdCueDe: holdCueDe ?? this.holdCueDe,
      holdCueEn: holdCueEn ?? this.holdCueEn,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      halfwaySwitch: halfwaySwitch ?? this.halfwaySwitch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (titleDe.present) {
      map['title_de'] = Variable<String>(titleDe.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (positionInstructionsDe.present) {
      map['position_instructions_de'] =
          Variable<String>(positionInstructionsDe.value);
    }
    if (positionInstructionsEn.present) {
      map['position_instructions_en'] =
          Variable<String>(positionInstructionsEn.value);
    }
    if (movementInstructionsDe.present) {
      map['movement_instructions_de'] =
          Variable<String>(movementInstructionsDe.value);
    }
    if (movementInstructionsEn.present) {
      map['movement_instructions_en'] =
          Variable<String>(movementInstructionsEn.value);
    }
    if (hintsDe.present) {
      map['hints_de'] = Variable<String>(hintsDe.value);
    }
    if (hintsEn.present) {
      map['hints_en'] = Variable<String>(hintsEn.value);
    }
    if (executionGuideDe.present) {
      map['execution_guide_de'] = Variable<String>(executionGuideDe.value);
    }
    if (executionGuideEn.present) {
      map['execution_guide_en'] = Variable<String>(executionGuideEn.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (duoImagePath.present) {
      map['duo_image_path'] = Variable<String>(duoImagePath.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (audioCuePath.present) {
      map['audio_cue_path'] = Variable<String>(audioCuePath.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (duoImageUrl.present) {
      map['duo_image_url'] = Variable<String>(duoImageUrl.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (rhythmType.present) {
      map['rhythm_type'] = Variable<String>(rhythmType.value);
    }
    if (phasesJson.present) {
      map['phases_json'] = Variable<String>(phasesJson.value);
    }
    if (hasRepSwitch.present) {
      map['has_rep_switch'] = Variable<bool>(hasRepSwitch.value);
    }
    if (holdCueDe.present) {
      map['hold_cue_de'] = Variable<String>(holdCueDe.value);
    }
    if (holdCueEn.present) {
      map['hold_cue_en'] = Variable<String>(holdCueEn.value);
    }
    if (holdSeconds.present) {
      map['hold_seconds'] = Variable<int>(holdSeconds.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (halfwaySwitch.present) {
      map['halfway_switch'] = Variable<bool>(halfwaySwitch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesTableCompanion(')
          ..write('id: $id, ')
          ..write('packageId: $packageId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('titleDe: $titleDe, ')
          ..write('titleEn: $titleEn, ')
          ..write('positionInstructionsDe: $positionInstructionsDe, ')
          ..write('positionInstructionsEn: $positionInstructionsEn, ')
          ..write('movementInstructionsDe: $movementInstructionsDe, ')
          ..write('movementInstructionsEn: $movementInstructionsEn, ')
          ..write('hintsDe: $hintsDe, ')
          ..write('hintsEn: $hintsEn, ')
          ..write('executionGuideDe: $executionGuideDe, ')
          ..write('executionGuideEn: $executionGuideEn, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('repetitions: $repetitions, ')
          ..write('imagePath: $imagePath, ')
          ..write('duoImagePath: $duoImagePath, ')
          ..write('videoPath: $videoPath, ')
          ..write('audioCuePath: $audioCuePath, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('duoImageUrl: $duoImageUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('rhythmType: $rhythmType, ')
          ..write('phasesJson: $phasesJson, ')
          ..write('hasRepSwitch: $hasRepSwitch, ')
          ..write('holdCueDe: $holdCueDe, ')
          ..write('holdCueEn: $holdCueEn, ')
          ..write('holdSeconds: $holdSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('halfwaySwitch: $halfwaySwitch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainingSessionsTableTable extends TrainingSessionsTable
    with TableInfo<$TrainingSessionsTableTable, TrainingSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enrollmentIdMeta =
      const VerificationMeta('enrollmentId');
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
      'enrollment_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionDateMeta =
      const VerificationMeta('sessionDate');
  @override
  late final GeneratedColumn<DateTime> sessionDate = GeneratedColumn<DateTime>(
      'session_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dayNumberMeta =
      const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
      'day_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedExerciseIdsMeta =
      const VerificationMeta('completedExerciseIds');
  @override
  late final GeneratedColumn<String> completedExerciseIds =
      GeneratedColumn<String>('completed_exercise_ids', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        subjectProfileId,
        enrollmentId,
        sessionDate,
        dayNumber,
        completedExerciseIds,
        isCompleted,
        completedAt,
        needsSync,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<TrainingSessionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
          _enrollmentIdMeta,
          enrollmentId.isAcceptableOrUnknown(
              data['enrollment_id']!, _enrollmentIdMeta));
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('session_date')) {
      context.handle(
          _sessionDateMeta,
          sessionDate.isAcceptableOrUnknown(
              data['session_date']!, _sessionDateMeta));
    } else if (isInserting) {
      context.missing(_sessionDateMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta,
          dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('completed_exercise_ids')) {
      context.handle(
          _completedExerciseIdsMeta,
          completedExerciseIds.isAcceptableOrUnknown(
              data['completed_exercise_ids']!, _completedExerciseIdsMeta));
    } else if (isInserting) {
      context.missing(_completedExerciseIdsMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingSessionsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingSessionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id']),
      enrollmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enrollment_id'])!,
      sessionDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}session_date'])!,
      dayNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      completedExerciseIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}completed_exercise_ids'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TrainingSessionsTableTable createAlias(String alias) {
    return $TrainingSessionsTableTable(attachedDatabase, alias);
  }
}

class TrainingSessionsTableData extends DataClass
    implements Insertable<TrainingSessionsTableData> {
  final String id;
  final String userId;
  final String? subjectProfileId;
  final String enrollmentId;
  final DateTime sessionDate;
  final int dayNumber;
  final String completedExerciseIds;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool needsSync;
  final DateTime createdAt;
  const TrainingSessionsTableData(
      {required this.id,
      required this.userId,
      this.subjectProfileId,
      required this.enrollmentId,
      required this.sessionDate,
      required this.dayNumber,
      required this.completedExerciseIds,
      required this.isCompleted,
      this.completedAt,
      required this.needsSync,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || subjectProfileId != null) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId);
    }
    map['enrollment_id'] = Variable<String>(enrollmentId);
    map['session_date'] = Variable<DateTime>(sessionDate);
    map['day_number'] = Variable<int>(dayNumber);
    map['completed_exercise_ids'] = Variable<String>(completedExerciseIds);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TrainingSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return TrainingSessionsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      subjectProfileId: subjectProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectProfileId),
      enrollmentId: Value(enrollmentId),
      sessionDate: Value(sessionDate),
      dayNumber: Value(dayNumber),
      completedExerciseIds: Value(completedExerciseIds),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      needsSync: Value(needsSync),
      createdAt: Value(createdAt),
    );
  }

  factory TrainingSessionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      subjectProfileId: serializer.fromJson<String?>(json['subjectProfileId']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      sessionDate: serializer.fromJson<DateTime>(json['sessionDate']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      completedExerciseIds:
          serializer.fromJson<String>(json['completedExerciseIds']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'subjectProfileId': serializer.toJson<String?>(subjectProfileId),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'sessionDate': serializer.toJson<DateTime>(sessionDate),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'completedExerciseIds': serializer.toJson<String>(completedExerciseIds),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TrainingSessionsTableData copyWith(
          {String? id,
          String? userId,
          Value<String?> subjectProfileId = const Value.absent(),
          String? enrollmentId,
          DateTime? sessionDate,
          int? dayNumber,
          String? completedExerciseIds,
          bool? isCompleted,
          Value<DateTime?> completedAt = const Value.absent(),
          bool? needsSync,
          DateTime? createdAt}) =>
      TrainingSessionsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        subjectProfileId: subjectProfileId.present
            ? subjectProfileId.value
            : this.subjectProfileId,
        enrollmentId: enrollmentId ?? this.enrollmentId,
        sessionDate: sessionDate ?? this.sessionDate,
        dayNumber: dayNumber ?? this.dayNumber,
        completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        needsSync: needsSync ?? this.needsSync,
        createdAt: createdAt ?? this.createdAt,
      );
  TrainingSessionsTableData copyWithCompanion(
      TrainingSessionsTableCompanion data) {
    return TrainingSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      sessionDate:
          data.sessionDate.present ? data.sessionDate.value : this.sessionDate,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      completedExerciseIds: data.completedExerciseIds.present
          ? data.completedExerciseIds.value
          : this.completedExerciseIds,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingSessionsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('completedExerciseIds: $completedExerciseIds, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      subjectProfileId,
      enrollmentId,
      sessionDate,
      dayNumber,
      completedExerciseIds,
      isCompleted,
      completedAt,
      needsSync,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingSessionsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.subjectProfileId == this.subjectProfileId &&
          other.enrollmentId == this.enrollmentId &&
          other.sessionDate == this.sessionDate &&
          other.dayNumber == this.dayNumber &&
          other.completedExerciseIds == this.completedExerciseIds &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.needsSync == this.needsSync &&
          other.createdAt == this.createdAt);
}

class TrainingSessionsTableCompanion
    extends UpdateCompanion<TrainingSessionsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> subjectProfileId;
  final Value<String> enrollmentId;
  final Value<DateTime> sessionDate;
  final Value<int> dayNumber;
  final Value<String> completedExerciseIds;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<bool> needsSync;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TrainingSessionsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.sessionDate = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.completedExerciseIds = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainingSessionsTableCompanion.insert({
    required String id,
    required String userId,
    this.subjectProfileId = const Value.absent(),
    required String enrollmentId,
    required DateTime sessionDate,
    required int dayNumber,
    required String completedExerciseIds,
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        enrollmentId = Value(enrollmentId),
        sessionDate = Value(sessionDate),
        dayNumber = Value(dayNumber),
        completedExerciseIds = Value(completedExerciseIds);
  static Insertable<TrainingSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? subjectProfileId,
    Expression<String>? enrollmentId,
    Expression<DateTime>? sessionDate,
    Expression<int>? dayNumber,
    Expression<String>? completedExerciseIds,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<bool>? needsSync,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (sessionDate != null) 'session_date': sessionDate,
      if (dayNumber != null) 'day_number': dayNumber,
      if (completedExerciseIds != null)
        'completed_exercise_ids': completedExerciseIds,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainingSessionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? subjectProfileId,
      Value<String>? enrollmentId,
      Value<DateTime>? sessionDate,
      Value<int>? dayNumber,
      Value<String>? completedExerciseIds,
      Value<bool>? isCompleted,
      Value<DateTime?>? completedAt,
      Value<bool>? needsSync,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TrainingSessionsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      sessionDate: sessionDate ?? this.sessionDate,
      dayNumber: dayNumber ?? this.dayNumber,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      needsSync: needsSync ?? this.needsSync,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (sessionDate.present) {
      map['session_date'] = Variable<DateTime>(sessionDate.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (completedExerciseIds.present) {
      map['completed_exercise_ids'] =
          Variable<String>(completedExerciseIds.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('completedExerciseIds: $completedExerciseIds, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressEntriesTableTable extends ProgressEntriesTable
    with TableInfo<$ProgressEntriesTableTable, ProgressEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enrollmentIdMeta =
      const VerificationMeta('enrollmentId');
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
      'enrollment_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentDayMeta =
      const VerificationMeta('currentDay');
  @override
  late final GeneratedColumn<int> currentDay = GeneratedColumn<int>(
      'current_day', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastActivityDateMeta =
      const VerificationMeta('lastActivityDate');
  @override
  late final GeneratedColumn<DateTime> lastActivityDate =
      GeneratedColumn<DateTime>('last_activity_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _consecutiveInactiveDaysMeta =
      const VerificationMeta('consecutiveInactiveDays');
  @override
  late final GeneratedColumn<int> consecutiveInactiveDays =
      GeneratedColumn<int>('consecutive_inactive_days', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _dailyStreakMeta =
      const VerificationMeta('dailyStreak');
  @override
  late final GeneratedColumn<int> dailyStreak = GeneratedColumn<int>(
      'daily_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _weeklyStreakMeta =
      const VerificationMeta('weeklyStreak');
  @override
  late final GeneratedColumn<int> weeklyStreak = GeneratedColumn<int>(
      'weekly_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _trainingsThisWeekMeta =
      const VerificationMeta('trainingsThisWeek');
  @override
  late final GeneratedColumn<int> trainingsThisWeek = GeneratedColumn<int>(
      'trainings_this_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastTrainingWeekStartMeta =
      const VerificationMeta('lastTrainingWeekStart');
  @override
  late final GeneratedColumn<DateTime> lastTrainingWeekStart =
      GeneratedColumn<DateTime>('last_training_week_start', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _weeklyGoalMeta =
      const VerificationMeta('weeklyGoal');
  @override
  late final GeneratedColumn<int> weeklyGoal = GeneratedColumn<int>(
      'weekly_goal', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _totalSessionsSinceDisclaimerMeta =
      const VerificationMeta('totalSessionsSinceDisclaimer');
  @override
  late final GeneratedColumn<int> totalSessionsSinceDisclaimer =
      GeneratedColumn<int>(
          'total_sessions_since_disclaimer', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _lastDisclaimerAcceptedAtMeta =
      const VerificationMeta('lastDisclaimerAcceptedAt');
  @override
  late final GeneratedColumn<DateTime> lastDisclaimerAcceptedAt =
      GeneratedColumn<DateTime>(
          'last_disclaimer_accepted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        subjectProfileId,
        enrollmentId,
        currentDay,
        lastActivityDate,
        consecutiveInactiveDays,
        dailyStreak,
        weeklyStreak,
        trainingsThisWeek,
        lastTrainingWeekStart,
        weeklyGoal,
        totalSessionsSinceDisclaimer,
        lastDisclaimerAcceptedAt,
        needsSync,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<ProgressEntriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
          _enrollmentIdMeta,
          enrollmentId.isAcceptableOrUnknown(
              data['enrollment_id']!, _enrollmentIdMeta));
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('current_day')) {
      context.handle(
          _currentDayMeta,
          currentDay.isAcceptableOrUnknown(
              data['current_day']!, _currentDayMeta));
    }
    if (data.containsKey('last_activity_date')) {
      context.handle(
          _lastActivityDateMeta,
          lastActivityDate.isAcceptableOrUnknown(
              data['last_activity_date']!, _lastActivityDateMeta));
    }
    if (data.containsKey('consecutive_inactive_days')) {
      context.handle(
          _consecutiveInactiveDaysMeta,
          consecutiveInactiveDays.isAcceptableOrUnknown(
              data['consecutive_inactive_days']!,
              _consecutiveInactiveDaysMeta));
    }
    if (data.containsKey('daily_streak')) {
      context.handle(
          _dailyStreakMeta,
          dailyStreak.isAcceptableOrUnknown(
              data['daily_streak']!, _dailyStreakMeta));
    }
    if (data.containsKey('weekly_streak')) {
      context.handle(
          _weeklyStreakMeta,
          weeklyStreak.isAcceptableOrUnknown(
              data['weekly_streak']!, _weeklyStreakMeta));
    }
    if (data.containsKey('trainings_this_week')) {
      context.handle(
          _trainingsThisWeekMeta,
          trainingsThisWeek.isAcceptableOrUnknown(
              data['trainings_this_week']!, _trainingsThisWeekMeta));
    }
    if (data.containsKey('last_training_week_start')) {
      context.handle(
          _lastTrainingWeekStartMeta,
          lastTrainingWeekStart.isAcceptableOrUnknown(
              data['last_training_week_start']!, _lastTrainingWeekStartMeta));
    }
    if (data.containsKey('weekly_goal')) {
      context.handle(
          _weeklyGoalMeta,
          weeklyGoal.isAcceptableOrUnknown(
              data['weekly_goal']!, _weeklyGoalMeta));
    }
    if (data.containsKey('total_sessions_since_disclaimer')) {
      context.handle(
          _totalSessionsSinceDisclaimerMeta,
          totalSessionsSinceDisclaimer.isAcceptableOrUnknown(
              data['total_sessions_since_disclaimer']!,
              _totalSessionsSinceDisclaimerMeta));
    }
    if (data.containsKey('last_disclaimer_accepted_at')) {
      context.handle(
          _lastDisclaimerAcceptedAtMeta,
          lastDisclaimerAcceptedAt.isAcceptableOrUnknown(
              data['last_disclaimer_accepted_at']!,
              _lastDisclaimerAcceptedAtMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressEntriesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressEntriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id']),
      enrollmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enrollment_id'])!,
      currentDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_day'])!,
      lastActivityDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_activity_date']),
      consecutiveInactiveDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}consecutive_inactive_days'])!,
      dailyStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_streak'])!,
      weeklyStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekly_streak'])!,
      trainingsThisWeek: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}trainings_this_week'])!,
      lastTrainingWeekStart: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_training_week_start']),
      weeklyGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekly_goal'])!,
      totalSessionsSinceDisclaimer: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}total_sessions_since_disclaimer'])!,
      lastDisclaimerAcceptedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_disclaimer_accepted_at']),
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProgressEntriesTableTable createAlias(String alias) {
    return $ProgressEntriesTableTable(attachedDatabase, alias);
  }
}

class ProgressEntriesTableData extends DataClass
    implements Insertable<ProgressEntriesTableData> {
  final String id;
  final String userId;
  final String? subjectProfileId;
  final String enrollmentId;
  final int currentDay;
  final DateTime? lastActivityDate;
  final int consecutiveInactiveDays;
  final int dailyStreak;
  final int weeklyStreak;
  final int trainingsThisWeek;
  final DateTime? lastTrainingWeekStart;
  final int weeklyGoal;
  final int totalSessionsSinceDisclaimer;
  final DateTime? lastDisclaimerAcceptedAt;
  final bool needsSync;
  final DateTime updatedAt;
  const ProgressEntriesTableData(
      {required this.id,
      required this.userId,
      this.subjectProfileId,
      required this.enrollmentId,
      required this.currentDay,
      this.lastActivityDate,
      required this.consecutiveInactiveDays,
      required this.dailyStreak,
      required this.weeklyStreak,
      required this.trainingsThisWeek,
      this.lastTrainingWeekStart,
      required this.weeklyGoal,
      required this.totalSessionsSinceDisclaimer,
      this.lastDisclaimerAcceptedAt,
      required this.needsSync,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || subjectProfileId != null) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId);
    }
    map['enrollment_id'] = Variable<String>(enrollmentId);
    map['current_day'] = Variable<int>(currentDay);
    if (!nullToAbsent || lastActivityDate != null) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate);
    }
    map['consecutive_inactive_days'] = Variable<int>(consecutiveInactiveDays);
    map['daily_streak'] = Variable<int>(dailyStreak);
    map['weekly_streak'] = Variable<int>(weeklyStreak);
    map['trainings_this_week'] = Variable<int>(trainingsThisWeek);
    if (!nullToAbsent || lastTrainingWeekStart != null) {
      map['last_training_week_start'] =
          Variable<DateTime>(lastTrainingWeekStart);
    }
    map['weekly_goal'] = Variable<int>(weeklyGoal);
    map['total_sessions_since_disclaimer'] =
        Variable<int>(totalSessionsSinceDisclaimer);
    if (!nullToAbsent || lastDisclaimerAcceptedAt != null) {
      map['last_disclaimer_accepted_at'] =
          Variable<DateTime>(lastDisclaimerAcceptedAt);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProgressEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return ProgressEntriesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      subjectProfileId: subjectProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectProfileId),
      enrollmentId: Value(enrollmentId),
      currentDay: Value(currentDay),
      lastActivityDate: lastActivityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityDate),
      consecutiveInactiveDays: Value(consecutiveInactiveDays),
      dailyStreak: Value(dailyStreak),
      weeklyStreak: Value(weeklyStreak),
      trainingsThisWeek: Value(trainingsThisWeek),
      lastTrainingWeekStart: lastTrainingWeekStart == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTrainingWeekStart),
      weeklyGoal: Value(weeklyGoal),
      totalSessionsSinceDisclaimer: Value(totalSessionsSinceDisclaimer),
      lastDisclaimerAcceptedAt: lastDisclaimerAcceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDisclaimerAcceptedAt),
      needsSync: Value(needsSync),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressEntriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      subjectProfileId: serializer.fromJson<String?>(json['subjectProfileId']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      currentDay: serializer.fromJson<int>(json['currentDay']),
      lastActivityDate:
          serializer.fromJson<DateTime?>(json['lastActivityDate']),
      consecutiveInactiveDays:
          serializer.fromJson<int>(json['consecutiveInactiveDays']),
      dailyStreak: serializer.fromJson<int>(json['dailyStreak']),
      weeklyStreak: serializer.fromJson<int>(json['weeklyStreak']),
      trainingsThisWeek: serializer.fromJson<int>(json['trainingsThisWeek']),
      lastTrainingWeekStart:
          serializer.fromJson<DateTime?>(json['lastTrainingWeekStart']),
      weeklyGoal: serializer.fromJson<int>(json['weeklyGoal']),
      totalSessionsSinceDisclaimer:
          serializer.fromJson<int>(json['totalSessionsSinceDisclaimer']),
      lastDisclaimerAcceptedAt:
          serializer.fromJson<DateTime?>(json['lastDisclaimerAcceptedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'subjectProfileId': serializer.toJson<String?>(subjectProfileId),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'currentDay': serializer.toJson<int>(currentDay),
      'lastActivityDate': serializer.toJson<DateTime?>(lastActivityDate),
      'consecutiveInactiveDays':
          serializer.toJson<int>(consecutiveInactiveDays),
      'dailyStreak': serializer.toJson<int>(dailyStreak),
      'weeklyStreak': serializer.toJson<int>(weeklyStreak),
      'trainingsThisWeek': serializer.toJson<int>(trainingsThisWeek),
      'lastTrainingWeekStart':
          serializer.toJson<DateTime?>(lastTrainingWeekStart),
      'weeklyGoal': serializer.toJson<int>(weeklyGoal),
      'totalSessionsSinceDisclaimer':
          serializer.toJson<int>(totalSessionsSinceDisclaimer),
      'lastDisclaimerAcceptedAt':
          serializer.toJson<DateTime?>(lastDisclaimerAcceptedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProgressEntriesTableData copyWith(
          {String? id,
          String? userId,
          Value<String?> subjectProfileId = const Value.absent(),
          String? enrollmentId,
          int? currentDay,
          Value<DateTime?> lastActivityDate = const Value.absent(),
          int? consecutiveInactiveDays,
          int? dailyStreak,
          int? weeklyStreak,
          int? trainingsThisWeek,
          Value<DateTime?> lastTrainingWeekStart = const Value.absent(),
          int? weeklyGoal,
          int? totalSessionsSinceDisclaimer,
          Value<DateTime?> lastDisclaimerAcceptedAt = const Value.absent(),
          bool? needsSync,
          DateTime? updatedAt}) =>
      ProgressEntriesTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        subjectProfileId: subjectProfileId.present
            ? subjectProfileId.value
            : this.subjectProfileId,
        enrollmentId: enrollmentId ?? this.enrollmentId,
        currentDay: currentDay ?? this.currentDay,
        lastActivityDate: lastActivityDate.present
            ? lastActivityDate.value
            : this.lastActivityDate,
        consecutiveInactiveDays:
            consecutiveInactiveDays ?? this.consecutiveInactiveDays,
        dailyStreak: dailyStreak ?? this.dailyStreak,
        weeklyStreak: weeklyStreak ?? this.weeklyStreak,
        trainingsThisWeek: trainingsThisWeek ?? this.trainingsThisWeek,
        lastTrainingWeekStart: lastTrainingWeekStart.present
            ? lastTrainingWeekStart.value
            : this.lastTrainingWeekStart,
        weeklyGoal: weeklyGoal ?? this.weeklyGoal,
        totalSessionsSinceDisclaimer:
            totalSessionsSinceDisclaimer ?? this.totalSessionsSinceDisclaimer,
        lastDisclaimerAcceptedAt: lastDisclaimerAcceptedAt.present
            ? lastDisclaimerAcceptedAt.value
            : this.lastDisclaimerAcceptedAt,
        needsSync: needsSync ?? this.needsSync,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProgressEntriesTableData copyWithCompanion(
      ProgressEntriesTableCompanion data) {
    return ProgressEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      currentDay:
          data.currentDay.present ? data.currentDay.value : this.currentDay,
      lastActivityDate: data.lastActivityDate.present
          ? data.lastActivityDate.value
          : this.lastActivityDate,
      consecutiveInactiveDays: data.consecutiveInactiveDays.present
          ? data.consecutiveInactiveDays.value
          : this.consecutiveInactiveDays,
      dailyStreak:
          data.dailyStreak.present ? data.dailyStreak.value : this.dailyStreak,
      weeklyStreak: data.weeklyStreak.present
          ? data.weeklyStreak.value
          : this.weeklyStreak,
      trainingsThisWeek: data.trainingsThisWeek.present
          ? data.trainingsThisWeek.value
          : this.trainingsThisWeek,
      lastTrainingWeekStart: data.lastTrainingWeekStart.present
          ? data.lastTrainingWeekStart.value
          : this.lastTrainingWeekStart,
      weeklyGoal:
          data.weeklyGoal.present ? data.weeklyGoal.value : this.weeklyGoal,
      totalSessionsSinceDisclaimer: data.totalSessionsSinceDisclaimer.present
          ? data.totalSessionsSinceDisclaimer.value
          : this.totalSessionsSinceDisclaimer,
      lastDisclaimerAcceptedAt: data.lastDisclaimerAcceptedAt.present
          ? data.lastDisclaimerAcceptedAt.value
          : this.lastDisclaimerAcceptedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntriesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('currentDay: $currentDay, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('consecutiveInactiveDays: $consecutiveInactiveDays, ')
          ..write('dailyStreak: $dailyStreak, ')
          ..write('weeklyStreak: $weeklyStreak, ')
          ..write('trainingsThisWeek: $trainingsThisWeek, ')
          ..write('lastTrainingWeekStart: $lastTrainingWeekStart, ')
          ..write('weeklyGoal: $weeklyGoal, ')
          ..write(
              'totalSessionsSinceDisclaimer: $totalSessionsSinceDisclaimer, ')
          ..write('lastDisclaimerAcceptedAt: $lastDisclaimerAcceptedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      subjectProfileId,
      enrollmentId,
      currentDay,
      lastActivityDate,
      consecutiveInactiveDays,
      dailyStreak,
      weeklyStreak,
      trainingsThisWeek,
      lastTrainingWeekStart,
      weeklyGoal,
      totalSessionsSinceDisclaimer,
      lastDisclaimerAcceptedAt,
      needsSync,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressEntriesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.subjectProfileId == this.subjectProfileId &&
          other.enrollmentId == this.enrollmentId &&
          other.currentDay == this.currentDay &&
          other.lastActivityDate == this.lastActivityDate &&
          other.consecutiveInactiveDays == this.consecutiveInactiveDays &&
          other.dailyStreak == this.dailyStreak &&
          other.weeklyStreak == this.weeklyStreak &&
          other.trainingsThisWeek == this.trainingsThisWeek &&
          other.lastTrainingWeekStart == this.lastTrainingWeekStart &&
          other.weeklyGoal == this.weeklyGoal &&
          other.totalSessionsSinceDisclaimer ==
              this.totalSessionsSinceDisclaimer &&
          other.lastDisclaimerAcceptedAt == this.lastDisclaimerAcceptedAt &&
          other.needsSync == this.needsSync &&
          other.updatedAt == this.updatedAt);
}

class ProgressEntriesTableCompanion
    extends UpdateCompanion<ProgressEntriesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> subjectProfileId;
  final Value<String> enrollmentId;
  final Value<int> currentDay;
  final Value<DateTime?> lastActivityDate;
  final Value<int> consecutiveInactiveDays;
  final Value<int> dailyStreak;
  final Value<int> weeklyStreak;
  final Value<int> trainingsThisWeek;
  final Value<DateTime?> lastTrainingWeekStart;
  final Value<int> weeklyGoal;
  final Value<int> totalSessionsSinceDisclaimer;
  final Value<DateTime?> lastDisclaimerAcceptedAt;
  final Value<bool> needsSync;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProgressEntriesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.currentDay = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.consecutiveInactiveDays = const Value.absent(),
    this.dailyStreak = const Value.absent(),
    this.weeklyStreak = const Value.absent(),
    this.trainingsThisWeek = const Value.absent(),
    this.lastTrainingWeekStart = const Value.absent(),
    this.weeklyGoal = const Value.absent(),
    this.totalSessionsSinceDisclaimer = const Value.absent(),
    this.lastDisclaimerAcceptedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressEntriesTableCompanion.insert({
    required String id,
    required String userId,
    this.subjectProfileId = const Value.absent(),
    required String enrollmentId,
    this.currentDay = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.consecutiveInactiveDays = const Value.absent(),
    this.dailyStreak = const Value.absent(),
    this.weeklyStreak = const Value.absent(),
    this.trainingsThisWeek = const Value.absent(),
    this.lastTrainingWeekStart = const Value.absent(),
    this.weeklyGoal = const Value.absent(),
    this.totalSessionsSinceDisclaimer = const Value.absent(),
    this.lastDisclaimerAcceptedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        enrollmentId = Value(enrollmentId);
  static Insertable<ProgressEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? subjectProfileId,
    Expression<String>? enrollmentId,
    Expression<int>? currentDay,
    Expression<DateTime>? lastActivityDate,
    Expression<int>? consecutiveInactiveDays,
    Expression<int>? dailyStreak,
    Expression<int>? weeklyStreak,
    Expression<int>? trainingsThisWeek,
    Expression<DateTime>? lastTrainingWeekStart,
    Expression<int>? weeklyGoal,
    Expression<int>? totalSessionsSinceDisclaimer,
    Expression<DateTime>? lastDisclaimerAcceptedAt,
    Expression<bool>? needsSync,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (currentDay != null) 'current_day': currentDay,
      if (lastActivityDate != null) 'last_activity_date': lastActivityDate,
      if (consecutiveInactiveDays != null)
        'consecutive_inactive_days': consecutiveInactiveDays,
      if (dailyStreak != null) 'daily_streak': dailyStreak,
      if (weeklyStreak != null) 'weekly_streak': weeklyStreak,
      if (trainingsThisWeek != null) 'trainings_this_week': trainingsThisWeek,
      if (lastTrainingWeekStart != null)
        'last_training_week_start': lastTrainingWeekStart,
      if (weeklyGoal != null) 'weekly_goal': weeklyGoal,
      if (totalSessionsSinceDisclaimer != null)
        'total_sessions_since_disclaimer': totalSessionsSinceDisclaimer,
      if (lastDisclaimerAcceptedAt != null)
        'last_disclaimer_accepted_at': lastDisclaimerAcceptedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressEntriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? subjectProfileId,
      Value<String>? enrollmentId,
      Value<int>? currentDay,
      Value<DateTime?>? lastActivityDate,
      Value<int>? consecutiveInactiveDays,
      Value<int>? dailyStreak,
      Value<int>? weeklyStreak,
      Value<int>? trainingsThisWeek,
      Value<DateTime?>? lastTrainingWeekStart,
      Value<int>? weeklyGoal,
      Value<int>? totalSessionsSinceDisclaimer,
      Value<DateTime?>? lastDisclaimerAcceptedAt,
      Value<bool>? needsSync,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProgressEntriesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      currentDay: currentDay ?? this.currentDay,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      consecutiveInactiveDays:
          consecutiveInactiveDays ?? this.consecutiveInactiveDays,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      weeklyStreak: weeklyStreak ?? this.weeklyStreak,
      trainingsThisWeek: trainingsThisWeek ?? this.trainingsThisWeek,
      lastTrainingWeekStart:
          lastTrainingWeekStart ?? this.lastTrainingWeekStart,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      totalSessionsSinceDisclaimer:
          totalSessionsSinceDisclaimer ?? this.totalSessionsSinceDisclaimer,
      lastDisclaimerAcceptedAt:
          lastDisclaimerAcceptedAt ?? this.lastDisclaimerAcceptedAt,
      needsSync: needsSync ?? this.needsSync,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (currentDay.present) {
      map['current_day'] = Variable<int>(currentDay.value);
    }
    if (lastActivityDate.present) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate.value);
    }
    if (consecutiveInactiveDays.present) {
      map['consecutive_inactive_days'] =
          Variable<int>(consecutiveInactiveDays.value);
    }
    if (dailyStreak.present) {
      map['daily_streak'] = Variable<int>(dailyStreak.value);
    }
    if (weeklyStreak.present) {
      map['weekly_streak'] = Variable<int>(weeklyStreak.value);
    }
    if (trainingsThisWeek.present) {
      map['trainings_this_week'] = Variable<int>(trainingsThisWeek.value);
    }
    if (lastTrainingWeekStart.present) {
      map['last_training_week_start'] =
          Variable<DateTime>(lastTrainingWeekStart.value);
    }
    if (weeklyGoal.present) {
      map['weekly_goal'] = Variable<int>(weeklyGoal.value);
    }
    if (totalSessionsSinceDisclaimer.present) {
      map['total_sessions_since_disclaimer'] =
          Variable<int>(totalSessionsSinceDisclaimer.value);
    }
    if (lastDisclaimerAcceptedAt.present) {
      map['last_disclaimer_accepted_at'] =
          Variable<DateTime>(lastDisclaimerAcceptedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('currentDay: $currentDay, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('consecutiveInactiveDays: $consecutiveInactiveDays, ')
          ..write('dailyStreak: $dailyStreak, ')
          ..write('weeklyStreak: $weeklyStreak, ')
          ..write('trainingsThisWeek: $trainingsThisWeek, ')
          ..write('lastTrainingWeekStart: $lastTrainingWeekStart, ')
          ..write('weeklyGoal: $weeklyGoal, ')
          ..write(
              'totalSessionsSinceDisclaimer: $totalSessionsSinceDisclaimer, ')
          ..write('lastDisclaimerAcceptedAt: $lastDisclaimerAcceptedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoodCheckinsTableTable extends MoodCheckinsTable
    with TableInfo<$MoodCheckinsTableTable, MoodCheckinsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodCheckinsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enrollmentIdMeta =
      const VerificationMeta('enrollmentId');
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
      'enrollment_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
      'day_key', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
      'mood', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<int> energy = GeneratedColumn<int>(
      'energy', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stressMeta = const VerificationMeta('stress');
  @override
  late final GeneratedColumn<int> stress = GeneratedColumn<int>(
      'stress', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        enrollmentId,
        sessionId,
        recordedAt,
        dayKey,
        mood,
        energy,
        stress,
        note,
        source,
        subjectProfileId,
        needsSync,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_checkins';
  @override
  VerificationContext validateIntegrity(
      Insertable<MoodCheckinsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
          _enrollmentIdMeta,
          enrollmentId.isAcceptableOrUnknown(
              data['enrollment_id']!, _enrollmentIdMeta));
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(_dayKeyMeta,
          dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta));
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('energy')) {
      context.handle(_energyMeta,
          energy.isAcceptableOrUnknown(data['energy']!, _energyMeta));
    }
    if (data.containsKey('stress')) {
      context.handle(_stressMeta,
          stress.isAcceptableOrUnknown(data['stress']!, _stressMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodCheckinsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodCheckinsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      enrollmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enrollment_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      dayKey: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_key'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood']),
      energy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy']),
      stress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stress']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id']),
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MoodCheckinsTableTable createAlias(String alias) {
    return $MoodCheckinsTableTable(attachedDatabase, alias);
  }
}

class MoodCheckinsTableData extends DataClass
    implements Insertable<MoodCheckinsTableData> {
  final String id;
  final String userId;
  final String enrollmentId;
  final String? sessionId;
  final DateTime recordedAt;
  final int dayKey;
  final int? mood;
  final int? energy;
  final int? stress;
  final String? note;
  final String source;
  final String? subjectProfileId;
  final bool needsSync;
  final DateTime createdAt;
  const MoodCheckinsTableData(
      {required this.id,
      required this.userId,
      required this.enrollmentId,
      this.sessionId,
      required this.recordedAt,
      required this.dayKey,
      this.mood,
      this.energy,
      this.stress,
      this.note,
      required this.source,
      this.subjectProfileId,
      required this.needsSync,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['enrollment_id'] = Variable<String>(enrollmentId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['day_key'] = Variable<int>(dayKey);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || energy != null) {
      map['energy'] = Variable<int>(energy);
    }
    if (!nullToAbsent || stress != null) {
      map['stress'] = Variable<int>(stress);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || subjectProfileId != null) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MoodCheckinsTableCompanion toCompanion(bool nullToAbsent) {
    return MoodCheckinsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      enrollmentId: Value(enrollmentId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      recordedAt: Value(recordedAt),
      dayKey: Value(dayKey),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      energy:
          energy == null && nullToAbsent ? const Value.absent() : Value(energy),
      stress:
          stress == null && nullToAbsent ? const Value.absent() : Value(stress),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      source: Value(source),
      subjectProfileId: subjectProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectProfileId),
      needsSync: Value(needsSync),
      createdAt: Value(createdAt),
    );
  }

  factory MoodCheckinsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodCheckinsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      mood: serializer.fromJson<int?>(json['mood']),
      energy: serializer.fromJson<int?>(json['energy']),
      stress: serializer.fromJson<int?>(json['stress']),
      note: serializer.fromJson<String?>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      subjectProfileId: serializer.fromJson<String?>(json['subjectProfileId']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'dayKey': serializer.toJson<int>(dayKey),
      'mood': serializer.toJson<int?>(mood),
      'energy': serializer.toJson<int?>(energy),
      'stress': serializer.toJson<int?>(stress),
      'note': serializer.toJson<String?>(note),
      'source': serializer.toJson<String>(source),
      'subjectProfileId': serializer.toJson<String?>(subjectProfileId),
      'needsSync': serializer.toJson<bool>(needsSync),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MoodCheckinsTableData copyWith(
          {String? id,
          String? userId,
          String? enrollmentId,
          Value<String?> sessionId = const Value.absent(),
          DateTime? recordedAt,
          int? dayKey,
          Value<int?> mood = const Value.absent(),
          Value<int?> energy = const Value.absent(),
          Value<int?> stress = const Value.absent(),
          Value<String?> note = const Value.absent(),
          String? source,
          Value<String?> subjectProfileId = const Value.absent(),
          bool? needsSync,
          DateTime? createdAt}) =>
      MoodCheckinsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        enrollmentId: enrollmentId ?? this.enrollmentId,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        recordedAt: recordedAt ?? this.recordedAt,
        dayKey: dayKey ?? this.dayKey,
        mood: mood.present ? mood.value : this.mood,
        energy: energy.present ? energy.value : this.energy,
        stress: stress.present ? stress.value : this.stress,
        note: note.present ? note.value : this.note,
        source: source ?? this.source,
        subjectProfileId: subjectProfileId.present
            ? subjectProfileId.value
            : this.subjectProfileId,
        needsSync: needsSync ?? this.needsSync,
        createdAt: createdAt ?? this.createdAt,
      );
  MoodCheckinsTableData copyWithCompanion(MoodCheckinsTableCompanion data) {
    return MoodCheckinsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      mood: data.mood.present ? data.mood.value : this.mood,
      energy: data.energy.present ? data.energy.value : this.energy,
      stress: data.stress.present ? data.stress.value : this.stress,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodCheckinsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('sessionId: $sessionId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayKey: $dayKey, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('stress: $stress, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('needsSync: $needsSync, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      enrollmentId,
      sessionId,
      recordedAt,
      dayKey,
      mood,
      energy,
      stress,
      note,
      source,
      subjectProfileId,
      needsSync,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodCheckinsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.enrollmentId == this.enrollmentId &&
          other.sessionId == this.sessionId &&
          other.recordedAt == this.recordedAt &&
          other.dayKey == this.dayKey &&
          other.mood == this.mood &&
          other.energy == this.energy &&
          other.stress == this.stress &&
          other.note == this.note &&
          other.source == this.source &&
          other.subjectProfileId == this.subjectProfileId &&
          other.needsSync == this.needsSync &&
          other.createdAt == this.createdAt);
}

class MoodCheckinsTableCompanion
    extends UpdateCompanion<MoodCheckinsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> enrollmentId;
  final Value<String?> sessionId;
  final Value<DateTime> recordedAt;
  final Value<int> dayKey;
  final Value<int?> mood;
  final Value<int?> energy;
  final Value<int?> stress;
  final Value<String?> note;
  final Value<String> source;
  final Value<String?> subjectProfileId;
  final Value<bool> needsSync;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MoodCheckinsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.stress = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoodCheckinsTableCompanion.insert({
    required String id,
    required String userId,
    required String enrollmentId,
    this.sessionId = const Value.absent(),
    required DateTime recordedAt,
    required int dayKey,
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.stress = const Value.absent(),
    this.note = const Value.absent(),
    required String source,
    this.subjectProfileId = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        enrollmentId = Value(enrollmentId),
        recordedAt = Value(recordedAt),
        dayKey = Value(dayKey),
        source = Value(source);
  static Insertable<MoodCheckinsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? enrollmentId,
    Expression<String>? sessionId,
    Expression<DateTime>? recordedAt,
    Expression<int>? dayKey,
    Expression<int>? mood,
    Expression<int>? energy,
    Expression<int>? stress,
    Expression<String>? note,
    Expression<String>? source,
    Expression<String>? subjectProfileId,
    Expression<bool>? needsSync,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (sessionId != null) 'session_id': sessionId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (dayKey != null) 'day_key': dayKey,
      if (mood != null) 'mood': mood,
      if (energy != null) 'energy': energy,
      if (stress != null) 'stress': stress,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (needsSync != null) 'needs_sync': needsSync,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoodCheckinsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? enrollmentId,
      Value<String?>? sessionId,
      Value<DateTime>? recordedAt,
      Value<int>? dayKey,
      Value<int?>? mood,
      Value<int?>? energy,
      Value<int?>? stress,
      Value<String?>? note,
      Value<String>? source,
      Value<String?>? subjectProfileId,
      Value<bool>? needsSync,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MoodCheckinsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      sessionId: sessionId ?? this.sessionId,
      recordedAt: recordedAt ?? this.recordedAt,
      dayKey: dayKey ?? this.dayKey,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      stress: stress ?? this.stress,
      note: note ?? this.note,
      source: source ?? this.source,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      needsSync: needsSync ?? this.needsSync,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (energy.present) {
      map['energy'] = Variable<int>(energy.value);
    }
    if (stress.present) {
      map['stress'] = Variable<int>(stress.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodCheckinsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('sessionId: $sessionId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayKey: $dayKey, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('stress: $stress, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('needsSync: $needsSync, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncJobsTableTable extends SyncJobsTable
    with TableInfo<$SyncJobsTableTable, SyncJobsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncJobsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tableName_Meta =
      const VerificationMeta('tableName_');
  @override
  late final GeneratedColumn<String> tableName_ = GeneratedColumn<String>(
      'table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        action,
        tableName_,
        recordId,
        payload,
        retryCount,
        createdAt,
        lastAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncJobsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
          _tableName_Meta,
          tableName_.isAcceptableOrUnknown(
              data['table_name']!, _tableName_Meta));
    } else if (isInserting) {
      context.missing(_tableName_Meta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncJobsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncJobsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      tableName_: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
    );
  }

  @override
  $SyncJobsTableTable createAlias(String alias) {
    return $SyncJobsTableTable(attachedDatabase, alias);
  }
}

class SyncJobsTableData extends DataClass
    implements Insertable<SyncJobsTableData> {
  final String id;
  final String action;
  final String tableName_;
  final String recordId;
  final String payload;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  const SyncJobsTableData(
      {required this.id,
      required this.action,
      required this.tableName_,
      required this.recordId,
      required this.payload,
      required this.retryCount,
      required this.createdAt,
      this.lastAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['action'] = Variable<String>(action);
    map['table_name'] = Variable<String>(tableName_);
    map['record_id'] = Variable<String>(recordId);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  SyncJobsTableCompanion toCompanion(bool nullToAbsent) {
    return SyncJobsTableCompanion(
      id: Value(id),
      action: Value(action),
      tableName_: Value(tableName_),
      recordId: Value(recordId),
      payload: Value(payload),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory SyncJobsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncJobsTableData(
      id: serializer.fromJson<String>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      tableName_: serializer.fromJson<String>(json['tableName_']),
      recordId: serializer.fromJson<String>(json['recordId']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'action': serializer.toJson<String>(action),
      'tableName_': serializer.toJson<String>(tableName_),
      'recordId': serializer.toJson<String>(recordId),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  SyncJobsTableData copyWith(
          {String? id,
          String? action,
          String? tableName_,
          String? recordId,
          String? payload,
          int? retryCount,
          DateTime? createdAt,
          Value<DateTime?> lastAttemptAt = const Value.absent()}) =>
      SyncJobsTableData(
        id: id ?? this.id,
        action: action ?? this.action,
        tableName_: tableName_ ?? this.tableName_,
        recordId: recordId ?? this.recordId,
        payload: payload ?? this.payload,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
      );
  SyncJobsTableData copyWithCompanion(SyncJobsTableCompanion data) {
    return SyncJobsTableData(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      tableName_:
          data.tableName_.present ? data.tableName_.value : this.tableName_,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncJobsTableData(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('tableName_: $tableName_, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, action, tableName_, recordId, payload,
      retryCount, createdAt, lastAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncJobsTableData &&
          other.id == this.id &&
          other.action == this.action &&
          other.tableName_ == this.tableName_ &&
          other.recordId == this.recordId &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class SyncJobsTableCompanion extends UpdateCompanion<SyncJobsTableData> {
  final Value<String> id;
  final Value<String> action;
  final Value<String> tableName_;
  final Value<String> recordId;
  final Value<String> payload;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const SyncJobsTableCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.tableName_ = const Value.absent(),
    this.recordId = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncJobsTableCompanion.insert({
    required String id,
    required String action,
    required String tableName_,
    required String recordId,
    required String payload,
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        action = Value(action),
        tableName_ = Value(tableName_),
        recordId = Value(recordId),
        payload = Value(payload);
  static Insertable<SyncJobsTableData> custom({
    Expression<String>? id,
    Expression<String>? action,
    Expression<String>? tableName_,
    Expression<String>? recordId,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (tableName_ != null) 'table_name': tableName_,
      if (recordId != null) 'record_id': recordId,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncJobsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? action,
      Value<String>? tableName_,
      Value<String>? recordId,
      Value<String>? payload,
      Value<int>? retryCount,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastAttemptAt,
      Value<int>? rowid}) {
    return SyncJobsTableCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      tableName_: tableName_ ?? this.tableName_,
      recordId: recordId ?? this.recordId,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (tableName_.present) {
      map['table_name'] = Variable<String>(tableName_.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncJobsTableCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('tableName_: $tableName_, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakeAssessmentsTableTable extends IntakeAssessmentsTable
    with TableInfo<$IntakeAssessmentsTableTable, IntakeAssessmentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeAssessmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enrollmentIdMeta =
      const VerificationMeta('enrollmentId');
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
      'enrollment_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hadIsometricWithTrainerMeta =
      const VerificationMeta('hadIsometricWithTrainer');
  @override
  late final GeneratedColumn<bool> hadIsometricWithTrainer =
      GeneratedColumn<bool>('had_isometric_with_trainer', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("had_isometric_with_trainer" IN (0, 1))'));
  static const VerificationMeta _additionalAnswersMeta =
      const VerificationMeta('additionalAnswers');
  @override
  late final GeneratedColumn<String> additionalAnswers =
      GeneratedColumn<String>('additional_answers', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recommendedDurationWeeksMeta =
      const VerificationMeta('recommendedDurationWeeks');
  @override
  late final GeneratedColumn<int> recommendedDurationWeeks =
      GeneratedColumn<int>('recommended_duration_weeks', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _userAcceptedRecommendationMeta =
      const VerificationMeta('userAcceptedRecommendation');
  @override
  late final GeneratedColumn<bool> userAcceptedRecommendation =
      GeneratedColumn<bool>('user_accepted_recommendation', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("user_accepted_recommendation" IN (0, 1))'));
  static const VerificationMeta _finalDurationWeeksMeta =
      const VerificationMeta('finalDurationWeeks');
  @override
  late final GeneratedColumn<int> finalDurationWeeks = GeneratedColumn<int>(
      'final_duration_weeks', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        enrollmentId,
        hadIsometricWithTrainer,
        additionalAnswers,
        recommendedDurationWeeks,
        userAcceptedRecommendation,
        finalDurationWeeks,
        needsSync,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_assessments';
  @override
  VerificationContext validateIntegrity(
      Insertable<IntakeAssessmentsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
          _enrollmentIdMeta,
          enrollmentId.isAcceptableOrUnknown(
              data['enrollment_id']!, _enrollmentIdMeta));
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('had_isometric_with_trainer')) {
      context.handle(
          _hadIsometricWithTrainerMeta,
          hadIsometricWithTrainer.isAcceptableOrUnknown(
              data['had_isometric_with_trainer']!,
              _hadIsometricWithTrainerMeta));
    } else if (isInserting) {
      context.missing(_hadIsometricWithTrainerMeta);
    }
    if (data.containsKey('additional_answers')) {
      context.handle(
          _additionalAnswersMeta,
          additionalAnswers.isAcceptableOrUnknown(
              data['additional_answers']!, _additionalAnswersMeta));
    }
    if (data.containsKey('recommended_duration_weeks')) {
      context.handle(
          _recommendedDurationWeeksMeta,
          recommendedDurationWeeks.isAcceptableOrUnknown(
              data['recommended_duration_weeks']!,
              _recommendedDurationWeeksMeta));
    } else if (isInserting) {
      context.missing(_recommendedDurationWeeksMeta);
    }
    if (data.containsKey('user_accepted_recommendation')) {
      context.handle(
          _userAcceptedRecommendationMeta,
          userAcceptedRecommendation.isAcceptableOrUnknown(
              data['user_accepted_recommendation']!,
              _userAcceptedRecommendationMeta));
    } else if (isInserting) {
      context.missing(_userAcceptedRecommendationMeta);
    }
    if (data.containsKey('final_duration_weeks')) {
      context.handle(
          _finalDurationWeeksMeta,
          finalDurationWeeks.isAcceptableOrUnknown(
              data['final_duration_weeks']!, _finalDurationWeeksMeta));
    } else if (isInserting) {
      context.missing(_finalDurationWeeksMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntakeAssessmentsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeAssessmentsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      enrollmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enrollment_id'])!,
      hadIsometricWithTrainer: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}had_isometric_with_trainer'])!,
      additionalAnswers: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}additional_answers']),
      recommendedDurationWeeks: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recommended_duration_weeks'])!,
      userAcceptedRecommendation: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}user_accepted_recommendation'])!,
      finalDurationWeeks: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}final_duration_weeks'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
    );
  }

  @override
  $IntakeAssessmentsTableTable createAlias(String alias) {
    return $IntakeAssessmentsTableTable(attachedDatabase, alias);
  }
}

class IntakeAssessmentsTableData extends DataClass
    implements Insertable<IntakeAssessmentsTableData> {
  final String id;
  final String enrollmentId;
  final bool hadIsometricWithTrainer;
  final String? additionalAnswers;
  final int recommendedDurationWeeks;
  final bool userAcceptedRecommendation;
  final int finalDurationWeeks;
  final bool needsSync;
  final DateTime completedAt;
  const IntakeAssessmentsTableData(
      {required this.id,
      required this.enrollmentId,
      required this.hadIsometricWithTrainer,
      this.additionalAnswers,
      required this.recommendedDurationWeeks,
      required this.userAcceptedRecommendation,
      required this.finalDurationWeeks,
      required this.needsSync,
      required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['enrollment_id'] = Variable<String>(enrollmentId);
    map['had_isometric_with_trainer'] = Variable<bool>(hadIsometricWithTrainer);
    if (!nullToAbsent || additionalAnswers != null) {
      map['additional_answers'] = Variable<String>(additionalAnswers);
    }
    map['recommended_duration_weeks'] = Variable<int>(recommendedDurationWeeks);
    map['user_accepted_recommendation'] =
        Variable<bool>(userAcceptedRecommendation);
    map['final_duration_weeks'] = Variable<int>(finalDurationWeeks);
    map['needs_sync'] = Variable<bool>(needsSync);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  IntakeAssessmentsTableCompanion toCompanion(bool nullToAbsent) {
    return IntakeAssessmentsTableCompanion(
      id: Value(id),
      enrollmentId: Value(enrollmentId),
      hadIsometricWithTrainer: Value(hadIsometricWithTrainer),
      additionalAnswers: additionalAnswers == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalAnswers),
      recommendedDurationWeeks: Value(recommendedDurationWeeks),
      userAcceptedRecommendation: Value(userAcceptedRecommendation),
      finalDurationWeeks: Value(finalDurationWeeks),
      needsSync: Value(needsSync),
      completedAt: Value(completedAt),
    );
  }

  factory IntakeAssessmentsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeAssessmentsTableData(
      id: serializer.fromJson<String>(json['id']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      hadIsometricWithTrainer:
          serializer.fromJson<bool>(json['hadIsometricWithTrainer']),
      additionalAnswers:
          serializer.fromJson<String?>(json['additionalAnswers']),
      recommendedDurationWeeks:
          serializer.fromJson<int>(json['recommendedDurationWeeks']),
      userAcceptedRecommendation:
          serializer.fromJson<bool>(json['userAcceptedRecommendation']),
      finalDurationWeeks: serializer.fromJson<int>(json['finalDurationWeeks']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'hadIsometricWithTrainer':
          serializer.toJson<bool>(hadIsometricWithTrainer),
      'additionalAnswers': serializer.toJson<String?>(additionalAnswers),
      'recommendedDurationWeeks':
          serializer.toJson<int>(recommendedDurationWeeks),
      'userAcceptedRecommendation':
          serializer.toJson<bool>(userAcceptedRecommendation),
      'finalDurationWeeks': serializer.toJson<int>(finalDurationWeeks),
      'needsSync': serializer.toJson<bool>(needsSync),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  IntakeAssessmentsTableData copyWith(
          {String? id,
          String? enrollmentId,
          bool? hadIsometricWithTrainer,
          Value<String?> additionalAnswers = const Value.absent(),
          int? recommendedDurationWeeks,
          bool? userAcceptedRecommendation,
          int? finalDurationWeeks,
          bool? needsSync,
          DateTime? completedAt}) =>
      IntakeAssessmentsTableData(
        id: id ?? this.id,
        enrollmentId: enrollmentId ?? this.enrollmentId,
        hadIsometricWithTrainer:
            hadIsometricWithTrainer ?? this.hadIsometricWithTrainer,
        additionalAnswers: additionalAnswers.present
            ? additionalAnswers.value
            : this.additionalAnswers,
        recommendedDurationWeeks:
            recommendedDurationWeeks ?? this.recommendedDurationWeeks,
        userAcceptedRecommendation:
            userAcceptedRecommendation ?? this.userAcceptedRecommendation,
        finalDurationWeeks: finalDurationWeeks ?? this.finalDurationWeeks,
        needsSync: needsSync ?? this.needsSync,
        completedAt: completedAt ?? this.completedAt,
      );
  IntakeAssessmentsTableData copyWithCompanion(
      IntakeAssessmentsTableCompanion data) {
    return IntakeAssessmentsTableData(
      id: data.id.present ? data.id.value : this.id,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      hadIsometricWithTrainer: data.hadIsometricWithTrainer.present
          ? data.hadIsometricWithTrainer.value
          : this.hadIsometricWithTrainer,
      additionalAnswers: data.additionalAnswers.present
          ? data.additionalAnswers.value
          : this.additionalAnswers,
      recommendedDurationWeeks: data.recommendedDurationWeeks.present
          ? data.recommendedDurationWeeks.value
          : this.recommendedDurationWeeks,
      userAcceptedRecommendation: data.userAcceptedRecommendation.present
          ? data.userAcceptedRecommendation.value
          : this.userAcceptedRecommendation,
      finalDurationWeeks: data.finalDurationWeeks.present
          ? data.finalDurationWeeks.value
          : this.finalDurationWeeks,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeAssessmentsTableData(')
          ..write('id: $id, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('hadIsometricWithTrainer: $hadIsometricWithTrainer, ')
          ..write('additionalAnswers: $additionalAnswers, ')
          ..write('recommendedDurationWeeks: $recommendedDurationWeeks, ')
          ..write('userAcceptedRecommendation: $userAcceptedRecommendation, ')
          ..write('finalDurationWeeks: $finalDurationWeeks, ')
          ..write('needsSync: $needsSync, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      enrollmentId,
      hadIsometricWithTrainer,
      additionalAnswers,
      recommendedDurationWeeks,
      userAcceptedRecommendation,
      finalDurationWeeks,
      needsSync,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeAssessmentsTableData &&
          other.id == this.id &&
          other.enrollmentId == this.enrollmentId &&
          other.hadIsometricWithTrainer == this.hadIsometricWithTrainer &&
          other.additionalAnswers == this.additionalAnswers &&
          other.recommendedDurationWeeks == this.recommendedDurationWeeks &&
          other.userAcceptedRecommendation == this.userAcceptedRecommendation &&
          other.finalDurationWeeks == this.finalDurationWeeks &&
          other.needsSync == this.needsSync &&
          other.completedAt == this.completedAt);
}

class IntakeAssessmentsTableCompanion
    extends UpdateCompanion<IntakeAssessmentsTableData> {
  final Value<String> id;
  final Value<String> enrollmentId;
  final Value<bool> hadIsometricWithTrainer;
  final Value<String?> additionalAnswers;
  final Value<int> recommendedDurationWeeks;
  final Value<bool> userAcceptedRecommendation;
  final Value<int> finalDurationWeeks;
  final Value<bool> needsSync;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const IntakeAssessmentsTableCompanion({
    this.id = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.hadIsometricWithTrainer = const Value.absent(),
    this.additionalAnswers = const Value.absent(),
    this.recommendedDurationWeeks = const Value.absent(),
    this.userAcceptedRecommendation = const Value.absent(),
    this.finalDurationWeeks = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeAssessmentsTableCompanion.insert({
    required String id,
    required String enrollmentId,
    required bool hadIsometricWithTrainer,
    this.additionalAnswers = const Value.absent(),
    required int recommendedDurationWeeks,
    required bool userAcceptedRecommendation,
    required int finalDurationWeeks,
    this.needsSync = const Value.absent(),
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        enrollmentId = Value(enrollmentId),
        hadIsometricWithTrainer = Value(hadIsometricWithTrainer),
        recommendedDurationWeeks = Value(recommendedDurationWeeks),
        userAcceptedRecommendation = Value(userAcceptedRecommendation),
        finalDurationWeeks = Value(finalDurationWeeks),
        completedAt = Value(completedAt);
  static Insertable<IntakeAssessmentsTableData> custom({
    Expression<String>? id,
    Expression<String>? enrollmentId,
    Expression<bool>? hadIsometricWithTrainer,
    Expression<String>? additionalAnswers,
    Expression<int>? recommendedDurationWeeks,
    Expression<bool>? userAcceptedRecommendation,
    Expression<int>? finalDurationWeeks,
    Expression<bool>? needsSync,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (hadIsometricWithTrainer != null)
        'had_isometric_with_trainer': hadIsometricWithTrainer,
      if (additionalAnswers != null) 'additional_answers': additionalAnswers,
      if (recommendedDurationWeeks != null)
        'recommended_duration_weeks': recommendedDurationWeeks,
      if (userAcceptedRecommendation != null)
        'user_accepted_recommendation': userAcceptedRecommendation,
      if (finalDurationWeeks != null)
        'final_duration_weeks': finalDurationWeeks,
      if (needsSync != null) 'needs_sync': needsSync,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeAssessmentsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? enrollmentId,
      Value<bool>? hadIsometricWithTrainer,
      Value<String?>? additionalAnswers,
      Value<int>? recommendedDurationWeeks,
      Value<bool>? userAcceptedRecommendation,
      Value<int>? finalDurationWeeks,
      Value<bool>? needsSync,
      Value<DateTime>? completedAt,
      Value<int>? rowid}) {
    return IntakeAssessmentsTableCompanion(
      id: id ?? this.id,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      hadIsometricWithTrainer:
          hadIsometricWithTrainer ?? this.hadIsometricWithTrainer,
      additionalAnswers: additionalAnswers ?? this.additionalAnswers,
      recommendedDurationWeeks:
          recommendedDurationWeeks ?? this.recommendedDurationWeeks,
      userAcceptedRecommendation:
          userAcceptedRecommendation ?? this.userAcceptedRecommendation,
      finalDurationWeeks: finalDurationWeeks ?? this.finalDurationWeeks,
      needsSync: needsSync ?? this.needsSync,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (hadIsometricWithTrainer.present) {
      map['had_isometric_with_trainer'] =
          Variable<bool>(hadIsometricWithTrainer.value);
    }
    if (additionalAnswers.present) {
      map['additional_answers'] = Variable<String>(additionalAnswers.value);
    }
    if (recommendedDurationWeeks.present) {
      map['recommended_duration_weeks'] =
          Variable<int>(recommendedDurationWeeks.value);
    }
    if (userAcceptedRecommendation.present) {
      map['user_accepted_recommendation'] =
          Variable<bool>(userAcceptedRecommendation.value);
    }
    if (finalDurationWeeks.present) {
      map['final_duration_weeks'] = Variable<int>(finalDurationWeeks.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeAssessmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('hadIsometricWithTrainer: $hadIsometricWithTrainer, ')
          ..write('additionalAnswers: $additionalAnswers, ')
          ..write('recommendedDurationWeeks: $recommendedDurationWeeks, ')
          ..write('userAcceptedRecommendation: $userAcceptedRecommendation, ')
          ..write('finalDurationWeeks: $finalDurationWeeks, ')
          ..write('needsSync: $needsSync, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionQuestionnairesTableTable extends CompletionQuestionnairesTable
    with
        TableInfo<$CompletionQuestionnairesTableTable,
            CompletionQuestionnairesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionQuestionnairesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enrollmentIdMeta =
      const VerificationMeta('enrollmentId');
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
      'enrollment_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptNumberMeta =
      const VerificationMeta('attemptNumber');
  @override
  late final GeneratedColumn<int> attemptNumber = GeneratedColumn<int>(
      'attempt_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _responseMeta =
      const VerificationMeta('response');
  @override
  late final GeneratedColumn<bool> response = GeneratedColumn<bool>(
      'response', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("response" IN (0, 1))'));
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nextEnrollmentCreatedMeta =
      const VerificationMeta('nextEnrollmentCreated');
  @override
  late final GeneratedColumn<bool> nextEnrollmentCreated =
      GeneratedColumn<bool>('next_enrollment_created', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("next_enrollment_created" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _submittedAtMeta =
      const VerificationMeta('submittedAt');
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
      'submitted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        enrollmentId,
        attemptNumber,
        response,
        result,
        nextEnrollmentCreated,
        needsSync,
        subjectProfileId,
        submittedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completion_questionnaires';
  @override
  VerificationContext validateIntegrity(
      Insertable<CompletionQuestionnairesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
          _enrollmentIdMeta,
          enrollmentId.isAcceptableOrUnknown(
              data['enrollment_id']!, _enrollmentIdMeta));
    } else if (isInserting) {
      context.missing(_enrollmentIdMeta);
    }
    if (data.containsKey('attempt_number')) {
      context.handle(
          _attemptNumberMeta,
          attemptNumber.isAcceptableOrUnknown(
              data['attempt_number']!, _attemptNumberMeta));
    }
    if (data.containsKey('response')) {
      context.handle(_responseMeta,
          response.isAcceptableOrUnknown(data['response']!, _responseMeta));
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('next_enrollment_created')) {
      context.handle(
          _nextEnrollmentCreatedMeta,
          nextEnrollmentCreated.isAcceptableOrUnknown(
              data['next_enrollment_created']!, _nextEnrollmentCreatedMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
          _submittedAtMeta,
          submittedAt.isAcceptableOrUnknown(
              data['submitted_at']!, _submittedAtMeta));
    } else if (isInserting) {
      context.missing(_submittedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletionQuestionnairesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletionQuestionnairesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      enrollmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enrollment_id'])!,
      attemptNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_number'])!,
      response: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}response'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      nextEnrollmentCreated: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}next_enrollment_created'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id']),
      submittedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}submitted_at'])!,
    );
  }

  @override
  $CompletionQuestionnairesTableTable createAlias(String alias) {
    return $CompletionQuestionnairesTableTable(attachedDatabase, alias);
  }
}

class CompletionQuestionnairesTableData extends DataClass
    implements Insertable<CompletionQuestionnairesTableData> {
  final String id;
  final String enrollmentId;
  final int attemptNumber;
  final bool response;
  final String result;
  final bool nextEnrollmentCreated;
  final bool needsSync;
  final String? subjectProfileId;
  final DateTime submittedAt;
  const CompletionQuestionnairesTableData(
      {required this.id,
      required this.enrollmentId,
      required this.attemptNumber,
      required this.response,
      required this.result,
      required this.nextEnrollmentCreated,
      required this.needsSync,
      this.subjectProfileId,
      required this.submittedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['enrollment_id'] = Variable<String>(enrollmentId);
    map['attempt_number'] = Variable<int>(attemptNumber);
    map['response'] = Variable<bool>(response);
    map['result'] = Variable<String>(result);
    map['next_enrollment_created'] = Variable<bool>(nextEnrollmentCreated);
    map['needs_sync'] = Variable<bool>(needsSync);
    if (!nullToAbsent || subjectProfileId != null) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId);
    }
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    return map;
  }

  CompletionQuestionnairesTableCompanion toCompanion(bool nullToAbsent) {
    return CompletionQuestionnairesTableCompanion(
      id: Value(id),
      enrollmentId: Value(enrollmentId),
      attemptNumber: Value(attemptNumber),
      response: Value(response),
      result: Value(result),
      nextEnrollmentCreated: Value(nextEnrollmentCreated),
      needsSync: Value(needsSync),
      subjectProfileId: subjectProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectProfileId),
      submittedAt: Value(submittedAt),
    );
  }

  factory CompletionQuestionnairesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletionQuestionnairesTableData(
      id: serializer.fromJson<String>(json['id']),
      enrollmentId: serializer.fromJson<String>(json['enrollmentId']),
      attemptNumber: serializer.fromJson<int>(json['attemptNumber']),
      response: serializer.fromJson<bool>(json['response']),
      result: serializer.fromJson<String>(json['result']),
      nextEnrollmentCreated:
          serializer.fromJson<bool>(json['nextEnrollmentCreated']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      subjectProfileId: serializer.fromJson<String?>(json['subjectProfileId']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'enrollmentId': serializer.toJson<String>(enrollmentId),
      'attemptNumber': serializer.toJson<int>(attemptNumber),
      'response': serializer.toJson<bool>(response),
      'result': serializer.toJson<String>(result),
      'nextEnrollmentCreated': serializer.toJson<bool>(nextEnrollmentCreated),
      'needsSync': serializer.toJson<bool>(needsSync),
      'subjectProfileId': serializer.toJson<String?>(subjectProfileId),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
    };
  }

  CompletionQuestionnairesTableData copyWith(
          {String? id,
          String? enrollmentId,
          int? attemptNumber,
          bool? response,
          String? result,
          bool? nextEnrollmentCreated,
          bool? needsSync,
          Value<String?> subjectProfileId = const Value.absent(),
          DateTime? submittedAt}) =>
      CompletionQuestionnairesTableData(
        id: id ?? this.id,
        enrollmentId: enrollmentId ?? this.enrollmentId,
        attemptNumber: attemptNumber ?? this.attemptNumber,
        response: response ?? this.response,
        result: result ?? this.result,
        nextEnrollmentCreated:
            nextEnrollmentCreated ?? this.nextEnrollmentCreated,
        needsSync: needsSync ?? this.needsSync,
        subjectProfileId: subjectProfileId.present
            ? subjectProfileId.value
            : this.subjectProfileId,
        submittedAt: submittedAt ?? this.submittedAt,
      );
  CompletionQuestionnairesTableData copyWithCompanion(
      CompletionQuestionnairesTableCompanion data) {
    return CompletionQuestionnairesTableData(
      id: data.id.present ? data.id.value : this.id,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      attemptNumber: data.attemptNumber.present
          ? data.attemptNumber.value
          : this.attemptNumber,
      response: data.response.present ? data.response.value : this.response,
      result: data.result.present ? data.result.value : this.result,
      nextEnrollmentCreated: data.nextEnrollmentCreated.present
          ? data.nextEnrollmentCreated.value
          : this.nextEnrollmentCreated,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      submittedAt:
          data.submittedAt.present ? data.submittedAt.value : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletionQuestionnairesTableData(')
          ..write('id: $id, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('response: $response, ')
          ..write('result: $result, ')
          ..write('nextEnrollmentCreated: $nextEnrollmentCreated, ')
          ..write('needsSync: $needsSync, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, enrollmentId, attemptNumber, response,
      result, nextEnrollmentCreated, needsSync, subjectProfileId, submittedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletionQuestionnairesTableData &&
          other.id == this.id &&
          other.enrollmentId == this.enrollmentId &&
          other.attemptNumber == this.attemptNumber &&
          other.response == this.response &&
          other.result == this.result &&
          other.nextEnrollmentCreated == this.nextEnrollmentCreated &&
          other.needsSync == this.needsSync &&
          other.subjectProfileId == this.subjectProfileId &&
          other.submittedAt == this.submittedAt);
}

class CompletionQuestionnairesTableCompanion
    extends UpdateCompanion<CompletionQuestionnairesTableData> {
  final Value<String> id;
  final Value<String> enrollmentId;
  final Value<int> attemptNumber;
  final Value<bool> response;
  final Value<String> result;
  final Value<bool> nextEnrollmentCreated;
  final Value<bool> needsSync;
  final Value<String?> subjectProfileId;
  final Value<DateTime> submittedAt;
  final Value<int> rowid;
  const CompletionQuestionnairesTableCompanion({
    this.id = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.attemptNumber = const Value.absent(),
    this.response = const Value.absent(),
    this.result = const Value.absent(),
    this.nextEnrollmentCreated = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionQuestionnairesTableCompanion.insert({
    required String id,
    required String enrollmentId,
    this.attemptNumber = const Value.absent(),
    required bool response,
    required String result,
    this.nextEnrollmentCreated = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    required DateTime submittedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        enrollmentId = Value(enrollmentId),
        response = Value(response),
        result = Value(result),
        submittedAt = Value(submittedAt);
  static Insertable<CompletionQuestionnairesTableData> custom({
    Expression<String>? id,
    Expression<String>? enrollmentId,
    Expression<int>? attemptNumber,
    Expression<bool>? response,
    Expression<String>? result,
    Expression<bool>? nextEnrollmentCreated,
    Expression<bool>? needsSync,
    Expression<String>? subjectProfileId,
    Expression<DateTime>? submittedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (attemptNumber != null) 'attempt_number': attemptNumber,
      if (response != null) 'response': response,
      if (result != null) 'result': result,
      if (nextEnrollmentCreated != null)
        'next_enrollment_created': nextEnrollmentCreated,
      if (needsSync != null) 'needs_sync': needsSync,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionQuestionnairesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? enrollmentId,
      Value<int>? attemptNumber,
      Value<bool>? response,
      Value<String>? result,
      Value<bool>? nextEnrollmentCreated,
      Value<bool>? needsSync,
      Value<String?>? subjectProfileId,
      Value<DateTime>? submittedAt,
      Value<int>? rowid}) {
    return CompletionQuestionnairesTableCompanion(
      id: id ?? this.id,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      response: response ?? this.response,
      result: result ?? this.result,
      nextEnrollmentCreated:
          nextEnrollmentCreated ?? this.nextEnrollmentCreated,
      needsSync: needsSync ?? this.needsSync,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      submittedAt: submittedAt ?? this.submittedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (attemptNumber.present) {
      map['attempt_number'] = Variable<int>(attemptNumber.value);
    }
    if (response.present) {
      map['response'] = Variable<bool>(response.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (nextEnrollmentCreated.present) {
      map['next_enrollment_created'] =
          Variable<bool>(nextEnrollmentCreated.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionQuestionnairesTableCompanion(')
          ..write('id: $id, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('response: $response, ')
          ..write('result: $result, ')
          ..write('nextEnrollmentCreated: $nextEnrollmentCreated, ')
          ..write('needsSync: $needsSync, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTableTable extends JournalEntriesTable
    with TableInfo<$JournalEntriesTableTable, JournalEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enrollmentIdMeta =
      const VerificationMeta('enrollmentId');
  @override
  late final GeneratedColumn<String> enrollmentId = GeneratedColumn<String>(
      'enrollment_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkinIdMeta =
      const VerificationMeta('checkinId');
  @override
  late final GeneratedColumn<String> checkinId = GeneratedColumn<String>(
      'checkin_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
      'mood', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<int> energy = GeneratedColumn<int>(
      'energy', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stressMeta = const VerificationMeta('stress');
  @override
  late final GeneratedColumn<int> stress = GeneratedColumn<int>(
      'stress', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
      'day_key', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        enrollmentId,
        checkinId,
        content,
        mood,
        energy,
        stress,
        dayKey,
        createdAt,
        updatedAt,
        subjectProfileId,
        needsSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<JournalEntriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('enrollment_id')) {
      context.handle(
          _enrollmentIdMeta,
          enrollmentId.isAcceptableOrUnknown(
              data['enrollment_id']!, _enrollmentIdMeta));
    }
    if (data.containsKey('checkin_id')) {
      context.handle(_checkinIdMeta,
          checkinId.isAcceptableOrUnknown(data['checkin_id']!, _checkinIdMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('energy')) {
      context.handle(_energyMeta,
          energy.isAcceptableOrUnknown(data['energy']!, _energyMeta));
    }
    if (data.containsKey('stress')) {
      context.handle(_stressMeta,
          stress.isAcceptableOrUnknown(data['stress']!, _stressMeta));
    }
    if (data.containsKey('day_key')) {
      context.handle(_dayKeyMeta,
          dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta));
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntriesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      enrollmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enrollment_id']),
      checkinId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checkin_id']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood']),
      energy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy']),
      stress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stress']),
      dayKey: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id']),
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
    );
  }

  @override
  $JournalEntriesTableTable createAlias(String alias) {
    return $JournalEntriesTableTable(attachedDatabase, alias);
  }
}

class JournalEntriesTableData extends DataClass
    implements Insertable<JournalEntriesTableData> {
  final String id;
  final String userId;
  final String? enrollmentId;

  /// FK to the mood_checkin that was submitted alongside this note, or null for
  /// standalone entries.
  final String? checkinId;
  final String content;

  /// Snapshot of mood at the time of writing (1–5, nullable).
  final int? mood;
  final int? energy;
  final int? stress;

  /// Epoch-day key (days since 1970-01-01) — matches mood_checkins.day_key.
  final int dayKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subjectProfileId;
  final bool needsSync;
  const JournalEntriesTableData(
      {required this.id,
      required this.userId,
      this.enrollmentId,
      this.checkinId,
      required this.content,
      this.mood,
      this.energy,
      this.stress,
      required this.dayKey,
      required this.createdAt,
      required this.updatedAt,
      this.subjectProfileId,
      required this.needsSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || enrollmentId != null) {
      map['enrollment_id'] = Variable<String>(enrollmentId);
    }
    if (!nullToAbsent || checkinId != null) {
      map['checkin_id'] = Variable<String>(checkinId);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || energy != null) {
      map['energy'] = Variable<int>(energy);
    }
    if (!nullToAbsent || stress != null) {
      map['stress'] = Variable<int>(stress);
    }
    map['day_key'] = Variable<int>(dayKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || subjectProfileId != null) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  JournalEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      enrollmentId: enrollmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(enrollmentId),
      checkinId: checkinId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkinId),
      content: Value(content),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      energy:
          energy == null && nullToAbsent ? const Value.absent() : Value(energy),
      stress:
          stress == null && nullToAbsent ? const Value.absent() : Value(stress),
      dayKey: Value(dayKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      subjectProfileId: subjectProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectProfileId),
      needsSync: Value(needsSync),
    );
  }

  factory JournalEntriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      enrollmentId: serializer.fromJson<String?>(json['enrollmentId']),
      checkinId: serializer.fromJson<String?>(json['checkinId']),
      content: serializer.fromJson<String>(json['content']),
      mood: serializer.fromJson<int?>(json['mood']),
      energy: serializer.fromJson<int?>(json['energy']),
      stress: serializer.fromJson<int?>(json['stress']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      subjectProfileId: serializer.fromJson<String?>(json['subjectProfileId']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'enrollmentId': serializer.toJson<String?>(enrollmentId),
      'checkinId': serializer.toJson<String?>(checkinId),
      'content': serializer.toJson<String>(content),
      'mood': serializer.toJson<int?>(mood),
      'energy': serializer.toJson<int?>(energy),
      'stress': serializer.toJson<int?>(stress),
      'dayKey': serializer.toJson<int>(dayKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'subjectProfileId': serializer.toJson<String?>(subjectProfileId),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  JournalEntriesTableData copyWith(
          {String? id,
          String? userId,
          Value<String?> enrollmentId = const Value.absent(),
          Value<String?> checkinId = const Value.absent(),
          String? content,
          Value<int?> mood = const Value.absent(),
          Value<int?> energy = const Value.absent(),
          Value<int?> stress = const Value.absent(),
          int? dayKey,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<String?> subjectProfileId = const Value.absent(),
          bool? needsSync}) =>
      JournalEntriesTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        enrollmentId:
            enrollmentId.present ? enrollmentId.value : this.enrollmentId,
        checkinId: checkinId.present ? checkinId.value : this.checkinId,
        content: content ?? this.content,
        mood: mood.present ? mood.value : this.mood,
        energy: energy.present ? energy.value : this.energy,
        stress: stress.present ? stress.value : this.stress,
        dayKey: dayKey ?? this.dayKey,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        subjectProfileId: subjectProfileId.present
            ? subjectProfileId.value
            : this.subjectProfileId,
        needsSync: needsSync ?? this.needsSync,
      );
  JournalEntriesTableData copyWithCompanion(JournalEntriesTableCompanion data) {
    return JournalEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      enrollmentId: data.enrollmentId.present
          ? data.enrollmentId.value
          : this.enrollmentId,
      checkinId: data.checkinId.present ? data.checkinId.value : this.checkinId,
      content: data.content.present ? data.content.value : this.content,
      mood: data.mood.present ? data.mood.value : this.mood,
      energy: data.energy.present ? data.energy.value : this.energy,
      stress: data.stress.present ? data.stress.value : this.stress,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('checkinId: $checkinId, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('stress: $stress, ')
          ..write('dayKey: $dayKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      enrollmentId,
      checkinId,
      content,
      mood,
      energy,
      stress,
      dayKey,
      createdAt,
      updatedAt,
      subjectProfileId,
      needsSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntriesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.enrollmentId == this.enrollmentId &&
          other.checkinId == this.checkinId &&
          other.content == this.content &&
          other.mood == this.mood &&
          other.energy == this.energy &&
          other.stress == this.stress &&
          other.dayKey == this.dayKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.subjectProfileId == this.subjectProfileId &&
          other.needsSync == this.needsSync);
}

class JournalEntriesTableCompanion
    extends UpdateCompanion<JournalEntriesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> enrollmentId;
  final Value<String?> checkinId;
  final Value<String> content;
  final Value<int?> mood;
  final Value<int?> energy;
  final Value<int?> stress;
  final Value<int> dayKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> subjectProfileId;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const JournalEntriesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.enrollmentId = const Value.absent(),
    this.checkinId = const Value.absent(),
    this.content = const Value.absent(),
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.stress = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEntriesTableCompanion.insert({
    required String id,
    required String userId,
    this.enrollmentId = const Value.absent(),
    this.checkinId = const Value.absent(),
    required String content,
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.stress = const Value.absent(),
    required int dayKey,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        content = Value(content),
        dayKey = Value(dayKey);
  static Insertable<JournalEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? enrollmentId,
    Expression<String>? checkinId,
    Expression<String>? content,
    Expression<int>? mood,
    Expression<int>? energy,
    Expression<int>? stress,
    Expression<int>? dayKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? subjectProfileId,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
      if (checkinId != null) 'checkin_id': checkinId,
      if (content != null) 'content': content,
      if (mood != null) 'mood': mood,
      if (energy != null) 'energy': energy,
      if (stress != null) 'stress': stress,
      if (dayKey != null) 'day_key': dayKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEntriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? enrollmentId,
      Value<String?>? checkinId,
      Value<String>? content,
      Value<int?>? mood,
      Value<int?>? energy,
      Value<int?>? stress,
      Value<int>? dayKey,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String?>? subjectProfileId,
      Value<bool>? needsSync,
      Value<int>? rowid}) {
    return JournalEntriesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      checkinId: checkinId ?? this.checkinId,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      stress: stress ?? this.stress,
      dayKey: dayKey ?? this.dayKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (enrollmentId.present) {
      map['enrollment_id'] = Variable<String>(enrollmentId.value);
    }
    if (checkinId.present) {
      map['checkin_id'] = Variable<String>(checkinId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (energy.present) {
      map['energy'] = Variable<int>(energy.value);
    }
    if (stress.present) {
      map['stress'] = Variable<int>(stress.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('enrollmentId: $enrollmentId, ')
          ..write('checkinId: $checkinId, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('stress: $stress, ')
          ..write('dayKey: $dayKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakCreditsTableTable extends StreakCreditsTable
    with TableInfo<$StreakCreditsTableTable, StreakCreditsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakCreditsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectProfileIdMeta =
      const VerificationMeta('subjectProfileId');
  @override
  late final GeneratedColumn<String> subjectProfileId = GeneratedColumn<String>(
      'subject_profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _availableMeta =
      const VerificationMeta('available');
  @override
  late final GeneratedColumn<int> available = GeneratedColumn<int>(
      'available', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _progressToNextMeta =
      const VerificationMeta('progressToNext');
  @override
  late final GeneratedColumn<int> progressToNext = GeneratedColumn<int>(
      'progress_to_next', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastCountedDayMeta =
      const VerificationMeta('lastCountedDay');
  @override
  late final GeneratedColumn<DateTime> lastCountedDay =
      GeneratedColumn<DateTime>('last_counted_day', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _rescuedDaysMeta =
      const VerificationMeta('rescuedDays');
  @override
  late final GeneratedColumn<String> rescuedDays = GeneratedColumn<String>(
      'rescued_days', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        subjectProfileId,
        available,
        progressToNext,
        lastCountedDay,
        rescuedDays,
        needsSync,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_credits';
  @override
  VerificationContext validateIntegrity(
      Insertable<StreakCreditsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('subject_profile_id')) {
      context.handle(
          _subjectProfileIdMeta,
          subjectProfileId.isAcceptableOrUnknown(
              data['subject_profile_id']!, _subjectProfileIdMeta));
    } else if (isInserting) {
      context.missing(_subjectProfileIdMeta);
    }
    if (data.containsKey('available')) {
      context.handle(_availableMeta,
          available.isAcceptableOrUnknown(data['available']!, _availableMeta));
    }
    if (data.containsKey('progress_to_next')) {
      context.handle(
          _progressToNextMeta,
          progressToNext.isAcceptableOrUnknown(
              data['progress_to_next']!, _progressToNextMeta));
    }
    if (data.containsKey('last_counted_day')) {
      context.handle(
          _lastCountedDayMeta,
          lastCountedDay.isAcceptableOrUnknown(
              data['last_counted_day']!, _lastCountedDayMeta));
    }
    if (data.containsKey('rescued_days')) {
      context.handle(
          _rescuedDaysMeta,
          rescuedDays.isAcceptableOrUnknown(
              data['rescued_days']!, _rescuedDaysMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakCreditsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakCreditsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      subjectProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subject_profile_id'])!,
      available: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}available'])!,
      progressToNext: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress_to_next'])!,
      lastCountedDay: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_counted_day']),
      rescuedDays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rescued_days'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StreakCreditsTableTable createAlias(String alias) {
    return $StreakCreditsTableTable(attachedDatabase, alias);
  }
}

class StreakCreditsTableData extends DataClass
    implements Insertable<StreakCreditsTableData> {
  final String id;
  final String userId;
  final String subjectProfileId;

  /// Credits ready to be spent, 0..2.
  final int available;

  /// Training days counted towards the next credit, 0..2.
  final int progressToNext;

  /// Latest training day already counted, date-only.
  final DateTime? lastCountedDay;

  /// Rescued days as a JSON-encoded list of `yyyy-MM-dd` strings.
  final String rescuedDays;
  final bool needsSync;
  final DateTime updatedAt;
  const StreakCreditsTableData(
      {required this.id,
      required this.userId,
      required this.subjectProfileId,
      required this.available,
      required this.progressToNext,
      this.lastCountedDay,
      required this.rescuedDays,
      required this.needsSync,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['subject_profile_id'] = Variable<String>(subjectProfileId);
    map['available'] = Variable<int>(available);
    map['progress_to_next'] = Variable<int>(progressToNext);
    if (!nullToAbsent || lastCountedDay != null) {
      map['last_counted_day'] = Variable<DateTime>(lastCountedDay);
    }
    map['rescued_days'] = Variable<String>(rescuedDays);
    map['needs_sync'] = Variable<bool>(needsSync);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StreakCreditsTableCompanion toCompanion(bool nullToAbsent) {
    return StreakCreditsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      subjectProfileId: Value(subjectProfileId),
      available: Value(available),
      progressToNext: Value(progressToNext),
      lastCountedDay: lastCountedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCountedDay),
      rescuedDays: Value(rescuedDays),
      needsSync: Value(needsSync),
      updatedAt: Value(updatedAt),
    );
  }

  factory StreakCreditsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakCreditsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      subjectProfileId: serializer.fromJson<String>(json['subjectProfileId']),
      available: serializer.fromJson<int>(json['available']),
      progressToNext: serializer.fromJson<int>(json['progressToNext']),
      lastCountedDay: serializer.fromJson<DateTime?>(json['lastCountedDay']),
      rescuedDays: serializer.fromJson<String>(json['rescuedDays']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'subjectProfileId': serializer.toJson<String>(subjectProfileId),
      'available': serializer.toJson<int>(available),
      'progressToNext': serializer.toJson<int>(progressToNext),
      'lastCountedDay': serializer.toJson<DateTime?>(lastCountedDay),
      'rescuedDays': serializer.toJson<String>(rescuedDays),
      'needsSync': serializer.toJson<bool>(needsSync),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StreakCreditsTableData copyWith(
          {String? id,
          String? userId,
          String? subjectProfileId,
          int? available,
          int? progressToNext,
          Value<DateTime?> lastCountedDay = const Value.absent(),
          String? rescuedDays,
          bool? needsSync,
          DateTime? updatedAt}) =>
      StreakCreditsTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        subjectProfileId: subjectProfileId ?? this.subjectProfileId,
        available: available ?? this.available,
        progressToNext: progressToNext ?? this.progressToNext,
        lastCountedDay:
            lastCountedDay.present ? lastCountedDay.value : this.lastCountedDay,
        rescuedDays: rescuedDays ?? this.rescuedDays,
        needsSync: needsSync ?? this.needsSync,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StreakCreditsTableData copyWithCompanion(StreakCreditsTableCompanion data) {
    return StreakCreditsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      subjectProfileId: data.subjectProfileId.present
          ? data.subjectProfileId.value
          : this.subjectProfileId,
      available: data.available.present ? data.available.value : this.available,
      progressToNext: data.progressToNext.present
          ? data.progressToNext.value
          : this.progressToNext,
      lastCountedDay: data.lastCountedDay.present
          ? data.lastCountedDay.value
          : this.lastCountedDay,
      rescuedDays:
          data.rescuedDays.present ? data.rescuedDays.value : this.rescuedDays,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakCreditsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('available: $available, ')
          ..write('progressToNext: $progressToNext, ')
          ..write('lastCountedDay: $lastCountedDay, ')
          ..write('rescuedDays: $rescuedDays, ')
          ..write('needsSync: $needsSync, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, subjectProfileId, available,
      progressToNext, lastCountedDay, rescuedDays, needsSync, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakCreditsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.subjectProfileId == this.subjectProfileId &&
          other.available == this.available &&
          other.progressToNext == this.progressToNext &&
          other.lastCountedDay == this.lastCountedDay &&
          other.rescuedDays == this.rescuedDays &&
          other.needsSync == this.needsSync &&
          other.updatedAt == this.updatedAt);
}

class StreakCreditsTableCompanion
    extends UpdateCompanion<StreakCreditsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> subjectProfileId;
  final Value<int> available;
  final Value<int> progressToNext;
  final Value<DateTime?> lastCountedDay;
  final Value<String> rescuedDays;
  final Value<bool> needsSync;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StreakCreditsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.subjectProfileId = const Value.absent(),
    this.available = const Value.absent(),
    this.progressToNext = const Value.absent(),
    this.lastCountedDay = const Value.absent(),
    this.rescuedDays = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreakCreditsTableCompanion.insert({
    required String id,
    required String userId,
    required String subjectProfileId,
    this.available = const Value.absent(),
    this.progressToNext = const Value.absent(),
    this.lastCountedDay = const Value.absent(),
    this.rescuedDays = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        subjectProfileId = Value(subjectProfileId);
  static Insertable<StreakCreditsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? subjectProfileId,
    Expression<int>? available,
    Expression<int>? progressToNext,
    Expression<DateTime>? lastCountedDay,
    Expression<String>? rescuedDays,
    Expression<bool>? needsSync,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      if (available != null) 'available': available,
      if (progressToNext != null) 'progress_to_next': progressToNext,
      if (lastCountedDay != null) 'last_counted_day': lastCountedDay,
      if (rescuedDays != null) 'rescued_days': rescuedDays,
      if (needsSync != null) 'needs_sync': needsSync,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreakCreditsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? subjectProfileId,
      Value<int>? available,
      Value<int>? progressToNext,
      Value<DateTime?>? lastCountedDay,
      Value<String>? rescuedDays,
      Value<bool>? needsSync,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StreakCreditsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectProfileId: subjectProfileId ?? this.subjectProfileId,
      available: available ?? this.available,
      progressToNext: progressToNext ?? this.progressToNext,
      lastCountedDay: lastCountedDay ?? this.lastCountedDay,
      rescuedDays: rescuedDays ?? this.rescuedDays,
      needsSync: needsSync ?? this.needsSync,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (subjectProfileId.present) {
      map['subject_profile_id'] = Variable<String>(subjectProfileId.value);
    }
    if (available.present) {
      map['available'] = Variable<int>(available.value);
    }
    if (progressToNext.present) {
      map['progress_to_next'] = Variable<int>(progressToNext.value);
    }
    if (lastCountedDay.present) {
      map['last_counted_day'] = Variable<DateTime>(lastCountedDay.value);
    }
    if (rescuedDays.present) {
      map['rescued_days'] = Variable<String>(rescuedDays.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakCreditsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectProfileId: $subjectProfileId, ')
          ..write('available: $available, ')
          ..write('progressToNext: $progressToNext, ')
          ..write('lastCountedDay: $lastCountedDay, ')
          ..write('rescuedDays: $rescuedDays, ')
          ..write('needsSync: $needsSync, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EnrollmentsTableTable enrollmentsTable =
      $EnrollmentsTableTable(this);
  late final $ExercisesTableTable exercisesTable = $ExercisesTableTable(this);
  late final $TrainingSessionsTableTable trainingSessionsTable =
      $TrainingSessionsTableTable(this);
  late final $ProgressEntriesTableTable progressEntriesTable =
      $ProgressEntriesTableTable(this);
  late final $MoodCheckinsTableTable moodCheckinsTable =
      $MoodCheckinsTableTable(this);
  late final $SyncJobsTableTable syncJobsTable = $SyncJobsTableTable(this);
  late final $IntakeAssessmentsTableTable intakeAssessmentsTable =
      $IntakeAssessmentsTableTable(this);
  late final $CompletionQuestionnairesTableTable completionQuestionnairesTable =
      $CompletionQuestionnairesTableTable(this);
  late final $JournalEntriesTableTable journalEntriesTable =
      $JournalEntriesTableTable(this);
  late final $StreakCreditsTableTable streakCreditsTable =
      $StreakCreditsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        enrollmentsTable,
        exercisesTable,
        trainingSessionsTable,
        progressEntriesTable,
        moodCheckinsTable,
        syncJobsTable,
        intakeAssessmentsTable,
        completionQuestionnairesTable,
        journalEntriesTable,
        streakCreditsTable
      ];
}

typedef $$EnrollmentsTableTableCreateCompanionBuilder
    = EnrollmentsTableCompanion Function({
  required String id,
  required String userId,
  Value<String?> subjectProfileId,
  required String packageId,
  Value<String> status,
  required int assignedDurationWeeks,
  required DateTime startDate,
  required DateTime targetCompletionDate,
  Value<DateTime?> completedAt,
  Value<DateTime?> pausedAt,
  Value<String?> precedingEnrollmentId,
  Value<bool> needsSync,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$EnrollmentsTableTableUpdateCompanionBuilder
    = EnrollmentsTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> subjectProfileId,
  Value<String> packageId,
  Value<String> status,
  Value<int> assignedDurationWeeks,
  Value<DateTime> startDate,
  Value<DateTime> targetCompletionDate,
  Value<DateTime?> completedAt,
  Value<DateTime?> pausedAt,
  Value<String?> precedingEnrollmentId,
  Value<bool> needsSync,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EnrollmentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $EnrollmentsTableTable> {
  $$EnrollmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageId => $composableBuilder(
      column: $table.packageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get assignedDurationWeeks => $composableBuilder(
      column: $table.assignedDurationWeeks,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetCompletionDate => $composableBuilder(
      column: $table.targetCompletionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
      column: $table.pausedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get precedingEnrollmentId => $composableBuilder(
      column: $table.precedingEnrollmentId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EnrollmentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EnrollmentsTableTable> {
  $$EnrollmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageId => $composableBuilder(
      column: $table.packageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get assignedDurationWeeks => $composableBuilder(
      column: $table.assignedDurationWeeks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetCompletionDate => $composableBuilder(
      column: $table.targetCompletionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
      column: $table.pausedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get precedingEnrollmentId => $composableBuilder(
      column: $table.precedingEnrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EnrollmentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnrollmentsTableTable> {
  $$EnrollmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<String> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get assignedDurationWeeks => $composableBuilder(
      column: $table.assignedDurationWeeks, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get targetCompletionDate => $composableBuilder(
      column: $table.targetCompletionDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<String> get precedingEnrollmentId => $composableBuilder(
      column: $table.precedingEnrollmentId, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EnrollmentsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EnrollmentsTableTable,
    EnrollmentsTableData,
    $$EnrollmentsTableTableFilterComposer,
    $$EnrollmentsTableTableOrderingComposer,
    $$EnrollmentsTableTableAnnotationComposer,
    $$EnrollmentsTableTableCreateCompanionBuilder,
    $$EnrollmentsTableTableUpdateCompanionBuilder,
    (
      EnrollmentsTableData,
      BaseReferences<_$AppDatabase, $EnrollmentsTableTable,
          EnrollmentsTableData>
    ),
    EnrollmentsTableData,
    PrefetchHooks Function()> {
  $$EnrollmentsTableTableTableManager(
      _$AppDatabase db, $EnrollmentsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnrollmentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnrollmentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnrollmentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<String> packageId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> assignedDurationWeeks = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> targetCompletionDate = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime?> pausedAt = const Value.absent(),
            Value<String?> precedingEnrollmentId = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EnrollmentsTableCompanion(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            packageId: packageId,
            status: status,
            assignedDurationWeeks: assignedDurationWeeks,
            startDate: startDate,
            targetCompletionDate: targetCompletionDate,
            completedAt: completedAt,
            pausedAt: pausedAt,
            precedingEnrollmentId: precedingEnrollmentId,
            needsSync: needsSync,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> subjectProfileId = const Value.absent(),
            required String packageId,
            Value<String> status = const Value.absent(),
            required int assignedDurationWeeks,
            required DateTime startDate,
            required DateTime targetCompletionDate,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime?> pausedAt = const Value.absent(),
            Value<String?> precedingEnrollmentId = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EnrollmentsTableCompanion.insert(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            packageId: packageId,
            status: status,
            assignedDurationWeeks: assignedDurationWeeks,
            startDate: startDate,
            targetCompletionDate: targetCompletionDate,
            completedAt: completedAt,
            pausedAt: pausedAt,
            precedingEnrollmentId: precedingEnrollmentId,
            needsSync: needsSync,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EnrollmentsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EnrollmentsTableTable,
    EnrollmentsTableData,
    $$EnrollmentsTableTableFilterComposer,
    $$EnrollmentsTableTableOrderingComposer,
    $$EnrollmentsTableTableAnnotationComposer,
    $$EnrollmentsTableTableCreateCompanionBuilder,
    $$EnrollmentsTableTableUpdateCompanionBuilder,
    (
      EnrollmentsTableData,
      BaseReferences<_$AppDatabase, $EnrollmentsTableTable,
          EnrollmentsTableData>
    ),
    EnrollmentsTableData,
    PrefetchHooks Function()>;
typedef $$ExercisesTableTableCreateCompanionBuilder = ExercisesTableCompanion
    Function({
  required String id,
  required String packageId,
  required int sequenceNumber,
  required String titleDe,
  required String titleEn,
  required String positionInstructionsDe,
  required String positionInstructionsEn,
  required String movementInstructionsDe,
  required String movementInstructionsEn,
  Value<String?> hintsDe,
  Value<String?> hintsEn,
  required String executionGuideDe,
  required String executionGuideEn,
  required int durationSeconds,
  required int repetitions,
  required String imagePath,
  Value<String?> duoImagePath,
  Value<String?> videoPath,
  Value<String?> audioCuePath,
  Value<String?> imageUrl,
  Value<String?> duoImageUrl,
  Value<String?> videoUrl,
  Value<String> rhythmType,
  Value<String> phasesJson,
  Value<bool> hasRepSwitch,
  Value<String> holdCueDe,
  Value<String> holdCueEn,
  Value<int> holdSeconds,
  Value<int> restSeconds,
  Value<bool> halfwaySwitch,
  Value<int> rowid,
});
typedef $$ExercisesTableTableUpdateCompanionBuilder = ExercisesTableCompanion
    Function({
  Value<String> id,
  Value<String> packageId,
  Value<int> sequenceNumber,
  Value<String> titleDe,
  Value<String> titleEn,
  Value<String> positionInstructionsDe,
  Value<String> positionInstructionsEn,
  Value<String> movementInstructionsDe,
  Value<String> movementInstructionsEn,
  Value<String?> hintsDe,
  Value<String?> hintsEn,
  Value<String> executionGuideDe,
  Value<String> executionGuideEn,
  Value<int> durationSeconds,
  Value<int> repetitions,
  Value<String> imagePath,
  Value<String?> duoImagePath,
  Value<String?> videoPath,
  Value<String?> audioCuePath,
  Value<String?> imageUrl,
  Value<String?> duoImageUrl,
  Value<String?> videoUrl,
  Value<String> rhythmType,
  Value<String> phasesJson,
  Value<bool> hasRepSwitch,
  Value<String> holdCueDe,
  Value<String> holdCueEn,
  Value<int> holdSeconds,
  Value<int> restSeconds,
  Value<bool> halfwaySwitch,
  Value<int> rowid,
});

class $$ExercisesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTableTable> {
  $$ExercisesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageId => $composableBuilder(
      column: $table.packageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
      column: $table.sequenceNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleDe => $composableBuilder(
      column: $table.titleDe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleEn => $composableBuilder(
      column: $table.titleEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get positionInstructionsDe => $composableBuilder(
      column: $table.positionInstructionsDe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get positionInstructionsEn => $composableBuilder(
      column: $table.positionInstructionsEn,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movementInstructionsDe => $composableBuilder(
      column: $table.movementInstructionsDe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movementInstructionsEn => $composableBuilder(
      column: $table.movementInstructionsEn,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hintsDe => $composableBuilder(
      column: $table.hintsDe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hintsEn => $composableBuilder(
      column: $table.hintsEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get executionGuideDe => $composableBuilder(
      column: $table.executionGuideDe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get executionGuideEn => $composableBuilder(
      column: $table.executionGuideEn,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get duoImagePath => $composableBuilder(
      column: $table.duoImagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoPath => $composableBuilder(
      column: $table.videoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioCuePath => $composableBuilder(
      column: $table.audioCuePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get duoImageUrl => $composableBuilder(
      column: $table.duoImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoUrl => $composableBuilder(
      column: $table.videoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rhythmType => $composableBuilder(
      column: $table.rhythmType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phasesJson => $composableBuilder(
      column: $table.phasesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasRepSwitch => $composableBuilder(
      column: $table.hasRepSwitch, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get holdCueDe => $composableBuilder(
      column: $table.holdCueDe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get holdCueEn => $composableBuilder(
      column: $table.holdCueEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get holdSeconds => $composableBuilder(
      column: $table.holdSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get halfwaySwitch => $composableBuilder(
      column: $table.halfwaySwitch, builder: (column) => ColumnFilters(column));
}

class $$ExercisesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTableTable> {
  $$ExercisesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageId => $composableBuilder(
      column: $table.packageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
      column: $table.sequenceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleDe => $composableBuilder(
      column: $table.titleDe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleEn => $composableBuilder(
      column: $table.titleEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get positionInstructionsDe => $composableBuilder(
      column: $table.positionInstructionsDe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get positionInstructionsEn => $composableBuilder(
      column: $table.positionInstructionsEn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movementInstructionsDe => $composableBuilder(
      column: $table.movementInstructionsDe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movementInstructionsEn => $composableBuilder(
      column: $table.movementInstructionsEn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hintsDe => $composableBuilder(
      column: $table.hintsDe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hintsEn => $composableBuilder(
      column: $table.hintsEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get executionGuideDe => $composableBuilder(
      column: $table.executionGuideDe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get executionGuideEn => $composableBuilder(
      column: $table.executionGuideEn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get duoImagePath => $composableBuilder(
      column: $table.duoImagePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoPath => $composableBuilder(
      column: $table.videoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioCuePath => $composableBuilder(
      column: $table.audioCuePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get duoImageUrl => $composableBuilder(
      column: $table.duoImageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoUrl => $composableBuilder(
      column: $table.videoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rhythmType => $composableBuilder(
      column: $table.rhythmType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phasesJson => $composableBuilder(
      column: $table.phasesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasRepSwitch => $composableBuilder(
      column: $table.hasRepSwitch,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get holdCueDe => $composableBuilder(
      column: $table.holdCueDe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get holdCueEn => $composableBuilder(
      column: $table.holdCueEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get holdSeconds => $composableBuilder(
      column: $table.holdSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get halfwaySwitch => $composableBuilder(
      column: $table.halfwaySwitch,
      builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTableTable> {
  $$ExercisesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
      column: $table.sequenceNumber, builder: (column) => column);

  GeneratedColumn<String> get titleDe =>
      $composableBuilder(column: $table.titleDe, builder: (column) => column);

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get positionInstructionsDe => $composableBuilder(
      column: $table.positionInstructionsDe, builder: (column) => column);

  GeneratedColumn<String> get positionInstructionsEn => $composableBuilder(
      column: $table.positionInstructionsEn, builder: (column) => column);

  GeneratedColumn<String> get movementInstructionsDe => $composableBuilder(
      column: $table.movementInstructionsDe, builder: (column) => column);

  GeneratedColumn<String> get movementInstructionsEn => $composableBuilder(
      column: $table.movementInstructionsEn, builder: (column) => column);

  GeneratedColumn<String> get hintsDe =>
      $composableBuilder(column: $table.hintsDe, builder: (column) => column);

  GeneratedColumn<String> get hintsEn =>
      $composableBuilder(column: $table.hintsEn, builder: (column) => column);

  GeneratedColumn<String> get executionGuideDe => $composableBuilder(
      column: $table.executionGuideDe, builder: (column) => column);

  GeneratedColumn<String> get executionGuideEn => $composableBuilder(
      column: $table.executionGuideEn, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get duoImagePath => $composableBuilder(
      column: $table.duoImagePath, builder: (column) => column);

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<String> get audioCuePath => $composableBuilder(
      column: $table.audioCuePath, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get duoImageUrl => $composableBuilder(
      column: $table.duoImageUrl, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get rhythmType => $composableBuilder(
      column: $table.rhythmType, builder: (column) => column);

  GeneratedColumn<String> get phasesJson => $composableBuilder(
      column: $table.phasesJson, builder: (column) => column);

  GeneratedColumn<bool> get hasRepSwitch => $composableBuilder(
      column: $table.hasRepSwitch, builder: (column) => column);

  GeneratedColumn<String> get holdCueDe =>
      $composableBuilder(column: $table.holdCueDe, builder: (column) => column);

  GeneratedColumn<String> get holdCueEn =>
      $composableBuilder(column: $table.holdCueEn, builder: (column) => column);

  GeneratedColumn<int> get holdSeconds => $composableBuilder(
      column: $table.holdSeconds, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => column);

  GeneratedColumn<bool> get halfwaySwitch => $composableBuilder(
      column: $table.halfwaySwitch, builder: (column) => column);
}

class $$ExercisesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTableTable,
    ExercisesTableData,
    $$ExercisesTableTableFilterComposer,
    $$ExercisesTableTableOrderingComposer,
    $$ExercisesTableTableAnnotationComposer,
    $$ExercisesTableTableCreateCompanionBuilder,
    $$ExercisesTableTableUpdateCompanionBuilder,
    (
      ExercisesTableData,
      BaseReferences<_$AppDatabase, $ExercisesTableTable, ExercisesTableData>
    ),
    ExercisesTableData,
    PrefetchHooks Function()> {
  $$ExercisesTableTableTableManager(
      _$AppDatabase db, $ExercisesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> packageId = const Value.absent(),
            Value<int> sequenceNumber = const Value.absent(),
            Value<String> titleDe = const Value.absent(),
            Value<String> titleEn = const Value.absent(),
            Value<String> positionInstructionsDe = const Value.absent(),
            Value<String> positionInstructionsEn = const Value.absent(),
            Value<String> movementInstructionsDe = const Value.absent(),
            Value<String> movementInstructionsEn = const Value.absent(),
            Value<String?> hintsDe = const Value.absent(),
            Value<String?> hintsEn = const Value.absent(),
            Value<String> executionGuideDe = const Value.absent(),
            Value<String> executionGuideEn = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String?> duoImagePath = const Value.absent(),
            Value<String?> videoPath = const Value.absent(),
            Value<String?> audioCuePath = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> duoImageUrl = const Value.absent(),
            Value<String?> videoUrl = const Value.absent(),
            Value<String> rhythmType = const Value.absent(),
            Value<String> phasesJson = const Value.absent(),
            Value<bool> hasRepSwitch = const Value.absent(),
            Value<String> holdCueDe = const Value.absent(),
            Value<String> holdCueEn = const Value.absent(),
            Value<int> holdSeconds = const Value.absent(),
            Value<int> restSeconds = const Value.absent(),
            Value<bool> halfwaySwitch = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesTableCompanion(
            id: id,
            packageId: packageId,
            sequenceNumber: sequenceNumber,
            titleDe: titleDe,
            titleEn: titleEn,
            positionInstructionsDe: positionInstructionsDe,
            positionInstructionsEn: positionInstructionsEn,
            movementInstructionsDe: movementInstructionsDe,
            movementInstructionsEn: movementInstructionsEn,
            hintsDe: hintsDe,
            hintsEn: hintsEn,
            executionGuideDe: executionGuideDe,
            executionGuideEn: executionGuideEn,
            durationSeconds: durationSeconds,
            repetitions: repetitions,
            imagePath: imagePath,
            duoImagePath: duoImagePath,
            videoPath: videoPath,
            audioCuePath: audioCuePath,
            imageUrl: imageUrl,
            duoImageUrl: duoImageUrl,
            videoUrl: videoUrl,
            rhythmType: rhythmType,
            phasesJson: phasesJson,
            hasRepSwitch: hasRepSwitch,
            holdCueDe: holdCueDe,
            holdCueEn: holdCueEn,
            holdSeconds: holdSeconds,
            restSeconds: restSeconds,
            halfwaySwitch: halfwaySwitch,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String packageId,
            required int sequenceNumber,
            required String titleDe,
            required String titleEn,
            required String positionInstructionsDe,
            required String positionInstructionsEn,
            required String movementInstructionsDe,
            required String movementInstructionsEn,
            Value<String?> hintsDe = const Value.absent(),
            Value<String?> hintsEn = const Value.absent(),
            required String executionGuideDe,
            required String executionGuideEn,
            required int durationSeconds,
            required int repetitions,
            required String imagePath,
            Value<String?> duoImagePath = const Value.absent(),
            Value<String?> videoPath = const Value.absent(),
            Value<String?> audioCuePath = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> duoImageUrl = const Value.absent(),
            Value<String?> videoUrl = const Value.absent(),
            Value<String> rhythmType = const Value.absent(),
            Value<String> phasesJson = const Value.absent(),
            Value<bool> hasRepSwitch = const Value.absent(),
            Value<String> holdCueDe = const Value.absent(),
            Value<String> holdCueEn = const Value.absent(),
            Value<int> holdSeconds = const Value.absent(),
            Value<int> restSeconds = const Value.absent(),
            Value<bool> halfwaySwitch = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesTableCompanion.insert(
            id: id,
            packageId: packageId,
            sequenceNumber: sequenceNumber,
            titleDe: titleDe,
            titleEn: titleEn,
            positionInstructionsDe: positionInstructionsDe,
            positionInstructionsEn: positionInstructionsEn,
            movementInstructionsDe: movementInstructionsDe,
            movementInstructionsEn: movementInstructionsEn,
            hintsDe: hintsDe,
            hintsEn: hintsEn,
            executionGuideDe: executionGuideDe,
            executionGuideEn: executionGuideEn,
            durationSeconds: durationSeconds,
            repetitions: repetitions,
            imagePath: imagePath,
            duoImagePath: duoImagePath,
            videoPath: videoPath,
            audioCuePath: audioCuePath,
            imageUrl: imageUrl,
            duoImageUrl: duoImageUrl,
            videoUrl: videoUrl,
            rhythmType: rhythmType,
            phasesJson: phasesJson,
            hasRepSwitch: hasRepSwitch,
            holdCueDe: holdCueDe,
            holdCueEn: holdCueEn,
            holdSeconds: holdSeconds,
            restSeconds: restSeconds,
            halfwaySwitch: halfwaySwitch,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExercisesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTableTable,
    ExercisesTableData,
    $$ExercisesTableTableFilterComposer,
    $$ExercisesTableTableOrderingComposer,
    $$ExercisesTableTableAnnotationComposer,
    $$ExercisesTableTableCreateCompanionBuilder,
    $$ExercisesTableTableUpdateCompanionBuilder,
    (
      ExercisesTableData,
      BaseReferences<_$AppDatabase, $ExercisesTableTable, ExercisesTableData>
    ),
    ExercisesTableData,
    PrefetchHooks Function()>;
typedef $$TrainingSessionsTableTableCreateCompanionBuilder
    = TrainingSessionsTableCompanion Function({
  required String id,
  required String userId,
  Value<String?> subjectProfileId,
  required String enrollmentId,
  required DateTime sessionDate,
  required int dayNumber,
  required String completedExerciseIds,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  Value<bool> needsSync,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TrainingSessionsTableTableUpdateCompanionBuilder
    = TrainingSessionsTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> subjectProfileId,
  Value<String> enrollmentId,
  Value<DateTime> sessionDate,
  Value<int> dayNumber,
  Value<String> completedExerciseIds,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  Value<bool> needsSync,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TrainingSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingSessionsTableTable> {
  $$TrainingSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sessionDate => $composableBuilder(
      column: $table.sessionDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completedExerciseIds => $composableBuilder(
      column: $table.completedExerciseIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TrainingSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingSessionsTableTable> {
  $$TrainingSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sessionDate => $composableBuilder(
      column: $table.sessionDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completedExerciseIds => $composableBuilder(
      column: $table.completedExerciseIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TrainingSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingSessionsTableTable> {
  $$TrainingSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => column);

  GeneratedColumn<DateTime> get sessionDate => $composableBuilder(
      column: $table.sessionDate, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<String> get completedExerciseIds => $composableBuilder(
      column: $table.completedExerciseIds, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TrainingSessionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrainingSessionsTableTable,
    TrainingSessionsTableData,
    $$TrainingSessionsTableTableFilterComposer,
    $$TrainingSessionsTableTableOrderingComposer,
    $$TrainingSessionsTableTableAnnotationComposer,
    $$TrainingSessionsTableTableCreateCompanionBuilder,
    $$TrainingSessionsTableTableUpdateCompanionBuilder,
    (
      TrainingSessionsTableData,
      BaseReferences<_$AppDatabase, $TrainingSessionsTableTable,
          TrainingSessionsTableData>
    ),
    TrainingSessionsTableData,
    PrefetchHooks Function()> {
  $$TrainingSessionsTableTableTableManager(
      _$AppDatabase db, $TrainingSessionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingSessionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingSessionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingSessionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<String> enrollmentId = const Value.absent(),
            Value<DateTime> sessionDate = const Value.absent(),
            Value<int> dayNumber = const Value.absent(),
            Value<String> completedExerciseIds = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TrainingSessionsTableCompanion(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            enrollmentId: enrollmentId,
            sessionDate: sessionDate,
            dayNumber: dayNumber,
            completedExerciseIds: completedExerciseIds,
            isCompleted: isCompleted,
            completedAt: completedAt,
            needsSync: needsSync,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> subjectProfileId = const Value.absent(),
            required String enrollmentId,
            required DateTime sessionDate,
            required int dayNumber,
            required String completedExerciseIds,
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TrainingSessionsTableCompanion.insert(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            enrollmentId: enrollmentId,
            sessionDate: sessionDate,
            dayNumber: dayNumber,
            completedExerciseIds: completedExerciseIds,
            isCompleted: isCompleted,
            completedAt: completedAt,
            needsSync: needsSync,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrainingSessionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TrainingSessionsTableTable,
        TrainingSessionsTableData,
        $$TrainingSessionsTableTableFilterComposer,
        $$TrainingSessionsTableTableOrderingComposer,
        $$TrainingSessionsTableTableAnnotationComposer,
        $$TrainingSessionsTableTableCreateCompanionBuilder,
        $$TrainingSessionsTableTableUpdateCompanionBuilder,
        (
          TrainingSessionsTableData,
          BaseReferences<_$AppDatabase, $TrainingSessionsTableTable,
              TrainingSessionsTableData>
        ),
        TrainingSessionsTableData,
        PrefetchHooks Function()>;
typedef $$ProgressEntriesTableTableCreateCompanionBuilder
    = ProgressEntriesTableCompanion Function({
  required String id,
  required String userId,
  Value<String?> subjectProfileId,
  required String enrollmentId,
  Value<int> currentDay,
  Value<DateTime?> lastActivityDate,
  Value<int> consecutiveInactiveDays,
  Value<int> dailyStreak,
  Value<int> weeklyStreak,
  Value<int> trainingsThisWeek,
  Value<DateTime?> lastTrainingWeekStart,
  Value<int> weeklyGoal,
  Value<int> totalSessionsSinceDisclaimer,
  Value<DateTime?> lastDisclaimerAcceptedAt,
  Value<bool> needsSync,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ProgressEntriesTableTableUpdateCompanionBuilder
    = ProgressEntriesTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> subjectProfileId,
  Value<String> enrollmentId,
  Value<int> currentDay,
  Value<DateTime?> lastActivityDate,
  Value<int> consecutiveInactiveDays,
  Value<int> dailyStreak,
  Value<int> weeklyStreak,
  Value<int> trainingsThisWeek,
  Value<DateTime?> lastTrainingWeekStart,
  Value<int> weeklyGoal,
  Value<int> totalSessionsSinceDisclaimer,
  Value<DateTime?> lastDisclaimerAcceptedAt,
  Value<bool> needsSync,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProgressEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressEntriesTableTable> {
  $$ProgressEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentDay => $composableBuilder(
      column: $table.currentDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActivityDate => $composableBuilder(
      column: $table.lastActivityDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consecutiveInactiveDays => $composableBuilder(
      column: $table.consecutiveInactiveDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyStreak => $composableBuilder(
      column: $table.dailyStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weeklyStreak => $composableBuilder(
      column: $table.weeklyStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trainingsThisWeek => $composableBuilder(
      column: $table.trainingsThisWeek,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastTrainingWeekStart => $composableBuilder(
      column: $table.lastTrainingWeekStart,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weeklyGoal => $composableBuilder(
      column: $table.weeklyGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSessionsSinceDisclaimer => $composableBuilder(
      column: $table.totalSessionsSinceDisclaimer,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastDisclaimerAcceptedAt => $composableBuilder(
      column: $table.lastDisclaimerAcceptedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProgressEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressEntriesTableTable> {
  $$ProgressEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentDay => $composableBuilder(
      column: $table.currentDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActivityDate => $composableBuilder(
      column: $table.lastActivityDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consecutiveInactiveDays => $composableBuilder(
      column: $table.consecutiveInactiveDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyStreak => $composableBuilder(
      column: $table.dailyStreak, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weeklyStreak => $composableBuilder(
      column: $table.weeklyStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trainingsThisWeek => $composableBuilder(
      column: $table.trainingsThisWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastTrainingWeekStart => $composableBuilder(
      column: $table.lastTrainingWeekStart,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weeklyGoal => $composableBuilder(
      column: $table.weeklyGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSessionsSinceDisclaimer => $composableBuilder(
      column: $table.totalSessionsSinceDisclaimer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastDisclaimerAcceptedAt => $composableBuilder(
      column: $table.lastDisclaimerAcceptedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProgressEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressEntriesTableTable> {
  $$ProgressEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => column);

  GeneratedColumn<int> get currentDay => $composableBuilder(
      column: $table.currentDay, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActivityDate => $composableBuilder(
      column: $table.lastActivityDate, builder: (column) => column);

  GeneratedColumn<int> get consecutiveInactiveDays => $composableBuilder(
      column: $table.consecutiveInactiveDays, builder: (column) => column);

  GeneratedColumn<int> get dailyStreak => $composableBuilder(
      column: $table.dailyStreak, builder: (column) => column);

  GeneratedColumn<int> get weeklyStreak => $composableBuilder(
      column: $table.weeklyStreak, builder: (column) => column);

  GeneratedColumn<int> get trainingsThisWeek => $composableBuilder(
      column: $table.trainingsThisWeek, builder: (column) => column);

  GeneratedColumn<DateTime> get lastTrainingWeekStart => $composableBuilder(
      column: $table.lastTrainingWeekStart, builder: (column) => column);

  GeneratedColumn<int> get weeklyGoal => $composableBuilder(
      column: $table.weeklyGoal, builder: (column) => column);

  GeneratedColumn<int> get totalSessionsSinceDisclaimer => $composableBuilder(
      column: $table.totalSessionsSinceDisclaimer, builder: (column) => column);

  GeneratedColumn<DateTime> get lastDisclaimerAcceptedAt => $composableBuilder(
      column: $table.lastDisclaimerAcceptedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProgressEntriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgressEntriesTableTable,
    ProgressEntriesTableData,
    $$ProgressEntriesTableTableFilterComposer,
    $$ProgressEntriesTableTableOrderingComposer,
    $$ProgressEntriesTableTableAnnotationComposer,
    $$ProgressEntriesTableTableCreateCompanionBuilder,
    $$ProgressEntriesTableTableUpdateCompanionBuilder,
    (
      ProgressEntriesTableData,
      BaseReferences<_$AppDatabase, $ProgressEntriesTableTable,
          ProgressEntriesTableData>
    ),
    ProgressEntriesTableData,
    PrefetchHooks Function()> {
  $$ProgressEntriesTableTableTableManager(
      _$AppDatabase db, $ProgressEntriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressEntriesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressEntriesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<String> enrollmentId = const Value.absent(),
            Value<int> currentDay = const Value.absent(),
            Value<DateTime?> lastActivityDate = const Value.absent(),
            Value<int> consecutiveInactiveDays = const Value.absent(),
            Value<int> dailyStreak = const Value.absent(),
            Value<int> weeklyStreak = const Value.absent(),
            Value<int> trainingsThisWeek = const Value.absent(),
            Value<DateTime?> lastTrainingWeekStart = const Value.absent(),
            Value<int> weeklyGoal = const Value.absent(),
            Value<int> totalSessionsSinceDisclaimer = const Value.absent(),
            Value<DateTime?> lastDisclaimerAcceptedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressEntriesTableCompanion(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            enrollmentId: enrollmentId,
            currentDay: currentDay,
            lastActivityDate: lastActivityDate,
            consecutiveInactiveDays: consecutiveInactiveDays,
            dailyStreak: dailyStreak,
            weeklyStreak: weeklyStreak,
            trainingsThisWeek: trainingsThisWeek,
            lastTrainingWeekStart: lastTrainingWeekStart,
            weeklyGoal: weeklyGoal,
            totalSessionsSinceDisclaimer: totalSessionsSinceDisclaimer,
            lastDisclaimerAcceptedAt: lastDisclaimerAcceptedAt,
            needsSync: needsSync,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> subjectProfileId = const Value.absent(),
            required String enrollmentId,
            Value<int> currentDay = const Value.absent(),
            Value<DateTime?> lastActivityDate = const Value.absent(),
            Value<int> consecutiveInactiveDays = const Value.absent(),
            Value<int> dailyStreak = const Value.absent(),
            Value<int> weeklyStreak = const Value.absent(),
            Value<int> trainingsThisWeek = const Value.absent(),
            Value<DateTime?> lastTrainingWeekStart = const Value.absent(),
            Value<int> weeklyGoal = const Value.absent(),
            Value<int> totalSessionsSinceDisclaimer = const Value.absent(),
            Value<DateTime?> lastDisclaimerAcceptedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressEntriesTableCompanion.insert(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            enrollmentId: enrollmentId,
            currentDay: currentDay,
            lastActivityDate: lastActivityDate,
            consecutiveInactiveDays: consecutiveInactiveDays,
            dailyStreak: dailyStreak,
            weeklyStreak: weeklyStreak,
            trainingsThisWeek: trainingsThisWeek,
            lastTrainingWeekStart: lastTrainingWeekStart,
            weeklyGoal: weeklyGoal,
            totalSessionsSinceDisclaimer: totalSessionsSinceDisclaimer,
            lastDisclaimerAcceptedAt: lastDisclaimerAcceptedAt,
            needsSync: needsSync,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProgressEntriesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ProgressEntriesTableTable,
        ProgressEntriesTableData,
        $$ProgressEntriesTableTableFilterComposer,
        $$ProgressEntriesTableTableOrderingComposer,
        $$ProgressEntriesTableTableAnnotationComposer,
        $$ProgressEntriesTableTableCreateCompanionBuilder,
        $$ProgressEntriesTableTableUpdateCompanionBuilder,
        (
          ProgressEntriesTableData,
          BaseReferences<_$AppDatabase, $ProgressEntriesTableTable,
              ProgressEntriesTableData>
        ),
        ProgressEntriesTableData,
        PrefetchHooks Function()>;
typedef $$MoodCheckinsTableTableCreateCompanionBuilder
    = MoodCheckinsTableCompanion Function({
  required String id,
  required String userId,
  required String enrollmentId,
  Value<String?> sessionId,
  required DateTime recordedAt,
  required int dayKey,
  Value<int?> mood,
  Value<int?> energy,
  Value<int?> stress,
  Value<String?> note,
  required String source,
  Value<String?> subjectProfileId,
  Value<bool> needsSync,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$MoodCheckinsTableTableUpdateCompanionBuilder
    = MoodCheckinsTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> enrollmentId,
  Value<String?> sessionId,
  Value<DateTime> recordedAt,
  Value<int> dayKey,
  Value<int?> mood,
  Value<int?> energy,
  Value<int?> stress,
  Value<String?> note,
  Value<String> source,
  Value<String?> subjectProfileId,
  Value<bool> needsSync,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MoodCheckinsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MoodCheckinsTableTable> {
  $$MoodCheckinsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayKey => $composableBuilder(
      column: $table.dayKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stress => $composableBuilder(
      column: $table.stress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MoodCheckinsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MoodCheckinsTableTable> {
  $$MoodCheckinsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayKey => $composableBuilder(
      column: $table.dayKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stress => $composableBuilder(
      column: $table.stress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MoodCheckinsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoodCheckinsTableTable> {
  $$MoodCheckinsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<int> get stress =>
      $composableBuilder(column: $table.stress, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MoodCheckinsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MoodCheckinsTableTable,
    MoodCheckinsTableData,
    $$MoodCheckinsTableTableFilterComposer,
    $$MoodCheckinsTableTableOrderingComposer,
    $$MoodCheckinsTableTableAnnotationComposer,
    $$MoodCheckinsTableTableCreateCompanionBuilder,
    $$MoodCheckinsTableTableUpdateCompanionBuilder,
    (
      MoodCheckinsTableData,
      BaseReferences<_$AppDatabase, $MoodCheckinsTableTable,
          MoodCheckinsTableData>
    ),
    MoodCheckinsTableData,
    PrefetchHooks Function()> {
  $$MoodCheckinsTableTableTableManager(
      _$AppDatabase db, $MoodCheckinsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodCheckinsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodCheckinsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodCheckinsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> enrollmentId = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int> dayKey = const Value.absent(),
            Value<int?> mood = const Value.absent(),
            Value<int?> energy = const Value.absent(),
            Value<int?> stress = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MoodCheckinsTableCompanion(
            id: id,
            userId: userId,
            enrollmentId: enrollmentId,
            sessionId: sessionId,
            recordedAt: recordedAt,
            dayKey: dayKey,
            mood: mood,
            energy: energy,
            stress: stress,
            note: note,
            source: source,
            subjectProfileId: subjectProfileId,
            needsSync: needsSync,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String enrollmentId,
            Value<String?> sessionId = const Value.absent(),
            required DateTime recordedAt,
            required int dayKey,
            Value<int?> mood = const Value.absent(),
            Value<int?> energy = const Value.absent(),
            Value<int?> stress = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required String source,
            Value<String?> subjectProfileId = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MoodCheckinsTableCompanion.insert(
            id: id,
            userId: userId,
            enrollmentId: enrollmentId,
            sessionId: sessionId,
            recordedAt: recordedAt,
            dayKey: dayKey,
            mood: mood,
            energy: energy,
            stress: stress,
            note: note,
            source: source,
            subjectProfileId: subjectProfileId,
            needsSync: needsSync,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MoodCheckinsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MoodCheckinsTableTable,
    MoodCheckinsTableData,
    $$MoodCheckinsTableTableFilterComposer,
    $$MoodCheckinsTableTableOrderingComposer,
    $$MoodCheckinsTableTableAnnotationComposer,
    $$MoodCheckinsTableTableCreateCompanionBuilder,
    $$MoodCheckinsTableTableUpdateCompanionBuilder,
    (
      MoodCheckinsTableData,
      BaseReferences<_$AppDatabase, $MoodCheckinsTableTable,
          MoodCheckinsTableData>
    ),
    MoodCheckinsTableData,
    PrefetchHooks Function()>;
typedef $$SyncJobsTableTableCreateCompanionBuilder = SyncJobsTableCompanion
    Function({
  required String id,
  required String action,
  required String tableName_,
  required String recordId,
  required String payload,
  Value<int> retryCount,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});
typedef $$SyncJobsTableTableUpdateCompanionBuilder = SyncJobsTableCompanion
    Function({
  Value<String> id,
  Value<String> action,
  Value<String> tableName_,
  Value<String> recordId,
  Value<String> payload,
  Value<int> retryCount,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});

class $$SyncJobsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncJobsTableTable> {
  $$SyncJobsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tableName_ => $composableBuilder(
      column: $table.tableName_, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$SyncJobsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncJobsTableTable> {
  $$SyncJobsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tableName_ => $composableBuilder(
      column: $table.tableName_, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncJobsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncJobsTableTable> {
  $$SyncJobsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get tableName_ => $composableBuilder(
      column: $table.tableName_, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);
}

class $$SyncJobsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncJobsTableTable,
    SyncJobsTableData,
    $$SyncJobsTableTableFilterComposer,
    $$SyncJobsTableTableOrderingComposer,
    $$SyncJobsTableTableAnnotationComposer,
    $$SyncJobsTableTableCreateCompanionBuilder,
    $$SyncJobsTableTableUpdateCompanionBuilder,
    (
      SyncJobsTableData,
      BaseReferences<_$AppDatabase, $SyncJobsTableTable, SyncJobsTableData>
    ),
    SyncJobsTableData,
    PrefetchHooks Function()> {
  $$SyncJobsTableTableTableManager(_$AppDatabase db, $SyncJobsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncJobsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncJobsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncJobsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> tableName_ = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncJobsTableCompanion(
            id: id,
            action: action,
            tableName_: tableName_,
            recordId: recordId,
            payload: payload,
            retryCount: retryCount,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String action,
            required String tableName_,
            required String recordId,
            required String payload,
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncJobsTableCompanion.insert(
            id: id,
            action: action,
            tableName_: tableName_,
            recordId: recordId,
            payload: payload,
            retryCount: retryCount,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncJobsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncJobsTableTable,
    SyncJobsTableData,
    $$SyncJobsTableTableFilterComposer,
    $$SyncJobsTableTableOrderingComposer,
    $$SyncJobsTableTableAnnotationComposer,
    $$SyncJobsTableTableCreateCompanionBuilder,
    $$SyncJobsTableTableUpdateCompanionBuilder,
    (
      SyncJobsTableData,
      BaseReferences<_$AppDatabase, $SyncJobsTableTable, SyncJobsTableData>
    ),
    SyncJobsTableData,
    PrefetchHooks Function()>;
typedef $$IntakeAssessmentsTableTableCreateCompanionBuilder
    = IntakeAssessmentsTableCompanion Function({
  required String id,
  required String enrollmentId,
  required bool hadIsometricWithTrainer,
  Value<String?> additionalAnswers,
  required int recommendedDurationWeeks,
  required bool userAcceptedRecommendation,
  required int finalDurationWeeks,
  Value<bool> needsSync,
  required DateTime completedAt,
  Value<int> rowid,
});
typedef $$IntakeAssessmentsTableTableUpdateCompanionBuilder
    = IntakeAssessmentsTableCompanion Function({
  Value<String> id,
  Value<String> enrollmentId,
  Value<bool> hadIsometricWithTrainer,
  Value<String?> additionalAnswers,
  Value<int> recommendedDurationWeeks,
  Value<bool> userAcceptedRecommendation,
  Value<int> finalDurationWeeks,
  Value<bool> needsSync,
  Value<DateTime> completedAt,
  Value<int> rowid,
});

class $$IntakeAssessmentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeAssessmentsTableTable> {
  $$IntakeAssessmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hadIsometricWithTrainer => $composableBuilder(
      column: $table.hadIsometricWithTrainer,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get additionalAnswers => $composableBuilder(
      column: $table.additionalAnswers,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recommendedDurationWeeks => $composableBuilder(
      column: $table.recommendedDurationWeeks,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get userAcceptedRecommendation => $composableBuilder(
      column: $table.userAcceptedRecommendation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get finalDurationWeeks => $composableBuilder(
      column: $table.finalDurationWeeks,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$IntakeAssessmentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeAssessmentsTableTable> {
  $$IntakeAssessmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hadIsometricWithTrainer => $composableBuilder(
      column: $table.hadIsometricWithTrainer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get additionalAnswers => $composableBuilder(
      column: $table.additionalAnswers,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recommendedDurationWeeks => $composableBuilder(
      column: $table.recommendedDurationWeeks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get userAcceptedRecommendation => $composableBuilder(
      column: $table.userAcceptedRecommendation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get finalDurationWeeks => $composableBuilder(
      column: $table.finalDurationWeeks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$IntakeAssessmentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeAssessmentsTableTable> {
  $$IntakeAssessmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => column);

  GeneratedColumn<bool> get hadIsometricWithTrainer => $composableBuilder(
      column: $table.hadIsometricWithTrainer, builder: (column) => column);

  GeneratedColumn<String> get additionalAnswers => $composableBuilder(
      column: $table.additionalAnswers, builder: (column) => column);

  GeneratedColumn<int> get recommendedDurationWeeks => $composableBuilder(
      column: $table.recommendedDurationWeeks, builder: (column) => column);

  GeneratedColumn<bool> get userAcceptedRecommendation => $composableBuilder(
      column: $table.userAcceptedRecommendation, builder: (column) => column);

  GeneratedColumn<int> get finalDurationWeeks => $composableBuilder(
      column: $table.finalDurationWeeks, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$IntakeAssessmentsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IntakeAssessmentsTableTable,
    IntakeAssessmentsTableData,
    $$IntakeAssessmentsTableTableFilterComposer,
    $$IntakeAssessmentsTableTableOrderingComposer,
    $$IntakeAssessmentsTableTableAnnotationComposer,
    $$IntakeAssessmentsTableTableCreateCompanionBuilder,
    $$IntakeAssessmentsTableTableUpdateCompanionBuilder,
    (
      IntakeAssessmentsTableData,
      BaseReferences<_$AppDatabase, $IntakeAssessmentsTableTable,
          IntakeAssessmentsTableData>
    ),
    IntakeAssessmentsTableData,
    PrefetchHooks Function()> {
  $$IntakeAssessmentsTableTableTableManager(
      _$AppDatabase db, $IntakeAssessmentsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeAssessmentsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeAssessmentsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeAssessmentsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> enrollmentId = const Value.absent(),
            Value<bool> hadIsometricWithTrainer = const Value.absent(),
            Value<String?> additionalAnswers = const Value.absent(),
            Value<int> recommendedDurationWeeks = const Value.absent(),
            Value<bool> userAcceptedRecommendation = const Value.absent(),
            Value<int> finalDurationWeeks = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IntakeAssessmentsTableCompanion(
            id: id,
            enrollmentId: enrollmentId,
            hadIsometricWithTrainer: hadIsometricWithTrainer,
            additionalAnswers: additionalAnswers,
            recommendedDurationWeeks: recommendedDurationWeeks,
            userAcceptedRecommendation: userAcceptedRecommendation,
            finalDurationWeeks: finalDurationWeeks,
            needsSync: needsSync,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String enrollmentId,
            required bool hadIsometricWithTrainer,
            Value<String?> additionalAnswers = const Value.absent(),
            required int recommendedDurationWeeks,
            required bool userAcceptedRecommendation,
            required int finalDurationWeeks,
            Value<bool> needsSync = const Value.absent(),
            required DateTime completedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              IntakeAssessmentsTableCompanion.insert(
            id: id,
            enrollmentId: enrollmentId,
            hadIsometricWithTrainer: hadIsometricWithTrainer,
            additionalAnswers: additionalAnswers,
            recommendedDurationWeeks: recommendedDurationWeeks,
            userAcceptedRecommendation: userAcceptedRecommendation,
            finalDurationWeeks: finalDurationWeeks,
            needsSync: needsSync,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IntakeAssessmentsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $IntakeAssessmentsTableTable,
        IntakeAssessmentsTableData,
        $$IntakeAssessmentsTableTableFilterComposer,
        $$IntakeAssessmentsTableTableOrderingComposer,
        $$IntakeAssessmentsTableTableAnnotationComposer,
        $$IntakeAssessmentsTableTableCreateCompanionBuilder,
        $$IntakeAssessmentsTableTableUpdateCompanionBuilder,
        (
          IntakeAssessmentsTableData,
          BaseReferences<_$AppDatabase, $IntakeAssessmentsTableTable,
              IntakeAssessmentsTableData>
        ),
        IntakeAssessmentsTableData,
        PrefetchHooks Function()>;
typedef $$CompletionQuestionnairesTableTableCreateCompanionBuilder
    = CompletionQuestionnairesTableCompanion Function({
  required String id,
  required String enrollmentId,
  Value<int> attemptNumber,
  required bool response,
  required String result,
  Value<bool> nextEnrollmentCreated,
  Value<bool> needsSync,
  Value<String?> subjectProfileId,
  required DateTime submittedAt,
  Value<int> rowid,
});
typedef $$CompletionQuestionnairesTableTableUpdateCompanionBuilder
    = CompletionQuestionnairesTableCompanion Function({
  Value<String> id,
  Value<String> enrollmentId,
  Value<int> attemptNumber,
  Value<bool> response,
  Value<String> result,
  Value<bool> nextEnrollmentCreated,
  Value<bool> needsSync,
  Value<String?> subjectProfileId,
  Value<DateTime> submittedAt,
  Value<int> rowid,
});

class $$CompletionQuestionnairesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CompletionQuestionnairesTableTable> {
  $$CompletionQuestionnairesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptNumber => $composableBuilder(
      column: $table.attemptNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get response => $composableBuilder(
      column: $table.response, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get nextEnrollmentCreated => $composableBuilder(
      column: $table.nextEnrollmentCreated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => ColumnFilters(column));
}

class $$CompletionQuestionnairesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletionQuestionnairesTableTable> {
  $$CompletionQuestionnairesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptNumber => $composableBuilder(
      column: $table.attemptNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get response => $composableBuilder(
      column: $table.response, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get nextEnrollmentCreated => $composableBuilder(
      column: $table.nextEnrollmentCreated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => ColumnOrderings(column));
}

class $$CompletionQuestionnairesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletionQuestionnairesTableTable> {
  $$CompletionQuestionnairesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => column);

  GeneratedColumn<int> get attemptNumber => $composableBuilder(
      column: $table.attemptNumber, builder: (column) => column);

  GeneratedColumn<bool> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<bool> get nextEnrollmentCreated => $composableBuilder(
      column: $table.nextEnrollmentCreated, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => column);
}

class $$CompletionQuestionnairesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CompletionQuestionnairesTableTable,
    CompletionQuestionnairesTableData,
    $$CompletionQuestionnairesTableTableFilterComposer,
    $$CompletionQuestionnairesTableTableOrderingComposer,
    $$CompletionQuestionnairesTableTableAnnotationComposer,
    $$CompletionQuestionnairesTableTableCreateCompanionBuilder,
    $$CompletionQuestionnairesTableTableUpdateCompanionBuilder,
    (
      CompletionQuestionnairesTableData,
      BaseReferences<_$AppDatabase, $CompletionQuestionnairesTableTable,
          CompletionQuestionnairesTableData>
    ),
    CompletionQuestionnairesTableData,
    PrefetchHooks Function()> {
  $$CompletionQuestionnairesTableTableTableManager(
      _$AppDatabase db, $CompletionQuestionnairesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionQuestionnairesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionQuestionnairesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionQuestionnairesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> enrollmentId = const Value.absent(),
            Value<int> attemptNumber = const Value.absent(),
            Value<bool> response = const Value.absent(),
            Value<String> result = const Value.absent(),
            Value<bool> nextEnrollmentCreated = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<DateTime> submittedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompletionQuestionnairesTableCompanion(
            id: id,
            enrollmentId: enrollmentId,
            attemptNumber: attemptNumber,
            response: response,
            result: result,
            nextEnrollmentCreated: nextEnrollmentCreated,
            needsSync: needsSync,
            subjectProfileId: subjectProfileId,
            submittedAt: submittedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String enrollmentId,
            Value<int> attemptNumber = const Value.absent(),
            required bool response,
            required String result,
            Value<bool> nextEnrollmentCreated = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            required DateTime submittedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CompletionQuestionnairesTableCompanion.insert(
            id: id,
            enrollmentId: enrollmentId,
            attemptNumber: attemptNumber,
            response: response,
            result: result,
            nextEnrollmentCreated: nextEnrollmentCreated,
            needsSync: needsSync,
            subjectProfileId: subjectProfileId,
            submittedAt: submittedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CompletionQuestionnairesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CompletionQuestionnairesTableTable,
        CompletionQuestionnairesTableData,
        $$CompletionQuestionnairesTableTableFilterComposer,
        $$CompletionQuestionnairesTableTableOrderingComposer,
        $$CompletionQuestionnairesTableTableAnnotationComposer,
        $$CompletionQuestionnairesTableTableCreateCompanionBuilder,
        $$CompletionQuestionnairesTableTableUpdateCompanionBuilder,
        (
          CompletionQuestionnairesTableData,
          BaseReferences<_$AppDatabase, $CompletionQuestionnairesTableTable,
              CompletionQuestionnairesTableData>
        ),
        CompletionQuestionnairesTableData,
        PrefetchHooks Function()>;
typedef $$JournalEntriesTableTableCreateCompanionBuilder
    = JournalEntriesTableCompanion Function({
  required String id,
  required String userId,
  Value<String?> enrollmentId,
  Value<String?> checkinId,
  required String content,
  Value<int?> mood,
  Value<int?> energy,
  Value<int?> stress,
  required int dayKey,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> subjectProfileId,
  Value<bool> needsSync,
  Value<int> rowid,
});
typedef $$JournalEntriesTableTableUpdateCompanionBuilder
    = JournalEntriesTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> enrollmentId,
  Value<String?> checkinId,
  Value<String> content,
  Value<int?> mood,
  Value<int?> energy,
  Value<int?> stress,
  Value<int> dayKey,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> subjectProfileId,
  Value<bool> needsSync,
  Value<int> rowid,
});

class $$JournalEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTableTable> {
  $$JournalEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkinId => $composableBuilder(
      column: $table.checkinId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stress => $composableBuilder(
      column: $table.stress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayKey => $composableBuilder(
      column: $table.dayKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));
}

class $$JournalEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTableTable> {
  $$JournalEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkinId => $composableBuilder(
      column: $table.checkinId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stress => $composableBuilder(
      column: $table.stress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayKey => $composableBuilder(
      column: $table.dayKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));
}

class $$JournalEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTableTable> {
  $$JournalEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get enrollmentId => $composableBuilder(
      column: $table.enrollmentId, builder: (column) => column);

  GeneratedColumn<String> get checkinId =>
      $composableBuilder(column: $table.checkinId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<int> get stress =>
      $composableBuilder(column: $table.stress, builder: (column) => column);

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$JournalEntriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JournalEntriesTableTable,
    JournalEntriesTableData,
    $$JournalEntriesTableTableFilterComposer,
    $$JournalEntriesTableTableOrderingComposer,
    $$JournalEntriesTableTableAnnotationComposer,
    $$JournalEntriesTableTableCreateCompanionBuilder,
    $$JournalEntriesTableTableUpdateCompanionBuilder,
    (
      JournalEntriesTableData,
      BaseReferences<_$AppDatabase, $JournalEntriesTableTable,
          JournalEntriesTableData>
    ),
    JournalEntriesTableData,
    PrefetchHooks Function()> {
  $$JournalEntriesTableTableTableManager(
      _$AppDatabase db, $JournalEntriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> enrollmentId = const Value.absent(),
            Value<String?> checkinId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int?> mood = const Value.absent(),
            Value<int?> energy = const Value.absent(),
            Value<int?> stress = const Value.absent(),
            Value<int> dayKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JournalEntriesTableCompanion(
            id: id,
            userId: userId,
            enrollmentId: enrollmentId,
            checkinId: checkinId,
            content: content,
            mood: mood,
            energy: energy,
            stress: stress,
            dayKey: dayKey,
            createdAt: createdAt,
            updatedAt: updatedAt,
            subjectProfileId: subjectProfileId,
            needsSync: needsSync,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> enrollmentId = const Value.absent(),
            Value<String?> checkinId = const Value.absent(),
            required String content,
            Value<int?> mood = const Value.absent(),
            Value<int?> energy = const Value.absent(),
            Value<int?> stress = const Value.absent(),
            required int dayKey,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> subjectProfileId = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JournalEntriesTableCompanion.insert(
            id: id,
            userId: userId,
            enrollmentId: enrollmentId,
            checkinId: checkinId,
            content: content,
            mood: mood,
            energy: energy,
            stress: stress,
            dayKey: dayKey,
            createdAt: createdAt,
            updatedAt: updatedAt,
            subjectProfileId: subjectProfileId,
            needsSync: needsSync,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JournalEntriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JournalEntriesTableTable,
    JournalEntriesTableData,
    $$JournalEntriesTableTableFilterComposer,
    $$JournalEntriesTableTableOrderingComposer,
    $$JournalEntriesTableTableAnnotationComposer,
    $$JournalEntriesTableTableCreateCompanionBuilder,
    $$JournalEntriesTableTableUpdateCompanionBuilder,
    (
      JournalEntriesTableData,
      BaseReferences<_$AppDatabase, $JournalEntriesTableTable,
          JournalEntriesTableData>
    ),
    JournalEntriesTableData,
    PrefetchHooks Function()>;
typedef $$StreakCreditsTableTableCreateCompanionBuilder
    = StreakCreditsTableCompanion Function({
  required String id,
  required String userId,
  required String subjectProfileId,
  Value<int> available,
  Value<int> progressToNext,
  Value<DateTime?> lastCountedDay,
  Value<String> rescuedDays,
  Value<bool> needsSync,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$StreakCreditsTableTableUpdateCompanionBuilder
    = StreakCreditsTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> subjectProfileId,
  Value<int> available,
  Value<int> progressToNext,
  Value<DateTime?> lastCountedDay,
  Value<String> rescuedDays,
  Value<bool> needsSync,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StreakCreditsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StreakCreditsTableTable> {
  $$StreakCreditsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get available => $composableBuilder(
      column: $table.available, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progressToNext => $composableBuilder(
      column: $table.progressToNext,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCountedDay => $composableBuilder(
      column: $table.lastCountedDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rescuedDays => $composableBuilder(
      column: $table.rescuedDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$StreakCreditsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StreakCreditsTableTable> {
  $$StreakCreditsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get available => $composableBuilder(
      column: $table.available, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progressToNext => $composableBuilder(
      column: $table.progressToNext,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCountedDay => $composableBuilder(
      column: $table.lastCountedDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rescuedDays => $composableBuilder(
      column: $table.rescuedDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$StreakCreditsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreakCreditsTableTable> {
  $$StreakCreditsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get subjectProfileId => $composableBuilder(
      column: $table.subjectProfileId, builder: (column) => column);

  GeneratedColumn<int> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  GeneratedColumn<int> get progressToNext => $composableBuilder(
      column: $table.progressToNext, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCountedDay => $composableBuilder(
      column: $table.lastCountedDay, builder: (column) => column);

  GeneratedColumn<String> get rescuedDays => $composableBuilder(
      column: $table.rescuedDays, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StreakCreditsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StreakCreditsTableTable,
    StreakCreditsTableData,
    $$StreakCreditsTableTableFilterComposer,
    $$StreakCreditsTableTableOrderingComposer,
    $$StreakCreditsTableTableAnnotationComposer,
    $$StreakCreditsTableTableCreateCompanionBuilder,
    $$StreakCreditsTableTableUpdateCompanionBuilder,
    (
      StreakCreditsTableData,
      BaseReferences<_$AppDatabase, $StreakCreditsTableTable,
          StreakCreditsTableData>
    ),
    StreakCreditsTableData,
    PrefetchHooks Function()> {
  $$StreakCreditsTableTableTableManager(
      _$AppDatabase db, $StreakCreditsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakCreditsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakCreditsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakCreditsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> subjectProfileId = const Value.absent(),
            Value<int> available = const Value.absent(),
            Value<int> progressToNext = const Value.absent(),
            Value<DateTime?> lastCountedDay = const Value.absent(),
            Value<String> rescuedDays = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StreakCreditsTableCompanion(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            available: available,
            progressToNext: progressToNext,
            lastCountedDay: lastCountedDay,
            rescuedDays: rescuedDays,
            needsSync: needsSync,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String subjectProfileId,
            Value<int> available = const Value.absent(),
            Value<int> progressToNext = const Value.absent(),
            Value<DateTime?> lastCountedDay = const Value.absent(),
            Value<String> rescuedDays = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StreakCreditsTableCompanion.insert(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            available: available,
            progressToNext: progressToNext,
            lastCountedDay: lastCountedDay,
            rescuedDays: rescuedDays,
            needsSync: needsSync,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StreakCreditsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StreakCreditsTableTable,
    StreakCreditsTableData,
    $$StreakCreditsTableTableFilterComposer,
    $$StreakCreditsTableTableOrderingComposer,
    $$StreakCreditsTableTableAnnotationComposer,
    $$StreakCreditsTableTableCreateCompanionBuilder,
    $$StreakCreditsTableTableUpdateCompanionBuilder,
    (
      StreakCreditsTableData,
      BaseReferences<_$AppDatabase, $StreakCreditsTableTable,
          StreakCreditsTableData>
    ),
    StreakCreditsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EnrollmentsTableTableTableManager get enrollmentsTable =>
      $$EnrollmentsTableTableTableManager(_db, _db.enrollmentsTable);
  $$ExercisesTableTableTableManager get exercisesTable =>
      $$ExercisesTableTableTableManager(_db, _db.exercisesTable);
  $$TrainingSessionsTableTableTableManager get trainingSessionsTable =>
      $$TrainingSessionsTableTableTableManager(_db, _db.trainingSessionsTable);
  $$ProgressEntriesTableTableTableManager get progressEntriesTable =>
      $$ProgressEntriesTableTableTableManager(_db, _db.progressEntriesTable);
  $$MoodCheckinsTableTableTableManager get moodCheckinsTable =>
      $$MoodCheckinsTableTableTableManager(_db, _db.moodCheckinsTable);
  $$SyncJobsTableTableTableManager get syncJobsTable =>
      $$SyncJobsTableTableTableManager(_db, _db.syncJobsTable);
  $$IntakeAssessmentsTableTableTableManager get intakeAssessmentsTable =>
      $$IntakeAssessmentsTableTableTableManager(
          _db, _db.intakeAssessmentsTable);
  $$CompletionQuestionnairesTableTableTableManager
      get completionQuestionnairesTable =>
          $$CompletionQuestionnairesTableTableTableManager(
              _db, _db.completionQuestionnairesTable);
  $$JournalEntriesTableTableTableManager get journalEntriesTable =>
      $$JournalEntriesTableTableTableManager(_db, _db.journalEntriesTable);
  $$StreakCreditsTableTableTableManager get streakCreditsTable =>
      $$StreakCreditsTableTableTableManager(_db, _db.streakCreditsTable);
}
