import 'package:flutter/material.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';

void main() => runApp(const AutoPrintApp());

class AutoPrintApp extends StatelessWidget {
  const AutoPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
