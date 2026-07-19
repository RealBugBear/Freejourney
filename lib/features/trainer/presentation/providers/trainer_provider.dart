import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/active_localizations.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../assessment/domain/models/reflex_profile_assessment.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';

// ── User role ─────────────────────────────────────────────────────────────────

final userRoleProvider = FutureProvider<String>((ref) async {
  // Re-run automatically on every auth state change (sign-in / sign-out).
  // Without this, a manual invalidate() during sign-out could race with the
  // Supabase sign-out call and cache 'practitioner' for the next session.
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'practitioner';
  final res = await Supabase.instance.client
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .single();
  return res['role'] as String? ?? 'practitioner';
});

// ── Trainer clients ───────────────────────────────────────────────────────────

class TrainerClientsNotifier extends AsyncNotifier<List<TrainerClient>> {
  @override
  Future<List<TrainerClient>> build() {
    ref.watch(authStateProvider);
    return _fetch();
  }

  Future<List<TrainerClient>> _fetch() async {
    if (Supabase.instance.client.auth.currentUser == null) return [];

    await Supabase.instance.client.rpc('reconcile_trainer_clients');
    final res = await Supabase.instance.client.rpc('get_trainer_clients');
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(TrainerClient.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String> generateInviteCode() async {
    final code =
        await Supabase.instance.client.rpc('create_invite_code') as String;
    await refresh();
    return code;
  }

  Future<void> saveNotes(String relationshipId, String notes) async {
    await Supabase.instance.client
        .from('trainer_client_relationships')
        .update({'trainer_notes': notes}).eq('id', relationshipId);
    await refresh();
  }
}

final trainerClientsProvider =
    AsyncNotifierProvider<TrainerClientsNotifier, List<TrainerClient>>(
  TrainerClientsNotifier.new,
);

final trainerOpenInvitesProvider =
    FutureProvider<List<TrainerOpenInvite>>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('id, invite_code, created_at')
      .eq('trainer_id', userId)
      .eq('status', 'pending')
      .eq('source_type', 'invite')
      .isFilter('client_id', null)
      .not('invite_code', 'is', null)
      .order('created_at', ascending: false);

  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(TrainerOpenInvite.fromJson)
      .where((invite) => invite.code.trim().isNotEmpty)
      .toList();
});

final trainerRecentObservationsProvider =
    FutureProvider<List<TrainerClientObservation>>((ref) async {
  final clients = await ref.watch(trainerClientsProvider.future);
  if (clients.isEmpty) return [];

  final namesById = {for (final client in clients) client.clientId: client};
  final l10n = await lookupActiveAppLocalizations();
  final rows = await Supabase.instance.client
      .from('mood_checkins')
      .select('id, user_id, recorded_at, note, mood, energy, stress, source')
      .inFilter('user_id', namesById.keys.toList())
      .not('note', 'is', null)
      .neq('note', '')
      .order('recorded_at', ascending: false)
      .limit(12);

  return (rows as List).cast<Map<String, dynamic>>().map((row) {
    final clientId = row['user_id'] as String;
    final name = namesById[clientId]?.displayName.trim();
    return TrainerClientObservation.fromJson(
      row,
      clientName:
          (name != null && name.isNotEmpty) ? name : l10n.clientFallbackName,
    );
  }).toList();
});

final trainerClientObservationsProvider =
    FutureProvider.family<List<TrainerClientObservation>, String>(
  (ref, clientId) async {
    final clients = await ref.watch(trainerClientsProvider.future);
    final client = clients.where((c) => c.clientId == clientId).firstOrNull;
    if (client == null) return [];

    final rows = await Supabase.instance.client
        .from('mood_checkins')
        .select('id, user_id, recorded_at, note, mood, energy, stress, source')
        .eq('user_id', clientId)
        .not('note', 'is', null)
        .neq('note', '')
        .order('recorded_at', ascending: false)
        .limit(20);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => TrainerClientObservation.fromJson(
            row,
            clientName: client.displayName,
          ),
        )
        .toList();
  },
);

