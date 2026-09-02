import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anilist_sync_service.dart';
import 'api_providers.dart';

class AnilistState {
  final bool isInitialized;
  final bool isLoading;
  final AnilistUser? user;
  final String? errorMessage;
  final bool isSyncing;

  bool get isConnected => user != null;

  const AnilistState({
    this.isInitialized = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isSyncing = false,
  });

  AnilistState copyWith({
    bool? isInitialized,
    bool? isLoading,
    AnilistUser? user,
    String? errorMessage,
    bool? isSyncing,
    bool clearUser = false,
  }) {
    return AnilistState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class AnilistNotifier extends StateNotifier<AnilistState> {
  final AnilistSyncService _service;
  final Ref _ref;

  AnilistNotifier(this._service, this._ref) : super(const AnilistState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _service.init();
    state = state.copyWith(
      isInitialized: true,
      isLoading: false,
      user: _service.currentUser,
    );
  }

  /// Conectare cu Token AniList
  Future<bool> connect(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.connectWithToken(token);
      state = state.copyWith(
        isLoading: false,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Deconectare AniList
  Future<void> disconnect() async {
    await _service.disconnect();
    state = state.copyWith(clearUser: true);
  }

  /// Sincronizează o intrare cu AniList
  Future<bool> syncMedia({
    required int anilistMediaId,
    required String status,
    double? score,
    int? progress,
    String? startedAt,
    String? completedAt,
  }) async {
    if (!state.isConnected) return false;
    return await _service.saveMediaListEntry(
      anilistMediaId: anilistMediaId,
      status: status,
      score: score,
      progress: progress,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  /// Importă întreaga listă AniList în Kurogane Watchlist
  Future<int> importCollectionToKurogane() async {
    if (!state.isConnected) return 0;
    state = state.copyWith(isSyncing: true);

    try {
      final rawEntries = await _service.fetchUserMediaCollection();
      int importedCount = 0;

      for (final entry in rawEntries) {
        final mediaIdNum = entry['mediaId'] as num?;
        if (mediaIdNum == null) continue;

        final rawStatus = entry['status'] as String? ?? 'CURRENT';
        String kuroganeStatus = 'WATCHING';
        switch (rawStatus.toUpperCase()) {
          case 'CURRENT':
            kuroganeStatus = 'WATCHING';
            break;
          case 'PLANNING':
            kuroganeStatus = 'PLAN_TO_WATCH';
            break;
          case 'COMPLETED':
            kuroganeStatus = 'COMPLETED';
            break;
          case 'PAUSED':
            kuroganeStatus = 'ON_HOLD';
            break;
          case 'DROPPED':
            kuroganeStatus = 'DROPPED';
            break;
        }

        final score = (entry['score'] as num?)?.toDouble();
        final progress = (entry['progress'] as num?)?.toInt() ?? 0;

        try {
          await _ref.read(watchlistProvider.notifier).updateItem(
            mediaId: 'anilist-$mediaIdNum',
            status: kuroganeStatus,
            score: (score != null && score > 0) ? score : null,
            progressEpisodes: progress,
          );
          importedCount++;
        } catch (_) {}
      }

      await _ref.read(watchlistProvider.notifier).fetchWatchlist(isSilent: true);
      state = state.copyWith(isSyncing: false);
      return importedCount;
    } catch (_) {
      state = state.copyWith(isSyncing: false);
      return 0;
    }
  }
}

final anilistServiceProvider = Provider<AnilistSyncService>((ref) {
  return AnilistSyncService();
});

final anilistProvider = StateNotifierProvider<AnilistNotifier, AnilistState>((ref) {
  final service = ref.watch(anilistServiceProvider);
  return AnilistNotifier(service, ref);
});
