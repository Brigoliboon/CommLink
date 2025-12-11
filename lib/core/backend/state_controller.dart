import 'dart:async';
import '../backend/peer_discovery.dart';
import '../audio/audio_engine.dart';
import '../network/udp_service.dart';
import '../backend/rt_voice_stream.dart';

class BackendStateController {
  final PeerDiscoveryService discoveryService;
  late final AudioEngine _audioEngine;
  late final UDPService _udpService;
  late final RTVoiceStream _voiceStream;
  int _currentChannel = 1;
  bool _isPTTActive = false;
  final StreamController<bool> _pttController = StreamController.broadcast();
  final StreamController<int> _channelController = StreamController.broadcast();
  final StreamController<String> _eventLogController = StreamController<String>.broadcast();

  BackendStateController(this.discoveryService) {
    _audioEngine = AudioEngine();
    _udpService = UDPService(_audioEngine);
    _voiceStream = RTVoiceStream(audioEngine: _audioEngine, udpService: _udpService);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _audioEngine.init();
    await _audioEngine.initPlayer();
    await _udpService.init();
    await discoveryService.start();
  }

  Stream<String> get eventLogStream => _eventLogController.stream;

  // Peer list stream
  Stream<List<Peer>> get peerStream => discoveryService.peerStream;
  List<Peer> get currentPeers => discoveryService.activePeers;

  // PTT State stream
  Stream<bool> get pttStream => _pttController.stream;
  bool get isPTTActive => _isPTTActive;

  // Channel State stream
  Stream<int> get channelStream => _channelController.stream;
  int get currentChannel => _currentChannel;

  void setChannel(int channel) {
    if (_currentChannel != channel) {
      _currentChannel = channel;
      _channelController.add(_currentChannel);
    }
  }

  void setPTTState(bool active) async {
    if (_isPTTActive != active) {
      _isPTTActive = active;
      _pttController.add(_isPTTActive);

      if (_isPTTActive) {
        await _voiceStream.startPTT();
      } else {
        await _voiceStream.stopPTT();
      }
    }
  }

  void dispose() {
    _pttController.close();
    _channelController.close();
    _eventLogController.close();
    discoveryService.dispose();
    _udpService.dispose();
  }
}
