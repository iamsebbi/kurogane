import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String cloudBaseUrl = 'https://kurogane.onrender.com';

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) {
      return _configuredUrl;
    }
    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:4000';
    }
    return 'http://localhost:4000';
  }

  static List<String> get candidateBaseUrls {
    if (_configuredUrl.isNotEmpty) {
      return [_configuredUrl];
    }
    if (kIsWeb) return ['http://localhost:4000', cloudBaseUrl];
    if (defaultTargetPlatform == TargetPlatform.android) {
      return [
        'http://127.0.0.1:4000',     // Physical phone (with adb reverse) or local loopback
        'http://192.168.1.224:4000',  // Physical phone over Wi-Fi (LAN IP)
        'http://10.0.2.2:4000',       // Android Studio Emulator standard host alias
        cloudBaseUrl,                 // Cloud fallback
      ];
    }
    return ['http://localhost:4000', 'http://192.168.1.224:4000', cloudBaseUrl];
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
  static const String checkUsername = '/api/auth/check-username';
  static const String googleServerClientId = '141330897882-cfls510bk9je8vjejngqo4isfpua8bck.apps.googleusercontent.com';
}
