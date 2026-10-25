import 'package:flutter/material.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:opencloud/pages/player/widgets/common/play_pause_button.dart';
import 'package:opencloud/pages/player/widgets/common/skip_controls.dart';

class MiniVideoPlayer extends StatefulWidget {
  const MiniVideoPlayer({
    Key? key,
  }) : super(key: key);

  @override
  State<MiniVideoPlayer> createState() => _MiniVideoPlayerState();
}

class _MiniVideoPlayerState extends State<MiniVideoPlayer> {
  @override
  void initState() {
    super.initState();
    final p = context.read<PlayerProvider>();
    p.addListener(_onProviderChanged);
    final active = p.player;
    if (active is VideoActive) {
      active.controller.addListener(_onControllerChanged);
    }
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final p = context.read<PlayerProvider>();
    p.removeListener(_onProviderChanged);
    final active = p.player;
    if (active is VideoActive) {
      active.controller.removeListener(_onControllerChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerProvider p = Provider.of<PlayerProvider>(context);
    if (p.player == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final active = p.player;
    if (active case VideoActive(:final controller)) {
      return Row(
        children: [
          Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(color: Colors.black),
                child: VideoPlayer(controller),
              )),
          Expanded(
            flex: 6,
            child: Text(p.playerQueue[p.playerIndex].fullPath.split("/").last),
          ),
          Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PlayPauseButton(provider: p),
                  SkipControls(provider: p),
                ],
              ))
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
