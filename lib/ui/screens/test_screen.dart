import 'package:flutter/material.dart';

class testScreen extends StatefulWidget {
  const testScreen({super.key});

  @override
  State<testScreen> createState() => _testScreenState();
}

class _testScreenState extends State<testScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: IconButton( onPressed: () {  }, icon:  Icon(Icons.mic)));
  }
}