final trainerClientsDebugProvider = FutureProvider<String>((ref) async {
  ref.watch(authStateProvider);

  final l10n = await lookupActiveAppLocalizations();
  final sb = Supabase.instance.client;
  final user = sb.auth.currentUser;
  if (user == null) return l10n.trainerDiagNotSignedIn;

  final lines = <String>[
    l10n.trainerDiagAuthUid(user.id),
    l10n.trainerDiagEmail(user.email ?? '-'),
  ];

  try {
    final profile = await sb
        .from('profiles')
        .select('role, display_name')
        .eq('id', user.id)
        .maybeSingle();
    lines.add(l10n.trainerDiagProfileRole('${profile?['role'] ?? '-'}'));
    lines.add(
      l10n.trainerDiagProfileName('${profile?['display_name'] ?? '-'}'),
    );
  } catch (e) {
    lines.add(l10n.trainerDiagScopeError('profiles', '$e'));
  }

  try {
    final relationships = await sb
        .from('trainer_client_relationships')
        .select('id, client_id, status, linked_at')
        .eq('trainer_id', user.id);
    final list = (relationships as List).cast<Map<String, dynamic>>();
    lines.add(l10n.trainerDiagRelationshipsTotal(list.length));
    lines.add(
      l10n.trainerDiagRelationshipsActive(
        list.where((r) => r['status'] == 'active').length,
      ),
    );
    if (list.isNotEmpty) {
      lines.add(
        l10n.trainerDiagRelationshipStatuses(
          list.map((r) => r['status']).join(', '),
        ),
      );
      lines.add(l10n.trainerDiagRelationshipClientIds);
      for (final row in list.take(5)) {
        lines.add('- ${row['client_id']} (${row['status']})');
      }
    }
  } catch (e) {
    lines.add(l10n.trainerDiagScopeError('relationships', '$e'));
  }

  try {
    final appointments = await sb
        .from('appointments')
        .select('id, trainee_id, status, scheduled_for')
        .eq('trainer_id', user.id);
    final list = (appointments as List).cast<Map<String, dynamic>>();
    lines.add(l10n.trainerDiagAppointmentsAsTrainer(list.length));
    if (list.isNotEmpty) {
      lines.add(l10n.trainerDiagAppointmentTraineeIds);
      for (final row in list.take(5)) {
        lines.add('- ${row['trainee_id']} (${row['status']})');
      }
    }
  } catch (e) {
    lines.add(l10n.trainerDiagScopeError('appointments', '$e'));
  }

  try {
    await sb.rpc('reconcile_trainer_clients');
    lines.add(l10n.trainerDiagReconcileOk);
  } catch (e) {
    lines.add(l10n.trainerDiagScopeError('reconcile_trainer_clients', '$e'));
  }

  try {
    final clients = await sb.rpc('get_trainer_clients');
    final list = clients as List;
    lines.add(l10n.trainerDiagGetClientsRows(list.length));
    if (list.isNotEmpty) {
      for (final row in list.take(5)) {
        lines.add('- ${row['client_id']} ${row['display_name']}');
      }
    }
  } catch (e) {
    lines.add(l10n.trainerDiagScopeError('get_trainer_clients', '$e'));
  }

  return lines.join('\n');
});

// ── Client sessions (for detail screen) ──────────────────────────────────────

final clientSessionsProvider =
    FutureProvider.family<List<ClientSession>, String>((ref, clientId) async {
  final res = await Supabase.instance.client
      .rpc('get_client_sessions', params: {'p_client_id': clientId});
  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map(ClientSession.fromJson).toList();
});

