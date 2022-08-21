import 'package:opencloud/utils/importer.dart';

class miniAudioPlayer extends StatelessWidget {
  const miniAudioPlayer({
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
                  child: const Icon(Icons.skip_next),
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
