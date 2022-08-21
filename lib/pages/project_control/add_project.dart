import 'package:opencloud/utils/importer.dart';

class AddProject extends StatefulWidget {
  final bool isInital;
  const AddProject({Key? key, this.isInital = false}) : super(key: key);
  static const String routeName = '/AddProject';

  @override
  State<AddProject> createState() => _AddProjectState();
}

class _AddProjectState extends State<AddProject> {
  @override
  Widget build(BuildContext context) {
    print(widget.isInital);
    Size ss = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(),
          if (widget.isInital) const Text("Welcome Add your First Project"),
          if (!widget.isInital) const Text("Add your Project"),
          const SizedBox(height: 20),
          Material(
            child: InkWell(
              onTap: () async {
                FilePickerResult? res = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                if (res != null) {
                  try {
                    print(res.files.first.path);
                    String file =
                        await File(res.files.first.path!).readAsString();
                    await Provider.of<OpenDrive>(context, listen: false)
                        .createProjectFromJson(
                            data: file, isInitial: widget.isInital);
                    Navigator.of(context).pop();
                  } catch (e) {
                    print(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                      ),
                    );
                  }
                }
                // await Provider.of<OpenDrive>(context, listen: false)
                //     .createProjectFromJson();
              },
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  width: ss.width * 0.8,
                  height: ss.height * 0.1,
                  child: const Text(
                    "Click here to Upload the config File",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  )),
            ),
          )
        ],
      ),
    );
  }
}
