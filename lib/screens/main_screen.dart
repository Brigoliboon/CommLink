import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'ptt_home_screen.dart';
import 'channel_selection_screen.dart';
import 'device_discovery_screen.dart';
import 'settings_screen.dart';
import 'debug_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PTTHomeScreen(),
    const ChannelSelectionScreen(),
    const DeviceDiscoveryScreen(),
    const SettingsScreen(),
    const DebugScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.forestGreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.yellow,
          unselectedItemColor: AppColors.white.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radio),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Channels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar),
              label: 'Discovery',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bug_report),
              label: 'Debug',
            ),
          ],
        ),
      ),
    );
  }
}