final trainerClientReflexProfileProvider =
    FutureProvider.family<ReflexProfileAssessment?, String>(
  (ref, clientId) async {
    ref.watch(authStateProvider);
    if (Supabase.instance.client.auth.currentUser == null) return null;

    final rows = await Supabase.instance.client
        .from('reflex_profile_assessments')
        .select()
        .eq('user_id', clientId)
        .eq('status', 'completed')
        .neq('questionnaire_type', 'demo_child_short')
        .order('completed_at', ascending: false)
        .limit(1);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return ReflexProfileAssessment.fromJson(list.first);
  },
);

class TrainerSharedProfile {
  const TrainerSharedProfile({
    required this.subjectProfileId,
    required this.displayName,
    required this.profileType,
    this.ageGroup,
    this.ageYears,
    this.latestAssessment,
  });

  final String subjectProfileId;
  final String displayName;
  final String profileType;
  final String? ageGroup;
  final int? ageYears;
  final ReflexProfileAssessment? latestAssessment;
}

/// All subject profiles a specific client has shared with the current trainer,
/// each paired with their latest completed assessment. Revocation is enforced
/// server-side via the RLS policy on reflex_profile_trainer_shares.
final trainerClientSharedProfilesProvider =
    FutureProvider.family<List<TrainerSharedProfile>, String>(
  (ref, clientId) async {
    ref.watch(authStateProvider);
    if (Supabase.instance.client.auth.currentUser == null) return [];

    final sharesRows = await Supabase.instance.client
        .from('reflex_profile_trainer_shares')
        .select('subject_profile_id')
        .eq('owner_user_id', clientId)
        .isFilter('revoked_at', null);

    final profileIds = (sharesRows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => r['subject_profile_id'] as String)
        .toList();

    if (profileIds.isEmpty) return [];

    final profileRows = await Supabase.instance.client
        .from('reflex_subject_profiles')
        .select('id, display_name, profile_type, age_group, age_years')
        .inFilter('id', profileIds);

    final assessmentRows = await Supabase.instance.client
        .from('reflex_profile_assessments')
        .select()
        .inFilter('subject_profile_id', profileIds)
        .eq('user_id', clientId)
        .eq('status', 'completed')
        .neq('questionnaire_type', 'demo_child_short')
        .order('completed_at', ascending: false);

    final latestByProfile = <String, ReflexProfileAssessment>{};
    for (final row in (assessmentRows as List).cast<Map<String, dynamic>>()) {
      final pid = row['subject_profile_id'] as String?;
      if (pid != null && !latestByProfile.containsKey(pid)) {
        latestByProfile[pid] = ReflexProfileAssessment.fromJson(row);
      }
    }

    return (profileRows as List).cast<Map<String, dynamic>>().map((row) {
      final id = row['id'] as String;
      return TrainerSharedProfile(
        subjectProfileId: id,
        displayName: row['display_name'] as String? ?? '',
        profileType: row['profile_type'] as String? ?? 'child',
        ageGroup: row['age_group'] as String?,
        ageYears: row['age_years'] as int?,
        latestAssessment: latestByProfile[id],
      );
    }).toList();
  },
);

class ReflexSubjectProfileNote {
  const ReflexSubjectProfileNote({
    required this.id,
    required this.subjectProfileId,
    required this.body,
    required this.noteType,
    required this.visibility,
    required this.createdAt,
  });

  final String id;
  final String subjectProfileId;
  final String body;
  final String noteType;
  final String visibility;
  final DateTime createdAt;

