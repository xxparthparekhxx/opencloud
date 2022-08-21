import 'package:opencloud/utils/importer.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: () {
                  setMiniPlayer(true);
                },
                icon: const Icon(Icons.keyboard_arrow_down_sharp)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
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
                      stream: (p.player as AudioPlayer).positionStream,
                      builder: (c, AsyncSnapshot<Duration> ss) {
                        return Text(ss.data
                            .toString()
                            .substring(0, ss.data.toString().length - 7));
                      }),
                  Expanded(
                    child: StreamBuilder(
                        stream: (p.player as AudioPlayer).positionStream,
                        builder: (c, AsyncSnapshot<Duration> ss) {
                          return Slider(
                            max: (p.player as AudioPlayer)
                                .duration!
                                .inMilliseconds
                                .roundToDouble(),
                            min: 0.0,
                            onChanged: (value) => {
                              (p.player as AudioPlayer)
                                  .seek(Duration(milliseconds: value.round()))
                            },
                            value: ss.data!.inMilliseconds.floorToDouble() <
                                    (p.player as AudioPlayer)
                                        .duration!
                                        .inMilliseconds
                                        .roundToDouble()
                                ? ss.data!.inMilliseconds.floorToDouble()
                                : (p.player as AudioPlayer)
                                    .duration!
                                    .inMilliseconds
                                    .roundToDouble(),
                          );
                        }),
                  ),
                  Text((p.player as AudioPlayer).duration.toString().substring(
                      0,
                      (p.player as AudioPlayer).duration.toString().length -
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
                      onPressed: () {}, icon: const Icon(Icons.skip_previous)),
                  if (p.playerState == PlayerStates.playing)
                    IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: () {
                        p.pausePlaying();
                      },
                    ),
                  if (p.playerState == PlayerStates.paused ||
                      p.playerState == PlayerStates.stopped)
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        p.resumePlaying();
                      },
                    ),
                  IconButton(
                      onPressed: () {
                        p.skipToNext();
                      },
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
    );
  }
}
