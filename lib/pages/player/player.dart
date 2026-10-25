import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:opencloud/pages/player/widgets/audio/page.dart';
import 'package:opencloud/pages/player/widgets/audio/mini.dart';
import 'package:opencloud/pages/player/widgets/video/page.dart';
import 'package:opencloud/pages/player/widgets/video/mini.dart';

class Player extends StatelessWidget {
  final bool miniPlayer;
  final Function setMiniPlayer;
  const Player(
      {Key? key, required this.miniPlayer, required this.setMiniPlayer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);
    final active = p.player;

    if (miniPlayer) {
      return switch (active) {
        AudioActive() => const MiniAudioPlayer(),
        VideoActive() => const MiniVideoPlayer(),
        ImageActive() => const SizedBox.shrink(),
        null => const SizedBox.shrink(),
      };
    }

    return switch (active) {
      AudioActive() => SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: AudioPlayerPage(setMiniPlayer: setMiniPlayer),
            ),
          ),
        ),
      VideoActive() => SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: VideoPlayerPage(setMiniPlayer: setMiniPlayer),
            ),
          ),
        ),
      ImageActive(:final url) => Image.network(url),
      null => const SizedBox.shrink(),
    };
  }
}
