import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import 'api_providers.dart';

class UserProfileData {
  final String pronoun;
  final String bio;
  final String? username;
  final String? avatarUrl;
  final String? bannerUrl;
  final List<String> favoriteGenres;
  final DateTime? usernameLastChangedAt;

  const UserProfileData({
    this.pronoun = 'el/lui',
    this.bio = '',
    this.username,
    this.avatarUrl,
    this.bannerUrl,
    this.favoriteGenres = const [],
    this.usernameLastChangedAt,
  });

  /// Calculează câte zile au mai rămas până când utilizatorul își poate schimba din nou @handle-ul
  int get daysUntilUsernameChangeAllowed {
    if (usernameLastChangedAt == null) return 0;
    final diffDays = DateTime.now().difference(usernameLastChangedAt!).inDays;
    if (diffDays >= 14) return 0;
    return 14 - diffDays;
  }

  /// True dacă utilizatorul poate edita handle-ul chiar acum
  bool get canChangeUsername => daysUntilUsernameChangeAllowed <= 0;

  /// Data exactă când handle-ul redevine editabil
  DateTime? get nextUsernameChangeDate {
    if (usernameLastChangedAt == null) return null;
    return usernameLastChangedAt!.add(const Duration(days: 14));
  }

  UserProfileData copyWith({
    String? pronoun,
    String? bio,
    String? username,
    String? avatarUrl,
    String? bannerUrl,
    List<String>? favoriteGenres,
    DateTime? usernameLastChangedAt,
    bool clearUsernameLastChangedAt = false,
  }) {
    return UserProfileData(
      pronoun: pronoun ?? this.pronoun,
      bio: bio ?? this.bio,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      usernameLastChangedAt: clearUsernameLastChangedAt
          ? null
          : (usernameLastChangedAt ?? this.usernameLastChangedAt),
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileData> {
  final ApiClient? _apiClient;

  UserProfileNotifier([this._apiClient]) : super(const UserProfileData()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    // 1. Instant local load from SharedPreferences (0ms UI latency)
    try {
      final prefs = await SharedPreferences.getInstance();
      final pronoun = prefs.getString('kurogane_user_pronoun') ?? 'el/lui';
      String bio = prefs.getString('kurogane_user_bio') ?? '';
      if (bio == 'Anime & Manga Enthusiast • Membru Kurogane Universe' ||
          bio == 'Entuziast Anime & Manga pe Kurogane.') {
        bio = '';
        await prefs.setString('kurogane_user_bio', '');
      }
      final username = prefs.getString('kurogane_user_name');
      final avatarUrl = prefs.getString('kurogane_user_avatar');
      final bannerUrl = prefs.getString('kurogane_user_banner');
      final rawChangedAt = prefs.getString('kurogane_user_username_changed_at');
      final usernameLastChangedAt = rawChangedAt != null ? DateTime.tryParse(rawChangedAt) : null;

      state = UserProfileData(
        pronoun: pronoun,
        bio: bio,
        username: username,
        avatarUrl: avatarUrl,
        bannerUrl: bannerUrl,
        usernameLastChangedAt: usernameLastChangedAt,
      );
    } catch (_) {}

    // 2. Asynchronously reconcile with Backend & Cloud Database
    await syncFromBackend();
  }

  Future<void> syncFromBackend() async {
    if (_apiClient == null) return;
    try {
      final profileMap = await _apiClient.getProfile();
      if (profileMap != null && profileMap['profile'] != null) {
        final profile = profileMap['profile'] as Map<String, dynamic>;
        String? bio = profile['bio'] as String?;
        if (bio == 'Anime & Manga Enthusiast • Membru Kurogane Universe' ||
            bio == 'Entuziast Anime & Manga pe Kurogane.') {
          bio = '';
        }
        final pronouns = profile['pronouns'] as String?;
        final username = profile['username'] as String?;
        final avatarUrl = profile['avatarUrl'] as String?;
        final bannerUrl = profile['bannerUrl'] as String?;
        final favGenres = (profile['favoriteGenres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final rawChangedAt = profile['usernameLastChangedAt'] as String? ?? profile['username_changed_at'] as String?;
        final usernameLastChangedAt = rawChangedAt != null ? DateTime.tryParse(rawChangedAt) : null;

        final prefs = await SharedPreferences.getInstance();
        if (bio != null) await prefs.setString('kurogane_user_bio', bio);
        if (pronouns != null) await prefs.setString('kurogane_user_pronoun', pronouns);
        if (username != null) await prefs.setString('kurogane_user_name', username);
        if (avatarUrl != null) await prefs.setString('kurogane_user_avatar', avatarUrl);
        if (bannerUrl != null) await prefs.setString('kurogane_user_banner', bannerUrl);

        if (rawChangedAt != null) {
          await prefs.setString('kurogane_user_username_changed_at', rawChangedAt);
        } else {
          // Backend-ul este sursa unică de adevăr: dacă pe backend e null, deblocăm și pe mobil
          await prefs.remove('kurogane_user_username_changed_at');
        }

        state = state.copyWith(
          bio: bio ?? state.bio,
          pronoun: pronouns ?? state.pronoun,
          username: username ?? state.username,
          avatarUrl: avatarUrl ?? state.avatarUrl,
          bannerUrl: bannerUrl ?? state.bannerUrl,
          favoriteGenres: favGenres.isNotEmpty ? favGenres : state.favoriteGenres,
          usernameLastChangedAt: usernameLastChangedAt,
          clearUsernameLastChangedAt: rawChangedAt == null,
        );
      }
    } catch (e) {
      debugPrint('[UserProfileNotifier] Backend profile sync notice: $e');
    }
  }

  Future<void> updateProfile({
    String? pronoun,
    String? bio,
    String? username,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    final isChangingUsername = username != null &&
        username.trim().isNotEmpty &&
        username.trim().toLowerCase() != (state.username ?? '').trim().toLowerCase();

    // 1. Salvare optimistică locală pentru bio / pronume / avatar
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pronoun != null) await prefs.setString('kurogane_user_pronoun', pronoun);
      if (bio != null) await prefs.setString('kurogane_user_bio', bio);
      if (avatarUrl != null) await prefs.setString('kurogane_user_avatar', avatarUrl);
      if (bannerUrl != null) await prefs.setString('kurogane_user_banner', bannerUrl);
    } catch (_) {}

    state = state.copyWith(
      pronoun: pronoun ?? state.pronoun,
      bio: bio ?? state.bio,
      avatarUrl: avatarUrl ?? state.avatarUrl,
      bannerUrl: bannerUrl ?? state.bannerUrl,
    );

    // 2. Persistență sigură către API Backend & Supabase Cloud
    if (_apiClient != null) {
      try {
        await _apiClient.updateProfile(
          username: username,
          bio: bio,
          pronouns: pronoun,
          avatarUrl: avatarUrl,
          bannerUrl: bannerUrl,
        );

        // Numai DUPĂ ce backend-ul confirmă succesul, salvăm noul username și activăm cooldown-ul
        final prefs = await SharedPreferences.getInstance();
        if (username != null) {
          await prefs.setString('kurogane_user_name', username);
        }
        if (isChangingUsername) {
          final now = DateTime.now();
          await prefs.setString('kurogane_user_username_changed_at', now.toIso8601String());
          state = state.copyWith(
            username: username,
            usernameLastChangedAt: now,
          );
        } else {
          state = state.copyWith(username: username ?? state.username);
        }
      } catch (e) {
        debugPrint('[UserProfileNotifier] Error updating backend profile: $e');
        // Dacă backend-ul a respins sau a dat eroare, reconciliem starea cu backend-ul
        await syncFromBackend();
        rethrow;
      }
    }
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileData>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserProfileNotifier(client);
});

/// Setări & Preferințe Globale
class AppSettingsData {
  // Afișare & Conținut
  final String language; // 'ro' | 'en'
  final bool adultContentFilter;
  final bool spoilerBlur;
  final bool antiReviewBombing;

  // Notificări
  final bool notifyNewEpisodes;
  final bool notifyNewSeasons;
  final bool notifyAppUpdates;

  // Sincronizare & Date
  final String syncFrequency; // 'auto' | 'manual'
  final bool syncWifiOnly;

  // Privacitate
  final bool isProfilePublic;
  final bool hideRecentActivity;

  const AppSettingsData({
    this.language = 'ro',
    this.adultContentFilter = true,
    this.spoilerBlur = true,
    this.antiReviewBombing = true,
    this.notifyNewEpisodes = true,
    this.notifyNewSeasons = true,
    this.notifyAppUpdates = false,
    this.syncFrequency = 'auto',
    this.syncWifiOnly = false,
    this.isProfilePublic = true,
    this.hideRecentActivity = false,
  });

  AppSettingsData copyWith({
    String? language,
    bool? adultContentFilter,
    bool? spoilerBlur,
    bool? antiReviewBombing,
    bool? notifyNewEpisodes,
    bool? notifyNewSeasons,
    bool? notifyAppUpdates,
    String? syncFrequency,
    bool? syncWifiOnly,
    bool? isProfilePublic,
    bool? hideRecentActivity,
  }) {
    return AppSettingsData(
      language: language ?? this.language,
      adultContentFilter: adultContentFilter ?? this.adultContentFilter,
      spoilerBlur: spoilerBlur ?? this.spoilerBlur,
      antiReviewBombing: antiReviewBombing ?? this.antiReviewBombing,
      notifyNewEpisodes: notifyNewEpisodes ?? this.notifyNewEpisodes,
      notifyNewSeasons: notifyNewSeasons ?? this.notifyNewSeasons,
      notifyAppUpdates: notifyAppUpdates ?? this.notifyAppUpdates,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      syncWifiOnly: syncWifiOnly ?? this.syncWifiOnly,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      hideRecentActivity: hideRecentActivity ?? this.hideRecentActivity,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsData> {
  AppSettingsNotifier() : super(const AppSettingsData()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AppSettingsData(
        language: prefs.getString('setting_language') ?? 'ro',
        adultContentFilter: prefs.getBool('setting_adult_filter') ?? true,
        spoilerBlur: prefs.getBool('setting_spoiler_blur') ?? true,
        antiReviewBombing: prefs.getBool('setting_anti_review_bombing') ?? true,
        notifyNewEpisodes: prefs.getBool('setting_notify_episodes') ?? true,
        notifyNewSeasons: prefs.getBool('setting_notify_seasons') ?? true,
        notifyAppUpdates: prefs.getBool('setting_notify_updates') ?? false,
        syncFrequency: prefs.getString('setting_sync_freq') ?? 'auto',
        syncWifiOnly: prefs.getBool('setting_sync_wifi_only') ?? false,
        isProfilePublic: prefs.getBool('setting_profile_public') ?? true,
        hideRecentActivity: prefs.getBool('setting_hide_recent') ?? false,
      );
    } catch (_) {}
  }

  Future<void> updateSetting({
    String? language,
    bool? adultContentFilter,
    bool? spoilerBlur,
    bool? antiReviewBombing,
    bool? notifyNewEpisodes,
    bool? notifyNewSeasons,
    bool? notifyAppUpdates,
    String? syncFrequency,
    bool? syncWifiOnly,
    bool? isProfilePublic,
    bool? hideRecentActivity,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (language != null) await prefs.setString('setting_language', language);
      if (adultContentFilter != null) await prefs.setBool('setting_adult_filter', adultContentFilter);
      if (spoilerBlur != null) await prefs.setBool('setting_spoiler_blur', spoilerBlur);
      if (antiReviewBombing != null) await prefs.setBool('setting_anti_review_bombing', antiReviewBombing);
      if (notifyNewEpisodes != null) await prefs.setBool('setting_notify_episodes', notifyNewEpisodes);
      if (notifyNewSeasons != null) await prefs.setBool('setting_notify_seasons', notifyNewSeasons);
      if (notifyAppUpdates != null) await prefs.setBool('setting_notify_updates', notifyAppUpdates);
      if (syncFrequency != null) await prefs.setString('setting_sync_freq', syncFrequency);
      if (syncWifiOnly != null) await prefs.setBool('setting_sync_wifi_only', syncWifiOnly);
      if (isProfilePublic != null) await prefs.setBool('setting_profile_public', isProfilePublic);
      if (hideRecentActivity != null) await prefs.setBool('setting_hide_recent', hideRecentActivity);
    } catch (_) {}

    state = state.copyWith(
      language: language,
      adultContentFilter: adultContentFilter,
      spoilerBlur: spoilerBlur,
      antiReviewBombing: antiReviewBombing,
      notifyNewEpisodes: notifyNewEpisodes,
      notifyNewSeasons: notifyNewSeasons,
      notifyAppUpdates: notifyAppUpdates,
      syncFrequency: syncFrequency,
      syncWifiOnly: syncWifiOnly,
      isProfilePublic: isProfilePublic,
      hideRecentActivity: hideRecentActivity,
    );
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsData>((ref) {
  return AppSettingsNotifier();
});
