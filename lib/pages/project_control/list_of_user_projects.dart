import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/pages/project_control/add_project.dart';
import 'package:opencloud/pages/project_control/widgets/list_files.dart';

class ListOfProjects extends StatelessWidget {
  const ListOfProjects({Key? key}) : super(key: key);
  static const String routeName = '/ListOfProjects';

  Future<void> _confirmDeleteProject(
      BuildContext context, int index, FirebaseApp projectApp) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Project'),
            content:
                const Text('Are you sure you want to delete this project?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      if (!context.mounted) return;
      await Provider.of<OpenDrive>(context, listen: false)
          .deleteProject(projectApp.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('List of Projects'),
        ),
        body: ListView.builder(
            itemCount: Provider.of<OpenDrive>(context).projects.length,
            itemBuilder: (context, index) {
              final projectApp =
                  Provider.of<OpenDrive>(context).projects[index];
              return ListTile(
                leading: const Icon(Icons.work_outlined),
                title: Text(projectApp.options.projectId),
                onTap: () {
                  Navigator.of(context).pushNamed(listOfProjectFilesRouteName,
                      arguments: ListOFProjectFilesData(projectApp, ""));
                },
                onLongPress: () =>
                    _confirmDeleteProject(context, index, projectApp),
              );
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).pushNamed(AddProject.routeName);
          },
          child: const Icon(Icons.add),
        ));
  }
}
