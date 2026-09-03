import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/api_constants.dart';
import '../../models/homepage_data.dart';
import '../../models/media_item.dart';
import '../../models/watch_order.dart';
import '../../models/news_article.dart';
import '../../models/watchlist_item.dart';

class ApiClient {
  late Dio _dio;
  static String? _workingBaseUrl;

  ApiClient({String? customBaseUrl}) {
    final initialBaseUrl = customBaseUrl ?? _workingBaseUrl ?? ApiConstants.baseUrl;
    _dio = _createConfiguredDio(initialBaseUrl);
  }

  static Future<String?> _resolveAuthToken() async {
    String? token;
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          token = await user.getIdToken(false).timeout(
            const Duration(milliseconds: 2500),
            onTimeout: () => null,
          );
          if (token == null || token.isEmpty) {
            try {
              token = await user.getIdToken(true).timeout(
                const Duration(milliseconds: 3000),
                onTimeout: () => null,
              );
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiClient] Token retrieval notice: $e');
    }

    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('kurogane_token');
    }
    return token;
  }

  static Dio _createConfiguredDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _resolveAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }

  Future<Response<dynamic>?> _executeWithFallback(
    Future<Response<dynamic>> Function(Dio dio) requestFn, {
    String? requestTag,
  }) async {
    // 1. Try current working URL first
    try {
      final response = await requestFn(_dio);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        _workingBaseUrl = _dio.options.baseUrl;
        return response;
      }
    } on DioException catch (e) {
      // If the server responded with an HTTP status code (e.g. 404 Not Found),
      // the server is reachable and active! Do NOT failover to other candidate URLs.
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
          return null;
        }
        return e.response;
      }
      debugPrint('[ApiClient] Network failure on ${_dio.options.baseUrl} ${requestTag ?? ""}: $e');
    } catch (e) {
      debugPrint('[ApiClient] Request failed on ${_dio.options.baseUrl} ${requestTag ?? ""}: $e');
    }

    // 2. Try candidate fallback URLs only on true network connection failure
    final currentBase = _dio.options.baseUrl;
    final candidates = ApiConstants.candidateBaseUrls.where((u) => u != currentBase);

    for (final candidateUrl in candidates) {
      try {
        final fallbackDio = _createConfiguredDio(candidateUrl);
        final response = await requestFn(fallbackDio);
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          _workingBaseUrl = candidateUrl;
          _dio = fallbackDio;
          debugPrint('[ApiClient] Switched working baseUrl to $candidateUrl for ${requestTag ?? ""}');
          return response;
        }
      } on DioException catch (e) {
        if (e.response != null) {
          if (e.response!.statusCode == 404) return null;
          return e.response;
        }
        debugPrint('[ApiClient] Candidate $candidateUrl failed for ${requestTag ?? ""}: $e');
      } catch (e) {
        debugPrint('[ApiClient] Candidate $candidateUrl failed for ${requestTag ?? ""}: $e');
      }
    }

    return null;
  }

  Future<Response<dynamic>?> _get(String path, {Map<String, dynamic>? queryParameters}) {
    return _executeWithFallback(
      (dio) => dio.get(path, queryParameters: queryParameters),
      requestTag: 'GET $path',
    );
  }

  Future<Response<dynamic>?> _post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _executeWithFallback(
      (dio) => dio.post(path, data: data, queryParameters: queryParameters),
      requestTag: 'POST $path',
    );
  }

  Future<Response<dynamic>?> _put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _executeWithFallback(
      (dio) => dio.put(path, data: data, queryParameters: queryParameters),
      requestTag: 'PUT $path',
    );
  }

  Future<Response<dynamic>?> _delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _executeWithFallback(
      (dio) => dio.delete(path, data: data, queryParameters: queryParameters),
      requestTag: 'DELETE $path',
    );
  }

  Future<HomepageData> getHomepage() async {
    try {
      final response = await _get(ApiConstants.homepage);
      if (response != null && response.data != null) {
        return HomepageData.fromJson(response.data as Map<String, dynamic>);
      }
      return HomepageData();
    } catch (e) {
      debugPrint('[ApiClient] Error fetching homepage: $e');
      return HomepageData();
    }
  }

  Future<List<MediaItem>> searchMedia({
    String query = '',
    String type = 'ALL',
    String format = 'ALL',
    String status = 'ALL',
    String demographic = 'ALL',
    List<String> genres = const [],
    List<String> microTags = const [],
    String sortBy = 'RELEVANCE',
    double? minScore,
    int page = 1,
    int limit = 30,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'type': type,
      'format': format,
      'status': status,
      'demographic': demographic,
      'sortBy': sortBy,
      'page': page,
      'limit': limit,
    };

    if (genres.isNotEmpty) {
      queryParams['genres'] = genres.join(',');
    }
    if (microTags.isNotEmpty) {
      queryParams['microTags'] = microTags.join(',');
    }
    if (minScore != null && minScore > 0) {
      queryParams['minScore'] = minScore;
    }

    try {
      final response = await _get(ApiConstants.search, queryParameters: queryParams);
      if (response != null && response.data != null) {
        final results = response.data['results'] as List<dynamic>? ?? [];
        return results.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ApiClient] Error searching media: $e');
      return [];
    }
  }

  Future<MediaItem?> getMediaById(String id) async {
    try {
      final response = await _get('${ApiConstants.mediaDetail}/$id');
      if (response != null && response.data != null) {
        return MediaItem.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Error fetching media by id $id: $e');
      return null;
    }
  }

  Future<List<MediaRelation>> getMediaRelations(String id) async {
    try {
      final response = await _get('${ApiConstants.mediaDetail}/$id/relations');
      if (response != null && response.data != null && response.data['relations'] is List) {
        return (response.data['relations'] as List)
            .map((e) => MediaRelation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ApiClient] Error fetching relations for $id: $e');
      return [];
    }
  }

  Future<WatchOrderGuide?> getWatchOrder(String id) async {
    try {
      final response = await _get('${ApiConstants.mediaDetail}/$id/watch-order');
      if (response != null && response.data != null) {
        return WatchOrderGuide.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Watch order not available for $id: $e');
      return null;
    }
  }

  Future<bool> voteWatchOrderPreset(String presetId, int vote) async {
    try {
      final response = await _post(
        '/api/media/watch-order/presets/$presetId/vote',
        data: {'vote': vote},
      );
      if (response != null && response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
      }
      final errorMsg = response?.data?['error']?.toString();
      if (errorMsg != null) {
        throw Exception(errorMsg);
      }
      return false;
    } catch (e) {
      debugPrint('[ApiClient] Error voting preset $presetId: $e');
      rethrow;
    }
  }

  Future<bool> reportWatchOrderPreset(String presetId, String reason) async {
    try {
      final response = await _post(
        '/api/media/watch-order/presets/$presetId/report',
        data: {'reason': reason},
      );
      return response != null && response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      debugPrint('[ApiClient] Error reporting preset $presetId: $e');
      return false;
    }
  }

  Future<WatchOrderPreset?> createWatchOrderPreset(String mediaId, Map<String, dynamic> data) async {
    try {
      final response = await _post(
        '${ApiConstants.mediaDetail}/$mediaId/watch-order/presets',
        data: data,
      );
      if (response != null && response.data != null && response.statusCode == 201) {
        return WatchOrderPreset.fromJson(response.data as Map<String, dynamic>);
      }
      final errorMsg = response?.data?['error']?.toString();
      if (errorMsg != null) {
        throw Exception(errorMsg);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Error creating preset for media $mediaId: $e');
      rethrow;
    }
  }

  Future<List<MediaItem>> getSimilarMedia(String id) async {
    try {
      final response = await _get('${ApiConstants.mediaDetail}/$id/similar');
      if (response != null && response.data != null) {
        final similarList = response.data['similarItems'] as List<dynamic>? ?? [];
        return similarList.map((e) => MediaItem.fromJson(e['item'] as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ApiClient] Error fetching similar media for $id: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> getNews({int limit = 20}) async {
    try {
      final response = await _get(ApiConstants.news, queryParameters: {'limit': limit});
      if (response != null && response.data != null) {
        final articles = response.data['articles'] as List<dynamic>? ?? [];
        return articles.map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ApiClient] Error fetching news: $e');
      return [];
    }
  }

  Future<List<WatchlistItemRecord>> getWatchlist() async {
    try {
      final response = await _get(ApiConstants.watchlist);
      if (response != null && response.data != null) {
        final items = response.data['items'] as List<dynamic>? ?? [];
        return items.map((e) => WatchlistItemRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ApiClient] Error fetching watchlist: $e');
      return [];
    }
  }

  Future<bool> upsertWatchlistItem({
    required String mediaId,
    required String status,
    double? score,
    int progressEpisodes = 0,
    String? notes,
    String? startedAt,
    String? completedAt,
  }) async {
    try {
      final response = await _post(
        ApiConstants.watchlist,
        data: {
          'mediaId': mediaId,
          'status': status,
          'score': score,
          'progressEpisodes': progressEpisodes,
          'notes': notes,
          if (startedAt != null) 'startedAt': startedAt,
          if (completedAt != null) 'completedAt': completedAt,
        },
      );
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Error updating watchlist item: $e');
      return false;
    }
  }

  Future<bool> deleteWatchlistItem(String mediaId) async {
    try {
      final response = await _delete('${ApiConstants.watchlist}/$mediaId');
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Error removing watchlist item: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _get(ApiConstants.profile);
      if (response != null && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Error fetching user profile: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? bio,
    String? pronouns,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    try {
      final response = await _put(
        ApiConstants.profile,
        data: {
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
          if (pronouns != null) 'pronouns': pronouns,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (bannerUrl != null) 'bannerUrl': bannerUrl,
        },
      );
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Error updating user profile: $e');
      return false;
    }
  }
}
