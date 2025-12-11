import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.forestGreen,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.radio,
                    size: 60,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CommLink',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.lightGreen),
            ListTile(
              leading: const Icon(Icons.radio, color: AppColors.yellow),
              title: const Text('Home', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view, color: AppColors.white),
              title: const Text('Channels', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.radar, color: AppColors.white),
              title: const Text('Discovery', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.white),
              title: const Text('Settings', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '© 2024 CommLink',
                style: TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
