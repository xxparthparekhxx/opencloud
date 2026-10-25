import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:opencloud/pages/project_control/widgets/file_type.dart';

class FileTile extends StatelessWidget {
  final Reference ele;
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onOptionsPressed;

  const FileTile({
    Key? key,
    required this.ele,
    required this.selected,
    required this.onLongPress,
    required this.onTap,
    required this.onOptionsPressed,
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
          : FileTypeIcon(extension: ele.name.split(".").last),
      title: Text(ele.name),
      selected: sel,
      selectedColor: Colors.blue,
      onLongPress: onLongPress,
      onTap: onTap,
      trailing: IconButton(
        onPressed: onOptionsPressed,
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}
