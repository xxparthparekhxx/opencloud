import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:opencloud/models/app_constants.dart';
import 'package:opencloud/models/options.dart';

/// Repository for per-project Firebase configuration stored in Firestore.
///
/// Project configs live in the `projects` collection of the base app's
/// Firestore database. Each document holds the serialized `FirebaseOptions`
/// for one Firebase project under the `"data"` field, and the uid of the
/// account that added it under [kProjectOwnerField]. Every query is scoped to
/// the signed-in owner so owner-only Security Rules can allow it.
class ProjectRepository {
  ProjectRepository({required this.app});

  final FirebaseApp app;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instanceFor(app: app).collection(kProjectsCollection);

  Query<Map<String, dynamic>> _ownedBy(String ownerUid) =>
      _collection.where(kProjectOwnerField, isEqualTo: ownerUid);

  Future<List<FirebaseApp>> fetchAllProjects({required String ownerUid}) async {
    if (app.options.projectId.isEmpty) {
      throw Exception("Firebase not initialized");
    }
    await _claimUnownedProjects(ownerUid);
    final docs = (await _ownedBy(ownerUid).get()).docs;

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

  /// Project documents written before they carried an owner have no
  /// [kProjectOwnerField], so the owner-scoped query does not return them and
  /// owner-only rules hide them. While the rules still allow reading the
  /// whole collection, tag them with [ownerUid]. Once owner-only rules are
  /// deployed that read is denied, and there is nothing left to claim.
  Future<void> _claimUnownedProjects(String ownerUid) async {
    final QuerySnapshot<Map<String, dynamic>> all;
    try {
      all = await _collection.get();
    } on FirebaseException catch (e) {
      if (e.code == "permission-denied") return;
      rethrow;
    }
    for (final doc in all.docs) {
      if (doc.data().containsKey(kProjectOwnerField)) continue;
      try {
        await doc.reference.update({kProjectOwnerField: ownerUid});
      } on FirebaseException catch (e) {
        // Rules that allow reading but not tagging: leave it untagged rather
        // than failing to load the projects that are already owned.
        if (e.code != "permission-denied") rethrow;
      }
    }
  }

  /// Creates a project owned by [ownerUid] from serialized Firebase config
  /// JSON.
  ///
  /// Returns the newly initialized `FirebaseApp`. When `isInitial` is true the
  /// app is also installed as the base app.
  Future<FirebaseApp> createProjectFromJson({
    required String data,
    required String ownerUid,
    bool isInitial = false,
  }) async {
    final ops = fbOpsFromJson(data);

    // Check if this owner already has a project with the same apiKey.
    final existingDocs = (await _ownedBy(ownerUid).get()).docs;
    for (final doc in existingDocs) {
      if (fbOpsFromJson(doc.data()["data"].toString()).apiKey == ops.apiKey) {
        throw Exception("Project already exists");
      }
    }

    // Save in Firestore using an auto-generated document ID so concurrent
    // creators cannot collide on a sequential counter.
    final docRef = _collection.doc();
    await docRef.set({"data": data, kProjectOwnerField: ownerUid});

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
    await _collection.doc(id).delete();
  }
}
