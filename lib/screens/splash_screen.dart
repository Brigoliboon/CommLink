import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main_screen.dart';
import '../utils/app_colors.dart';
import '../core/database/database_service.dart';
import '../utils/device_info.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _deviceFingerprint;
  bool _isCheckingHealth = false;
  bool _healthCheckPassed = false;
  bool _isDeviceRegistered = false;

  final TextEditingController _serverController = TextEditingController(text: 'http://0.0.0.0:8000');
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initDeviceFingerprint();
  }

  Future<void> _initDeviceFingerprint() async {
    _deviceFingerprint = await getDeviceFingerprint();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.location.request();
    _showServerDialog();
  }

  Future<void> _showServerDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.lightGreen,
          title: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Server Connection',
                style: TextStyle(color: AppColors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the server URL:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _serverController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'http://0.0.0.0:8000',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    prefixIcon: const Icon(Icons.cloud, color: AppColors.white),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setDialogState(() {
                    _healthCheckPassed = false;
                    _isDeviceRegistered = false;
                  }),
                ),
                const SizedBox(height: 10),
                if (_healthCheckPassed && !_isDeviceRegistered) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Device not registered. Enter your name:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      prefixIcon: const Icon(Icons.person, color: AppColors.white),
                    ),
                  ),
                ],
                if (_healthCheckPassed) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isDeviceRegistered ? Icons.check_circle : Icons.warning,
                          color: _isDeviceRegistered ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isDeviceRegistered
                                ? 'Connected - Device registered'
                                : 'Connected - Guest mode',
                            style: TextStyle(
                              color: _isDeviceRegistered ? Colors.green : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToMain(isGuestMode: true);
              },
              child: const Text(
                'Guest Mode',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: _healthCheckPassed && !_isDeviceRegistered
                  ? () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      final db = DatabaseService();
                      final result = await db.registerDeviceFull(
                        _deviceFingerprint ?? '',
                        name,
                      );
                      if (result != null && context.mounted) {
                        Navigator.pop(context);
                        _navigateToMain(isGuestMode: false);
                      }
                    }
                  : () async {
                      final url = _serverController.text.trim();
                      if (url.isEmpty) return;

                      setDialogState(() => _isCheckingHealth = true);

                      final db = DatabaseService();
                      db.setServerUrl(url);
                      final healthOk = await db.testConnection();

                      if (healthOk && _deviceFingerprint != null) {
                        final registered = await db.isDeviceRegistered(_deviceFingerprint!);
                        setDialogState(() {
                          _healthCheckPassed = true;
                          _isDeviceRegistered = registered;
                          _isCheckingHealth = false;
                        });
                        if (registered) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            _navigateToMain(isGuestMode: false);
                          }
                        }
                      } else {
                        setDialogState(() => _isCheckingHealth = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connection failed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.forestGreen,
              ),
              child: Text(
                _healthCheckPassed && !_isDeviceRegistered
                    ? 'Register & Connect'
                    : _isCheckingHealth
                        ? 'Checking...'
                        : 'Connect',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToMain({required bool isGuestMode}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(isGuestMode: isGuestMode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.radio,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'CommLink',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
