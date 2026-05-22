import 'package:flutter/material.dart';

import 'controllers/game_controller.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LudoApp());
}

class LudoApp extends StatefulWidget {
  const LudoApp({super.key});

  @override
  State<LudoApp> createState() => _LudoAppState();
}

class _LudoAppState extends State<LudoApp> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeScreen(controller: _controller),
    );
  }
}
