import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';

  /// Returns true if the user has already seen the tutorial
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenTutorialKey) ?? false;
  }

  /// Mark the tutorial as seen
  static Future<void> markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTutorialKey, true);
  }

  /// Reset so tutorial shows again (used from Settings toggle)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenTutorialKey);
  }
}
