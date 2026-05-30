// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_colors.dart';
import 'utils/device_info.dart';
import 'core/backend/state_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const CommLinkApp());
}

class CommLinkApp extends StatelessWidget {
  const CommLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.forestGreen,
        scaffoldBackgroundColor: AppColors.forestGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forestGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _CommLinkBootstrap(),
    );
  }
}

/// Resolves the device name, creates a single shared [BackendStateController],
/// and provides it to the entire widget tree via [Provider].
class _CommLinkBootstrap extends StatefulWidget {
  const _CommLinkBootstrap();

  @override
  State<_CommLinkBootstrap> createState() => _CommLinkBootstrapState();
}

class _CommLinkBootstrapState extends State<_CommLinkBootstrap> {
  BackendStateController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final deviceName = await getDeviceName();
    final deviceFingerprint = await getDeviceFingerprint();
    final controller = BackendStateController(
      deviceName: deviceName,
      deviceFingerprint: deviceFingerprint,
    );
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SplashScreen();
    }
    return Provider<BackendStateController>.value(
      value: _controller!,
      child: const MainScreen(),
    );
  }
}

