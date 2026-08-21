import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/active_localizations.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_draft_meta.dart';

class ReflexSubjectProfile {
  const ReflexSubjectProfile({
    required this.id,
    required this.displayName,
    required this.profileType,
    this.birthDate,
    this.ageYears,
    this.ageMonths,
    this.ageGroup,
  });

  final String id;
  final String displayName;
  final String profileType;
  final DateTime? birthDate;
  final int? ageYears;
  final int? ageMonths;
  final String? ageGroup;

  factory ReflexSubjectProfile.fromJson(Map<String, dynamic> json) {
    return ReflexSubjectProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      profileType: json['profile_type'] as String? ?? 'child',
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      ageYears: json['age_years'] as int?,
      ageMonths: json['age_months'] as int?,
      ageGroup: json['age_group'] as String?,
    );
  }
}

class ReflexTrainerShareLookup {
  const ReflexTrainerShareLookup({
    required this.subjectProfileId,
    required this.trainerId,
  });

  final String subjectProfileId;
  final String trainerId;

  @override
  bool operator ==(Object other) =>
      other is ReflexTrainerShareLookup &&
      other.subjectProfileId == subjectProfileId &&
      other.trainerId == trainerId;

  @override
  int get hashCode => Object.hash(subjectProfileId, trainerId);
}

class ReflexProfileSummary {
  const ReflexProfileSummary({required this.profile, this.latestAssessment});

  final ReflexSubjectProfile profile;
  final ReflexProfileAssessment? latestAssessment;
}

/// All child profiles owned by the current user, each paired with their latest
/// completed assessment (or null if none exists yet).
final profilesWithAssessmentsProvider =
    FutureProvider<List<ReflexProfileSummary>>((ref) async {
  final profiles = await ref.watch(reflexSubjectProfilesProvider.future);
  if (profiles.isEmpty) return [];

  final profileIds = profiles.map((p) => p.id).toList();

  final rows = await Supabase.instance.client
      .from('reflex_profile_assessments')
      .select()
      .inFilter('subject_profile_id', profileIds)
      .eq('status', 'completed')
      .order('completed_at', ascending: false);

  final latestByProfile = <String, ReflexProfileAssessment>{};
  for (final row in (rows as List).cast<Map<String, dynamic>>()) {
    final pid = row['subject_profile_id'] as String?;
    if (pid != null && !latestByProfile.containsKey(pid)) {
      latestByProfile[pid] = ReflexProfileAssessment.fromJson(row);
    }
  }

  return profiles
      .map((p) => ReflexProfileSummary(
            profile: p,
            latestAssessment: latestByProfile[p.id],
          ))
      .toList();
});

final latestReflexProfileProvider =
    FutureProvider<ReflexProfileAssessment?>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final response = await Supabase.instance.client.rpc(
    'get_latest_reflex_profile_assessment',
  );
  final rows = (response as List).cast<Map<String, dynamic>>();
  if (rows.isEmpty) return null;
  return ReflexProfileAssessment.fromJson(rows.first);
});

final allReflexSubjectProfilesProvider =
    FutureProvider<List<ReflexSubjectProfile>>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .from('reflex_subject_profiles')
      .select()
      .eq('owner_user_id', userId)
      .order('created_at', ascending: false);

  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(ReflexSubjectProfile.fromJson)
      .toList();
});

/// Child profiles owned by the current user.
///
/// The Reflex questionnaire is currently a parent-report flow, so screens that
/// start or summarize that questionnaire should not receive adult_self entries.
final reflexSubjectProfilesProvider =
    FutureProvider<List<ReflexSubjectProfile>>((ref) async {
  final profiles = await ref.watch(allReflexSubjectProfilesProvider.future);
  return profiles.where((profile) => profile.profileType == 'child').toList();
});

class SelectedSubjectProfileNotifier extends StateNotifier<String?> {
  SelectedSubjectProfileNotifier(this._ref, this._userId)
      : super(_ref
            .read(sharedPreferencesProvider)
            .getString(_storageKeyFor(_userId)));

  final Ref _ref;
  final String? _userId;

  static String _storageKeyFor(String? userId) => userId == null
      ? 'selected_subject_profile_id'
      : 'selected_subject_profile_id_$userId';

  void select(String? subjectProfileId) {
    state = subjectProfileId;
    final prefs = _ref.read(sharedPreferencesProvider);
    final key = _storageKeyFor(_userId);
    if (subjectProfileId == null) {
      prefs.remove(key);
    } else {
      prefs.setString(key, subjectProfileId);
    }
  }
}

