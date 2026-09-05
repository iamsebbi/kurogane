import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const String workersBaseUrl = 'https://kurogane-api.kurogane-workers-api.workers.dev';
  static const String localWorkerBaseUrl = 'http://127.0.0.1:8787';

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) {
      return _configuredUrl;
    }
    return workersBaseUrl;
  }

  static List<String> get candidateBaseUrls {
    final list = <String>[];
    if (_configuredUrl.isNotEmpty) {
      list.add(_configuredUrl);
    }
    list.add(workersBaseUrl);
    if (!kReleaseMode) {
      list.add(localWorkerBaseUrl);
      if (defaultTargetPlatform == TargetPlatform.android) {
        list.add('http://10.0.2.2:8787');
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
