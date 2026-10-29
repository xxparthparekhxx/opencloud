import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencloud/providers/openprovider.dart';

class AddProject extends StatefulWidget {
  final bool isInitial;
  const AddProject({Key? key, this.isInitial = false}) : super(key: key);
  static const String routeName = '/AddProject';

  @override
  State<AddProject> createState() => _AddProjectState();
}

class _AddProjectState extends State<AddProject> {
  @override
  Widget build(BuildContext context) {
    Size ss = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(),
          if (widget.isInitial) const Text("Welcome Add your First Project"),
          if (!widget.isInitial) const Text("Add your Project"),
          const SizedBox(height: 20),
          Material(
            child: InkWell(
              onTap: () async {
                final PlatformFile? picked = await FilePicker.pickFile(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                if (picked != null) {
                  try {
                    final path = picked.path;
                    if (path == null) {
                      throw Exception("Could not read the selected file");
                    }
                    String file = await File(path).readAsString();
                    if (!context.mounted) return;
                    await Provider.of<OpenDrive>(context, listen: false)
                        .createProjectFromJson(
                            data: file, isInitial: widget.isInitial);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                      ),
                    );
                  }
                }
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
