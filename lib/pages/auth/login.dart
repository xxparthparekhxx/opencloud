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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    _emailController.addListener(() {
      setState(() {});
    });
    _passwordController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  bool inited = false;

  Future<void> login(context) async {
    setState(() {
      inited = true;
    });
    await Provider.of<OpenDrive>(context, listen: false).login(
        email:
            "${Provider.of<OpenDrive>(context).Baseapp!.options.apiKey}@opencloud.org",
        password: Provider.of<OpenDrive>(context).Baseapp!.options.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    if (Provider.of<OpenDrive>(context).user == null) {
      if (!inited) {
        login(context);
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return const NavArea();
    }
  }
}
