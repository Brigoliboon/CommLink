import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class AudioEngine {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  final StreamController<Uint8List> _pcmController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get recordedStream => _pcmController.stream;

  bool _isPlayerStarted = false;

  final List<Uint8List> _audioBuffer = [];
  final int _maxBufferSize = 10;
  Timer? _bufferFlushTimer;

  // --- MISSING FIELDS YOU NEED ---
  final StreamController<bool> _audioReceivingController =
      StreamController<bool>.broadcast();
  Stream<bool> get audioReceivingStream => _audioReceivingController.stream;

  Timer? _receivingTimeoutTimer;
  // --------------------------------

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startRecording(Future<Null> Function(Uint8List frame) param0) async {
    await _recorder.startRecorder(
      toStream: _pcmController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
      bitRate: 16000,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
  }

  Future<void> initPlayer() async {
    if (!_isPlayerStarted) {
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        interleaved: true,
        bufferSize: 8192,
        onBufferUnderflow: () {
          print('⚠️ Audio buffer underrun detected');
        },
      );
      _isPlayerStarted = true;
    }
  }

  void playAudio(Uint8List frame) {
    if (!_isPlayerStarted) return;

    // Now works — controller exists
    _audioReceivingController.add(true);

    _receivingTimeoutTimer?.cancel();
    _receivingTimeoutTimer = Timer(const Duration(milliseconds: 500), () {
      _audioReceivingController.add(false);
    });

    _audioBuffer.add(frame);

    if (_audioBuffer.length >= 3 && _bufferFlushTimer == null) {
      _startBufferFlush();
    }

    if (_audioBuffer.length > _maxBufferSize) {
      _audioBuffer.removeAt(0);
    }
  }

  void _startBufferFlush() {
    _bufferFlushTimer =
        Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (_audioBuffer.isNotEmpty) {
        final frame = _audioBuffer.removeAt(0);
        _player.uint8ListSink?.add(frame);
      } else {
        _bufferFlushTimer?.cancel();
        _bufferFlushTimer = null;
      }
    });
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _pcmController.close();
    await _audioReceivingController.close();
  }
}
