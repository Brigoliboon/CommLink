import 'dart:async';
import '../backend/peer_discovery.dart';
import '../audio/audio_engine.dart';
import '../network/udp_service.dart';
import '../backend/rt_voice_stream.dart';

class BackendStateController {
  late final PeerDiscoveryService _discoveryService;
  late final AudioEngine _audioEngine;
  late final UDPService _udpService;
  late final RTVoiceStream _voiceStream;

  int _currentChannel;
  bool _isPTTActive = false;

  final StreamController<bool> _pttController = StreamController.broadcast();
  final StreamController<int> _channelController = StreamController.broadcast();
  final StreamController<String> _eventLogController = StreamController.broadcast();

  BackendStateController({
    required String deviceName,
    required String deviceFingerprint,
    int initialChannel = 1,
  }) : _currentChannel = initialChannel {
    _discoveryService = PeerDiscoveryService(
      selfName: deviceName,
      selfFingerprint: deviceFingerprint,
      channel: initialChannel,
    );
    _audioEngine = AudioEngine();
    _udpService = UDPService(_audioEngine, channel: initialChannel);
    _voiceStream = RTVoiceStream(audioEngine: _audioEngine, udpService: _udpService);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _audioEngine.init();
    await _audioEngine.initPlayer();
    await _udpService.init();
    await _discoveryService.start();
    _log('CommLink initialized on channel $_currentChannel');
  }

  // -- Accessors ----------------------------------------------------------

  PeerDiscoveryService get discoveryService => _discoveryService;
  AudioEngine get audioEngine => _audioEngine;

  Stream<String> get eventLogStream => _eventLogController.stream;
  Stream<List<Peer>> get peerStream => _discoveryService.peerStream;
  List<Peer> get currentPeers => _discoveryService.activePeers;

  Stream<bool> get pttStream => _pttController.stream;
  bool get isPTTActive => _isPTTActive;

  Stream<int> get channelStream => _channelController.stream;
  int get currentChannel => _currentChannel;

  // -- Channel -----------------------------------------------------------

  Future<void> setChannel(int channel) async {
    if (_currentChannel == channel) return;
    if (channel < 1 || channel > 8) return;

    _log('Switching to channel $channel...');

    _currentChannel = channel;
    _channelController.add(_currentChannel);

    // Switch both services to the new multicast group
    await Future.wait([
      _discoveryService.switchChannel(channel),
      _udpService.switchChannel(channel),
    ]);

    _log('Now on channel $channel');
  }

  // -- PTT ---------------------------------------------------------------

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

  // -- Logging -----------------------------------------------------------

  void _log(String msg) => _eventLogController.add(msg);

  // -- Dispose -----------------------------------------------------------

  void dispose() {
    _pttController.close();
    _channelController.close();
    _eventLogController.close();
    _discoveryService.dispose();
    _udpService.dispose();
  }
}