final selectedSubjectProfileIdProvider =
    StateNotifierProvider<SelectedSubjectProfileNotifier, String?>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  return SelectedSubjectProfileNotifier(ref, userId);
});

final selectedSubjectProfileProvider = Provider<ReflexSubjectProfile?>((ref) {
  final profiles = ref.watch(allReflexSubjectProfilesProvider).valueOrNull;
  if (profiles == null || profiles.isEmpty) return null;

  final selectedId = ref.watch(selectedSubjectProfileIdProvider);
  for (final profile in profiles) {
    if (profile.id == selectedId) return profile;
  }
  return profiles.first;
});

/// Latest completed assessment for a specific subject profile ID.
final latestReflexProfileForSubjectProvider =
    FutureProvider.family<ReflexProfileAssessment?, String>(
        (ref, subjectProfileId) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final rows = await Supabase.instance.client
      .from('reflex_profile_assessments')
      .select()
      .eq('subject_profile_id', subjectProfileId)
      .eq('user_id', userId)
      .eq('status', 'completed')
      .order('completed_at', ascending: false)
      .limit(1);

  final list = (rows as List).cast<Map<String, dynamic>>();
  if (list.isEmpty) return null;
  return ReflexProfileAssessment.fromJson(list.first);
});

/// Latest completed assessment for the currently selected subject profile.
final latestReflexProfileForSelectedSubjectProvider =
    FutureProvider<ReflexProfileAssessment?>((ref) async {
  final selectedProfile = ref.watch(selectedSubjectProfileProvider);
  if (selectedProfile == null) return null;
  return ref
      .watch(latestReflexProfileForSubjectProvider(selectedProfile.id).future);
});

final reflexProfileTrainerShareProvider =
    FutureProvider.family<bool, ReflexTrainerShareLookup>((ref, lookup) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  final row = await Supabase.instance.client
      .from('reflex_profile_trainer_shares')
      .select('id')
      .eq('owner_user_id', userId)
      .eq('subject_profile_id', lookup.subjectProfileId)
      .eq('trainer_id', lookup.trainerId)
      .isFilter('revoked_at', null)
      .maybeSingle();
  return row != null;
});

/// Saves in-progress questionnaire state as a draft. Errors are silenced so
/// that a network failure never blocks the user from completing the form.
Future<void> saveReflexProfileDraft({
  required String subjectProfileId,
  required String packageId,
  required String questionnaireVersion,
  required Map<String, dynamic> answersJson,
  required List<Map<String, dynamic>> warningConfirmations,
  required int currentModuleIndex,
  required String questionnaireFor,
  Map<String, String> filterAnswers = const {},
  DateTime? startedAt,
  Map<String, dynamic> moduleTimings = const {},
  List<String> supersededItemIds = const [],
}) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final payload = {
      ...answersJson,
      '__meta': ReflexDraftMeta(
        moduleIndex: currentModuleIndex,
        questionnaireFor: questionnaireFor,
        questionnaireVersion: questionnaireVersion,
        filterAnswers: filterAnswers,
        startedAt: startedAt,
        moduleTimings: moduleTimings,
        supersededItemIds: supersededItemIds,
      ).toJson(),
    };

    final existing = await Supabase.instance.client
        .from('reflex_profile_assessments')
        .select('id')
        .eq('subject_profile_id', subjectProfileId)
        .eq('user_id', userId)
        .eq('status', 'draft')
        .maybeSingle();

    if (existing == null) {
      await Supabase.instance.client.from('reflex_profile_assessments').insert({
        'subject_profile_id': subjectProfileId,
        'user_id': userId,
        'package_id': packageId,
        'questionnaire_type': 'child_parent_report',
        'questionnaire_version': questionnaireVersion,
        'status': 'draft',
        'answers': payload,
        'scores': <String, dynamic>{},
        'warning_confirmations': warningConfirmations,
        'safety_status': 'pending',
      });
    } else {
      await Supabase.instance.client.from('reflex_profile_assessments').update({
        'answers': payload,
        'warning_confirmations': warningConfirmations,
      }).eq('id', existing['id'] as String);
    }
  } catch (_) {
    // Silent: draft failures must not interrupt the questionnaire flow
  }
}