  factory ReflexSubjectProfileNote.fromJson(Map<String, dynamic> json) {
    return ReflexSubjectProfileNote(
      id: json['id'] as String,
      subjectProfileId: json['subject_profile_id'] as String,
      body: json['body'] as String? ?? '',
      noteType: json['note_type'] as String? ?? 'handover',
      visibility: json['visibility'] as String? ?? 'handover_visible',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

final reflexSubjectProfileNotesProvider =
    FutureProvider.family<List<ReflexSubjectProfileNote>, String>(
  (ref, subjectProfileId) async {
    ref.watch(authStateProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await Supabase.instance.client
        .from('reflex_subject_profile_notes')
        .select(
            'id, subject_profile_id, body, note_type, visibility, created_at')
        .eq('subject_profile_id', subjectProfileId)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ReflexSubjectProfileNote.fromJson)
        .toList();
  },
);

Future<void> addReflexSubjectProfileNote({
  required WidgetRef ref,
  required String subjectProfileId,
  required String ownerUserId,
  required String relatedAssessmentId,
  required String body,
}) async {
  final trainerId = Supabase.instance.client.auth.currentUser?.id;
  if (trainerId == null) {
    throw Exception((await lookupActiveAppLocalizations()).trainerNotSignedIn);
  }

  await Supabase.instance.client.from('reflex_subject_profile_notes').insert({
    'subject_profile_id': subjectProfileId,
    'owner_user_id': ownerUserId,
    'author_trainer_id': trainerId,
    'related_assessment_id': relatedAssessmentId,
    'note_type': 'handover',
    'body': body.trim(),
    'visibility': 'handover_visible',
  });

  ref.invalidate(reflexSubjectProfileNotesProvider(subjectProfileId));
}

// ── Appointments (trainer view — confirmed/planned) ───────────────────────────

final _appointmentsRefreshTickProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (tick) => tick);
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  ref.watch(authStateProvider);
  ref.watch(_appointmentsRefreshTickProvider);
  final clients = await ref.watch(trainerClientsProvider.future);
  final clientNamesById = {
    for (final client in clients) client.clientId: client.displayName,
  };

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('appointments')
      .select('*, profiles!trainee_id(display_name)')
      .eq('trainer_id', userId)
      .inFilter('status', ['planned', 'confirmed']).order('scheduled_for',
          ascending: true);

  final list = (res as List).cast<Map<String, dynamic>>();
  if (list.isEmpty) return [];

  // Enrich with subject profile names from the join table.
  final appointmentIds = list.map((r) => r['id'] as String).toList();
  final profileLinkRows = await Supabase.instance.client
      .from('appointment_subject_profiles')
      .select(
          'appointment_id, subject_profile_id, reflex_subject_profiles(display_name)')
      .inFilter('appointment_id', appointmentIds);

  final profilesByAppointment =
      <String, ({List<String> ids, List<String> names})>{};
  for (final row in (profileLinkRows as List).cast<Map<String, dynamic>>()) {
    final apptId = row['appointment_id'] as String;
    final profileId = row['subject_profile_id'] as String;
    final profileName =
        (row['reflex_subject_profiles'] as Map?)?['display_name'] as String? ??
            profileId;
    final entry =
        profilesByAppointment[apptId] ?? (ids: <String>[], names: <String>[]);
    profilesByAppointment[apptId] = (
      ids: [...entry.ids, profileId],
      names: [...entry.names, profileName],
    );
  }

  return list.map((row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final traineeId = row['trainee_id'] as String?;
    final relationshipName =
        traineeId == null ? null : clientNamesById[traineeId];
    final name = relationshipName?.trim().isNotEmpty == true
        ? relationshipName!.trim()
        : (profile?['display_name'] as String?)?.trim() ?? '';
    final apptId = row['id'] as String;
    final linked = profilesByAppointment[apptId];
    return Appointment.fromJson({
      ...row,
      'trainee_name': name,
      if (linked != null) 'subject_profile_ids': linked.ids,
      if (linked != null) 'subject_profile_names': linked.names,
    });
  }).toList();
});

// ── Pending proposals (trainee view) ─────────────────────────────────────────

