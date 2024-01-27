import 'package:opencloud/utils/importer.dart';

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
      return const miniAudioPlayer();
    } else if (miniPlayer && p.player.runtimeType == VideoPlayerController) {
      return const miniVideoPlayer();
    } else if (p.player.runtimeType == AudioPlayer ||
        p.player.runtimeType == VideoPlayerController) {
      return SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: p.player.runtimeType == AudioPlayer
                ? AudioPlayerPage(setMiniPlayer: setMiniPlayer)
                : VideoPlayerPage(setMiniPlayer: setMiniPlayer),
          ),
        ),
      );
    }
    return p.player;
  }
}
