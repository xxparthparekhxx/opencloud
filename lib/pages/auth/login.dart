import 'package:flutter/material.dart';
import 'package:opencloud/pages/auth/auth_form.dart';
import 'package:opencloud/pages/auth/secure_account.dart';
import 'package:opencloud/pages/project_control/widgets/nav_area.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/services/auth_service.dart';
import 'package:provider/provider.dart';

/// Shows the screen that matches where the account stands: sign-in, the
/// one-time "secure your account" step for legacy accounts, or the app.
class AuthDesider extends StatelessWidget {
  const AuthDesider({Key? key}) : super(key: key);
  static const String routeName = '/AuthDesider';

  @override
  Widget build(BuildContext context) {
    final openDrive = Provider.of<OpenDrive>(context);
    switch (openDrive.accountStatus) {
      case AccountStatus.signedOut:
        return const SignInPage();
      case AccountStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AccountStatus.needsSecuring:
        return const SecureAccountPage();
      case AccountStatus.emailChangeSent:
        return const EmailChangeSentPage();
      case AccountStatus.awaitingEmailChange:
      case AccountStatus.ready:
        return const NavArea();
    }
  }
}

/// Sign in to, or create, an account with the user's own email/password.
class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _creatingAccount = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final openDrive = Provider.of<OpenDrive>(context, listen: false);
    final email = _email.text.trim();
    try {
      if (_creatingAccount) {
        await openDrive.signUp(email: email, password: _password.text);
      } else {
        await openDrive.signIn(email: email, password: _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _creatingAccount = !_creatingAccount;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_creatingAccount ? "Create account" : "Sign in"),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _creatingAccount
                            ? "Create your Open Cloud account with your own "
                                "email and password."
                            : "Sign in with your Open Cloud email and "
                                "password.",
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key("signIn.email"),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key("signIn.password"),
                        controller: _password,
                        obscureText: true,
                        autofillHints: [
                          _creatingAccount
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration:
                            const InputDecoration(labelText: "Password"),
                        validator: _creatingAccount
                            ? validateNewPassword
                            : (value) => (value == null || value.isEmpty)
                                ? "Enter your password"
                                : null,
                      ),
                      if (_creatingAccount) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key("signIn.confirmPassword"),
                          controller: _confirmPassword,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: "Confirm password"),
                          validator: (value) => value != _password.text
                              ? "Passwords do not match"
                              : null,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          key: const Key("signIn.error"),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key("signIn.submit"),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_creatingAccount
                                ? "Create account"
                                : "Sign in"),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key("signIn.toggleMode"),
                        onPressed: _busy ? null : _toggleMode,
                        child: Text(_creatingAccount
                            ? "Already have an account? Sign in"
                            : "New here? Create an account"),
                      ),
                      const Divider(height: 32),
                      TextButton(
                        key: const Key("signIn.secureExisting"),
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SecureAccountPage(),
                                  ),
                                ),
                        child: const Text(
                          "Used Open Cloud before it had accounts? "
                          "Secure your existing account",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
