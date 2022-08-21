import 'package:opencloud/utils/importer.dart';

class FileOptions extends StatelessWidget {
  const FileOptions({
    Key? key,
    required this.reload,
    required this.app,
    required this.ele,
  }) : super(key: key);

  final FirebaseApp app;
  final Reference ele;
  final Function reload;

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
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('Delete'),
            onTap: () async {
              await ele.delete();
              await reload();
              Navigator.of(context).pop();
            },
          ),
          // ListTile(
          //   title: const Text("Rename"),
          //   onTap: () async {
          //     // await Provider.of<OpenDrive>(context, listen: false)
          //     //     .renameFile(app, ele);
          //     // Navigator.of(context).pop();
          //   },
          // ),
          // ListTile(
          //   title: const Text("Move"),
          //   onTap: () async {},
          // ),
          // ListTile(
          //   title: const Text("Copy"),
          //   onTap: () async {},
          // ),
          ListTile(
            title: const Text("Copy Link"),
            onTap: () async {
              Clipboard.setData(
                  ClipboardData(text: await ele.getDownloadURL()));
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
