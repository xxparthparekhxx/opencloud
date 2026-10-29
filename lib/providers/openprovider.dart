import 'dart:async';
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
  StreamSubscription<User?>? _authSubscription;

  AccountStatus _accountStatus = AccountStatus.signedOut;
  // The uid [_accountStatus] was worked out for, so repeated auth events for
  // the same user do not check the account again.
  String? _statusUid;
  // True while signIn/signUp/secureLegacyAccount run. They settle the
  // account state themselves when done, so auth events in between are
  // ignored.
  bool _authInFlight = false;
  String? _pendingEmail;

  OpenDrive();

  /// Test-only constructor: skips Firebase initialization and uses
  /// [authService] (typically backed by a fake `AuthClient`). There is no
  /// project registry, so no projects are loaded.
  @visibleForTesting
  OpenDrive.forTesting({required AuthService authService}) {
    _attachAuth(authService);
  }

  // Getters
  FirebaseApp? get baseApp => _baseApp;
  List<FirebaseApp> get projects => _projects;
  User? get user => _user;
  List<UploadMeta> get uploadingTasks => _uploadingTasks;
  Object? get initError => _initError;
  AccountStatus get accountStatus => _accountStatus;

  /// The address the email-change verification link was just sent to.
  String? get pendingEmail => _pendingEmail;

  bool get _hasUsableAccount =>
      _accountStatus == AccountStatus.ready ||
      _accountStatus == AccountStatus.awaitingEmailChange;

  void _setUpBaseApp(FirebaseApp app) {
    _baseApp = app;
    _projectRepository = ProjectRepository(app: app);
    _attachAuth(AuthService.forApp(app));
  }

  void _attachAuth(AuthService authService) {
    _authService = authService;
    _authSubscription?.cancel();
    _authSubscription =
        authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthService _requireAuth() {
    final auth = _authService;
    if (auth == null) {
      throw Exception("Firebase not initialized");
    }
    return auth;
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_authInFlight || user?.uid == _statusUid) return;
    await _updateAccount(user);
    if (_hasUsableAccount) await _loadProjects();
  }

  /// Sets [user] as the signed-in user and works out [accountStatus] for it
  /// (see [AuthService.checkAccount]).
  Future<void> _updateAccount(User? user) async {
    _user = user;
    if (user == null) {
      _statusUid = null;
      _accountStatus = AccountStatus.signedOut;
      _projects.clear();
      notifyListeners();
      return;
    }
    _statusUid = user.uid;
    _accountStatus = AccountStatus.checking;
    notifyListeners();

    AccountStatus status;
    try {
      status = await _authService!.checkAccount();
    } catch (_) {
      // Firebase could not be reached to tell whether this legacy account
      // was already secured. Ask for it to be secured: submitting that form
      // also copes with an account that already was.
      status = AccountStatus.needsSecuring;
    }
    // A newer auth event (e.g. the sign-out checkAccount does when the
    // session has ended) has already settled the state.
    if (_statusUid != user.uid) return;

    _user = _authService!.user;
    if (status == AccountStatus.signedOut) {
      _statusUid = null;
      _projects.clear();
    }
    _accountStatus = status;
    notifyListeners();
  }

  /// Runs an auth call, keeping auth events from interfering with it.
  Future<T> _whileAuthInFlight<T>(Future<T> Function() action) async {
    _authInFlight = true;
    try {
      return await action();
    } catch (_) {
      _authInFlight = false;
      // A call that failed part-way can still have changed who is signed in
      // (e.g. the legacy account was signed into before a later step
      // failed), so catch up with the session.
      final current = _authService?.user;
      if (current?.uid != _statusUid) await _updateAccount(current);
      rethrow;
    } finally {
      _authInFlight = false;
    }
  }

  Future<void> init() async {
    _initError = null;
    try {
      _prefs = await SharedPreferences.getInstance();
      String? config = _prefs!.getString(kBaseConfigPrefKey);
      if (config != null) {
        // initialize firebase
        _setUpBaseApp(
            await Firebase.initializeApp(options: fbOpsFromJson(config)));
        notifyListeners();

        // Firebase Auth persists the session on the device, so the signed-in
        // user is restored automatically instead of re-sending stored
        // credentials.
        await _updateAccount(_authService!.user);
        if (_hasUsableAccount) {
          await fetchAllProjectsOfCurrentUser();
        }
      }
    } catch (e) {
      _initError = e;
    }
  }

  /// Loads the signed-in user's projects. Signed out, there are none.
  Future<void> fetchAllProjectsOfCurrentUser() async {
    if (_baseApp == null) {
      throw Exception("Firebase not initialized");
    }
    final uid = _user?.uid;
    if (uid == null) {
      _projects.clear();
      notifyListeners();
      return;
    }
    final fetched = await _projectRepository!.fetchAllProjects(ownerUid: uid);
    // Signed out, or into another account, while fetching.
    if (_user?.uid != uid) return;
    _projects
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  Future<void> _loadProjects() async {
    // Without a base app there is no project registry (only in tests).
    if (_projectRepository == null) return;
    await fetchAllProjectsOfCurrentUser();
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
        _setUpBaseApp(await Firebase.initializeApp(options: ops));
        notifyListeners();
        await _updateAccount(_authService!.user);
      }
      if (_hasUsableAccount) {
        await fetchAllProjectsOfCurrentUser();
      }
      notifyListeners();
      return;
    }

    if (_baseApp == null) {
      throw Exception("Firebase not initialized");
    }
    final uid = _user?.uid;
    if (uid == null) {
      throw Exception("Sign in before adding a project");
    }
    await _projectRepository!.createProjectFromJson(data: data, ownerUid: uid);
    await fetchAllProjectsOfCurrentUser();
    notifyListeners();
  }

  /// Signs in with the user's own email/password. Failures (wrong password,
  /// unknown account, ...) are rethrown for the UI to surface. Credentials
  /// are not persisted: Firebase Auth keeps the session on the device.
  Future<void> signIn({required String email, required String password}) =>
      _signInWith(() => _requireAuth().signIn(email: email, password: password));

  /// Creates an account with the user's own email/password and signs into
  /// it. Failures (email already in use, weak password, ...) are rethrown
  /// for the UI to surface.
  Future<void> signUp({required String email, required String password}) =>
      _signInWith(() => _requireAuth().signUp(email: email, password: password));

  Future<void> _signInWith(Future<UserCredential> Function() action) async {
    final cred = await _whileAuthInFlight(action);
    await _updateAccount(cred.user);
    if (_hasUsableAccount) await _loadProjects();
  }

  /// The one-time "secure your account" step for a legacy account (see
  /// [AuthService.secureLegacyAccount]). Works whether the legacy session was
  /// restored or the user is signed out.
  ///
  /// On success [accountStatus] is [AccountStatus.emailChangeSent] until
  /// [acknowledgeEmailChangeSent] is called.
  Future<void> secureLegacyAccount({
    required String newEmail,
    required String newPassword,
  }) async {
    final auth = _requireAuth();
    await _whileAuthInFlight(() => auth.secureLegacyAccount(
          newEmail: newEmail,
          newPassword: newPassword,
        ));
    _user = auth.user;
    _statusUid = _user?.uid;
    _pendingEmail = newEmail;
    _accountStatus = AccountStatus.emailChangeSent;
    notifyListeners();
  }

  /// The user has read that the email change completes when they click the
  /// verification link: carry on into the app.
  Future<void> acknowledgeEmailChangeSent() async {
    _accountStatus = AccountStatus.awaitingEmailChange;
    notifyListeners();
    await _loadProjects();
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
    await _requireAuth().signOut();
    _user = null;
    _statusUid = null;
    _pendingEmail = null;
    _accountStatus = AccountStatus.signedOut;
    _projects.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
