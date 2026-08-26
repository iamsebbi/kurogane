import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileData {
  final String pronoun;
  final String bio;

  const UserProfileData({
    this.pronoun = 'el/lui',
    this.bio = 'Anime & Manga Enthusiast • Membru Kurogane Universe',
  });

  UserProfileData copyWith({
    String? pronoun,
    String? bio,
  }) {
    return UserProfileData(
      pronoun: pronoun ?? this.pronoun,
      bio: bio ?? this.bio,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileData> {
  UserProfileNotifier() : super(const UserProfileData()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pronoun = prefs.getString('kurogane_user_pronoun') ?? 'el/lui';
      final bio = prefs.getString('kurogane_user_bio') ?? 'Anime & Manga Enthusiast • Membru Kurogane Universe';
      state = UserProfileData(pronoun: pronoun, bio: bio);
    } catch (_) {}
  }

  Future<void> updateProfile({String? pronoun, String? bio}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pronoun != null) {
        await prefs.setString('kurogane_user_pronoun', pronoun);
      }
      if (bio != null) {
        await prefs.setString('kurogane_user_bio', bio);
      }
    } catch (_) {}
    state = state.copyWith(pronoun: pronoun, bio: bio);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileData>((ref) {
  return UserProfileNotifier();
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
