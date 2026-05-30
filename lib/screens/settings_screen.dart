import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../core/database/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _audioQuality = 'Medium';
  bool _darkMode = true;
  bool _vibrationOnPTT = true;
  bool _debugMode = false;
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isServerConnected = false;

  @override
  void initState() {
    super.initState();
    final db = DatabaseService();
    _serverUrlController.text = db.serverUrl;
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    final db = DatabaseService();
    final connected = await db.testConnection();
    if (mounted) setState(() => _isServerConnected = connected);
  }

  Future<void> _saveServerUrl() async {
    final db = DatabaseService();
    db.setServerUrl(_serverUrlController.text);
    await _checkServerConnection();
    if (_isServerConnected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server connected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsSection(
            'Server',
            [
              _buildServerTile(),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            'Audio',
            [
              _buildDropdownTile(
                'Audio Quality',
                _audioQuality,
                ['Low', 'Medium', 'High'],
                (value) => setState(() => _audioQuality = value!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            'Appearance',
            [
              _buildSwitchTile(
                'Dark Mode',
                _darkMode,
                (value) => setState(() => _darkMode = value),
              ),
              _buildSwitchTile(
                'Debug Mode',
                _debugMode,
                (value) => setState(() => _debugMode = value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            'Feedback',
            [
              _buildSwitchTile(
                'Vibration on PTT',
                _vibrationOnPTT,
                (value) => setState(() => _vibrationOnPTT = value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            'Permissions',
            [
              _buildInfoTile('Microphone', 'Granted', Icons.check_circle, Colors.green),
              _buildInfoTile('Location', 'Granted', Icons.check_circle, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
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
        ...children,
      ],
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: AppColors.white)),
              );
            }).toList(),
            dropdownColor: AppColors.lightGreen,
            style: const TextStyle(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.yellow,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String status, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          Text(
            status,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildServerTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isServerConnected ? Icons.cloud_done : Icons.cloud_off,
                color: _isServerConnected ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isServerConnected ? 'Connected' : 'Not Connected',
                style: TextStyle(
                  color: _isServerConnected ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _serverUrlController,
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'http://192.168.1.x:3000',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save, color: AppColors.white, size: 20),
                onPressed: _saveServerUrl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
