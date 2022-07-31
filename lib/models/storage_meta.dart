import 'package:firebase_storage/firebase_storage.dart';

class UploadMeta {
  final int id;
  final UploadTask task;
  final String toProject;
  UploadMeta(this.id, this.task, this.toProject);
}
