import 'package:flutter/material.dart';
import 'package:opencloud/providers/player_provider.dart';

/// Shared previous/next skip buttons.
class SkipControls extends StatelessWidget {
  final PlayerProvider provider;
  const SkipControls({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: provider.skipToPrevious,
          icon: const Icon(Icons.skip_previous),
        ),
        IconButton(
          onPressed: provider.skipToNext,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}
