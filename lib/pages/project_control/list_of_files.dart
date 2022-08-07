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

class ListOFProjectFilesData {
  final FirebaseApp app;
  final String path;
  ListOFProjectFilesData(this.app, this.path);
}

class ListOFProjectFiles extends StatefulWidget {
  final ListOFProjectFilesData data;
  const ListOFProjectFiles(this.data, {Key? key}) : super(key: key);
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
      await reload();
      setState(() {});
    });
  }

  Future<void> reload() async {
    _listResult = await Provider.of<OpenDrive>(context, listen: false)
        .listAllTheFilesOfAProject(widget.data.app, widget.data.path);
    setState(() {});
  }

  addToParent(List<int> a) => waitingForUpload.addAll(a);

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
    return _listResult != null
        ? ListFiles(
            projectId: widget.data.app.options.projectId,
            app: widget.data.app,
            reload: reload,
            addToParent: addToParent,
            listResult: _listResult!,
            path: widget.data.path,
          )
        : const Center(child: CircularProgressIndicator());
  }
}

class ListFiles extends StatefulWidget {
  final String projectId;
  final ListResult listResult;
  final FirebaseApp app;
  final Function reload;
  final Function addToParent;
  final String path;

  const ListFiles(
      {Key? key,
      required this.projectId,
      required this.app,
      required this.reload,
      required this.addToParent,
      required this.listResult,
      required this.path})
      : super(key: key);

  @override
  State<ListFiles> createState() => _ListFilesState();
}

class _ListFilesState extends State<ListFiles> {
  bool multiSelecting = false;
  List<Reference> selected = [];

  startMultiSelect(ele) {
    //if not multiSelecting then start multiSelecting
    if (!multiSelecting) {
      multiSelecting = true;
    }
    //add the prefix to the selected list
    if (!selected.contains(ele)) {
      selected.add(ele);
    }
    setState(() {});
  }

  select(bool Selected, Reference ele) {
    if (Selected) {
      selected.remove(ele);
      if (selected.isEmpty) {
        multiSelecting = false;
      }
    } else {
      if (multiSelecting) {
        selected.add(ele);
      }
    }
    setState(() {});
  }

  //write a recursive function to delete all the files in the selected
  deleteFolder(Reference ref) async {
    print(ref.fullPath);
    var list = await ref.listAll();
    print(list.prefixes);
    //list.items are the files in the current folder
    //list.prefix in the are folders inside the current folder
    for (var i = 0; i < list.items.length; i++) {
      await list.items[i].delete();
    }
    for (var i = 0; i < list.prefixes.length; i++) {
      await deleteFolder(list.prefixes[i]);
    }
  }

  bool Loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: multiSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    multiSelecting = false;
                    selected.clear();
                  });
                },
              )
            : null,
        title: Text(multiSelecting
            ? "${selected.length} ${selected.length == 1 ? 'item' : 'items'} "
            : widget.projectId),
        actions: [
          if (multiSelecting)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                setState(() {
                  Loading = true;
                });

                Iterable<Future> deletes = selected.map((e) {
                  if (selected[0].fullPath.split('/').last.split(".").length ==
                      1) {
                    return deleteFolder(e);
                  } else {
                    return e.delete();
                  }
                });

                for (var e in deletes) {
                  await e;
                }
                setState(() {
                  Loading = false;
                });
                setState(() {
                  Loading = false;
                  multiSelecting = false;
                  selected.clear();
                });
                await widget.reload();
              },
            ),
          if (Provider.of<OpenDrive>(context).uploadingTasks.isNotEmpty &&
              !multiSelecting)
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
          if (Loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              children: [
                for (var ele in widget.listResult.prefixes)
                  (ele) {
                    bool sel = selected.contains(ele);
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
                      onLongPress: () => startMultiSelect(ele),
                      onTap: multiSelecting
                          ? () => select(sel, ele)
                          : () {
                              Navigator.of(context).pushNamed(
                                  ListOFProjectFiles.routeName,
                                  arguments: ListOFProjectFilesData(
                                      widget.app, ele.fullPath));
                            },
                    );
                  }(ele),
                for (var ele in widget.listResult.items)
                  (ele) {
                    bool sel = selected.contains(ele);

                    return ListTile(
                      leading: sel
                          ? const Icon(
                              Icons.verified,
                              color: Colors.blue,
                            )
                          : FileTypeIcon(extension: ele.name.split(".").last),
                      title: Text(ele.name),
                      onTap: () => select(sel, ele),
                      selected: sel,
                      selectedColor: Colors.blue,
                      onLongPress: () => startMultiSelect(ele),
                      trailing: IconButton(
                        onPressed: () async {
                          showModalBottomSheet(
                              context: context,
                              builder: (c) {
                                return FileOptions(
                                  ele: ele,
                                  app: widget.app,
                                  reload: widget.reload,
                                );
                              });
                        },
                        icon: const Icon(Icons.more_vert),
                      ),
                    );
                  }(ele)
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: multiSelecting
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                    child: const Icon(Icons.create_new_folder_outlined),
                    onPressed: () {
                      //create a alert dialog to ask the user if they want to create a folder

                      showDialog(
                          context: context,
                          builder: (context) {
                            return NewFileAlertDialog(widget: widget);
                          });
                    }),
                FloatingActionButton(
                  child: const Icon(Icons.upload_file),
                  onPressed: () async {
                    FilePickerResult? re = await FilePicker.platform.pickFiles(
                      allowCompression: false,
                      allowMultiple: true,
                    );
                    if (re != null) {
                      List<PlatformFile> files = re.files;
                      widget.addToParent(
                          await Provider.of<OpenDrive>(context, listen: false)
                              .uploadFileToProject(
                                  app: widget.app,
                                  uploadpath: widget.path,
                                  paths: files.map((e) => e.path!).toList()));
                    }
                  },
                ),
              ],
            ),
    );
  }
}

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
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
