import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/trainer_application.dart';
import '../../domain/repositories/trainer_application_repository.dart';

class SupabaseTrainerApplicationRepository
    implements TrainerApplicationRepository {
  SupabaseTrainerApplicationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TrainerApplication?> getOwnApplication() async {
    final res = await _client.rpc('get_own_trainer_application');
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return TrainerApplication.fromJson(list.first);
  }

  @override
  Future<String> submitApplication({
    required String fullName,
    required String email,
    String? phone,
    String? city,
    required String professionalBackground,
    String? motivation,
    String? desiredDisplayName,
    String? desiredBio,
    double? lat,
    double? lng,
  }) async {
    final res = await _client.rpc('submit_trainer_application', params: {
      'p_full_name': fullName,
      'p_email': email,
      'p_phone': phone,
      'p_city': city,
      'p_professional_background': professionalBackground,
      'p_motivation': motivation,
      'p_desired_display_name': desiredDisplayName,
      'p_desired_bio': desiredBio,
      'p_lat': lat,
      'p_lng': lng,
    });
    return res as String;
  }

  @override
  Future<List<TrainerApplication>> getApplicationsForReview() async {
    final res = await _client.rpc('get_trainer_applications_for_review');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerApplication.fromJson)
        .toList();
  }

  @override
  Future<void> markBackgroundCheckSeen(String applicationId) async {
    await _client.rpc('mark_background_check_seen', params: {
      'p_application_id': applicationId,
    });
  }

  @override
  Future<void> setStatus(
    String applicationId,
    String status, {
    String? reason,
  }) async {
    await _client.rpc('set_trainer_application_status', params: {
      'p_application_id': applicationId,
      'p_status': status,
      'p_reason': reason,
    });
  }

  @override
  Future<String> approve(String applicationId) async {
    final res = await _client.rpc('approve_trainer_application', params: {
      'p_application_id': applicationId,
    });
    final row = switch (res) {
      final List list when list.isNotEmpty =>
        list.first as Map<String, dynamic>,
      final Map<String, dynamic> map => map,
      _ => throw StateError('No activation code was created.'),
    };
    final code = row['code'] as String?;
    if (code == null || code.isEmpty) {
      throw StateError('No activation code was created.');
    }
    return code;
  }
}
