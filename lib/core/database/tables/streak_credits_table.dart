import 'package:drift/drift.dart';

/// Freischein ledger, one row per subject profile.
///
/// The series itself is derived from `training_sessions` and is deliberately
/// not stored here (spec §4.1). Only [rescuedDays] cannot be derived — that a
/// missed day was forgiven leaves no other trace.
class StreakCreditsTable extends Table {
  @override
  String get tableName => 'streak_credits';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get subjectProfileId => text()();

  /// Credits ready to be spent, 0..2.
  IntColumn get available => integer().withDefault(const Constant(0))();

  /// Training days counted towards the next credit, 0..2.
  IntColumn get progressToNext => integer().withDefault(const Constant(0))();

  /// Latest training day already counted, date-only.
  DateTimeColumn get lastCountedDay => dateTime().nullable()();

  /// Rescued days as a JSON-encoded list of `yyyy-MM-dd` strings.
  TextColumn get rescuedDays => text().withDefault(const Constant('[]'))();

  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
