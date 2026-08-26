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
  late final Dio _dio;

  ApiClient({String? customBaseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add Auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token;
          try {
            if (Firebase.apps.isNotEmpty) {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                token = await user.getIdToken(false).timeout(
                  const Duration(milliseconds: 1500),
                  onTimeout: () => null,
                );
                if (token == null || token.isEmpty) {
                  final emailOrUid = user.email ?? user.uid;
                  final displayName = Uri.encodeComponent(user.displayName ?? user.email?.split('@')[0] ?? 'User');
                  token = 'fb-token:$emailOrUid:$displayName';
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

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<HomepageData> getHomepage() async {
    try {
      final response = await _dio.get(ApiConstants.homepage);
      if (response.statusCode == 200 && response.data != null) {
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
    try {
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

      final response = await _dio.get(ApiConstants.search, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
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
      final response = await _dio.get('${ApiConstants.mediaDetail}/$id');
      if (response.statusCode == 200 && response.data != null) {
        return MediaItem.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Error fetching media by id $id: $e');
      return null;
    }
  }

  Future<WatchOrderGuide?> getWatchOrder(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.mediaDetail}/$id/watch-order');
      if (response.statusCode == 200 && response.data != null) {
        return WatchOrderGuide.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Watch order not available for $id: $e');
      return null;
    }
  }

  Future<List<MediaItem>> getSimilarMedia(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.mediaDetail}/$id/similar');
      if (response.statusCode == 200 && response.data != null) {
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
      final response = await _dio.get(ApiConstants.news, queryParameters: {'limit': limit});
      if (response.statusCode == 200 && response.data != null) {
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
      final response = await _dio.get(ApiConstants.watchlist);
      if (response.statusCode == 200 && response.data != null) {
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
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.watchlist,
        data: {
          'mediaId': mediaId,
          'status': status,
          'score': score,
          'progressEpisodes': progressEpisodes,
          'notes': notes,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Error updating watchlist item: $e');
      return false;
    }
  }

  Future<bool> deleteWatchlistItem(String mediaId) async {
    try {
      final response = await _dio.delete('${ApiConstants.watchlist}/$mediaId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Error removing watchlist item: $e');
      return false;
    }
  }
}
