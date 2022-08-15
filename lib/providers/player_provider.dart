import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

enum PlayerFileType { audio, video, image, unknown }

enum PlayerState { playing, paused, stopped, loading, notPlaying }

class PlayerProvider with ChangeNotifier {
  // player methods
  PlayerState _playerState = PlayerState.notPlaying;
  List<Reference> _playerQueue = [];
  int _playerIndex = 0;
  PlayerFileType? _playerFileType;
  var _player;

  PlayerState get playerState => _playerState;
  List<Reference> get playerQueue => _playerQueue;
  int get playerIndex => _playerIndex;
  PlayerFileType? get playerFileType => _playerFileType;
  get player => _player;

  set playerState(PlayerState state) {
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
      _playerState = PlayerState.playing;
      notifyListeners();
      await (_player! as AudioPlayer).play();
    }
  }

  void stopPlaying() {
    if (_player != null) {
      _player!.dispose();
      _playerState = PlayerState.notPlaying;
      _player = null;
      _playerFileType = null;
      _playerIndex = 0;
      _playerQueue = [];
      notifyListeners();
    }
  }

  void startPlaying(List<Reference> refs, index) async {
    if (_player != null) {
      _player.dispose();
    }
    if (refs.isEmpty) {
      return;
    }
    _playerQueue = refs;
    _playerIndex = index;

    _playerState = PlayerState.loading;

    await determinePlayerWithtFileType(
        checkFileType(refs[index].fullPath, refs[index]), refs[index]);

    notifyListeners();
  }

  pausePlaying() {
    (_player as AudioPlayer).pause();
    _playerState = PlayerState.paused;
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
    _player = VideoPlayerController.network(
      await ref.getDownloadURL(),
    );
    (_player as VideoPlayerController).initialize().then((_) {
      _player.play();
      _playerState = PlayerState.playing;
      notifyListeners();
    });
  }

  Future<void> audioPlayer(Reference ref) async {
    _player = AudioPlayer();
    // Create a player

    final duration = await _player.setUrl(// Load a URL
        await ref.getDownloadURL()); // Schemes: (https: | file: | asset: )
    _playerState = PlayerState.playing;
    notifyListeners();
    await compute(_player.play(), (e) {
      _playerState = PlayerState.stopped;
      notifyListeners();
    });
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
