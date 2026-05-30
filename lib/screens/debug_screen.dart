import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../../core/backend/state_controller.dart';
import '../../core/backend/peer_discovery.dart';
import 'dart:async';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  late final StreamSubscription<String> _eventLogSub;
  final List<String> _eventLogs = [];
  List<NetworkInterface> _networkInterfaces = [];
  bool _fakePeerEnabled = false;
  bool _loopbackTestEnabled = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<BackendStateController>();

    _eventLogSub = controller.eventLogStream.listen((log) {
      _addEventLog(log);
    });

    controller.channelStream.listen((ch) {
      _addEventLog('Channel changed to $ch');
    });
    controller.pttStream.listen((ptt) {
      _addEventLog('PTT ${ptt ? 'pressed' : 'released'}');
    });

    _loadNetworkInterfaces();
  }

  @override
  void dispose() {
    _eventLogSub.cancel();
    super.dispose();
  }

  Future<void> _loadNetworkInterfaces() async {
    try {
      _networkInterfaces = await NetworkInterface.list();
      if (mounted) setState(() {});
    } catch (e) {
      _addEventLog('Error loading network interfaces: $e');
    }
  }

  void _addEventLog(String log) {
    if (!mounted) return;
    setState(() {
      _eventLogs.add('${DateTime.now()}: $log');
      if (_eventLogs.length > 50) _eventLogs.removeAt(0);
    });
  }

  void _clearEventLogs() {
    setState(() => _eventLogs.clear());
  }

  void _copyLogsToClipboard() {
    final logs = 'Event Logs:\n${_eventLogs.join('\n')}';
    Clipboard.setData(ClipboardData(text: logs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _toggleFakePeer(bool value) {
    setState(() => _fakePeerEnabled = value);
    _addEventLog('Fake peer ${value ? 'enabled' : 'disabled'} (stub)');
  }

  void _toggleLoopbackTest(bool value) {
    setState(() => _loopbackTestEnabled = value);
    _addEventLog('Loopback test ${value ? 'enabled' : 'disabled'} (stub)');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BackendStateController>();

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
          _buildSection('Peers Information', [
            StreamBuilder<List<Peer>>(
              stream: controller.peerStream,
              builder: (context, snapshot) {
                final peers = snapshot.data ?? controller.currentPeers;
                if (peers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No peers discovered', style: TextStyle(color: AppColors.white70)),
                  );
                }
                return Column(
                  children: peers.map((peer) => ListTile(
                    title: Text(peer.name, style: const TextStyle(color: AppColors.white)),
                    subtitle: Text('${peer.address.address}', style: const TextStyle(color: AppColors.white70)),
                  )).toList(),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('PTT & Channel State', [
            Text('Current Channel: ${controller.currentChannel}', style: const TextStyle(color: AppColors.white)),
            Text('PTT State: ${controller.isPTTActive ? 'Pressed' : 'Released'}', style: const TextStyle(color: AppColors.white)),
            const SizedBox(height: 10),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView(
                children: _eventLogs.map((log) => Text(log, style: const TextStyle(color: AppColors.white))).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _clearEventLogs,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Network Interfaces', [
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
          _buildSection('Simulation Toggles', [
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
          _buildSection('Share Logs', [
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
