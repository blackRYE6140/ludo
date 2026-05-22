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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ludo Flutter')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 12),
            const Text(
              'Jeu Ludo classique',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              '2 à 4 joueurs, local ou Wi-Fi local.',
              style: TextStyle(fontSize: 16, color: Color(0xFF455A64)),
            ),
            const SizedBox(height: 26),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Mode local (même appareil)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Text('Nombre de joueurs: '),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _playerCount,
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.controller.createLocalGame(playerCount: _playerCount);
                        if (!context.mounted) {
                          return;
                        }
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                GameScreen(controller: widget.controller),
                          ),
                        );
                      },
                      icon: const Icon(Icons.smartphone),
                      label: const Text('Démarrer en local'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Mode Wi-Fi local',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Un joueur héberge, les autres rejoignent via IP locale.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                WifiLobbyScreen(controller: widget.controller),
                          ),
                        );
                      },
                      icon: const Icon(Icons.wifi),
                      label: const Text('Ouvrir le lobby Wi-Fi'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Règles: sortie avec 6, capture hors cases protégées, reroll après 6.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
            ),
          ],
        ),
      ),
    );
  }
}
