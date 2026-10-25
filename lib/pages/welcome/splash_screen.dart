import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:opencloud/pages/project_control/add_project.dart';
import 'package:opencloud/pages/auth/login.dart';
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
    super.initState();
    Timer(Duration.zero, _initialize);
  }

  Future<void> _initialize() async {
    await Provider.of<OpenDrive>(context, listen: false).init();
    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final openDrive = Provider.of<OpenDrive>(context);
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (openDrive.initError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Initialization failed",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(openDrive.initError.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });
                  await _initialize();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    FirebaseApp? app = openDrive.baseApp;
    if (app == null) {
      return const AddProject(isInitial: true);
    } else {
      return const AuthDesider();
    }
  }
}
