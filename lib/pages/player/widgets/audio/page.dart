import 'package:flutter/material.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/pages/player/widgets/common/header_row.dart';
import 'package:opencloud/pages/player/widgets/common/play_pause_button.dart';
import 'package:opencloud/pages/player/widgets/common/skip_controls.dart';

class AudioPlayerPage extends StatelessWidget {
  final Function setMiniPlayer;

  const AudioPlayerPage({
    Key? key,
    required this.setMiniPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PlayerProvider p = Provider.of<PlayerProvider>(context);
    if (p.playerState == PlayerStates.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeaderRow(onMinimize: () => setMiniPlayer(true)),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    width: 200,
                    height: 200,
                    child: Image.asset("assets/music_note.png"),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.playerQueue[p.playerIndex].fullPath
                          .split("/")
                          .last),
                      const Text("Artist"),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  StreamBuilder(
                      stream: (p.player as AudioActive).player.positionStream,
                      builder: (c, AsyncSnapshot<Duration> ss) {
                        return Text(ss.data
                            .toString()
                            .substring(0, ss.data.toString().length - 7));
                      }),
                  Expanded(
                    child: StreamBuilder(
                        stream: (p.player as AudioActive).player.positionStream,
                        builder: (c, AsyncSnapshot<Duration> ss) {
                          final player = (p.player as AudioActive).player;
                          return Slider(
                            max:
                                player.duration!.inMilliseconds.roundToDouble(),
                            min: 0.0,
                            onChanged: (value) => player
                                .seek(Duration(milliseconds: value.round())),
                            value: ss.data!.inMilliseconds.floorToDouble() <
                                    player.duration!.inMilliseconds
                                        .roundToDouble()
                                ? ss.data!.inMilliseconds.floorToDouble()
                                : player.duration!.inMilliseconds
                                    .roundToDouble(),
                          );
                        }),
                  ),
                  Text((p.player as AudioActive)
                      .player
                      .duration
                      .toString()
                      .substring(
                          0,
                          (p.player as AudioActive)
                                  .player
                                  .duration
                                  .toString()
                                  .length -
                              7)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.shuffle_outlined)),
                  SkipControls(provider: p),
                  PlayPauseButton(provider: p, iconSize: 36.0),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.repeat_one_outlined)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
