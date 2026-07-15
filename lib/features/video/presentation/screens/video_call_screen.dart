// lib/features/video/presentation/screens/video_call_screen.dart

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/models/video_call.dart';
import '../providers/video_providers.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.call,
    required this.token,
    required this.localUid,
  });

  final VideoCall call;

  /// Agora token from the Edge Function. Empty string is valid in dev mode
  /// when certificate enforcement is disabled on the Agora project.
  final String token;
  final int localUid;

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _micMuted = false;
  bool _cameraMuted = false;
  bool _ending = false;
  String? _statusText;
  String? _errorText;
  Timer? _unansweredCallTimer;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    final appId = ref.read(appConfigProvider).agoraAppId;
    setState(() {
      _statusText = 'Video-Call wird vorbereitet ...';
      _errorText = null;
    });
    if (appId.isEmpty) {
      appLogger
          .e('VideoCallScreen: AGORA_APP_ID is empty — add it to .env.dev');
      if (mounted) {
        setState(
            () => _errorText = 'Konfigurationsfehler: Agora App-ID fehlt.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Konfigurationsfehler: Agora App-ID fehlt.')),
        );
      }
      return;
    }

    // Request camera + microphone before initialising Agora.
    appLogger.d('VideoCallScreen: requesting camera + microphone permissions');
    final statuses = await [Permission.camera, Permission.microphone].request();
    final cameraOk = statuses[Permission.camera]?.isGranted ?? false;
    final micOk = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraOk || !micOk) {
      appLogger.e(
        'VideoCallScreen: permissions denied — camera=$cameraOk mic=$micOk',
      );
      if (mounted) {
        setState(() {
          _errorText =
              'Kamera oder Mikrofon ist nicht freigegeben. Bitte App-Berechtigungen prüfen.';
        });
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kamera & Mikrofon benötigt'),
            content: const Text(
              'Bitte erlaube der App den Zugriff auf Kamera und Mikrofon '
              'in den iOS-Einstellungen, um an Video-Calls teilzunehmen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text('Einstellungen öffnen'),
              ),
            ],
          ),
        );
      }
      return;
    }

    appLogger
        .d('VideoCallScreen: permissions granted, initializing Agora engine');
    try {
      final engine = createAgoraRtcEngine();
      setState(() => _statusText = 'Video-Engine wird gestartet ...');
      await engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      appLogger.d('VideoCallScreen: engine initialized');
      if (mounted) setState(() => _engine = engine);

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          appLogger.d('VideoCallScreen: joined channel — elapsed ${elapsed}ms');
          if (mounted) {
            setState(() {
              _joined = true;
              _statusText = 'Warte auf Teilnehmer ...';
            });
            _startUnansweredCallTimer();
          }
        },
        onConnectionStateChanged: (connection, state, reason) {
          appLogger.d(
            'VideoCallScreen: connection state=$state reason=$reason',
          );
          if (!mounted) return;

          if (state == ConnectionStateType.connectionStateFailed ||
              reason ==
                  ConnectionChangedReasonType.connectionChangedInvalidToken ||
              reason ==
                  ConnectionChangedReasonType.connectionChangedTokenExpired ||
              reason ==
                  ConnectionChangedReasonType.connectionChangedInvalidAppId ||
              reason ==
                  ConnectionChangedReasonType.connectionChangedJoinFailed) {
            setState(() {
              _errorText = _connectionErrorText(reason);
            });
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          appLogger.d('VideoCallScreen: remote user joined uid=$remoteUid');
          _unansweredCallTimer?.cancel();
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
              _statusText = 'Verbunden';
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          appLogger.d(
              'VideoCallScreen: remote user offline uid=$remoteUid reason=$reason');
          if (mounted) {
            setState(() {
              _remoteUid = null;
              _statusText = 'Teilnehmer hat den Call verlassen';
            });
          }
        },
        onError: (err, msg) {
          appLogger.e('VideoCallScreen: Agora error code=$err msg=$msg');
          if (mounted) {
            setState(() => _errorText = 'Agora-Fehler: $msg ($err)');
          }
        },
        onLocalVideoStateChanged: (source, state, reason) {
          appLogger.d(
            'VideoCallScreen: local video state=$state reason=$reason',
          );
          if (!mounted) return;
          if (state == LocalVideoStreamState.localVideoStreamStateFailed) {
            setState(() {
              _errorText = _localVideoErrorText(reason);
            });
          }
        },
      ));

      await engine.enableVideo();
      appLogger.d('VideoCallScreen: video enabled');
      await engine.enableAudio();
      await engine.enableLocalVideo(true);
      await engine.muteLocalVideoStream(false);
      await engine.setDefaultAudioRouteToSpeakerphone(true);
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.setupLocalVideo(const VideoCanvas(uid: 0));
      await engine.startPreview();
      appLogger.d('VideoCallScreen: preview started');
      if (mounted) {
        setState(() => _statusText = 'Verbinde mit Video-Call ...');
      }

      await engine.joinChannel(
        token: widget.token,
        channelId: widget.call.agoraChannelName,
        uid: widget.localUid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      appLogger.d(
          'VideoCallScreen: joinChannel called for ${widget.call.agoraChannelName}');
    } catch (e, st) {
      appLogger.e('VideoCallScreen: init failed', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _errorText = 'Video-Call Fehler: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video-Call Fehler: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _unansweredCallTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  void _startUnansweredCallTimer() {
    _unansweredCallTimer?.cancel();
    _unansweredCallTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted || _remoteUid != null || _ending) return;
      setState(() {
        _statusText = 'Niemand ist beigetreten. Call wird beendet ...';
      });
      unawaited(_hangUp());
    });
  }

  Future<void> _hangUp() async {
    if (_ending) return;
    setState(() => _ending = true);
    try {
      await ref.read(endCallProvider.notifier).end(widget.call.id);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // When the remote side ends the call, pop automatically.
    ref.listen(activeCallProvider(widget.call.channelId), (prev, next) {
      if (_joined && next.valueOrNull == null && mounted) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video (full screen background) ──────────────────────────
          if (_engine != null && _remoteUid != null)
            Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid!),
                  connection:
                      RtcConnection(channelId: widget.call.agoraChannelName),
                ),
              ),
            )
          else
            Positioned.fill(
              child: _WaitingState(
                statusText:
                    _errorText ?? _statusText ?? 'Warte auf Teilnehmer ...',
                isError: _errorText != null,
              ),
            ),

          // ── Local video (PiP, top-right) ───────────────────────────────────
          if (_engine != null)
            Positioned(
              top: 56,
              right: 16,
              width: 100,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 0),
                    useAndroidSurfaceView: true,
                  ),
                  onAgoraVideoViewCreated: (_) {
                    _engine?.startPreview();
                  },
                ),
              ),
            ),

          // ── Controls (bottom) ──────────────────────────────────────────────
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: _micMuted ? Icons.mic_off : Icons.mic,
                  label: _micMuted ? 'Ton an' : 'Ton aus',
                  onTap: () {
                    setState(() => _micMuted = !_micMuted);
                    _engine?.muteLocalAudioStream(_micMuted);
                  },
                ),
                const SizedBox(width: 32),
                _ControlButton(
                  icon: Icons.call_end,
                  label: 'Auflegen',
                  background: Colors.red,
                  onTap: _hangUp,
                ),
                const SizedBox(width: 32),
                _ControlButton(
                  icon: _cameraMuted ? Icons.videocam_off : Icons.videocam,
                  label: _cameraMuted ? 'Kamera an' : 'Kamera aus',
                  onTap: () {
                    setState(() => _cameraMuted = !_cameraMuted);
                    _engine?.muteLocalVideoStream(_cameraMuted);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _connectionErrorText(ConnectionChangedReasonType reason) {
  switch (reason) {
    case ConnectionChangedReasonType.connectionChangedInvalidToken:
      return 'Video-Call Fehler: Agora Token ist ungültig. Bitte Edge Function neu deployen.';
    case ConnectionChangedReasonType.connectionChangedTokenExpired:
      return 'Video-Call Fehler: Agora Token ist abgelaufen.';
    case ConnectionChangedReasonType.connectionChangedInvalidAppId:
      return 'Video-Call Fehler: Agora App-ID ist ungültig.';
    case ConnectionChangedReasonType.connectionChangedJoinFailed:
      return 'Video-Call Verbindung fehlgeschlagen. Bitte Netzwerk und Agora-Konfiguration prüfen.';
    default:
      return 'Video-Call Verbindung fehlgeschlagen: $reason';
  }
}

String _localVideoErrorText(LocalVideoStreamReason reason) {
  switch (reason) {
    case LocalVideoStreamReason.localVideoStreamReasonDeviceNoPermission:
      return 'Kamera ist nicht freigegeben. Bitte App-Berechtigungen prüfen.';
    case LocalVideoStreamReason.localVideoStreamReasonDeviceBusy:
      return 'Kamera wird gerade von einer anderen App genutzt.';
    case LocalVideoStreamReason.localVideoStreamReasonCaptureFailure:
      return 'Kamera konnte nicht gestartet werden. Bitte App neu öffnen und erneut versuchen.';
    case LocalVideoStreamReason.localVideoStreamReasonDeviceNotFound:
      return 'Keine Kamera gefunden.';
    default:
      return 'Kamera konnte nicht gestartet werden: $reason';
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({
    required this.statusText,
    required this.isError,
  });

  final String statusText;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.person,
          size: 80,
          color: isError ? Colors.redAccent : Colors.white38,
        ),
        const SizedBox(height: 16),
        Text(
          statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? Colors.redAccent : Colors.white60,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? Colors.white.withValues(alpha: 0.2);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
