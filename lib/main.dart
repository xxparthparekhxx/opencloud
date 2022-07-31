import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:opencloud/pages/auth/login.dart';
import 'package:opencloud/pages/project_control/add_project.dart';
import 'package:opencloud/pages/project_control/list_of_files.dart';
import 'package:opencloud/pages/project_control/list_of_user_projects.dart';
import 'package:opencloud/pages/project_control/uploads.dart';
import 'package:opencloud/pages/settings/settings.dart';
import 'package:opencloud/pages/welcome/splash_screen.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        lazy: false,
        create: (context) => OpenDrive(),
        child: MaterialApp(
            title: 'Material App',
            home: const SplashScreen(),
            routes: {
              AuthDesider.routeName: (context) => const AuthDesider(),
              AddProject.routeName: (context) => const AddProject(),
              ListOfProjects.routeName: (context) => const ListOfProjects(),
              Settings.routeName: (context) => const Settings(),
              Uploads.routeName: (context) => const Uploads(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == ListOFProjectFiles.routeName) {
                final args = settings.arguments as FirebaseApp;
                return MaterialPageRoute(
                  builder: (context) {
                    return ListOFProjectFiles(args);
                  },
                );
              }
              return null;
            }));
  }
}
