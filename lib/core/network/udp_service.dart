import 'dart:typed_data';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:udp/udp.dart';
import '../audio/audio_engine.dart';
import '../../config/network_config.dart';

class UDPService {
  late UDP _sender;
  late UDP _receiver;
  final AudioEngine _audioEngine;
  final StreamController<String> _audioLogStream = StreamController.broadcast();
  String? _localIpAddress;
  int _currentChannel;

  Stream<String> get audioLogStream => _audioLogStream.stream;
  int get currentChannel => _currentChannel;

  UDPService(this._audioEngine, {int channel = NetworkConfig.DEFAULT_CHANNEL})
      : _currentChannel = channel;

  Future<void> init() async {
    // Get local IP address to filter out loopback
    _localIpAddress = await _getLocalIpAddress();

    _sender = await UDP.bind(Endpoint.any());
    _receiver = await UDP.bind(
      Endpoint.multicast(
        InternetAddress(NetworkConfig.getMulticastIp(_currentChannel)),
        port: Port(NetworkConfig.PORT),
      ),
    );

    _startReceiver();
  }

  void _startReceiver() {
    _receiver.asStream().listen((datagram) {
      if (datagram != null) {
        final senderIp = datagram.address.address;

        // Filter out packets from our own device to prevent loopback
        if (senderIp == _localIpAddress) {
          developer.log('🔇 Filtered loopback audio from $senderIp');
          return;
        }

        developer.log('🎵 Audio received: ${datagram.data.length} bytes from $senderIp');
        _audioEngine.playAudio(datagram.data);
      }
      developer.log(datagram.toString());
    });
  }

  Future<void> sendFrame(Uint8List frame) async {

    try {
      await _sender.send(
        frame,
        Endpoint.multicast(
          InternetAddress(NetworkConfig.getMulticastIp(_currentChannel)),
          port: Port(NetworkConfig.PORT),
        ),
      );
      developer.log('📤 Audio frame sent: ${frame.length} bytes');
    } catch (e) {
        developer.log('❌ Failed to send audio frame: $e');
      // Don't rethrow - we don't want to crash the app if sending fails
    }
  }

  /// Get the local IP address to filter out loopback audio
  Future<String> _getLocalIpAddress() async {
    try {
      // Get list of network interfaces
      final interfaces = await NetworkInterface.list();

      // Find the first non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback) {
            return addr.address;
          }
        }
      }

      // Fallback to localhost if no suitable address found
      return '127.0.0.1';
    } catch (e) {
      developer.log('Error getting local IP address: $e');
      return '127.0.0.1';
    }
  }

  Future<void> switchChannel(int channel) async {
    if (channel < 1 || channel > NetworkConfig.CHANNEL_COUNT) return;
    if (_currentChannel == channel) return;

    developer.log('📻 Switching UDP channel: $_currentChannel → $channel');
    _currentChannel = channel;

    // Rebind receiver to new multicast group
    _receiver.close();
    _receiver = await UDP.bind(
      Endpoint.multicast(
        InternetAddress(NetworkConfig.getMulticastIp(_currentChannel)),
        port: Port(NetworkConfig.PORT),
      ),
    );

    _startReceiver();
    developer.log('✔ Switched UDP to channel $channel (${NetworkConfig.getMulticastIp(channel)})');
  }

  Future<void> dispose() async {
    _sender.close();
    _receiver.close();
  }
}
