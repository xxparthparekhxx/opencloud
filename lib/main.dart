import 'package:flutter/material.dart';
import 'package:opencloud/pages/auth/login.dart';
import 'package:opencloud/pages/project_control/add_project.dart';
import 'package:opencloud/pages/project_control/list_of_files.dart';
import 'package:opencloud/pages/project_control/list_of_user_projects.dart';
import 'package:opencloud/pages/project_control/uploads.dart';
import 'package:opencloud/pages/settings/settings.dart';
import 'package:opencloud/pages/welcome/splash_screen.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/providers/player_provider.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => OpenDrive(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => PlayerProvider(),
        ),
      ],
      child: const App(),
    );
  }
}

class App extends StatelessWidget {
  const App({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.blue),
        darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            colorScheme: const ColorScheme.dark().copyWith(
              primary: Colors.blue,
              secondary: Colors.blue,
            ),
            scaffoldBackgroundColor: Colors.black87),
        themeMode: ThemeMode.system,
        title: 'Open Cloud',
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
            final args = settings.arguments as ListOFProjectFilesData;
            return MaterialPageRoute(
              builder: (context) {
                return ListOFProjectFiles(args);
              },
            );
          }
          return null;
        });
  }
}
