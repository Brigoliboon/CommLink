import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/device_info.dart';
import '../widgets/waveform_painter.dart';
import '../../core/backend/state_controller.dart';
import 'dart:async';
import 'dart:io';

class PTTHomeScreen extends StatefulWidget {
  final bool isGuestMode;

  const PTTHomeScreen({super.key, this.isGuestMode = true});

  @override
  State<PTTHomeScreen> createState() => _PTTHomeScreenState();
}

class _PTTHomeScreenState extends State<PTTHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isPressing = false;
  late AnimationController _waveController;
  String? _localIp;
  String? _fingerprint;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _getLocalIp();
    _getFingerprint();
  }

  Future<void> _getFingerprint() async {
    final fp = await getDeviceFingerprint();
    if (mounted) setState(() => _fingerprint = fp);
  }

  Future<void> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            if (mounted) setState(() => _localIp = addr.address);
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _localIp = 'Unknown');
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _onPTTPress() {
    setState(() => _isPressing = true);
    _waveController.repeat();
    context.read<BackendStateController>().setPTTState(true);
  }

  void _onPTTRelease() {
    setState(() => _isPressing = false);
    _waveController.stop();
    _waveController.reset();
    context.read<BackendStateController>().setPTTState(false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BackendStateController>();

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
              child: Column(
                children: [
                  Text(
                    'My IP: ${_localIp ?? ''}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (_fingerprint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Device ID: ${_fingerprint ?? ''}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
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
                  'Channel ${controller.currentChannel}',
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
        ],
      ),
    );
  }
}
