import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState extends ChangeNotifier {
  int _score = 0;
  int _highScore = 0;
  int _currentLevel = 1;
  bool _isPlaying = false;
  bool _isDead = false;
  String? _facePath;

  int get score => _score;
  int get highScore => _highScore;
  int get currentLevel => _currentLevel;
  bool get isPlaying => _isPlaying;
  bool get isDead => _isDead;
  String? get facePath => _facePath;

  GameState() {
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt('highScore') ?? 0;
    _facePath = prefs.getString('facePath');
    notifyListeners();
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', _highScore);
  }

  void startGame() {
    _score = 0;
    _currentLevel = 1;
    _isPlaying = true;
    _isDead = false;
    notifyListeners();
  }

  void incrementScore() {
    _score++;
    if (_score > _highScore) {
      _highScore = _score;
      _saveHighScore();
    }
    
    // Level up every 10 points
    if (_score % 10 == 0 && _currentLevel < 10) {
      _currentLevel++;
    }
    notifyListeners();
  }

  void gameOver() {
    _isDead = true;
    _isPlaying = false;
    notifyListeners();
  }

  void setFacePath(String path) {
    _facePath = path;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('facePath', path);
    });
    notifyListeners();
  }
}

