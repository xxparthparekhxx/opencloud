import 'package:flutter/material.dart';

/// Shared collapsible header row used by both audio and video player pages.
class HeaderRow extends StatelessWidget {
  final VoidCallback onMinimize;
  const HeaderRow({Key? key, required this.onMinimize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onMinimize,
          icon: const Icon(Icons.keyboard_arrow_down_sharp),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }
}
