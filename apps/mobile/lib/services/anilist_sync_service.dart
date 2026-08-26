import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnilistUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? siteUrl;

  const AnilistUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.siteUrl,
  });

  factory AnilistUser.fromJson(Map<String, dynamic> json) {
    return AnilistUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'AniList Member',
      avatarUrl: json['avatar']?['large'] as String? ?? json['avatar']?['medium'] as String?,
      siteUrl: json['siteUrl'] as String?,
    );
  }
}

class AnilistSyncService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://graphql.anilist.co',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static const String _prefTokenKey = 'anilist_access_token';
  static const String _prefIdKey = 'anilist_user_id';
  static const String _prefNameKey = 'anilist_user_name';
  static const String _prefAvatarKey = 'anilist_user_avatar';

  String? _accessToken;
  AnilistUser? _currentUser;

  String? get accessToken => _accessToken;
  AnilistUser? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  /// Inițializare din stocarea locală
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_prefTokenKey);
    final id = prefs.getInt(_prefIdKey);
    final name = prefs.getString(_prefNameKey);
    final avatar = prefs.getString(_prefAvatarKey);

    if (_accessToken != null && id != null && name != null) {
      _currentUser = AnilistUser(
        id: id,
        name: name,
        avatarUrl: avatar,
      );
    }
  }

  /// Conectare cu Token AniList și verificare identitate Viewer
  Future<AnilistUser> connectWithToken(String token) async {
    final cleanToken = token.trim();
    const String query = '''
      query {
        Viewer {
          id
          name
          avatar {
            large
            medium
          }
          siteUrl
        }
      }
    ''';

    final response = await _dio.post(
      '',
      data: {'query': query},
      options: Options(
        headers: {
          'Authorization': 'Bearer $cleanToken',
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final viewerData = response.data['data']?['Viewer'];
      if (viewerData != null) {
        final user = AnilistUser.fromJson(viewerData as Map<String, dynamic>);
        _accessToken = cleanToken;
        _currentUser = user;

        // Salvare persistentă
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefTokenKey, cleanToken);
        await prefs.setInt(_prefIdKey, user.id);
        await prefs.setString(_prefNameKey, user.name);
        if (user.avatarUrl != null) {
          await prefs.setString(_prefAvatarKey, user.avatarUrl!);
        }

        return user;
      }
    }

    throw Exception('Token-ul AniList este invalid sau a expirat.');
  }

  /// Deconectare AniList
  Future<void> disconnect() async {
    _accessToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefIdKey);
    await prefs.remove(_prefNameKey);
    await prefs.remove(_prefAvatarKey);
  }

  /// Sincronizare notă, progres și status către AniList
  Future<bool> saveMediaListEntry({
    required int anilistMediaId,
    required String status, // CURRENT, PLANNING, COMPLETED, DROPPED, PAUSED
    double? score,
    int? progress,
  }) async {
    if (!isAuthenticated || _accessToken == null) return false;

    // Convertire status Kurogane în MediaListStatus AniList
    String anilistStatus = 'CURRENT';
    switch (status.toUpperCase()) {
      case 'WATCHING':
      case 'CURRENT':
        anilistStatus = 'CURRENT';
        break;
      case 'PLAN_TO_WATCH':
      case 'PLANNING':
        anilistStatus = 'PLANNING';
        break;
      case 'COMPLETED':
        anilistStatus = 'COMPLETED';
        break;
      case 'ON_HOLD':
      case 'PAUSED':
        anilistStatus = 'PAUSED';
        break;
      case 'DROPPED':
        anilistStatus = 'DROPPED';
        break;
    }

    const String mutation = '''
      mutation (\$mediaId: Int, \$status: MediaListStatus, \$score: Float, \$progress: Int) {
        SaveMediaListEntry (mediaId: \$mediaId, status: \$status, score: \$score, progress: \$progress) {
          id
          status
          score
          progress
        }
      }
    ''';

    try {
      final response = await _dio.post(
        '',
        data: {
          'query': mutation,
          'variables': {
            'mediaId': anilistMediaId,
            'status': anilistStatus,
            if (score != null) 'score': score,
            if (progress != null) 'progress': progress,
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      return response.statusCode == 200 && response.data?['data']?['SaveMediaListEntry'] != null;
    } catch (_) {
      return false;
    }
  }

  /// Importă întreaga colecție a utilizatorului din AniList
  Future<List<Map<String, dynamic>>> fetchUserMediaCollection() async {
    if (!isAuthenticated || _currentUser == null || _accessToken == null) {
      return [];
    }

    const String query = '''
      query (\$userId: Int) {
        MediaListCollection (userId: \$userId, type: ANIME) {
          lists {
            name
            isCustomList
            entries {
              id
              mediaId
              status
              score(format: POINT_10_DECIMAL)
              progress
              media {
                id
                idMal
                title {
                  romaji
                  english
                  native
                  userPreferred
                }
                coverImage {
                  extraLarge
                  large
                  medium
                  color
                }
                bannerImage
                format
                status
                episodes
                genres
                averageScore
                startDate {
                  year
                }
              }
            }
          }
        }
      }
    ''';

    try {
      final response = await _dio.post(
        '',
        data: {
          'query': query,
          'variables': {
            'userId': _currentUser!.id,
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      final List<Map<String, dynamic>> allEntries = [];
      if (response.statusCode == 200) {
        final lists = response.data?['data']?['MediaListCollection']?['lists'] as List<dynamic>?;
        if (lists != null) {
          for (final l in lists) {
            final entries = l['entries'] as List<dynamic>?;
            if (entries != null) {
              for (final e in entries) {
                allEntries.add(e as Map<String, dynamic>);
              }
            }
          }
        }
      }
      return allEntries;
    } catch (e) {
      return [];
    }
  }
}
