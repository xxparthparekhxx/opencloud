import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';

FirebaseOptions FBOPSfromJson(String json) {
  print(json);
  Map<String, dynamic> data = jsonDecode(json);
  var client = (data["client"]! as List);

  return FirebaseOptions(
    apiKey: client[0]["api_key"][0]['current_key'] as String,
    appId: client[0]['client_info']['mobilesdk_app_id'] as String,
    messagingSenderId: "0",
    projectId: (data['project_info']! as Map)['project_id'] as String,
    storageBucket: (data['project_info']! as Map)['storage_bucket'] as String,
  );
}

// class Options {
  // Map<String, String> project_info;
  // List<Map<String ,>> client;
// }
