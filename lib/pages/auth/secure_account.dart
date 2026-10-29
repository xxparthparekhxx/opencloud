import 'package:flutter/material.dart';
import 'package:opencloud/pages/auth/auth_form.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/services/auth_service.dart';
import 'package:provider/provider.dart';

/// The one-time "secure your account" step for installs from before real
/// accounts, which signed in with credentials derived from the Firebase API
/// key. The user picks their own email and password to replace them.
///
/// Shown in place of the app when a restored session is such an account,
/// and pushed from the sign-in screen when signed out.
class SecureAccountPage extends StatefulWidget {
  const SecureAccountPage({Key? key}) : super(key: key);

  @override
  State<SecureAccountPage> createState() => _SecureAccountPageState();
}

class _SecureAccountPageState extends State<SecureAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
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
    final navigator = Navigator.of(context);
    try {
      await openDrive.secureLegacyAccount(
        newEmail: _email.text.trim(),
        newPassword: _password.text,
      );
      // Pushed from the sign-in screen: go back, where the "check your
      // inbox" page is now shown.
      if (mounted && navigator.canPop()) navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = isBadCredential(e)
            ? "Could not sign in to the account from the earlier version. "
                "If you have already secured it, enter the password you "
                "chose then. If you never used an earlier version, go back "
                "and create an account instead."
            : authErrorText(e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openDrive = Provider.of<OpenDrive>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure your account"),
        actions: [
          if (openDrive.user != null)
            TextButton(
              onPressed: _busy ? null : () => openDrive.logout(),
              child: const Text("Log out"),
            ),
        ],
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
                      const Text(
                        "Earlier versions of Open Cloud signed in to your "
                        "Firebase project with an email and password derived "
                        "from its API key. API keys are not secret, so anyone "
                        "with your project's config could sign in as you.",
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Choose your own email address and password to "
                        "replace them. Your projects and files stay where "
                        "they are.",
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key("secure.email"),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: "Your email"),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key("secure.password"),
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration:
                            const InputDecoration(labelText: "New password"),
                        validator: validateNewPassword,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key("secure.confirmPassword"),
                        controller: _confirmPassword,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: "Confirm new password"),
                        validator: (value) => value != _password.text
                            ? "Passwords do not match"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Firebase will email a verification link to this "
                        "address. Your sign-in email changes once you click "
                        "the link. Your new password works right away.",
                        style: theme.textTheme.bodySmall,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          key: const Key("secure.error"),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key("secure.submit"),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Secure my account"),
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

/// Shown right after the account was secured: the password is replaced, and
/// the email change waits for the verification link to be clicked.
class EmailChangeSentPage extends StatelessWidget {
  const EmailChangeSentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final openDrive = Provider.of<OpenDrive>(context);
    final email = openDrive.pendingEmail ?? "your new address";
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check your inbox"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    "Your account is now protected by your new password.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We sent a verification link to $email. Your sign-in "
                    "email changes to this address when you click the link; "
                    "until then the account keeps its old address.",
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "If you sign out before clicking it, choose \"Secure "
                    "your existing account\" on the sign-in screen and enter "
                    "your new password to get a new link.",
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key("emailSent.continue"),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await openDrive.acknowledgeEmailChangeSent();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    child: const Text("Continue"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
