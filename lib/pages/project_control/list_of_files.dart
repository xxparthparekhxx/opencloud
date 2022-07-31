import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:opencloud/pages/project_control/uploads.dart';
import 'package:opencloud/pages/project_control/widgets/file_options.dart';
import 'package:opencloud/pages/project_control/widgets/file_type.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:provider/provider.dart';

class ListOFProjectFiles extends StatefulWidget {
  final FirebaseApp app;
  const ListOFProjectFiles(this.app, {Key? key}) : super(key: key);
  static const String routeName = '/ListOFProjectFiles';

  @override
  State<ListOFProjectFiles> createState() => _ListOFProjectFilesState();
}

class _ListOFProjectFilesState extends State<ListOFProjectFiles> {
  ListResult? _listResult;
  List<int> waitingForUpload = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration.zero, () async {
      _listResult = await Provider.of<OpenDrive>(context, listen: false)
          .listAllTheFilesOfAProject(widget.app);
      setState(() {});
    });
  }

  Future<void> reload() async {
    _listResult = await Provider.of<OpenDrive>(context, listen: false)
        .listAllTheFilesOfAProject(widget.app);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var tasks = Provider.of<OpenDrive>(context).uploadingTasks;
    //check if all the ids in the waitingForUpload list are in the tasks list
    //if not then remove them from the waitingForUpload list
    for (int i = 0; i < waitingForUpload.length; i++) {
      if (!tasks.any((element) => element.id == waitingForUpload[i])) {
        waitingForUpload.removeAt(i);
        () async {
          await reload();
        }();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.app.options.projectId),
        actions: [
          if (Provider.of<OpenDrive>(context).uploadingTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_upload_sharp),
              onPressed: () {
                Navigator.of(context).pushNamed(Uploads.routeName);
              },
            )
        ],
      ),
      body: Column(
        children: [
          if (_listResult != null)
            for (var ele in _listResult!.items)
              ListTile(
                leading: FileTypeIcon(extension: ele.name.split(".").last),
                title: Text(ele.name),
                trailing: IconButton(
                  onPressed: () async {
                    showModalBottomSheet(
                        context: context,
                        builder: (c) {
                          return FileOptions(
                            ele: ele,
                            app: widget.app,
                            reload: reload,
                          );
                        });
                  },
                  icon: const Icon(Icons.more_vert),
                ),
                // onTap: () async {
                //   await Navigator.of(context).pushNamed(
                //       ListOFProjectFiles.routeName,
                //       arguments: ele);
                // },
              )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.upload_file),
        onPressed: () async {
          FilePickerResult? re = await FilePicker.platform.pickFiles(
            allowCompression: false,
            allowMultiple: false,
          );
          if (re != null) {
            PlatformFile file = re.files.first;
            waitingForUpload.add(
                await Provider.of<OpenDrive>(context, listen: false)
                    .uploadFileToProject(app: widget.app, path: file.path!));
          }
        },
      ),
    );
  }
}
