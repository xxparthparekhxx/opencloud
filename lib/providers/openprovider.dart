import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:opencloud/models/app_constants.dart';
import 'package:opencloud/models/options.dart';
import 'package:opencloud/models/storage_meta.dart';
import 'package:opencloud/services/auth_service.dart';
import 'package:opencloud/services/project_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Facade over the auth, project-registry and storage services.
///
/// `OpenDrive` remains a `ChangeNotifier` so existing callers (UI pages) keep
/// working, but it now delegates each concern to a dedicated service class
/// under `lib/services/`.
class OpenDrive with ChangeNotifier {
  // variables
  SharedPreferences? _prefs;
  FirebaseApp? _baseApp;
  final List<FirebaseApp> _projects = [];
  User? _user;
  Object? _initError;
  // ignore: prefer_final_fields
  List<UploadMeta> _uploadingTasks = [];

  AuthService? _authService;
  ProjectRepository? _projectRepository;

  OpenDrive();

  // Getters
  FirebaseApp? get baseApp => _baseApp;
  List<FirebaseApp> get projects => _projects;
  User? get user => _user;
  List<UploadMeta> get uploadingTasks => _uploadingTasks;
  Object? get initError => _initError;

  Future<void> init() async {
    _initError = null;
    try {
      _prefs = await SharedPreferences.getInstance();
      String? config = _prefs!.getString(kBaseConfigPrefKey);
      if (config != null) {
        // initialize firebase
        _baseApp = await Firebase.initializeApp(options: fbOpsFromJson(config));
        _authService = AuthService(app: _baseApp!);
        _projectRepository = ProjectRepository(app: _baseApp!);
        notifyListeners();

        // set User listener
        _authService!.authStateChanges.listen((event) async {
          _user = event;
          notifyListeners();
          if (event != null) {
            await fetchAllProjectsOfCurrentUser();
          }
        });
        // Firebase Auth persists the session on the device, so the signed-in
        // user is restored automatically instead of re-sending stored
        // credentials.
        _user = _authService!.user;
        notifyListeners();
        if (_user != null) {
          await fetchAllProjectsOfCurrentUser();
        }
      }
    } catch (e) {
      _initError = e;
    }
  }

  Future<void> fetchAllProjectsOfCurrentUser() async {
    if (_baseApp == null) {
      throw Exception("Firebase not initialized");
    }
    final fetched = await _projectRepository!.fetchAllProjects();
    _projects
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  Future<void> createProjectFromJson(
      {required String data, bool isInitial = false}) async {
    final ops = fbOpsFromJson(data);

    if (isInitial) {
      // First launch: there is no base app yet, so the project repository
      // (scoped to the base app) does not exist either. Persist the base
      // config first so a restart remembers this project, then initialize
      // the base app directly and set up the auth/project services on top
      // of it instead of going through a null repository.
      _prefs ??= await SharedPreferences.getInstance();
      final prefs = _prefs!;
      if (prefs.getString(kBaseConfigPrefKey) == null) {
        await prefs.setString(kBaseConfigPrefKey, data);
      }
      if (_baseApp == null) {
        _baseApp = await Firebase.initializeApp(options: ops);
        _authService = AuthService(app: _baseApp!);
        _projectRepository = ProjectRepository(app: _baseApp!);
        notifyListeners();
      }
      await fetchAllProjectsOfCurrentUser();
      notifyListeners();
      return;
    }

    if (_baseApp == null) {
      throw Exception("Firebase not initialized");
    }
    await _projectRepository!.createProjectFromJson(data: data);
    await fetchAllProjectsOfCurrentUser();
    notifyListeners();
  }

  /// Sign in with email/password, creating the account if it does not exist
  /// (`user-not-found`). Any other auth failure is rethrown so the UI can
  /// surface it; credentials are not persisted (Firebase Auth keeps the
  /// session on the device).
  Future<void> login({required String email, required String password}) async {
    if (_baseApp == null) {
      throw Exception("Firebase not initialized");
    }
    try {
      final cred = await _authService!.signInOrCreate(
        email: email,
        password: password,
      );
      _user = cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
    // Credentials are not stored locally: Firebase Auth persists the session
    // on the device, and the account is re-derived from the base app's
    // options whenever the app restarts.
    notifyListeners();
  }

  /// Deletes the Firestore project document and removes the matching app from
  /// the local project list so the UI does not show a stale entry.
  Future<void> deleteProject(String id) async {
    if (_baseApp == null) {
      throw Exception("Firebase not initialized");
    }
    await _projectRepository!.deleteProject(id);
    _projects.removeWhere((app) => app.name == id);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService!.signOut();
    _user = null;
    _projects.clear();
    notifyListeners();
  }

  Future<ListResult> listAllTheFilesOfAProject(
      FirebaseApp proj, String? path) async {
    return FirebaseStorage.instanceFor(
            app: proj, bucket: proj.options.storageBucket)
        .ref(path ?? "")
        .listAll();
  }

  Future<void> downloadFile({required Reference ref}) async {
    launchUrlString(await ref.getDownloadURL(),
        mode: LaunchMode.externalApplication);
  }

  Future<void> createFolder(
      {required String path,
      required String name,
      required FirebaseApp proj}) async {
    final storage = FirebaseStorage.instanceFor(
        app: proj, bucket: proj.options.storageBucket);
    await storage
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

  Future<List<int>> uploadFileToProject(
      {required FirebaseApp app,
      String? uploadpath,
      required List<String> paths}) async {
    final storage = FirebaseStorage.instanceFor(
        app: app, bucket: app.options.storageBucket);
    List<int> ids = [];
    for (var path in paths) {
      ids.add(await uploads(storage, uploadpath, path, app));
    }
    return ids;
  }

  Future<int> uploads(FirebaseStorage storage, String? uploadpath, String path,
      FirebaseApp app) async {
    UploadTask task =
        storage.ref("$uploadpath/${path.split("/").last}").putFile(File(path));
    final int id = DateTime.now().microsecondsSinceEpoch;
    _uploadingTasks.add(UploadMeta(id, task, app.options.projectId));
    notifyListeners();
    await task.whenComplete(() {
      _uploadingTasks.removeWhere((element) => element.id == id);
      notifyListeners();
    });
    return id;
  }
}
