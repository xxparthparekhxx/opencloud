import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FolderTile extends StatelessWidget {
  final Reference ele;
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const FolderTile({
    Key? key,
    required this.ele,
    required this.selected,
    required this.onLongPress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool sel = selected;
    return ListTile(
      leading: sel
          ? const Icon(
              Icons.verified,
              color: Colors.blue,
            )
          : const Icon(Icons.folder_open_sharp),
      title: Text(ele.name),
      selected: sel,
      selectedColor: Colors.blue,
      onLongPress: onLongPress,
      onTap: onTap,
    );
  }
}
