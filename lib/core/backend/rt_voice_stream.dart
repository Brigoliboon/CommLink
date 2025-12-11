import 'dart:async';
import 'dart:typed_data';
import '../audio/audio_engine.dart';
import '../network/udp_service.dart';

class RTVoiceStream {
  final AudioEngine audioEngine;
  final UDPService udpService;
  StreamSubscription<Uint8List>? _audioSub;

  RTVoiceStream({required this.audioEngine, required this.udpService});

  // Start sending audio on PTT press
  Future<void> startPTT() async {
    await audioEngine.startRecording((frame) async {
      await udpService.sendFrame(frame);
    });
    _audioSub = audioEngine.recordedStream.listen((frame) async {
      await udpService.sendFrame(frame);
    });
  }

  // Stop sending audio on PTT release
  Future<void> stopPTT() async {
    await audioEngine.stopRecording();
    await _audioSub?.cancel();
    _audioSub = null;
  }

  // Handle incoming UDP audio, already managed within UDPService by default,
  // Forward to AudioEngine's playAudio or hook here for more processing.
  // For extension: could add codecs/transforms here.
}
