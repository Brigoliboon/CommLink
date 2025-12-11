import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../../core/backend/peer_discovery.dart';
import '../../core/backend/state_controller.dart';
import '../../core/network/udp_service.dart';
import '../../core/audio/audio_engine.dart';
import 'dart:async';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  late BackendStateController _backendController;
  late PeerDiscoveryService _peerDiscoveryService;
  late final StreamSubscription<String> _packetLogSub;
  late final StreamSubscription<String> _eventLogSub;
  final List<String> _packetLogs = [];
  final List<String> _eventLogs = [];
  List<NetworkInterface> _networkInterfaces = [];
  bool _fakePeerEnabled = false;
  bool _loopbackTestEnabled = false;
  Timer? _noPeersTimer;
  int _audioPacketsReceived = 0;

  @override
  void initState() {
    super.initState();
    _peerDiscoveryService = PeerDiscoveryService(selfName: 'Me');
    _backendController = BackendStateController(_peerDiscoveryService);
    _loadNetworkInterfaces();
    _startNoPeersCheck();
    _backendController.channelStream.listen((ch) {
      _addEventLog('Channel changed to $ch');
    });
    _backendController.pttStream.listen((ptt) {
      _addEventLog('PTT ${ptt ? 'pressed' : 'released'}');
    });
    _peerDiscoveryService.peerStream.listen((peers) {
      if (peers.isEmpty && _noPeersTimer == null) {
        _startNoPeersCheck();
      } else if (peers.isNotEmpty) {
        _noPeersTimer?.cancel();
        _noPeersTimer = null;
      }
    });
    _packetLogSub = _peerDiscoveryService.packetLogStream.listen((log) {
      _addPacketLog(log);
    });
    _eventLogSub = _backendController.eventLogStream.listen((log) {
      _addEventLog(log);
    });
  }

  void _startNoPeersCheck() {
    _noPeersTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _backendController.currentPeers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No peers found. Check network connection.')),
        );
      }
    });
  }

  Future<void> _loadNetworkInterfaces() async {
    try {
      _networkInterfaces = await NetworkInterface.list();
      setState(() {});
    } catch (e) {
      _addEventLog('Error loading network interfaces: $e');
    }
  }

  void _addPacketLog(String log) {
    setState(() {
      _packetLogs.add('${DateTime.now()}: $log');
      if (_packetLogs.length > 50) _packetLogs.removeAt(0);
    });
  }

  void _addEventLog(String log) {
    setState(() {
      _eventLogs.add('${DateTime.now()}: $log');
      if (_eventLogs.length > 50) _eventLogs.removeAt(0);
    });
  }

  void _clearPacketLogs() {
    setState(() => _packetLogs.clear());
  }

  void _clearEventLogs() {
    setState(() => _eventLogs.clear());
  }

  void _copyLogsToClipboard() {
    final logs = 'Packet Logs:\n${_packetLogs.join('\n')}\n\nEvent Logs:\n${_eventLogs.join('\n')}';
    Clipboard.setData(ClipboardData(text: logs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _toggleFakePeer(bool value) {
    setState(() => _fakePeerEnabled = value);
    if (value) {
      // Add fake peer logic here
      _addEventLog('Fake peer enabled');
    } else {
      _addEventLog('Fake peer disabled');
    }
  }

  void _toggleLoopbackTest(bool value) {
    setState(() => _loopbackTestEnabled = value);
    if (value) {
      // Enable loopback broadcasting
      _addEventLog('Loopback test enabled');
    } else {
      _addEventLog('Loopback test disabled');
    }
  }

  @override
  void dispose() {
    _noPeersTimer?.cancel();
    _packetLogSub.cancel();
    _eventLogSub.cancel();
    _backendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text('Debug & Developer Tools', style: TextStyle(color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Peers Information Panel', [
            StreamBuilder<List<Peer>>(
              stream: _backendController.peerStream,
              builder: (context, snapshot) {
                final peers = snapshot.data ?? [];
                return Column(
                  children: peers.map((peer) => ListTile(
                    title: Text(peer.name, style: const TextStyle(color: AppColors.white)),
                    subtitle: Text('${peer.address.address} - Last seen: ${peer.lastSeen}', style: const TextStyle(color: AppColors.white70)),
                  )).toList(),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('UDP/Discovery Packet Log', [
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView(
                  children: _packetLogs.map((log) => Text(log, style: const TextStyle(color: AppColors.white))).toList(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _clearPacketLogs,
              child: const Text('Clear Log'),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Network/Connectivity Diagnostics', [
            ..._networkInterfaces.map((iface) => ListTile(
              title: Text(iface.name, style: const TextStyle(color: AppColors.white)),
              subtitle: Text(iface.addresses.map((a) => a.address).join(', '), style: const TextStyle(color: AppColors.white70)),
            )),
            ElevatedButton(
              onPressed: _loadNetworkInterfaces,
              child: const Text('Refresh'),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Simulation/Testing Toggles', [
            SwitchListTile(
              title: const Text('Fake Peer', style: TextStyle(color: AppColors.white)),
              value: _fakePeerEnabled,
              onChanged: _toggleFakePeer,
            ),
            SwitchListTile(
              title: const Text('Loopback Test', style: TextStyle(color: AppColors.white)),
              value: _loopbackTestEnabled,
              onChanged: _toggleLoopbackTest,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('PTT Channel/State Diagnostics', [
            Text('Current Channel: ${_backendController.currentChannel}', style: const TextStyle(color: AppColors.white)),
            Text('PTT State: ${_backendController.isPTTActive ? 'Pressed' : 'Released'}', style: const TextStyle(color: AppColors.white)),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView(
                  children: _eventLogs.map((log) => Text(log, style: const TextStyle(color: AppColors.white))).toList(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _clearEventLogs,
              child: const Text('Clear Event Log'),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Share/Copy Logs', [
            ElevatedButton(
              onPressed: _copyLogsToClipboard,
              child: const Text('Copy Logs to Clipboard'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
