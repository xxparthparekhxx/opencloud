import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

enum PlayerFileType { audio, video, image, unknown }

enum PlayerStates { playing, paused, stopped, loading, notPlaying }

/// Typed model for the currently active playback item.
sealed class ActivePlayer {}

/// An active audio playback session.
final class AudioActive extends ActivePlayer {
  final AudioPlayer player;
  AudioActive(this.player);
}

/// An active video playback session.
final class VideoActive extends ActivePlayer {
  final VideoPlayerController controller;
  VideoActive(this.controller);
}

/// An image to display (resolved download URL, not a widget).
final class ImageActive extends ActivePlayer {
  final String url;
  ImageActive(this.url);
}

class PlayerProvider with ChangeNotifier {
  // player methods
  PlayerStates _playerState = PlayerStates.notPlaying;
  List<Reference> _playerQueue = [];
  int _playerIndex = 0;
  PlayerFileType? _playerFileType;
  ActivePlayer? _player;

  PlayerStates get playerState => _playerState;
  List<Reference> get playerQueue => _playerQueue;
  int get playerIndex => _playerIndex;
  PlayerFileType? get playerFileType => _playerFileType;
  ActivePlayer? get player => _player;

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
    final player = _player;
    if (player is AudioActive) {
      _playerState = PlayerStates.playing;
      notifyListeners();
      await player.player.play();
    } else if (player is VideoActive) {
      _playerState = PlayerStates.playing;
      notifyListeners();
      player.controller.play();
    }
  }

  void stopPlaying() {
    _player?.disposeIfSupported();
    _playerState = PlayerStates.notPlaying;
    _player = null;
    _playerFileType = null;
    _playerIndex = 0;
    _playerQueue = [];
    notifyListeners();
  }

  void startPlaying(List<Reference> refs, int index) async {
    if (_player != null) {
      _player?.disposeIfSupported();
      _player = null;
    }
    if (refs.isEmpty) {
      return;
    }
    _playerQueue = refs;
    _playerIndex = index;
    notifyListeners();

    _playerState = PlayerStates.loading;
    final type = _fileTypeForPath(refs[index].fullPath);
    await _determinePlayerForFileType(type, refs[index]);
    notifyListeners();
  }

  void skipToNext() {
    _player?.disposeIfSupported();
    _player = null;
    _playerIndex += 1;
    if (_playerIndex >= _playerQueue.length) {
      _playerState = PlayerStates.stopped;
      notifyListeners();
      return;
    }
    _playerState = PlayerStates.loading;
    notifyListeners();
    final type = _fileTypeForPath(
      _playerQueue[_playerIndex].fullPath,
    );
    _determinePlayerForFileType(type, _playerQueue[_playerIndex]);
    notifyListeners();
  }

  void skipToPrevious() {
    _playerIndex -= 2;
    if (_playerIndex < 0) {
      _playerIndex = 0;
    }
    _player?.disposeIfSupported();
    _player = null;
    _playerState = PlayerStates.stopped;
    notifyListeners();
  }

  void pausePlaying() {
    final player = _player;
    if (player is AudioActive) {
      player.player.pause();
    } else if (player is VideoActive) {
      player.controller.pause();
    }
    _playerState = PlayerStates.paused;
    notifyListeners();
  }

  Future<void> _determinePlayerForFileType(
    PlayerFileType type,
    Reference ref,
  ) async {
    if (type == PlayerFileType.audio) {
      await _audioPlayer(ref);
    } else if (type == PlayerFileType.video) {
      await _videoPlayer(ref);
    } else if (type == PlayerFileType.image) {
      _playerState = PlayerStates.loading;
      notifyListeners();
      final url = await ref.getDownloadURL();
      _player = ImageActive(url);
      _playerState = PlayerStates.playing;
    } else {
      _player = null;
    }
    notifyListeners();
  }

  Future<void> _videoPlayer(Reference ref) async {
    _playerState = PlayerStates.loading;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(await ref.getDownloadURL()),
    );
    _player = VideoActive(controller);
    notifyListeners();

    await controller.initialize();
    await controller.play();
    _playerState = PlayerStates.playing;
    notifyListeners();

    controller.addListener(() {
      if (!controller.value.isPlaying &&
          controller.value.position >= controller.value.duration &&
          _playerState != PlayerStates.stopped &&
          _playerState != PlayerStates.notPlaying) {
        _playerState = PlayerStates.stopped;
        notifyListeners();
      }
    });
  }

  Future<void> _audioPlayer(Reference ref) async {
    final player = AudioPlayer();
    _player = AudioActive(player);
    _playerState = PlayerStates.playing;
    notifyListeners();
    await player.setUrl(await ref.getDownloadURL());
    await player.play();
    player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed &&
          _playerState != PlayerStates.stopped &&
          _playerState != PlayerStates.notPlaying) {
        _playerState = PlayerStates.stopped;
        notifyListeners();
      }
    });
  }

  PlayerFileType _fileTypeForPath(String name) {
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
}

extension _ActivePlayerDispose on ActivePlayer? {
  void disposeIfSupported() {
    switch (this) {
      case AudioActive(:final player):
        player.dispose();
      case VideoActive(:final controller):
        controller.dispose();
      case ImageActive():
        break;
      case null:
        break;
    }
  }
}
