import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:opencloud/models/app_constants.dart';
import 'package:opencloud/models/options.dart';

/// Repository for per-project Firebase configuration stored in Firestore.
///
/// Project configs live in the `projects` collection of the base app's
/// Firestore database. Each document holds the serialized `FirebaseOptions`
/// for one Firebase project under the `"data"` field.
class ProjectRepository {
  ProjectRepository({required this.app});

  final FirebaseApp app;

  Future<List<FirebaseApp>> fetchAllProjects() async {
    if (app.options.projectId.isEmpty) {
      throw Exception("Firebase not initialized");
    }
    final docs = (await FirebaseFirestore.instanceFor(app: app)
            .collection(kProjectsCollection)
            .get())
        .docs;

    final List<FirebaseApp> projects = [];
    for (final ele in docs) {
      FirebaseOptions ops = fbOpsFromJson(ele.data()["data"] as String);
      // Skip projects already initialized.
      if (projects
          .any((element) => element.options.projectId == ops.projectId)) {
        continue;
      }
      projects.add(await Firebase.initializeApp(name: ele.id, options: ops));
    }
    return projects;
  }

  /// Creates a project from serialized Firebase config JSON.
  ///
  /// Returns the newly initialized `FirebaseApp`. When `isInitial` is true the
  /// app is also installed as the base app.
  Future<FirebaseApp> createProjectFromJson({
    required String data,
    bool isInitial = false,
  }) async {
    final ops = fbOpsFromJson(data);

    // Check if a project with the same apiKey already exists.
    final existingDocs = (await FirebaseFirestore.instanceFor(app: app)
            .collection(kProjectsCollection)
            .get())
        .docs;
    for (final doc in existingDocs) {
      if (fbOpsFromJson(doc.data()["data"].toString()).apiKey == ops.apiKey) {
        throw Exception("Project already exists");
      }
    }

    // Save in Firestore using an auto-generated document ID so concurrent
    // creators cannot collide on a sequential counter.
    final docRef = FirebaseFirestore.instanceFor(app: app)
        .collection(kProjectsCollection)
        .doc();
    await docRef.set({"data": data});

    FirebaseApp baseApp;
    if (isInitial) {
      baseApp = await Firebase.initializeApp(options: ops);
    } else {
      baseApp = await Firebase.initializeApp(name: docRef.id, options: ops);
    }
    return baseApp;
  }

  /// Deletes the project document with the given id from Firestore.
  Future<void> deleteProject(String id) async {
    await FirebaseFirestore.instanceFor(app: app)
        .collection(kProjectsCollection)
        .doc(id)
        .delete();
  }
}