final traineeProposalsProvider = FutureProvider<List<Appointment>>((ref) async {
  ref.watch(authStateProvider);
  ref.watch(_appointmentsRefreshTickProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('appointments')
      .select('*, profiles!trainer_id(display_name)')
      .eq('trainee_id', userId)
      .eq('status', 'proposed')
      .order('created_at', ascending: false);

  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map((row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final trainerName = (profile?['display_name'] as String?) ?? '';
    return Appointment.fromJson({...row, 'trainee_name': trainerName});
  }).toList();
});

// ── Confirmed/planned appointments (trainee view) ────────────────────────────

final traineeConfirmedAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('appointments')
      .select('*, profiles!trainer_id(display_name)')
      .eq('trainee_id', userId)
      .inFilter('status', ['planned', 'confirmed']).order('scheduled_for',
          ascending: true);

  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map((row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final trainerName = (profile?['display_name'] as String?) ?? '';
    return Appointment.fromJson({...row, 'trainee_name': trainerName});
  }).toList();
});

// ── Confirm a proposed slot (trainee action) ──────────────────────────────────

Future<void> confirmProposedSlot(String appointmentId, DateTime chosen) async {
  await Supabase.instance.client.rpc(
    'confirm_proposed_appointment',
    params: {
      'p_appointment_id': appointmentId,
      'p_chosen_slot': chosen.toUtc().toIso8601String(),
    },
  );

  try {
    await Supabase.instance.client.functions.invoke(
      'notify-appointment-confirmed',
      body: {'appointment_id': appointmentId},
    );
  } catch (_) {
    // The appointment confirmation itself succeeded; notification delivery is
    // best-effort and must not block the trainee flow.
  }
}

// ── Become trainer ───────────────────────────────────────────────────────────

/// Sends [enteredCode] to the activate-trainer Edge Function for server-side
/// validation. The code is never compared on the client — the secret lives
/// only in Supabase project secrets.
/// Returns null on success, or a localised error message on failure.
Future<String?> activateTrainerRole(String enteredCode) async {
  final l10n = await lookupActiveAppLocalizations();
  if (Supabase.instance.client.auth.currentUser == null) {
    return l10n.trainerNotSignedIn;
  }

  try {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await Supabase.instance.client.functions.invoke(
      'activate-trainer',
      body: {'code': enteredCode.trim()},
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    final data = response.data as Map<String, dynamic>?;
    if (data?['error'] != null) return data!['error'] as String;
    return null;
  } on FunctionException catch (e) {
    final details = e.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    return e.reasonPhrase ?? e.toString();
  } catch (e) {
    return l10n.trainerActivateFailed('$e');
  }
}

// ── Accept invite (client side) ───────────────────────────────────────────────

Future<void> acceptInvite(String code) async {
  await Supabase.instance.client
      .rpc('accept_invite', params: {'p_code': code.trim().toUpperCase()});
}

// ── Switch trainer (client side) ─────────────────────────────────────────────

/// Wechselt den Trainer atomar im Backend.
/// accept_invite() übernimmt alles: Deaktivierung alter Beziehungen,
/// Re-Linking bei bestehendem disconnected-Record, Erstellung neuer Beziehung.
/// Kein Client-Side State-Management nötig.
Future<void> switchTrainer(String newInviteCode) async {
  await acceptInvite(newInviteCode);
}

// ── Client's linked trainer ───────────────────────────────────────────────────

final clientTrainerProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  // Step 1: get trainer_id from relationship (avoid ambiguous multi-FK join)
  final rel = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('trainer_id')
      .eq('client_id', userId)
      .eq('status', 'active')
      .maybeSingle();
  if (rel == null) return null;

  // Step 2: fetch trainer's display name separately
  final trainerId = rel['trainer_id'] as String;
  final profile = await Supabase.instance.client
      .from('profiles')
      .select('display_name')
      .eq('id', trainerId)
      .maybeSingle();
  return (profile?['display_name'] as String?) ?? '';
});

/// Returns the user_id of the currently linked trainer (null if none).
final clientTrainerIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final rel = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('trainer_id')
      .eq('client_id', userId)
      .eq('status', 'active')
      .maybeSingle();
  return rel?['trainer_id'] as String?;
});

