import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../../core/backend/state_controller.dart';

class ChannelSelectionScreen extends StatelessWidget {
  const ChannelSelectionScreen({super.key});

  static const List<Map<String, dynamic>> _channels = [
    {'id': 1, 'freq': '462.5625 MHz'},
    {'id': 2, 'freq': '462.5875 MHz'},
    {'id': 3, 'freq': '462.6125 MHz'},
    {'id': 4, 'freq': '462.6375 MHz'},
    {'id': 5, 'freq': '462.6625 MHz'},
    {'id': 6, 'freq': '462.6875 MHz'},
    {'id': 7, 'freq': '462.7125 MHz'},
    {'id': 8, 'freq': '467.5625 MHz'},
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BackendStateController>();

    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text('Select Channel', style: TextStyle(color: AppColors.white)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
        ),
        itemCount: _channels.length,
        itemBuilder: (context, index) {
          final channel = _channels[index];
          final chId = channel['id'] as int;
          final isSelected = chId == controller.currentChannel;

          return GestureDetector(
            onTap: () => controller.setChannel(chId),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.yellow : AppColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppColors.yellow : Colors.black)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CH $chId',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.forestGreen : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    channel['freq'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.forestGreen.withValues(alpha: 0.8)
                          : AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
