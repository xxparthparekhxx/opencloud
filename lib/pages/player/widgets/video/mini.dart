import 'package:opencloud/utils/importer.dart';

class miniVideoPlayer extends StatefulWidget {
  const miniVideoPlayer({
    Key? key,
  }) : super(key: key);

  @override
  State<miniVideoPlayer> createState() => _miniVideoPlayerState();
}

class _miniVideoPlayerState extends State<miniVideoPlayer> {
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
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(color: Colors.black),
              child: VideoPlayer(p.player),
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
                if (p.playerState == PlayerStates.playing)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: () {
                      p.pausePlaying();
                    },
                  ),
                if (p.playerState == PlayerStates.paused)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      p.resumePlaying();
                    },
                  ),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.skip_next),
                  ),
                  onTap: () {
                    p.skipToNext();
                  },
                )
              ],
            ))
      ],
    );
  }
}
