import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/pages/project_control/widgets/list_files.dart';

class NewFileAlertDialog extends StatefulWidget {
  const NewFileAlertDialog({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final ListFiles widget;

  @override
  State<NewFileAlertDialog> createState() => _NewFileAlertDialogState();
}

class _NewFileAlertDialogState extends State<NewFileAlertDialog> {
  String folderName = "";
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Folder"),
      content: TextField(
        onChanged: (value) {
          folderName = value;
        },
        decoration: const InputDecoration(
            labelText: "Folder Name", border: OutlineInputBorder()),
      ),
      actions: [
        ElevatedButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text("Create"),
          onPressed: () async {
            if (folderName.isNotEmpty) {
              await Provider.of<OpenDrive>(context, listen: false).createFolder(
                  path: widget.widget.path,
                  name: folderName,
                  proj: widget.widget.app);
            }
            await widget.widget.reload();
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
