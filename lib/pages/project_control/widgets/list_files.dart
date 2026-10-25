import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:opencloud/pages/player/player.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:opencloud/pages/project_control/uploads.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/pages/project_control/widgets/file_options.dart';
import 'package:opencloud/pages/project_control/widgets/folder_tile.dart';
import 'package:opencloud/pages/project_control/widgets/file_tile.dart';
import 'package:opencloud/pages/project_control/widgets/new_file_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/models/app_constants.dart';

/// Route name used to navigate to the project file list screen.
const String listOfProjectFilesRouteName = '/ListOFProjectFiles';

/// Data passed as route arguments to the project file list screen.
class ListOFProjectFilesData {
  final FirebaseApp app;
  final String path;
  ListOFProjectFilesData(this.app, this.path);
}

class ListFiles extends StatefulWidget {
  final String projectId;
  final ListResult listResult;
  final FirebaseApp app;
  final Future<void> Function() reload;
  final void Function(List<int>) addToParent;
  final String path;

  const ListFiles({
    Key? key,
    required this.projectId,
    required this.app,
    required this.reload,
    required this.addToParent,
    required this.listResult,
    required this.path,
  }) : super(key: key);

  @override
  State<ListFiles> createState() => _ListFilesState();
}

class _ListFilesState extends State<ListFiles> {
  bool multiSelecting = false;
  List<Reference> selected = [];
  MiniplayerController controller = MiniplayerController();

  bool isLoading = false;

  Future<void> uploadFile() async {
    FilePickerResult? re = await FilePicker.platform.pickFiles(
      allowCompression: false,
      allowMultiple: true,
    );
    if (re != null) {
      List<PlatformFile> files = re.files;
      if (!mounted) return;
      widget.addToParent(await Provider.of<OpenDrive>(context, listen: false)
          .uploadFileToProject(
              app: widget.app,
              uploadpath: widget.path,
              paths: files.map((e) => e.path!).toList()));
    }
  }

  void startMultiSelect(Reference ele) {
    if (!multiSelecting) {
      multiSelecting = true;
    }
    if (!selected.contains(ele)) {
      selected.add(ele);
    }
    setState(() {});
  }

  void select(bool selectedFlag, Reference ele) {
    if (selectedFlag) {
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

  Future<void> _deleteSelected() async {
    setState(() {
      isLoading = true;
    });

    Iterable<Future> deletes = selected.map((e) {
      final last = e.fullPath.split('/').last;
      final isFolder = last.split('.').length == 1;
      if (isFolder) {
        return Provider.of<OpenDrive>(context, listen: false)
            .deleteFolderRecursive(e);
      } else {
        return Provider.of<OpenDrive>(context, listen: false).deleteFile(e);
      }
    });

    for (final e in deletes) {
      await e;
    }
    setState(() {
      isLoading = false;
      multiSelecting = false;
      selected.clear();
    });
    await widget.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                  onPressed: _deleteSelected,
                ),
              if (Provider.of<OpenDrive>(context).uploadingTasks.isNotEmpty &&
                  !multiSelecting)
                IconButton(
                  icon: const Icon(Icons.cloud_upload_sharp),
                  onPressed: () {
                    Navigator.of(context).pushNamed(Uploads.routeName);
                  },
                ),
              IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return NewFileAlertDialog(widget: widget);
                        });
                  })
            ],
          ),
          body: Column(
            children: [
              if (isLoading) const LinearProgressIndicator(),
              Expanded(
                child: ListView(
                  children: [
                    //folders
                    for (var ele in widget.listResult.prefixes)
                      FolderTile(
                        ele: ele,
                        selected: selected.contains(ele),
                        onLongPress: () => startMultiSelect(ele),
                        onTap: multiSelecting
                            ? () => select(selected.contains(ele), ele)
                            : () {
                                Navigator.of(context).pushNamed(
                                    listOfProjectFilesRouteName,
                                    arguments: ListOFProjectFilesData(
                                        widget.app, ele.fullPath));
                              },
                      ),
                    //files
                    for (Reference ele in widget.listResult.items)
                      if (ele.fullPath.split("/").last ==
                          kFolderPlaceholderFileName)
                        const SizedBox.shrink()
                      else
                        FileTile(
                          ele: ele,
                          selected: selected.contains(ele),
                          onLongPress: () => startMultiSelect(ele),
                          onTap: multiSelecting
                              ? () => select(selected.contains(ele), ele)
                              : () {
                                  if (["mp3", "opus", "mp4", "jpg"].contains(ele
                                      .fullPath
                                      .split("/")
                                      .last
                                      .split(".")
                                      .last)) {
                                    Provider.of<PlayerProvider>(context,
                                            listen: false)
                                        .startPlaying(
                                            widget.listResult.items,
                                            widget.listResult.items
                                                .indexOf(ele));
                                  }
                                },
                          onOptionsPressed: () async {
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
                        ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: multiSelecting
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                            onPressed: uploadFile,
                            child: const Icon(Icons.upload_file))
                      ],
                    ),
                    if (Provider.of<PlayerProvider>(context).playerState !=
                        PlayerStates.notPlaying)
                      const SizedBox(
                        height: 55,
                      )
                  ],
                ),
        ),
        if (Provider.of<PlayerProvider>(context).playerState !=
            PlayerStates.notPlaying)
          Miniplayer(
            controller: controller,
            minHeight: 50,
            onDismissed:
                Provider.of<PlayerProvider>(context, listen: false).stopPlaying,
            maxHeight: MediaQuery.of(context).size.height,
            builder: (height, percentage) {
              return Player(
                miniPlayer: percentage > 0.2 ? false : true,
                setMiniPlayer: setmini,
              );
            },
          )
      ],
    );
  }

  void setmini(bool e) {
    controller.animateToHeight(state: e ? PanelState.MAX : PanelState.MIN);
  }
}
