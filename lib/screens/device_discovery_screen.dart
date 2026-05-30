import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../../core/backend/state_controller.dart';
import '../../core/backend/peer_discovery.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
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
    final controller = context.watch<BackendStateController>();

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
            child: StreamBuilder<List<Peer>>(
              stream: controller.peerStream,
              builder: (context, snapshot) {
                final devices = snapshot.data ?? controller.currentPeers;

                if (devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar, size: 64, color: AppColors.yellow.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No devices found',
                          style: TextStyle(color: AppColors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Press Start Scan to discover peers',
                          style: TextStyle(color: AppColors.white70),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final Peer device = devices[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
