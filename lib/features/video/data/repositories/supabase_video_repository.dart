// lib/features/video/data/repositories/supabase_video_repository.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/video_call.dart';
import '../../domain/repositories/video_repository.dart';

class SupabaseVideoRepository implements VideoRepository {
  SupabaseVideoRepository({required this.allowEmptyDevToken});

  final _client = Supabase.instance.client;
  final bool allowEmptyDevToken;

  @override
  Future<VideoCall> startCall(String channelId) async {
    final now = DateTime.now();
    // Short Agora channel name: prefix + first 8 chars of channel UUID (no dashes) + timestamp.
    // Agora channel names must be ≤ 64 chars, alphanumeric + underscore only.
    final shortId = channelId.replaceAll('-', '').substring(0, 8);
    final agoraChannelName = 'cj_${shortId}_${now.millisecondsSinceEpoch}';
    final userId = _client.auth.currentUser!.id;

    try {
      final data = await _client.rpc(
        'start_direct_call',
        params: {'p_channel_id': channelId},
      ) as Map<String, dynamic>;
      final call = VideoCall.fromJson(data);
      unawaited(_notifyVideoCall(call.id));
      return call;
    } on PostgrestException catch (e) {
      if (!_isMissingRpc(e, 'start_direct_call')) rethrow;
    }

    final data = await _client
        .from('video_calls')
        .insert({
          'channel_id': channelId,
          'agora_channel_name': agoraChannelName,
          'started_by': userId,
        })
        .select()
        .single();

    final call = VideoCall.fromJson(data);
    unawaited(_notifyVideoCall(call.id));
    return call;
  }

  @override
  Future<void> endCall(String callId) async {
    try {
      await _client.rpc('end_call', params: {'p_call_id': callId});
      return;
    } on PostgrestException catch (e) {
      if (!_isMissingRpc(e, 'end_call')) rethrow;
    }

    await _client
        .from('video_calls')
        .update({'ended_at': DateTime.now().toUtc().toIso8601String()}).eq(
            'id', callId);
  }

  @override
  Future<VideoCall?> getCallById(String callId) async {
    final row = await _client
        .from('video_calls')
        .select()
        .eq('id', callId)
        .maybeSingle();

    if (row == null) return null;
    return VideoCall.fromJson(row);
  }

  @override
  Future<String> getAgoraToken(
    String channelId,
    String agoraChannelName, {
    required int uid,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'agora-token',
        body: {
          'channel_id': channelId,
          'agora_channel_name': agoraChannelName,
          'uid': uid,
        },
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String? ?? '';
      if (token.isEmpty && !allowEmptyDevToken) {
        throw StateError('Agora token fehlt.');
      }
      return token;
    } catch (e) {
      if (!allowEmptyDevToken) rethrow;
      debugPrint(
        'getAgoraToken failed in development mode; using empty token: $e',
      );
      return '';
    }
  }

  @override
  Stream<VideoCall?> watchActiveCall(String channelId) {
    return _pollActiveCall(channelId);
  }

  @override
  Stream<List<VideoCall>> watchActiveCalls() {
    return _pollActiveCalls();
  }

  Stream<VideoCall?> _pollActiveCall(String channelId) async* {
    VideoCall? last;
    var hasEmittedInitialValue = false;

    while (true) {
      try {
        final next = await _fetchActiveCall(channelId);
        if (_activeCallSignature(next) != _activeCallSignature(last) ||
            !hasEmittedInitialValue) {
          last = next;
          hasEmittedInitialValue = true;
          yield next;
        }
      } catch (e) {
        debugPrint('watchActiveCall polling failed: $e');
        if (!hasEmittedInitialValue) {
          hasEmittedInitialValue = true;
          yield null;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<VideoCall?> _fetchActiveCall(String channelId) async {
    final rows = await _client
        .from('video_calls')
        .select()
        .eq('channel_id', channelId)
        .isFilter('ended_at', null)
        .order('started_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return VideoCall.fromJson(rows.first);
  }

  Stream<List<VideoCall>> _pollActiveCalls() async* {
    var lastSignature = '';
    var hasEmittedInitialValue = false;

    while (true) {
      try {
        final calls = await _fetchActiveCalls();
        final signature = calls.map(_activeCallSignature).join('|');
        if (signature != lastSignature || !hasEmittedInitialValue) {
          lastSignature = signature;
          hasEmittedInitialValue = true;
          yield calls;
        }
      } catch (e) {
        debugPrint('watchActiveCalls polling failed: $e');
        if (!hasEmittedInitialValue) {
          hasEmittedInitialValue = true;
          yield const [];
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<List<VideoCall>> _fetchActiveCalls() async {
    final rows = await _client
        .from('video_calls')
        .select()
        .isFilter('ended_at', null)
        .order('started_at', ascending: false);

    return (rows as List)
        .map((row) => VideoCall.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  String _activeCallSignature(VideoCall? call) {
    if (call == null) return 'none';
    return '${call.id}|${call.endedAt?.toIso8601String() ?? 'active'}';
  }

  bool _isMissingRpc(PostgrestException e, String functionName) {
    return e.code == 'PGRST202' ||
        e.message.contains(functionName) ||
        e.message.contains('Could not find the function');
  }

  Future<void> _notifyVideoCall(String callId) async {
    try {
      await _client.functions.invoke(
        'notify-video-call',
        body: {'call_id': callId},
      );
    } catch (e) {
      debugPrint('notify-video-call failed: $e');
    }
  }
}