class ClientTrainerConnection {
  const ClientTrainerConnection({
    required this.relationshipId,
    required this.trainerId,
    required this.displayName,
    required this.status,
    required this.sourceType,
    required this.createdAt,
  });

  final String relationshipId;
  final String trainerId;
  final String displayName;
  final String status;
  final String sourceType;
  final DateTime createdAt;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
}

final clientTrainerConnectionsProvider =
    FutureProvider<List<ClientTrainerConnection>>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('id, trainer_id, status, source_type, created_at')
      .eq('client_id', userId)
      .inFilter('status', ['active', 'pending']).order('created_at',
          ascending: false);

  final relationships = (rows as List).cast<Map<String, dynamic>>();
  if (relationships.isEmpty) return [];

  final trainerIds =
      relationships.map((row) => row['trainer_id'] as String).toSet().toList();
  final profiles = await Supabase.instance.client
      .from('profiles')
      .select('id, display_name')
      .inFilter('id', trainerIds);
  final namesById = {
    for (final row in (profiles as List).cast<Map<String, dynamic>>())
      row['id'] as String: (row['display_name'] as String?)?.trim(),
  };

  return relationships.map((row) {
    final trainerId = row['trainer_id'] as String;
    return ClientTrainerConnection(
      relationshipId: row['id'] as String,
      trainerId: trainerId,
      displayName: (namesById[trainerId]?.isNotEmpty ?? false)
          ? namesById[trainerId]!
          : '',
      status: row['status'] as String? ?? 'pending',
      sourceType: row['source_type'] as String? ?? 'invite',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }).toList();
});

// ── Subscription tier ─────────────────────────────────────────────────────────

/// Returns 'free' or 'premium' for the currently signed-in user.
/// Re-runs on auth state change (same pattern as userRoleProvider).
final subscriptionTierProvider = FutureProvider<String>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'free';
  final res = await Supabase.instance.client
      .from('profiles')
      .select('subscription_tier')
      .eq('id', userId)
      .single();
  return res['subscription_tier'] as String? ?? 'free';
});

// ── Trainer linked (bool) ─────────────────────────────────────────────────────

/// True wenn der aktuelle User einen aktiv verknüpften Trainer hat.
/// Leitet sich von clientTrainerProvider ab — kein extra DB-Call.
final trainerLinkedProvider = Provider<bool>((ref) {
  return ref.watch(clientTrainerProvider).valueOrNull != null;
});

// ── Chat partner ──────────────────────────────────────────────────────────────

/// For a direct channel, returns the OTHER participant's user_id.
/// Returns null for community channels or if not found.
final chatPartnerIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, channelId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final rows = await Supabase.instance.client
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channelId)
      .neq('user_id', userId);

  final list = rows as List;
  if (list.isEmpty) return null;
  return list.first['user_id'] as String?;
});

/// For a direct channel, returns the OTHER participant's display name.
/// Falls back to their role so both sides always know who the chat is with.
final chatPartnerNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, channelId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return (await lookupActiveAppLocalizations()).trainerChatFallback;
  }

  // Step 1: get partner's user_id
  final rows = await Supabase.instance.client
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channelId)
      .neq('user_id', userId);

  final list = rows as List;
  if (list.isEmpty) {
    return (await lookupActiveAppLocalizations()).trainerChatFallback;
  }
  final partnerId = list.first['user_id'] as String;

  // Step 2: fetch their display name
  final profile = await Supabase.instance.client
      .from('profiles')
      .select('display_name, role')
      .eq('id', partnerId)
      .maybeSingle();
  final displayName = profile?['display_name'] as String?;
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }

  final role = profile?['role'] as String?;
  final l10n = await lookupActiveAppLocalizations();
  return role == 'trainer' ? l10n.trainerYourTrainer : l10n.trainerYourClient;
});
