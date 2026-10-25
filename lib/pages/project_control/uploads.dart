import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/openprovider.dart';

class Uploads extends StatelessWidget {
  const Uploads({Key? key}) : super(key: key);
  static const String routeName = '/Uploads';

  @override
  Widget build(BuildContext context) {
    var uploads = Provider.of<OpenDrive>(context).uploadingTasks;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploads"),
      ),
      body: ListView.builder(
        itemCount: uploads.length,
        itemBuilder: (context, index) {
          final task = uploads[index].task.snapshot;
          final totalBytes = task.totalBytes;
          final progress =
              totalBytes <= 0 ? null : task.bytesTransferred / totalBytes;
          return ListTile(
            title: Text(task.ref.name),
            isThreeLine: true,
            subtitle: Column(
              children: [
                Text(uploads[index].toProject),
                LinearProgressIndicator(
                  // set the value of the progress indicator in percentage
                  value: progress != 0 ? progress : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
