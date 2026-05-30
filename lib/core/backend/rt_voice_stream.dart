import 'dart:async';
import 'dart:typed_data';
import '../audio/audio_engine.dart';
import '../network/udp_service.dart';

class RTVoiceStream {
  final AudioEngine audioEngine;
  final UDPService udpService;
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<bool>? _receivingSub;
  bool _isMuted = false;

  RTVoiceStream({required this.audioEngine, required this.udpService});

  Future<void> init() async {
    _receivingSub = audioEngine.audioReceivingStream.listen((isReceiving) {
      _isMuted = isReceiving;
    });
  }

  Future<void> startPTT() async {
    await audioEngine.startRecording((frame) async {
      await udpService.sendFrame(frame);
    });
    _audioSub = audioEngine.recordedStream.listen((frame) async {
      if (_isMuted && audioEngine.isEchoCancellationEnabled) {
        return;
      }
      await udpService.sendFrame(frame);
    });
  }

  // Stop sending audio on PTT release
  Future<void> stopPTT() async {
    await audioEngine.stopRecording();
    await _audioSub?.cancel();
    _audioSub = null;
  }

  void setEchoCancellation(bool enabled) {
    audioEngine.setEchoCancellation(enabled);
  }

  Future<void> dispose() async {
    await _receivingSub?.cancel();
    await _audioSub?.cancel();
  }
}