/// Loads an existing draft for [subjectProfileId], or null if none exists.
Future<Map<String, dynamic>?> loadReflexProfileDraft(
    String subjectProfileId) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    return await Supabase.instance.client
        .from('reflex_profile_assessments')
        .select()
        .eq('subject_profile_id', subjectProfileId)
        .eq('user_id', userId)
        .eq('status', 'draft')
        .maybeSingle();
  } catch (_) {
    return null;
  }
}

/// Deletes any draft for [subjectProfileId]. Called after successful submission.
Future<void> deleteReflexProfileDraft(String subjectProfileId) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('reflex_profile_assessments')
        .delete()
        .eq('subject_profile_id', subjectProfileId)
        .eq('user_id', userId)
        .eq('status', 'draft');
  } catch (_) {}
}

Future<void> recordReflexProfileSkipped(
  WidgetRef ref, {
  required String packageId,
}) async {
  await Supabase.instance.client.rpc(
    'record_reflex_profile_skip',
    params: {'p_package_id': packageId},
  );
  ref.invalidate(latestReflexProfileProvider);
  ref.invalidate(latestReflexProfileForSubjectProvider);
}

Future<ReflexSubjectProfile> createAdultSelfProfile(
  WidgetRef ref, {
  String? displayName,
  DateTime? birthDate,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not signed in.');

  final resolvedName =
      displayName ?? (await lookupActiveAppLocalizations()).selfName;

  final payload = <String, dynamic>{
    'owner_user_id': userId,
    'profile_type': 'adult_self',
    'display_name': resolvedName.trim().isEmpty
        ? (await lookupActiveAppLocalizations()).selfName
        : resolvedName.trim(),
  };
  if (birthDate != null) {
    final now = DateTime.now();
    final ageMonths =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    final ageYears = ageMonths ~/ 12;
    payload['birth_date'] =
        '${birthDate.year.toString().padLeft(4, '0')}'
        '-${birthDate.month.toString().padLeft(2, '0')}'
        '-${birthDate.day.toString().padLeft(2, '0')}';
    payload['age_years'] = ageYears;
    payload['age_months'] = ageMonths;
  }

  final row = await Supabase.instance.client
      .from('reflex_subject_profiles')
      .insert(payload)
      .select()
      .single();

  ref.invalidate(allReflexSubjectProfilesProvider);
  ref.invalidate(reflexSubjectProfilesProvider);
  final profile = ReflexSubjectProfile.fromJson(row);
  ref.read(selectedSubjectProfileIdProvider.notifier).select(profile.id);
  return profile;
}

Future<ReflexSubjectProfile> createChildReflexSubjectProfile(
  WidgetRef ref, {
  required String displayName,
  required DateTime birthDate,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not signed in.');

  final now = DateTime.now();
  final ageMonths =
      (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
  final ageYears = ageMonths ~/ 12;
  final ageGroup = _ageGroupForYears(ageYears);
  final row = await Supabase.instance.client
      .from('reflex_subject_profiles')
      .insert({
        'owner_user_id': userId,
        'profile_type': 'child',
        'display_name': displayName.trim(),
        'birth_date': '${birthDate.year.toString().padLeft(4, '0')}'
            '-${birthDate.month.toString().padLeft(2, '0')}'
            '-${birthDate.day.toString().padLeft(2, '0')}',
        'age_years': ageYears,
        'age_months': ageMonths,
        'age_group': ageGroup,
      })
      .select()
      .single();

  ref.invalidate(allReflexSubjectProfilesProvider);
  ref.invalidate(reflexSubjectProfilesProvider);
  final profile = ReflexSubjectProfile.fromJson(row);
  ref.read(selectedSubjectProfileIdProvider.notifier).select(profile.id);
  return profile;
}

Future<ReflexSubjectProfile> updateReflexSubjectProfile(
  WidgetRef ref, {
  required String subjectProfileId,
  required String displayName,
  DateTime? birthDate,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not signed in.');

  final trimmedName = displayName.trim();
  if (trimmedName.isEmpty) {
    final l10n = await lookupActiveAppLocalizations();
    throw Exception(l10n.reflexProfileNameRequired);
  }

  final payload = <String, dynamic>{
    'display_name': trimmedName,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  if (birthDate != null) {
    final now = DateTime.now();
    final ageMonths =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    final ageYears = ageMonths ~/ 12;
    payload.addAll({
      'birth_date': '${birthDate.year.toString().padLeft(4, '0')}'
          '-${birthDate.month.toString().padLeft(2, '0')}'
          '-${birthDate.day.toString().padLeft(2, '0')}',
      'age_years': ageYears,
      'age_months': ageMonths,
      'age_group': _ageGroupForYears(ageYears),
    });
  }

  final row = await Supabase.instance.client
      .from('reflex_subject_profiles')
      .update(payload)
      .eq('id', subjectProfileId)
      .eq('owner_user_id', userId)
      .select()
      .single();

  ref.invalidate(allReflexSubjectProfilesProvider);
  ref.invalidate(reflexSubjectProfilesProvider);
  ref.invalidate(profilesWithAssessmentsProvider);
  return ReflexSubjectProfile.fromJson(row);
}

Future<String> submitReflexProfileAssessment(
  WidgetRef ref, {
  required String subjectProfileId,
  required String packageId,
  required String questionnaireType,
  required String questionnaireVersion,
  required Map<String, dynamic> answers,
  required Map<String, dynamic> scores,
  required List<Map<String, dynamic>> warningConfirmations,
  required String safetyStatus,
}) async {
  final id = await Supabase.instance.client.rpc(
    'submit_reflex_profile_assessment',
    params: {
      'p_subject_profile_id': subjectProfileId,
      'p_package_id': packageId,
      'p_questionnaire_type': questionnaireType,
      'p_questionnaire_version': questionnaireVersion,
      'p_answers': answers,
      'p_scores': scores,
      'p_warning_confirmations': warningConfirmations,
      'p_safety_status': safetyStatus,
    },
  ) as String;

  ref.invalidate(latestReflexProfileProvider);
  ref.invalidate(latestReflexProfileForSubjectProvider);
  ref.invalidate(profilesWithAssessmentsProvider);
  return id;
}

Future<void> grantReflexProfileTrainerShare(
  WidgetRef ref, {
  required String subjectProfileId,
  required String trainerId,
  required String relationshipId,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not signed in.');

  final existing = await Supabase.instance.client
      .from('reflex_profile_trainer_shares')
      .select('id')
      .eq('owner_user_id', userId)
      .eq('subject_profile_id', subjectProfileId)
      .eq('trainer_id', trainerId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  final now = DateTime.now().toUtc().toIso8601String();
  if (existing == null) {
    await Supabase.instance.client
        .from('reflex_profile_trainer_shares')
        .insert({
      'subject_profile_id': subjectProfileId,
      'owner_user_id': userId,
      'trainer_id': trainerId,
      'relationship_id': relationshipId,
      'scope': 'full_profile',
      'granted_at': now,
      'updated_at': now,
    });
  } else {
    await Supabase.instance.client
        .from('reflex_profile_trainer_shares')
        .update({
      'relationship_id': relationshipId,
      'scope': 'full_profile',
      'granted_at': now,
      'revoked_at': null,
      'updated_at': now,
    }).eq('id', existing['id'] as String);
  }
  _invalidateShareState(
    ref,
    subjectProfileId: subjectProfileId,
    trainerId: trainerId,
  );
}

Future<void> revokeReflexProfileTrainerShare(
  WidgetRef ref, {
  required String subjectProfileId,
  required String trainerId,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not signed in.');

  await Supabase.instance.client
      .from('reflex_profile_trainer_shares')
      .update({
        'revoked_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('owner_user_id', userId)
      .eq('subject_profile_id', subjectProfileId)
      .eq('trainer_id', trainerId)
      .isFilter('revoked_at', null);
  _invalidateShareState(
    ref,
    subjectProfileId: subjectProfileId,
    trainerId: trainerId,
  );
}

void _invalidateShareState(
  WidgetRef ref, {
  required String subjectProfileId,
  required String trainerId,
}) {
  ref.invalidate(
    reflexProfileTrainerShareProvider(
      ReflexTrainerShareLookup(
        subjectProfileId: subjectProfileId,
        trainerId: trainerId,
      ),
    ),
  );
  ref.invalidate(latestReflexProfileProvider);
  ref.invalidate(latestReflexProfileForSubjectProvider);
  ref.invalidate(profilesWithAssessmentsProvider);
}

String _ageGroupForYears(int ageYears) {
  if (ageYears <= 2) return '0-2';
  if (ageYears <= 4) return '3-4';
  if (ageYears <= 7) return '5-7';
  if (ageYears <= 10) return '8-10';
  if (ageYears <= 13) return '11-13';
  if (ageYears <= 17) return '14-17';
  return '18+';
}
