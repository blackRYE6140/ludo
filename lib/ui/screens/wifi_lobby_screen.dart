import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  final TextEditingController _portController = TextEditingController(text: '4545');

  int _hostPlayers = 2;
  bool _isScanning = false;

  static const Color _bgDark = Color(0xFF0B1238);
  static const Color _bgLight = Color(0xFF162054);
  static const Color _blue = Color(0xFF25A8F1);
  static const Color _green = Color(0xFF21B44B);

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
          backgroundColor: _bgDark,
          appBar: AppBar(
            backgroundColor: _bgDark,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Lobby Wi-Fi', style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: _blue,
              labelColor: _blue,
              unselectedLabelColor: Colors.white54,
              tabs: const <Widget>[
                Tab(text: 'Héberger'),
                Tab(text: 'Rejoindre'),
              ],
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgDark, _bgLight],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(), // Prevent swipe during scan
                      children: <Widget>[
                        _buildHostTab(state),
                        _buildJoinTab(),
                      ],
                    ),
                  ),
                  if (state != null) _buildLobbyStatus(state),
                ],
              ),
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
                  backgroundColor: _green,
                  icon: const Icon(Icons.sports_esports, color: Colors.white),
                  label: const Text('Ouvrir la partie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHostTab(GameState? state) {
    final bool isHosting = state != null && state.mode == GameMode.wifiHost;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: isHosting ? _buildHostLobbyInfo() : _buildHostSetup(),
    );
  }

  Widget _buildHostSetup() {
    return ListView(
      children: <Widget>[
        const Text(
          'Créer une partie locale',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _hostNameController,
          label: 'Votre Pseudo',
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Nombre de joueurs:', style: TextStyle(color: Colors.white, fontSize: 16)),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _hostPlayers,
                  dropdownColor: const Color(0xFF1A224F),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  items: const <DropdownMenuItem<int>>[
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 3, child: Text('3')),
                    DropdownMenuItem(value: 4, child: Text('4')),
                  ],
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() => _hostPlayers = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Générer le QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildHostLobbyInfo() {
    String qrData = '';
    if (widget.controller.networkInfo.isNotEmpty) {
      final List<String> parts = widget.controller.networkInfo.split(' ');
      if (parts.length > 1) {
        qrData = parts.last;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Faites scanner ce code pour rejoindre',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 24),
        if (qrData.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(color: _blue.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          )
        else
          const CircularProgressIndicator(),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: widget.controller.canStartHostedGame
              ? () => widget.controller.startHostedGame()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            disabledBackgroundColor: Colors.white24,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text('Lancer la partie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Rejoindre une partie',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _joinNameController,
            label: 'Votre Pseudo',
            icon: Icons.person,
          ),
          const SizedBox(height: 32),
          if (_isScanning)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (BarcodeCapture capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final String code = barcodes.first.rawValue!;
                      final List<String> parts = code.split(':');
                      if (parts.length == 2) {
                        setState(() => _isScanning = false);
                        widget.controller.joinWifiGame(
                          host: parts[0],
                          port: int.tryParse(parts[1]) ?? 4545,
                          playerName: _joinNameController.text.trim().isEmpty
                              ? 'Joueur'
                              : _joinNameController.text.trim(),
                        );
                      }
                    }
                  },
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isScanning = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  label: const Text('Scanner le QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildLobbyStatus(GameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF131A3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                state.status == GameStatus.inProgress ? Icons.videogame_asset : Icons.groups,
                color: _blue,
              ),
              const SizedBox(width: 12),
              Text(
                state.status == GameStatus.inProgress ? 'Partie en cours' : 'Salle d\'attente',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.controller.lastError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                widget.controller.lastError,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: state.players.map((Player player) {
              final bool isWaiting = player.name.startsWith('En attente');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isWaiting ? Colors.white10 : player.color.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWaiting ? Colors.white24 : player.color.color.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isWaiting ? Icons.hourglass_empty : Icons.check_circle,
                      size: 16,
                      color: isWaiting ? Colors.white54 : player.color.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.name,
                      style: TextStyle(
                        color: isWaiting ? Colors.white54 : Colors.white,
                        fontWeight: isWaiting ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
