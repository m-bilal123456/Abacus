import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal() {
    _init();
  }

  final AudioPlayer player = AudioPlayer();
  String? currentUrl;
  bool isPlaying = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  void _init() {
    player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });

    player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });

    player.onPlayerComplete.listen((_) {
      isPlaying = false;
      currentUrl = null;
      position = Duration.zero;
      notifyListeners();
    });
  }

  Future<void> play(String path, {bool isAsset = false}) async {
    await player.stop(); // stop any previous audio
    isPlaying = false;
    position = Duration.zero;
    currentUrl = path;
    notifyListeners();

    if (isAsset) {
      await player.play(AssetSource(path.replaceFirst('assets/', '')));
    } else {
      await player.play(UrlSource(path));
    }

    isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await player.pause();
    isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration pos) async {
    await player.seek(pos);
    position = pos;
    notifyListeners();
  }
}
