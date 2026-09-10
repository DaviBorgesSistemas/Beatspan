import 'package:flutter/material.dart';

import '../../domain/model/musica_playback_result.dart';

sealed class GameNavigationEvent {
  const GameNavigationEvent();
}

class NavigateToError extends GameNavigationEvent {
  final String? title;
  final String? message;
  final IconData? icon;

  const NavigateToError({this.title, this.message, this.icon});
}

class NavigateToPlayer extends GameNavigationEvent {
  final MusicaPlaybackResult playback;

  const NavigateToPlayer(this.playback);
}
