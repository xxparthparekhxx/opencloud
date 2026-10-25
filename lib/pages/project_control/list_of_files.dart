import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/pages/project_control/uploads.dart';
import 'package:opencloud/pages/project_control/widgets/bottomnavigation.dart';
import 'package:opencloud/pages/project_control/widgets/list_files.dart';

export 'package:opencloud/pages/project_control/widgets/list_files.dart'
    show ListOFProjectFilesData, listOfProjectFilesRouteName;

class ListOFProjectFiles extends StatefulWidget {
  final ListOFProjectFilesData data;
  const ListOFProjectFiles(this.data, {Key? key}) : super(key: key);
  static const String routeName = listOfProjectFilesRouteName;

  @override
  State<ListOFProjectFiles> createState() => _ListOFProjectFilesState();
}

class _ListOFProjectFilesState extends State<ListOFProjectFiles> {
  ListResult? _listResult;
  List<int> waitingForUpload = [];

  @override
  void initState() {
    super.initState();
    Timer(Duration.zero, () async {
      await reload();
      setState(() {});
    });
  }

  Future<void> reload() async {
    _listResult = await Provider.of<OpenDrive>(context, listen: false)
        .listAllTheFilesOfAProject(widget.data.app, widget.data.path);
    setState(() {});
  }

  void addToParent(List<int> a) => waitingForUpload.addAll(a);

  void updateindex(e) {
    setState(() {
      selectedIndex = e;
    });
  }

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var tasks = Provider.of<OpenDrive>(context).uploadingTasks;
    //check if all the ids in the waitingForUpload list are in the tasks list
    //if not then remove them from the waitingForUpload list
    final originalLength = waitingForUpload.length;
    waitingForUpload
        .removeWhere((id) => !tasks.any((element) => element.id == id));
    if (waitingForUpload.length != originalLength) {
      () async {
        await reload();
      }();
    }
    return Scaffold(
      body: _listResult != null
          ? selectedIndex == 0
              ? ListFiles(
                  projectId: widget.data.app.options.projectId,
                  app: widget.data.app,
                  reload: reload,
                  addToParent: addToParent,
                  listResult: _listResult!,
                  path: widget.data.path,
                )
              : const Uploads()
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar:
          BottomNav(currentIndex: selectedIndex, onTap: updateindex),
    );
  }
}
