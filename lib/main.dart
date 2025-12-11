// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const CommLinkApp());
}

class CommLinkApp extends StatelessWidget {
  const CommLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.forestGreen,
        scaffoldBackgroundColor: AppColors.forestGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forestGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

