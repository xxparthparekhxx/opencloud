import 'package:opencloud/utils/importer.dart';

enum PlayerFileType { audio, video, image, unknown }

enum PlayerStates { playing, paused, stopped, loading, notPlaying }

class PlayerProvider with ChangeNotifier {
  // player methods
  PlayerStates _playerState = PlayerStates.notPlaying;
  List<Reference> _playerQueue = [];
  int _playerIndex = 0;
  PlayerFileType? _playerFileType;
  var _player;

  PlayerStates get playerState => _playerState;
  List<Reference> get playerQueue => _playerQueue;
  int get playerIndex => _playerIndex;
  PlayerFileType? get playerFileType => _playerFileType;
  get player => _player;

  Future? currentPlayingFuture;

  set playerState(PlayerStates state) {
    _playerState = state;
    notifyListeners();
  }

  set playerIndex(int value) {
    _playerIndex = value;
    notifyListeners();
  }

  set playerFileType(PlayerFileType? value) {
    _playerFileType = value;
    notifyListeners();
  }

  void resumePlaying() async {
    if (_player != null) {
      _playerState = PlayerStates.playing;
      notifyListeners();
      await _player!.play();
    }
  }

  void stopPlaying() {
    _playerState = PlayerStates.notPlaying;
    _player?.dispose();

    currentPlayingFuture = null;
    _player = null;
    _playerFileType = null;
    _playerIndex = 0;
    _playerQueue = [];
    if (_player != null) {}
    notifyListeners();
  }

  void startPlaying(List<Reference> refs, index) async {
    if (_player != null) {
      _player.dispose();
      _player = null;
    }
    if (refs.isEmpty) {
      return;
    }
    _playerQueue = refs;
    _playerIndex = index;
    notifyListeners();

    _playerState = PlayerStates.loading;
    currentPlayingFuture = determinePlayerWithtFileType(
        checkFileType(refs[_playerIndex].fullPath, refs[_playerIndex]),
        refs[_playerIndex]);

    await currentPlayingFuture;

    await _player?.dispose();
    _player = null;
    _playerState = PlayerStates.notPlaying;

    notifyListeners();
  }

  skipToNext() {
    currentPlayingFuture = null;
    if (_player != null) {
      _player?.dispose();
    }
    _player = null;
    _playerState = PlayerStates.stopped;
    notifyListeners();
  }

  skipToPrevious() {
    _playerIndex -= 2;
    currentPlayingFuture = null;

    if (_player != null) {
      _player?.dispose();
    }
    _player = null;
    _playerState = PlayerStates.stopped;

    notifyListeners();
  }

  pausePlaying() {
    _player.pause();
    _playerState = PlayerStates.paused;
    notifyListeners();
  }

  determinePlayerWithtFileType(
    PlayerFileType type,
    Reference ref,
  ) async {
    if (type == PlayerFileType.audio) {
      await audioPlayer(ref);
    } else if (type == PlayerFileType.video) {
      await videoPlayer(ref);
    } else if (type == PlayerFileType.image) {
      _player = Image.network(
        await ref.getDownloadURL(),
      );
    } else {
      _player = null;
    }

    notifyListeners();
  }

  Future<void> videoPlayer(Reference ref) async {
    _playerState = PlayerStates.loading;
    _player = VideoPlayerController.networkUrl(
      Uri.parse(await ref.getDownloadURL()),
    );
    notifyListeners();

    var p = _player as VideoPlayerController;
    await p.initialize();
    await p.play();
    _playerState = PlayerStates.playing;
    while (p.value.position < p.value.duration &&
        (_playerState != PlayerStates.stopped &&
            _playerState != PlayerStates.notPlaying)) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _playerState = PlayerStates.stopped;
    notifyListeners();
  }

  Future<void> audioPlayer(Reference ref) async {
    _player = AudioPlayer();
    // Create a player
    _playerState = PlayerStates.playing;
    notifyListeners();
    final duration = await _player.setUrl(// Load a URL
        await ref.getDownloadURL()); // Schemes: (https: | file: | asset: )

    await _player.play();
    var p = _player as AudioPlayer;
    while (p.position < duration &&
        (_playerState != PlayerStates.stopped &&
            _playerState != PlayerStates.notPlaying)) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _playerState = PlayerStates.stopped;
    notifyListeners();
  }

  checkFileType(
    String name,
    Reference ref,
  ) {
    if (name.endsWith(".mp3") || name.endsWith(".opus")) {
      return PlayerFileType.audio;
    } else if (name.endsWith(".mp4")) {
      return PlayerFileType.video;
    } else if (name.endsWith(".jpg") || name.endsWith(".png")) {
      return PlayerFileType.image;
    } else {
      return PlayerFileType.unknown;
    }
  }

  // music player  methods

  //video player  methods
}
