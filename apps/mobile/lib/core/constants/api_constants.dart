import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String workersBaseUrl = 'https://kurogane-api.kurogane-workers-api.workers.dev';
  static const String cloudBaseUrl = 'https://kurogane.onrender.com';

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) {
      return _configuredUrl;
    }
    // Default to Cloudflare Workers edge backend
    if (kReleaseMode) {
      return workersBaseUrl;
    }
    if (kIsWeb) return workersBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return workersBaseUrl;
    }
    return workersBaseUrl;
  }

  static List<String> get candidateBaseUrls {
    final list = <String>[];
    if (_configuredUrl.isNotEmpty) {
      list.add(_configuredUrl);
      list.add(workersBaseUrl);
      list.add(cloudBaseUrl);
    } else if (kReleaseMode) {
      list.add(workersBaseUrl);
      list.add(cloudBaseUrl);
      list.add('http://192.168.1.224:4000');
    } else {
      list.add(workersBaseUrl);
      if (defaultTargetPlatform == TargetPlatform.android) {
        list.add('http://192.168.1.224:4000');
        list.add(cloudBaseUrl);
        list.add('http://127.0.0.1:4000');
        list.add('http://10.0.2.2:4000');
      } else {
        list.add('http://localhost:4000');
        list.add(cloudBaseUrl);
        list.add('http://192.168.1.224:4000');
      }
    }
    return list.toSet().toList();
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
