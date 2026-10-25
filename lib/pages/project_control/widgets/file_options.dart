import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/openprovider.dart';

class FileOptions extends StatelessWidget {
  const FileOptions({
    Key? key,
    required this.reload,
    required this.app,
    required this.ele,
  }) : super(key: key);

  final FirebaseApp app;
  final Reference ele;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Download'),
            onTap: () async {
              await Provider.of<OpenDrive>(context, listen: false)
                  .downloadFile(ref: ele);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('Delete'),
            onTap: () async {
              await Provider.of<OpenDrive>(context, listen: false)
                  .deleteFile(ele);
              await reload();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text("Copy Link"),
            onTap: () async {
              Clipboard.setData(
                  ClipboardData(text: await ele.getDownloadURL()));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Link Copied"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
