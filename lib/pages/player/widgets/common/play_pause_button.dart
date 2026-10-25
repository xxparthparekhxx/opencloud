import 'package:flutter/material.dart';
import 'package:opencloud/providers/player_provider.dart';

/// Shared play/pause toggle. Shows pause when playing, play otherwise.
class PlayPauseButton extends StatelessWidget {
  final PlayerProvider provider;
  final double iconSize;
  const PlayPauseButton({
    Key? key,
    required this.provider,
    this.iconSize = 36.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playing = provider.playerState == PlayerStates.playing;
    return IconButton(
      onPressed: playing ? provider.pausePlaying : provider.resumePlaying,
      icon: Icon(
        playing ? Icons.pause : Icons.play_arrow,
        size: iconSize,
      ),
    );
  }
}
