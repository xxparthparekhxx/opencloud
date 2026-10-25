import 'package:flutter/material.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/pages/player/widgets/common/play_pause_button.dart';
import 'package:opencloud/pages/player/widgets/common/skip_controls.dart';

class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PlayerProvider p = Provider.of<PlayerProvider>(context);
    if (p.playerState == PlayerStates.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(color: Colors.black),
              width: 50,
              height: 50,
              child: Image.asset("assets/music_note.png"),
            )),
        Expanded(
          flex: 6,
          child: Text(p.playerQueue[p.playerIndex].fullPath.split("/").last),
        ),
        Expanded(
            flex: 3,
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
}
