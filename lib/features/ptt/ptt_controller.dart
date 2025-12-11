import '../../core/audio/audio_engine.dart';
import '../../core/network/udp_service.dart';
import 'dart:typed_data';

class PTTController {
  final AudioEngine _audioEngine;
  final UDPService _udpService;
  bool isRecording = false;

  PTTController(this._audioEngine, this._udpService);

  Future<void> startPTT() async {
    isRecording = true;
    await _audioEngine.startRecording((Uint8List frame) async {
      if (isRecording) {
        await _udpService.sendFrame(frame);
      }
    });
  }

  Future<void> stopPTT() async {
    isRecording = false;
    await _audioEngine.stopRecording();
  }
}
