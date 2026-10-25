import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:opencloud/models/app_constants.dart';

/// Parses a Firebase project config JSON string into [FirebaseOptions].
///
/// Validates every field it reads and throws a descriptive
/// [FormatException] when the config is missing or malformed, instead of
/// failing with an opaque index/null error.
FirebaseOptions fbOpsFromJson(String json) {
  final Map<String, dynamic> data = jsonDecode(json) as Map<String, dynamic>;

  final client = data["client"];
  if (client == null || client is! List || client.isEmpty) {
    throw const FormatException(
        "Firebase config is missing a non-empty 'client' array.");
  }
  final client0 = client[0] as Map<String, dynamic>;

  final apiKey = client0["api_key"];
  if (apiKey == null || apiKey is! List || apiKey.isEmpty) {
    throw const FormatException(
        "Firebase config is missing a non-empty 'client[0].api_key' array.");
  }
  final apiKey0 = apiKey[0] as Map<String, dynamic>;
  final currentKey = apiKey0['current_key'];
  if (currentKey == null || currentKey is! String) {
    throw const FormatException(
        "Firebase config is missing 'client[0].api_key[0].current_key' (String).");
  }

  final clientInfo = client0['client_info'];
  if (clientInfo == null || clientInfo is! Map) {
    throw const FormatException(
        "Firebase config is missing 'client[0].client_info' (object).");
  }
  final mobilesdkAppId = clientInfo['mobilesdk_app_id'];
  if (mobilesdkAppId == null || mobilesdkAppId is! String) {
    throw const FormatException(
        "Firebase config is missing 'client[0].client_info.mobilesdk_app_id' (String).");
  }

  final projectInfo = data['project_info'];
  if (projectInfo == null || projectInfo is! Map) {
    throw const FormatException(
        "Firebase config is missing 'project_info' (object).");
  }
  final projectId = projectInfo['project_id'];
  if (projectId == null || projectId is! String) {
    throw const FormatException(
        "Firebase config is missing 'project_info.project_id' (String).");
  }
  final storageBucket = projectInfo['storage_bucket'];
  if (storageBucket == null || storageBucket is! String) {
    throw const FormatException(
        "Firebase config is missing 'project_info.storage_bucket' (String).");
  }

  // Read messagingSenderId from the config when present (project_info or the
  // client's messaging section), falling back to a named constant.
  String messagingSenderId = kDefaultMessagingSenderId;
  final projectMessagingSenderId = projectInfo['messaging_sender_id'];
  if (projectMessagingSenderId is String &&
      projectMessagingSenderId.isNotEmpty) {
    messagingSenderId = projectMessagingSenderId;
  } else {
    final messaging = client0['messaging'];
    if (messaging is Map) {
      final msId = messaging['messaging_sender_id'];
      if (msId is String && msId.isNotEmpty) {
        messagingSenderId = msId;
      }
    }
  }

  return FirebaseOptions(
    apiKey: currentKey,
    appId: mobilesdkAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
