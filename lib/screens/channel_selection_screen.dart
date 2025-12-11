import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../../core/backend/peer_discovery.dart';
import '../../core/backend/state_controller.dart';
import '../../config/network_config.dart';

class ChannelSelectionScreen extends StatefulWidget {
  const ChannelSelectionScreen({super.key});

  @override
  State<ChannelSelectionScreen> createState() => _ChannelSelectionScreenState();
}

class _ChannelSelectionScreenState extends State<ChannelSelectionScreen> {
  late BackendStateController _backendController;
  late PeerDiscoveryService _peerDiscoveryService;
  int _selectedChannel = NetworkConfig.DEFAULT_CHANNEL;

  final List<Map<String, dynamic>> _channels = [
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
  void initState() {
    super.initState();
    _peerDiscoveryService = PeerDiscoveryService(selfName: 'Me');
    _backendController = BackendStateController(_peerDiscoveryService);
    _selectedChannel = _backendController.currentChannel;
    _backendController.channelStream.listen((ch) {
      if (mounted) setState(() => _selectedChannel = ch);
    });
  }

  @override
  void dispose() {
    _backendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          final isSelected = channel['id'] == _selectedChannel;

          return GestureDetector(
            onTap: () {
              _backendController.setChannel(channel['id']);
              setState(() {
                _selectedChannel = channel['id'];
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.yellow : AppColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppColors.yellow : Colors.black)
                        .withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CH ${channel['id']}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.forestGreen : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    channel['freq'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.forestGreen.withOpacity(0.8)
                          : AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isSelected ? AppColors.forestGreen : AppColors.yellow,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${channel['users']}',
                        style: TextStyle(
                          color: isSelected ? AppColors.forestGreen : AppColors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
