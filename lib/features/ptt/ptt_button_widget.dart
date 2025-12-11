import 'package:flutter/material.dart';
import 'ptt_controller.dart';

class PTTButtonWidget extends StatefulWidget {
  final PTTController controller;
  const PTTButtonWidget({required this.controller, super.key});

  @override
  _PTTButtonWidgetState createState() => _PTTButtonWidgetState();
}

class _PTTButtonWidgetState extends State<PTTButtonWidget> {
  bool isRecording = false;

  void onPress() async {
    setState(() => isRecording = true);
    await widget.controller.startPTT();
  }

  void onRelease() async {
    setState(() => isRecording = false);
    await widget.controller.stopPTT();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onPress(),
      onLongPressEnd: (_) => onRelease(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isRecording ? Colors.red : Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, size: 48, color: Colors.white),
      ),
    );
  }
}
