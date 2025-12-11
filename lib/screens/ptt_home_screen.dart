import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/waveform_painter.dart';
import '../../core/backend/peer_discovery.dart';
import '../../core/backend/state_controller.dart';
import 'dart:async';
import 'dart:io';

class PTTHomeScreen extends StatefulWidget {
  const PTTHomeScreen({super.key});

  @override
  State<PTTHomeScreen> createState() => _PTTHomeScreenState();
}

class _PTTHomeScreenState extends State<PTTHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isPressing = false;
  late AnimationController _waveController;
  late PeerDiscoveryService _peerDiscoveryService;
  late BackendStateController _backendController;
  late Stream<List<Peer>> _peerStream;
  late Stream<int> _channelStream;
  late Stream<bool> _audioReceivingStream;
  int _currentChannel = 1;
  List<Peer> _peers = [];
  bool _isReceivingAudio = false;
  late final StreamSubscription<List<Peer>> _peerSub;
  late final StreamSubscription<int> _chSub;
  late final StreamSubscription<bool> _audioReceivingSub;
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _peerDiscoveryService = PeerDiscoveryService(selfName: 'Me');
    _backendController = BackendStateController(_peerDiscoveryService);
    _peerDiscoveryService.start();
    _peerStream = _backendController.peerStream;
    _channelStream = _backendController.channelStream;
    _peerSub = _peerStream.listen((peers) {
      if (mounted) setState(() => _peers = peers);
    });
    _chSub = _channelStream.listen((ch) {
      if (mounted) setState(() => _currentChannel = ch);
    });
    _currentChannel = _backendController.currentChannel;
    _peers = _backendController.currentPeers;
    _getLocalIp();
  }

  Future<void> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            setState(() => _localIp = addr.address);
            return;
          }
        }
      }
    } catch (e) {
      setState(() => _localIp = 'Unknown');
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _peerSub.cancel();
    _chSub.cancel();
    _audioReceivingSub.cancel();
    _backendController.dispose();
    super.dispose();
  }

  void _onPTTPress() {
    setState(() => _isPressing = true);
    _waveController.repeat();
    _backendController.setPTTState(true);
  }

  void _onPTTRelease() {
    setState(() => _isPressing = false);
    _waveController.stop();
    _waveController.reset();
    _backendController.setPTTState(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text('CommLink', style: TextStyle(color: AppColors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                SizedBox(width: 5),
                Text(
                  'Connected',
                  style: TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_localIp != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'My IP:  a0 a0 a0 a0 a0 a0 a0${_localIp ?? ''}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.radio, color: AppColors.yellow, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Channel $_currentChannel',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => _onPTTPress(),
                onTapUp: (_) => _onPTTRelease(),
                onTapCancel: _onPTTRelease,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _isPressing
                          ? WaveformPainter(_waveController.value)
                          : null,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPressing
                              ? AppColors.yellow
                              : AppColors.lightGreen,
                          boxShadow: [
                            BoxShadow(
                              color: (_isPressing
                                      ? AppColors.yellow
                                      : AppColors.lightGreen)
                                  .withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: _isPressing ? 10 : 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPressing ? Icons.mic : Icons.mic_none,
                              size: 60,
                              color: _isPressing
                                  ? AppColors.forestGreen
                                  : AppColors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isPressing ? 'TALKING' : 'PUSH TO TALK',
                              style: TextStyle(
                                color: _isPressing
                                    ? AppColors.forestGreen
                                    : AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, color: AppColors.yellow, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Peers',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_peers.length}',
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._peers.map((peer) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.greenAccent, // No status logic yet
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppColors.debugMode ? '${peer.name} (${peer.address.address})' : peer.name,
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
