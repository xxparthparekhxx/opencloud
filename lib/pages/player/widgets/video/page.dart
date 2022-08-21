import 'package:opencloud/utils/importer.dart';

class VideoPlayerPage extends StatefulWidget {
  final Function setMiniPlayer;
  const VideoPlayerPage({
    Key? key,
    required this.setMiniPlayer,
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  @override
  Widget build(BuildContext context) {
    PlayerProvider p = Provider.of<PlayerProvider>(context);
    p.addListener(() {
      if (mounted) setState(() {});
    });
    if (p.player == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    VideoPlayerController player = (p.player as VideoPlayerController);
    player.addListener(() {
      if (mounted) setState(() {});
    });
    return Column(
      children: [
        SizedBox(
            height: 250,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black),
                        child: AspectRatio(
                            aspectRatio: p.player.value.aspectRatio,
                            child: VideoPlayer(p.player)),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () {
                              widget.setMiniPlayer(true);
                            },
                            icon: const Icon(Icons.keyboard_arrow_down_sharp)),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert)),
                      ],
                    )
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: () => p.skipToPrevious(),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 50,
                            )),
                        IconButton(
                            constraints: const BoxConstraints(minWidth: 200),
                            onPressed: () {
                              if (p.playerState == PlayerStates.paused) {
                                p.resumePlaying();
                              } else {
                                p.pausePlaying();
                              }
                            },
                            icon: Icon(
                                p.playerState == PlayerStates.paused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                size: 50.0)),
                        IconButton(
                            onPressed: () => p.skipToNext(),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 50,
                            ))
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Slider(
                      min: 0.0,
                      max: player.value.duration.inSeconds.toDouble(),
                      value: player.value.position.inSeconds.toDouble(),
                      onChanged: (value) {
                        player.seekTo(Duration(seconds: value.toInt()));
                      },
                    )
                  ],
                )
              ],
            ))
      ],
    );
  }
}
