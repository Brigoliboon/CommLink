import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../../core/backend/peer_discovery.dart';
import '../../core/backend/state_controller.dart';
import 'dart:async';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _scanController;
  late BackendStateController _backendController;
  late PeerDiscoveryService _peerDiscoveryService;
  List<Peer> _devices = [];
  late final StreamSubscription<List<Peer>> _peerSub;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Init peer discovery, name could be device/user; for now let's use 'Me'.
    _peerDiscoveryService = PeerDiscoveryService(selfName: 'Me');
    _backendController = BackendStateController(_peerDiscoveryService);
    _peerSub = _backendController.peerStream.listen((peers) {
      if (mounted) {
        setState(() => _devices = peers);
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _peerSub.cancel();
    _backendController.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() => _isScanning = true);
    _scanController.repeat();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isScanning = false);
        _scanController.stop();
        _scanController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text('Device Discovery', style: TextStyle(color: AppColors.white)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isScanning ? null : _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? AppColors.yellow : AppColors.white,
                    foregroundColor: _isScanning ? AppColors.forestGreen : AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(_isScanning ? 'Scanning...' : 'Start Scan'),
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Scanning for devices...',
                    style: TextStyle(color: AppColors.white),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final Peer device = _devices[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.yellow,
                        child: const Icon(Icons.phone, color: AppColors.forestGreen),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(children: [
                                const Icon(Icons.radio, size: 14, color: AppColors.yellow),
                                const SizedBox(width: 5),
                                Text(
                                device.address.address,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                            ]),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.signal_cellular_4_bar,
                        color: AppColors.yellow,
                        size: 28,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
