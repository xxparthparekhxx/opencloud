import 'package:flutter/material.dart';
import 'package:opencloud/pages/project_control/list_of_user_projects.dart';
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

  @override
  Widget build(BuildContext context) {
    if (Provider.of<OpenDrive>(context).user == null) {
      return Scaffold(
          body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            ElevatedButton(
              child: const Text('Login'),
              onPressed: () {
                Provider.of<OpenDrive>(context, listen: false).login(
                    email: _emailController.text,
                    password: _passwordController.text);
              },
            ),
          ],
        ),
      ));
    } else {
      return const ListOfProjects();
    }
  }
}
