import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:opencloud/pages/auth/login.dart';
import 'package:opencloud/pages/project_control/add_project.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool loading = true;
  @override
  void initState() {
    Timer(Duration.zero, () async {
      await Provider.of<OpenDrive>(context, listen: false).init();
      setState(() {
        loading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseApp? app = Provider.of<OpenDrive>(context).Baseapp;
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (app == null) {
      return const AddProject(isInital: true);
    } else {
      return const AuthDesider();
    }
  }
}
