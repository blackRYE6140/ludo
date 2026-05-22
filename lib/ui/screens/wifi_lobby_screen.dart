import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'game_screen.dart';

class WifiLobbyScreen extends StatefulWidget {
  const WifiLobbyScreen({
    super.key,
    required this.controller,
  });

  final GameController controller;

  @override
  State<WifiLobbyScreen> createState() => _WifiLobbyScreenState();
}

class _WifiLobbyScreenState extends State<WifiLobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _hostNameController = TextEditingController(text: 'Hôte');
  final TextEditingController _joinNameController = TextEditingController(text: 'Joueur');
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '4545');

  int _hostPlayers = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostNameController.dispose();
    _joinNameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, _) {
        final GameState? state = widget.controller.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lobby Wi-Fi local'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const <Widget>[
                Tab(text: 'Créer (Hôte)'),
                Tab(text: 'Rejoindre'),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _buildHostTab(),
                      _buildJoinTab(),
                    ],
                  ),
                ),
                if (state != null) _buildLobbyStatus(state),
              ],
            ),
          ),
          floatingActionButton: (state != null && state.status == GameStatus.inProgress)
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameScreen(controller: widget.controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('Ouvrir la partie'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHostTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: <Widget>[
          TextField(
            controller: _hostNameController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'hôte',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Text('Joueurs:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _hostPlayers,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                ],
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _hostPlayers = value;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final int port = int.tryParse(_portController.text.trim()) ?? 4545;
              await widget.controller.hostWifiGame(
                playerCount: _hostPlayers,
                playerName: _hostNameController.text.trim().isEmpty
                    ? 'Hôte'
                    : _hostNameController.text.trim(),
                port: port,
              );
            },
            icon: const Icon(Icons.router),
            label: const Text('Démarrer le lobby hôte'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: widget.controller.canStartHostedGame
                ? () => widget.controller.startHostedGame()
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lancer la partie'),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: <Widget>[
          TextField(
            controller: _joinNameController,
            decoration: const InputDecoration(
              labelText: 'Votre nom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP de l\'hôte',
              hintText: 'Ex: 192.168.1.42',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final int port = int.tryParse(_portController.text.trim()) ?? 4545;
              await widget.controller.joinWifiGame(
                host: _ipController.text.trim(),
                port: port,
                playerName: _joinNameController.text.trim().isEmpty
                    ? 'Joueur'
                    : _joinNameController.text.trim(),
              );
            },
            icon: const Icon(Icons.wifi_find),
            label: const Text('Rejoindre la partie'),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyStatus(GameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            state.status == GameStatus.inProgress ? 'Partie en cours' : 'Lobby',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(state.infoMessage),
          if (widget.controller.networkInfo.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(widget.controller.networkInfo),
          ],
          if (widget.controller.lastError.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              widget.controller.lastError,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.players
                .map(
                  (Player player) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: player.color.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${player.color.label}: ${player.name}'),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
