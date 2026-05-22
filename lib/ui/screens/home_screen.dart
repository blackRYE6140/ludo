import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import 'game_screen.dart';
import 'wifi_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final GameController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _playerCount = 2;

  static const Color _red = Color(0xFFEB3D3D);
  static const Color _green = Color(0xFF21B44B);
  static const Color _yellow = Color(0xFFF2C51D);
  static const Color _blue = Color(0xFF25A8F1);
  static const Color _bgDark = Color(0xFF0B1238);
  static const Color _bgLight = Color(0xFF162054);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgLight, _bgDark],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            children: <Widget>[
              const SizedBox(height: 20),
              // Logo / Title area
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildColorLetter('L', _red),
                    _buildColorLetter('U', _green),
                    _buildColorLetter('D', _yellow),
                    _buildColorLetter('O', _blue),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Le jeu classique multijoueur',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Local Mode Card
              _buildMenuCard(
                title: 'Mode Local',
                subtitle: 'Jouez sur le même appareil',
                icon: Icons.people_alt_rounded,
                accentColor: _red,
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Joueurs :',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _playerCount,
                          dropdownColor: const Color(0xFF1A224F),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          items: const <DropdownMenuItem<int>>[
                            DropdownMenuItem(value: 2, child: Text('2')),
                            DropdownMenuItem(value: 3, child: Text('3')),
                            DropdownMenuItem(value: 4, child: Text('4')),
                          ],
                          onChanged: (int? value) {
                            if (value != null) {
                              setState(() {
                                _playerCount = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                buttonText: 'Démarrer la partie',
                onPressed: () async {
                  await widget.controller.createLocalGame(playerCount: _playerCount);
                  if (!context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => GameScreen(controller: widget.controller),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Wifi Mode Card
              _buildMenuCard(
                title: 'Wi-Fi Local',
                subtitle: 'Rejoignez ou hébergez une partie',
                icon: Icons.wifi_rounded,
                accentColor: _blue,
                content: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Jouez avec vos amis sur le même réseau Wi-Fi, chacun sur son écran.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),
                buttonText: 'Ouvrir le Lobby',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => WifiLobbyScreen(controller: widget.controller),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              // Rules footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white54, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Faites un 6 pour sortir un pion.\nRejouez si vous faites un 6.',
                        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorLetter(String letter, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget content,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF222B5D),
            Color(0xFF181F46),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white10, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                content,
              ],
            ),
          ),
          InkWell(
            onTap: onPressed,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor,
                    Color.lerp(accentColor, Colors.black, 0.2)!,
                  ],
                ),
              ),
              child: Text(
                buttonText.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
