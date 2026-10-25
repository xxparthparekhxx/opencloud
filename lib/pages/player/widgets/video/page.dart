import 'package:flutter/material.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:opencloud/pages/player/widgets/common/header_row.dart';
import 'package:opencloud/pages/player/widgets/common/play_pause_button.dart';

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
    final active = p.player;
    if (active == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return switch (active) {
      VideoActive(:final controller) => OverflowBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: Container(
                            decoration:
                                const BoxDecoration(color: Colors.black),
                            child: VideoPlayer(controller),
                          )),
                      Column(
                        children: [
                          HeaderRow(
                              onMinimize: () => widget.setMiniPlayer(true)),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PlayPauseButton(
                                provider: p,
                                iconSize: 50.0,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Slider(
                            min: 0.0,
                            max: controller.value.duration.inSeconds.toDouble(),
                            value:
                                controller.value.position.inSeconds.toDouble(),
                            onChanged: (value) {
                              controller
                                  .seekTo(Duration(seconds: value.toInt()));
                            },
                          )
                        ],
                      )
                    ],
                  )),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
