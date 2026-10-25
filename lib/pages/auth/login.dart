import 'package:flutter/material.dart';
import 'package:opencloud/pages/project_control/widgets/nav_area.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:provider/provider.dart';

class AuthDesider extends StatefulWidget {
  const AuthDesider({Key? key}) : super(key: key);
  static const String routeName = '/AuthDesider';

  @override
  State<AuthDesider> createState() => _AuthDesiderState();
}

class _AuthDesiderState extends State<AuthDesider> {
  Object? _loginError;

  @override
  void initState() {
    super.initState();
    // Trigger the login attempt post-frame (not during build) to avoid
    // setState-during-build and calling providers during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptLogin());
  }

  Future<void> _attemptLogin() async {
    if (!mounted) return;
    final openDrive = Provider.of<OpenDrive>(context, listen: false);
    try {
      await openDrive.login(
        email: "${openDrive.baseApp!.options.apiKey}@opencloud.org",
        password: openDrive.baseApp!.options.apiKey,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final openDrive = Provider.of<OpenDrive>(context);
    if (openDrive.user == null) {
      if (_loginError != null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Login failed", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text(_loginError.toString()),
              ],
            ),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      return const NavArea();
    }
  }
}
