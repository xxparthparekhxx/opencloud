import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:opencloud/models/app_constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Handles Firebase Storage IO for a given `FirebaseApp` project.
class StorageService {
  StorageService({required this.app});

  final FirebaseApp app;

  FirebaseStorage _storage() =>
      FirebaseStorage.instanceFor(app: app, bucket: app.options.storageBucket);

  Future<ListResult> listAllTheFilesOfAProject(String? path) async {
    return _storage().ref(path ?? "").listAll();
  }

  Future<void> downloadFile({required Reference ref}) async {
    launchUrlString(await ref.getDownloadURL(),
        mode: LaunchMode.externalApplication);
  }

  Future<void> createFolder({
    required String path,
    required String name,
  }) async {
    await _storage()
        .ref(path)
        .child("$name/$kFolderPlaceholderFileName")
        .putData(Uint8List(0));
  }

  /// Deletes a single file at [ref].
  Future<void> deleteFile(Reference ref) async {
    await ref.delete();
  }

  /// Recursively deletes a folder and everything under it at [ref].
  Future<void> deleteFolderRecursive(Reference ref) async {
    final list = await ref.listAll();
    for (final item in list.items) {
      await item.delete();
    }
    for (final prefix in list.prefixes) {
      await deleteFolderRecursive(prefix);
    }
    await ref.delete();
  }
}
