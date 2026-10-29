import 'package:firebase_auth/firebase_auth.dart';
import 'package:opencloud/services/auth_service.dart';

/// A message telling the user why an auth call failed.
String authErrorText(Object error) {
  if (error is FirebaseAuthException) {
    if (isBadCredential(error)) return "Incorrect email or password.";
    switch (error.code) {
      case "invalid-email":
        return "That email address is not valid.";
      case "email-already-in-use":
        return "Another account already uses this email address.";
      case "weak-password":
        return "Choose a stronger password (at least 6 characters).";
      case "too-many-requests":
        return "Too many attempts. Wait a moment and try again.";
      case "network-request-failed":
        return "Could not reach Firebase. Check your connection and try again.";
      case "operation-not-allowed":
        return "Email/password sign-in is turned off for this Firebase "
            "project. Enable it in the Firebase console under "
            "Authentication > Sign-in method.";
      case "user-disabled":
        return "This account has been disabled.";
    }
    return error.message ?? error.code;
  }
  return error.toString();
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? "";
  if (email.isEmpty) return "Enter your email address";
  if (!email.contains("@")) return "Enter a valid email address";
  return null;
}

/// Firebase rejects passwords shorter than 6 characters.
String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return "Choose a password";
  if (value.length < 6) return "Use at least 6 characters";
  return null;
}
