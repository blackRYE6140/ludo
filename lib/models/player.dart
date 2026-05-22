import 'package:flutter/material.dart';

import 'pawn.dart';

enum PlayerColor { red, green, yellow, blue }

extension PlayerColorX on PlayerColor {
  String get label {
    switch (this) {
      case PlayerColor.red:
        return 'Rouge';
      case PlayerColor.green:
        return 'Vert';
      case PlayerColor.yellow:
        return 'Jaune';
      case PlayerColor.blue:
        return 'Bleu';
    }
  }

  Color get color {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFD32F2F);
      case PlayerColor.green:
        return const Color(0xFF2E7D32);
      case PlayerColor.yellow:
        return const Color(0xFFF9A825);
      case PlayerColor.blue:
        return const Color(0xFF1565C0);
    }
  }

  int get startTrackIndex {
    switch (this) {
      case PlayerColor.red:
        return 0;
      case PlayerColor.green:
        return 13;
      case PlayerColor.yellow:
        return 26;
      case PlayerColor.blue:
        return 39;
    }
  }

  int get homeEntryTrackIndex => (startTrackIndex + 50) % 52;

  String get code => name;

  static PlayerColor fromCode(String value) {
    return PlayerColor.values.firstWhere(
      (PlayerColor color) => color.name == value,
      orElse: () => PlayerColor.red,
    );
  }
}

@immutable
class Player {
  final PlayerColor color;
  final String name;
  final List<Pawn> pawns;

  const Player({
    required this.color,
    required this.name,
    required this.pawns,
  });

  bool get hasWon => pawns.every((Pawn pawn) => pawn.isFinished);

  Player copyWith({
    String? name,
    List<Pawn>? pawns,
  }) {
    return Player(
      color: color,
      name: name ?? this.name,
      pawns: pawns ?? this.pawns,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'color': color.code,
      'name': name,
      'pawns': pawns.map((Pawn pawn) => pawn.toJson()).toList(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      color: PlayerColorX.fromCode((json['color'] ?? 'red') as String),
      name: (json['name'] ?? '') as String,
      pawns: ((json['pawns'] ?? <dynamic>[]) as List<dynamic>)
          .map((dynamic raw) => Pawn.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }
}
