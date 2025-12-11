import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:udp/udp.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../config/network_config.dart';

class Peer {
  final String name;
  final InternetAddress address;
  final DateTime lastSeen;

  Peer(this.name, this.address, this.lastSeen);
}

class PeerDiscoveryService {
  final Map<String, Peer> _peers = {};
  final StreamController<List<Peer>> _peerStream =
      StreamController.broadcast();

  final StreamController<String> _logStream =
      StreamController.broadcast();

  Stream<List<Peer>> get peers => _peerStream.stream;
  Stream<String> get logs => _logStream.stream;

  Stream<List<Peer>> get peerStream => _peerStream.stream;
  List<Peer> get activePeers => _peers.values.toList();
  Stream<String> get packetLogStream => _logStream.stream;

  UDP? _listener;
  UDP? _broadcaster;

  Timer? _announceTimer;
  Timer? _cleanupTimer;
  Timer? _networkMonitor;

  final String selfName;

  PeerDiscoveryService({required this.selfName});

  // ---------------------------------------------------------------------------
  // START SERVICE
  // ---------------------------------------------------------------------------
  Future<void> start() async {
    await _bindSockets();

    _startListeners();
    _startAnnouncer();
    _startCleanup();
    _startNetworkWatcher();
  }

  // ---------------------------------------------------------------------------
  // BIND SOCKETS (WITH RETRY LOGIC)
  // ---------------------------------------------------------------------------
  Future<void> _bindSockets() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _log("🔄 Attempting to bind sockets (attempt $attempt/$maxRetries)...");

        // Listener uses multicast endpoint
        _listener = await UDP.bind(
          Endpoint.multicast(
            InternetAddress(NetworkConfig.MULTICAST_IP),
            port: Port(NetworkConfig.PORT),
          ),
        );

        // Broadcaster can send on any interface
        _broadcaster = await UDP.bind(Endpoint.any());

        _log("✔ UDP sockets bound successfully");
        return; // Success, exit the retry loop
      } catch (e) {
        _log("❌ Failed binding sockets (attempt $attempt/$maxRetries): $e");

        if (attempt < maxRetries) {
          _log("⏳ Retrying in ${retryDelay.inSeconds} seconds...");
          await Future.delayed(retryDelay);
        } else {
          _log("💥 All binding attempts failed. Service may not function properly.");
          // Reset sockets to null on final failure
          _listener = null;
          _broadcaster = null;
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LISTEN FOR PACKETS
  // ---------------------------------------------------------------------------
  void _startListeners() {
    if (_listener == null) return;

    _listener!.asStream().listen((datagram) {
      if (datagram == null) return;

      try {
        final msg = utf8.decode(datagram.data);
        final json = jsonDecode(msg);

        if (json["type"] == "peer_announce" &&
            json["name"] != selfName) {
          final ip = datagram.address.address;

          _peers[ip] = Peer(
            json["name"],
            datagram.address,
            DateTime.now(),
          );

          _peerStream.add(_peers.values.toList());
          _log("📩 Peer updated: ${json["name"]} ($ip)");
        }
      } catch (e) {
        _log("❌ Decode error: $e");
      }
    });
  }

  // ---------------------------------------------------------------------------
  // ANNOUNCE SELF TO NETWORK
  // ---------------------------------------------------------------------------
  void _startAnnouncer() {
    _announceTimer?.cancel();

    _announceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_broadcaster == null) return;

      final data = jsonEncode({
        "type": "peer_announce",
        "name": selfName,
      });

      _broadcaster!.send(
        utf8.encode(data),
        Endpoint.multicast(
          InternetAddress(NetworkConfig.MULTICAST_IP),
          port: Port(NetworkConfig.PORT),
        ),
      );
    });

    _log("📡 Announcer started");
  }

  // ---------------------------------------------------------------------------
  // REMOVE OLD PEERS
  // ---------------------------------------------------------------------------
  void _startCleanup() {
    _cleanupTimer?.cancel();

    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      _peers.removeWhere(
        (_, peer) => now.difference(peer.lastSeen) >
            const Duration(seconds: 10),
      );

      _peerStream.add(_peers.values.toList());
    });

    _log("🧹 Cleanup started");
  }

  // ---------------------------------------------------------------------------
// WATCH IF NETWORK CHANGES (Wi-Fi reconnect → auto-heal)
// ---------------------------------------------------------------------------
  void _startNetworkWatcher() {
    _networkMonitor?.cancel();

    _networkMonitor = Timer.periodic(const Duration(seconds: 4), (_) async {
      final connected = await WiFiForIoTPlugin.isConnected();

      if (!connected) {
        _log("⚠ Network disconnected");
        return;
      }

      // Rebind sockets if suddenly stop receiving packets
      // Check if we haven't received packets in the last 10 seconds
      final now = DateTime.now();
      final hasRecentPackets = _peers.values.any(
        (peer) => now.difference(peer.lastSeen) < const Duration(seconds: 10),
      );

      if (!hasRecentPackets && _listener != null) {
        _log("⚠ No recent packets received, rebinding sockets");
        await _rebindSockets();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // LOGGING
  // ---------------------------------------------------------------------------
  void _log(String m) => _logStream.add(m);

  // ---------------------------------------------------------------------------
  // REBIND SOCKETS (FOR NETWORK RECOVERY)
  // ---------------------------------------------------------------------------
  Future<void> _rebindSockets() async {
    _log("🔄 Rebinding sockets...");

    // Close existing sockets
    _listener?.close();
    _broadcaster?.close();

    _listener = null;
    _broadcaster = null;

    // Rebind with retry logic
    await _bindSockets();

    // Restart listeners if binding succeeded
    if (_listener != null) {
      _startListeners();
      _log("✔ Sockets rebound successfully");
    } else {
      _log("❌ Failed to rebind sockets");
    }
  }

  // ---------------------------------------------------------------------------
// DISPOSE
// ---------------------------------------------------------------------------
  void dispose() {
    _listener?.close();
    _broadcaster?.close();

    _announceTimer?.cancel();
    _cleanupTimer?.cancel();
    _networkMonitor?.cancel();

    _peerStream.close();
    _logStream.close();
  }

}
