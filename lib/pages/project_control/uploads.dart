import 'package:flutter/material.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:provider/provider.dart';

class Uploads extends StatelessWidget {
  const Uploads({Key? key}) : super(key: key);
  static const String routeName = '/Uploads';

  @override
  Widget build(BuildContext context) {
    var Uploads = Provider.of<OpenDrive>(context).uploadingTasks;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploads"),
      ),
      body: ListView.builder(
        itemCount: Uploads.length,
        itemBuilder: (context, index) {
          double progress = (Uploads[index].task.snapshot.bytesTransferred /
              Uploads[index].task.snapshot.totalBytes);
          return ListTile(
            title: Text(Uploads[index].task.snapshot.ref.name),
            isThreeLine: true,
            subtitle: Column(
              children: [
                Text(Uploads[index].toProject),
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
