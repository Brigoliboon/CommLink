import 'package:flutter/material.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/network/udp_service.dart';
import '../../features/ptt/ptt_controller.dart';
import '../../features/ptt/ptt_button_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AudioEngine audioEngine;
  late UDPService udpService;
  late PTTController pttController;

  @override
  void initState() {
    super.initState();
    audioEngine = AudioEngine();
    udpService = UDPService(audioEngine);
    pttController = PTTController(audioEngine, udpService);

    initServices();
  }

  Future<void> initServices() async {
    await audioEngine.init();
    await udpService.init();
  }

  @override
  void dispose() {
    udpService.dispose();
    audioEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PTTButtonWidget(controller: pttController),
      ),
    );
  }
}
