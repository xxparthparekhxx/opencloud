import 'package:flutter/material.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:provider/provider.dart';

class Player extends StatelessWidget {
  final bool miniPlayer;
  const Player({Key? key, required this.miniPlayer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<OpenDrive>(context);
    if (miniPlayer) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(p.playerQueue[p.playerIndex].fullPath.split("/").last),
          ),
          Expanded(
              child: Row(
            children: [
              if (p.playerState == PlayerState.playing)
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    p.pausePlaying();
                  },
                ),
              if (p.playerState == PlayerState.paused)
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
    return Container(
      child: Column(),
    );
  }
}
