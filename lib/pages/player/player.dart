import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:opencloud/providers/player_provider.dart' as a;

import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class Player extends StatelessWidget {
  final bool miniPlayer;
  final Function setMiniPlayer;
  const Player(
      {Key? key, required this.miniPlayer, required this.setMiniPlayer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);

    if (miniPlayer && p.player.runtimeType == AudioPlayer) {
      return Row(
        children: [
          Expanded(
              child: Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(color: Colors.white),
            width: 50,
            height: 50,
            child: Image.asset("assets/music_note.png"),
          )),
          Expanded(
            flex: 3,
            child: Text(p.playerQueue[p.playerIndex].fullPath.split("/").last),
          ),
          Expanded(
              child: Row(
            children: [
              if (p.playerState == a.PlayerState.playing)
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    p.pausePlaying();
                  },
                ),
              if (p.playerState == a.PlayerState.paused)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    p.resumePlaying();
                  },
                ),
              const Icon(Icons.skip_next)
            ],
          ))
        ],
      );
    } else if (miniPlayer && p.player.runtimeType == VideoPlayerController) {
      return Row(
        children: [
          Expanded(
              child: Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(color: Colors.white),
            width: 50,
            height: 60,
            child: VideoPlayer(p.player),
          )),
          Expanded(
            flex: 3,
            child: Text(p.playerQueue[p.playerIndex].fullPath.split("/").last),
          ),
          Expanded(
              child: Row(
            children: [
              if (p.playerState == a.PlayerState.playing)
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    p.pausePlaying();
                  },
                ),
              if (p.playerState == a.PlayerState.paused)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    p.resumePlaying();
                  },
                ),
              const Icon(Icons.skip_next)
            ],
          ))
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: p.player.runtimeType == AudioPlayer
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.keyboard_arrow_down_sharp)),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration:
                                    const BoxDecoration(color: Colors.white),
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
                                  stream:
                                      (p.player as AudioPlayer).positionStream,
                                  builder: (c, AsyncSnapshot<Duration> ss) {
                                    return Text(ss.data.toString().substring(
                                        0, ss.data.toString().length - 7));
                                  }),
                              Expanded(
                                child: StreamBuilder(
                                  stream:
                                      (p.player as AudioPlayer).positionStream,
                                  builder: (c, AsyncSnapshot<Duration> ss) =>
                                      Slider(
                                    max: (p.player as AudioPlayer)
                                        .duration!
                                        .inMilliseconds
                                        .toDouble(),
                                    min: 0.0,
                                    onChanged: (value) => {
                                      (p.player as AudioPlayer).seek(
                                          Duration(milliseconds: value.toInt()))
                                    },
                                    value: ss.data!.inMilliseconds.toDouble(),
                                  ),
                                ),
                              ),
                              Text((p.player as AudioPlayer)
                                  .duration
                                  .toString()
                                  .substring(
                                      0,
                                      (p.player as AudioPlayer)
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
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.skip_previous)),
                              if (p.playerState == a.PlayerState.playing)
                                IconButton(
                                  icon: const Icon(Icons.pause),
                                  onPressed: () {
                                    p.pausePlaying();
                                  },
                                ),
                              if (p.playerState == a.PlayerState.paused)
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () {
                                    p.resumePlaying();
                                  },
                                ),
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.skip_next)),
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.repeat_one_outlined)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: VideoPlayer(p.player))
                  ],
                ),
        ),
      ),
    );
  }
}
