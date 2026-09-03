import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/homepage_data.dart';
import '../models/media_item.dart';
import '../models/watch_order.dart';
import '../models/news_article.dart';
import '../models/watchlist_item.dart';
import 'auth_provider.dart';

// ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Homepage Data Provider
final homepageDataProvider = FutureProvider<HomepageData>((ref) async {
  final client = ref.watch(apiClientProvider);
  return await client.getHomepage();
});

// News Provider
final newsListProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return await client.getNews();
});

// Media Detail Family Provider
final mediaDetailProvider = FutureProvider.autoDispose.family<MediaItem?, String>((ref, id) async {
  final client = ref.watch(apiClientProvider);
  return await client.getMediaById(id);
});

// Watch Order Family Provider
final watchOrderProvider = FutureProvider.autoDispose.family<WatchOrderGuide?, String>((ref, id) async {
  final client = ref.watch(apiClientProvider);
  return await client.getWatchOrder(id);
});

// Similar Media Family Provider
final similarMediaProvider = FutureProvider.autoDispose.family<List<MediaItem>, String>((ref, id) async {
  final client = ref.watch(apiClientProvider);
  return await client.getSimilarMedia(id);
});

// Search State & Notifier
class SearchFilterState {
  final String query;
  final String type;
  final String format;
  final String status;
  final String demographic;
  final List<String> genres;
  final List<String> microTags;
  final String sortBy;

  SearchFilterState({
    this.query = '',
    this.type = 'ALL',
    this.format = 'ALL',
    this.status = 'ALL',
    this.demographic = 'ALL',
    this.genres = const [],
    this.microTags = const [],
    this.sortBy = 'RELEVANCE',
  });

  SearchFilterState copyWith({
    String? query,
    String? type,
    String? format,
    String? status,
    String? demographic,
    List<String>? genres,
    List<String>? microTags,
    String? sortBy,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      type: type ?? this.type,
      format: format ?? this.format,
      status: status ?? this.status,
      demographic: demographic ?? this.demographic,
      genres: genres ?? this.genres,
      microTags: microTags ?? this.microTags,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final searchFiltersProvider = StateProvider<SearchFilterState>((ref) {
  return SearchFilterState();
});

final searchResultsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final filters = ref.watch(searchFiltersProvider);

  final results = await client.searchMedia(
    query: filters.query,
    type: filters.type,
    format: filters.format,
    status: filters.status,
    demographic: filters.demographic,
    genres: filters.genres,
    microTags: filters.microTags,
    sortBy: filters.sortBy,
    limit: 50,
  );

  if (results.isNotEmpty) {
    return results;
  }

  // Dacă utilizatorul este în starea inițială Explore (fără query/filtre active),
  // populăm garantat ecranul de Explore cu 30-50 de titluri populare și sezoniere!
  final bool hasActiveFilters = filters.genres.isNotEmpty ||
      filters.microTags.isNotEmpty ||
      filters.type != 'ALL' ||
      filters.format != 'ALL' ||
      filters.status != 'ALL';

  if (!hasActiveFilters && filters.query.trim().isEmpty) {
    try {
      final homeData = await client.getHomepage();
      final Set<String> seenIds = {};
      final List<MediaItem> exploreInitial = [];

      void addItems(List<MediaItem> list) {
        for (final item in list) {
          if (seenIds.add(item.id)) {
            exploreInitial.add(item);
          }
        }
      }

      addItems(homeData.heroItems);
      addItems(homeData.featuredSeason);
      addItems(homeData.topAiring);
      addItems(homeData.trendingSeason);
      addItems(homeData.top100);

      if (exploreInitial.isNotEmpty) {
        return exploreInitial.take(50).toList();
      }
    } catch (_) {}
  }

  return results;
});

// Quick Search Provider (Live Title / Acronym search)
final quickSearchQueryProvider = StateProvider<String>((ref) => '');

final quickSearchResultsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final query = ref.watch(quickSearchQueryProvider).trim();
  if (query.isEmpty) {
    return const [];
  }
  final client = ref.watch(apiClientProvider);
  return await client.searchMedia(query: query);
});

// Watchlist State Notifier
class WatchlistNotifier extends StateNotifier<AsyncValue<List<WatchlistItemRecord>>> {
  final ApiClient _client;

  WatchlistNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchWatchlist();
  }

  Future<void> fetchWatchlist({bool isSilent = false, bool preserveCurrentOrder = false}) async {
    if (!mounted) return;
    if (!isSilent) {
      state = const AsyncValue.loading();
    }
    try {
      final items = await _client.getWatchlist();
      if (!mounted) return;

      // Păstrăm ordinea statică a listei pe ecran dacă este o reconciliere silențioasă sau dacă se solicită explicit
      if ((preserveCurrentOrder || isSilent) && state.value != null && state.value!.isNotEmpty) {
        final currentList = state.value!;
        final orderMap = <String, int>{};
        for (int i = 0; i < currentList.length; i++) {
          orderMap[currentList[i].mediaId] = i;
        }

        items.sort((a, b) {
          final indexA = orderMap[a.mediaId];
          final indexB = orderMap[b.mediaId];
          if (indexA != null && indexB != null) {
            return indexA.compareTo(indexB);
          }
          if (indexA != null) return -1;
          if (indexB != null) return 1;
          return 0;
        });
      }

      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!mounted) return;
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateItem({
    required String mediaId,
    required String status,
    double? score,
    int progressEpisodes = 0,
    String? notes,
    String? startedAt,
    String? completedAt,
  }) async {
    final currentList = state.value;

    // 1. Optimistic Local Update (Instant 0ms UI feedback, zero screen flash/disappearing)
    if (currentList != null) {
      final updatedList = currentList.map((item) {
        if (item.mediaId == mediaId) {
          final total = item.media?.episodes;
          int clamped = progressEpisodes < 0 ? 0 : progressEpisodes;
          if (total != null && total > 0 && clamped > total) {
            clamped = total;
          }
          final newStatus = (total != null && total > 0 && clamped >= total) ? 'COMPLETED' : status;

          final resolvedScore = (score == 0.0) ? null : (score ?? item.score);
          final resolvedStartedAt = startedAt ?? item.startedAt;
          final resolvedCompletedAt = completedAt ?? item.completedAt;

          return WatchlistItemRecord(
            id: item.id,
            userId: item.userId,
            mediaId: item.mediaId,
            status: newStatus,
            score: resolvedScore,
            progressEpisodes: clamped,
            notes: notes ?? item.notes,
            startedAt: resolvedStartedAt,
            completedAt: resolvedCompletedAt,
            mediaItem: item.mediaItem,
            createdAt: item.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return item;
      }).toList();

      state = AsyncValue.data(updatedList);
    }

    // 2. Persist to API and silently reconcile păstrând poziția statică a seriei
    try {
      final resolvedScore = (score == 0.0) ? null : score;
      await _client.upsertWatchlistItem(
        mediaId: mediaId,
        status: status,
        score: resolvedScore,
        progressEpisodes: progressEpisodes,
        notes: notes,
        startedAt: startedAt,
        completedAt: completedAt,
      );
      await fetchWatchlist(isSilent: true, preserveCurrentOrder: true);
    } catch (e) {
      // If error occurs, reload live state păstrând ordinea
      await fetchWatchlist(isSilent: true, preserveCurrentOrder: true);
    }
  }

  Future<void> incrementProgress(WatchlistItemRecord item) async {
    final total = item.media?.episodes;
    if (total != null && total > 0 && item.progressEpisodes >= total) {
      return; // Already reached max episodes
    }
    final nextProgress = item.progressEpisodes + 1;
    final isCompleted = (total != null && total > 0 && nextProgress >= total);

    await updateItem(
      mediaId: item.mediaId,
      status: isCompleted ? 'COMPLETED' : item.status,
      score: item.score,
      progressEpisodes: nextProgress,
      notes: item.notes,
    );
  }

  Future<void> removeItem(String mediaId) async {
    final currentList = state.value;
    if (currentList != null) {
      state = AsyncValue.data(currentList.where((i) => i.mediaId != mediaId).toList());
    }
    try {
      await _client.deleteWatchlistItem(mediaId);
      await fetchWatchlist(isSilent: true, preserveCurrentOrder: true);
    } catch (e) {
      await fetchWatchlist(isSilent: true, preserveCurrentOrder: true);
    }
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, AsyncValue<List<WatchlistItemRecord>>>((ref) {
  final client = ref.watch(apiClientProvider);
  ref.watch(authStateProvider);
  return WatchlistNotifier(client);
});

/// Provider pentru numărul de notificări necitite (0 ascunde bulina roșie conform auditului)
final unreadNotificationsCountProvider = StateProvider<int>((ref) => 0);

