import 'package:opencloud/utils/importer.dart';

class OpenDrive with ChangeNotifier {
  //variables

  SharedPreferences? _prefs;
  FirebaseApp? _Baseapp;
  List<FirebaseApp> Projects = [];
  User? _user;
  // ignore: prefer_final_fields
  List<UploadMeta> _uploadingTasks = [];
  final List<DownloadTask> _downloadingTasks = [];
  // constructor
  OpenDrive();

  // Getters
  FirebaseApp? get Baseapp => _Baseapp;
  User? get user => _user;
  List<UploadMeta> get uploadingTasks => _uploadingTasks;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    String? config = _prefs!.getString("BaseConfig");
    if (config != null) {
      // initialize firebase
      _Baseapp = await Firebase.initializeApp(options: FBOPSfromJson(config));
      notifyListeners();

      // set UserListner

      FirebaseAuth.instanceFor(app: Baseapp!)
          .authStateChanges()
          .listen((event) {
        print(event);
        _user = event;
        notifyListeners();
      });
      if (_prefs!.getString("email") != null) {
        FirebaseAuth.instanceFor(app: Baseapp!).signInWithEmailAndPassword(
            email: _prefs!.getString("email")!,
            password: _prefs!.getString("password")!);
        await fetchAllProjectsOfCurrentUser();
      }

      notifyListeners();
    }
  }

  Future<void> fetchAllProjectsOfCurrentUser() async {
    if (_Baseapp == null) {
      throw Exception("Firebase not initialized");
    }
    var docs = (await FirebaseFirestore.instanceFor(app: _Baseapp!)
            .collection("projects")
            .get())
        .docs;

    for (var ele in docs) {
      Projects.add(await Firebase.initializeApp(
          name: ele.id, options: FBOPSfromJson(ele.data()["data"] as String)));
    }
    // for (doc.) {

    // Projects.add(
    //     await Firebase.initializeApp(options: FBOPSfromJson(doc['data'])));
    // }

    notifyListeners();
  }

  Future<void> createProjectFromJson(
      {required String data, bool isInitial = false}) async {
    if (isInitial) {
      _Baseapp = await Firebase.initializeApp(options: FBOPSfromJson(data));
      notifyListeners();
    }
    if (_Baseapp == null && !isInitial) {
      throw Exception("Firebase not initialized");
    }
    // check if project already exists
    for (var doc in (await FirebaseFirestore.instanceFor(app: _Baseapp!)
            .collection("projects")
            .get())
        .docs) {
      if (FBOPSfromJson(doc.data()["data"].toString()).apiKey ==
              FBOPSfromJson(data).apiKey &&
          _prefs!.getString("BaseConfig") != null) {
        throw Exception("Project already exists");
      }
    }

    // save in Firebase
    if (_prefs!.getString("BaseConfig") != null) {
      int count = ((await FirebaseFirestore.instanceFor(app: _Baseapp!)
              .collection("projects")
              .get())
          .docs
          .length);
      await FirebaseFirestore.instanceFor(app: _Baseapp!)
          .collection("projects")
          .doc("$count")
          .set({"data": data});
    }
    // save in SharedPreferences if first project is not saved
    print(
        "isFirst \n\n\n\n\n\n >>>>>> ${_prefs!.getString("BaseConfig") == null} \n\n\n\n\n\n\n");
    if (_prefs!.getString("BaseConfig") == null) {
      print(await _prefs!.setString("BaseConfig", data));
    }

    await fetchAllProjectsOfCurrentUser();
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    try {
      var cred = await FirebaseAuth.instanceFor(app: _Baseapp!)
          .signInWithEmailAndPassword(email: email, password: password);
      _user = cred.user;
    } catch (e) {
      if (e.runtimeType == FirebaseAuthException) {
        if ((e as FirebaseAuthException).code == "user-not-found") {
          var cred = await FirebaseAuth.instanceFor(app: _Baseapp!)
              .createUserWithEmailAndPassword(email: email, password: password);
          _user = cred.user;
        }
      }
    }
    _prefs!.setString("email", email);
    _prefs!.setString("password", password);
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    if (_Baseapp == null) {
      throw Exception("Firebase not initialized");
    }
    await FirebaseFirestore.instanceFor(app: _Baseapp!)
        .collection("projects")
        .doc(id)
        .delete();

    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instanceFor(app: _Baseapp!).signOut();
    _user = null;
    notifyListeners();
  }

  Future<ListResult> listAllTheFilesOfAProject(
      FirebaseApp proj, String? path) async {
    return FirebaseStorage.instanceFor(
            app: proj, bucket: proj.options.storageBucket)
        .ref(path ?? "")
        .listAll();
  }

  Future<void> uploadFile(
      {required File file,
      required String path,
      required FirebaseApp proj}) async {
    await FirebaseStorage.instanceFor(
            app: proj, bucket: proj.options.storageBucket)
        .ref(path)
        .putFile(file);
  }

  Future<void> downloadFile({required Reference ref}) async {
    launchUrlString(await ref.getDownloadURL(),
        mode: LaunchMode.externalApplication);
  }

  Future<void> createFolder(
      {required String path,
      required String name,
      required FirebaseApp proj}) async {
    await FirebaseStorage.instanceFor(
            app: proj, bucket: proj.options.storageBucket)
        .ref(path)
        .child("$name/NEWFILEPLACEHOLDER.txt")
        .putData(Uint8List(0));
  }

  Future<List<int>> uploadFileToProject(
      {required FirebaseApp app,
      String? uploadpath,
      required List<String> paths}) async {
    var storage = FirebaseStorage.instanceFor(
        app: app, bucket: app.options.storageBucket);
    List<int> ids = [];
    List<Future> brr = [
      for (var path in paths) uploads(storage, uploadpath, path, app)
    ];
    for (var element in brr) {
      ids.add(await element);
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
