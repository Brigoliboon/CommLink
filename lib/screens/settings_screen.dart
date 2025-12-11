import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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
}
