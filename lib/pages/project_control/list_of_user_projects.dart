import 'package:opencloud/utils/importer.dart';

class ListOfProjects extends StatelessWidget {
  const ListOfProjects({Key? key}) : super(key: key);
  static const String routeName = '/ListOfProjects';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('List of Projects'),
        ),
        body: ListView.builder(
            itemCount: Provider.of<OpenDrive>(context).Projects.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.work_outlined),
                title: Text(Provider.of<OpenDrive>(context)
                    .Projects[index]
                    .options
                    .projectId),
                onTap: () {
                  Navigator.of(context).pushNamed(ListOFProjectFiles.routeName,
                      arguments: ListOFProjectFilesData(
                          Provider.of<OpenDrive>(context, listen: false)
                              .Projects[index],
                          ""));
                },
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
