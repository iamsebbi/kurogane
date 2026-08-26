import 'package:flutter/foundation.dart';

class ApiConstants {
  // Default development baseUrl:
  // Android Emulator uses 10.0.2.2 to access host machine's localhost
  // iOS Simulator / Desktop uses localhost:4000
  static String get baseUrl {
    // În Release (aplicația instalată pe telefon, fără cablu sau debugger):
    if (kReleaseMode) {
      return 'https://kurogane.onrender.com';
    }
    if (kIsWeb) {
      return 'http://localhost:4000';
    }
    // În Debug: compatibil cu adb reverse tcp:4000 tcp:4000 pe telefon fizic și emulator
    return 'http://127.0.0.1:4000';
  }

  // Endpoints
  static const String health = '/api/health';
  static const String homepage = '/api/homepage';
  static const String search = '/api/search';
  static const String mediaDetail = '/api/media';
  static const String categories = '/api/categories';
  static const String news = '/api/news';
  static const String watchlist = '/api/watchlist';
  static const String profile = '/api/user/profile';
  static const String resolveIdentifier = '/api/auth/resolve-identifier';
  static const String registerUser = '/api/auth/register-user';
}
