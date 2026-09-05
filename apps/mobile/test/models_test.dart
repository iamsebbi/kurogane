import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/watchlist_item.dart';
import 'package:mobile/models/watch_order.dart';
import 'package:mobile/models/media_item.dart';

void main() {
  group('WatchlistItemRecord.fromJson Tests', () {
    test('parses successfully with mediaItem key', () {
      final json = {
        'id': 'witem-1',
        'userId': 'user-123',
        'mediaId': 'anilist-101922',
        'status': 'WATCHING',
        'score': 9.5,
        'progressEpisodes': 12,
        'notes': 'Great series',
        'startedAt': '2025-01-01',
        'completedAt': null,
        'createdAt': '2025-01-01T00:00:00Z',
        'updatedAt': '2025-01-02T00:00:00Z',
        'mediaItem': {
          'id': 'anilist-101922',
          'title': {
            'userPreferred': 'Kimetsu no Yaiba',
            'romaji': 'Kimetsu no Yaiba',
            'english': 'Demon Slayer',
          },
          'coverImage': {
            'extraLarge': 'https://example.com/cover_xl.jpg',
            'large': 'https://example.com/cover_lg.jpg',
          },
          'format': 'TV',
          'episodes': 26,
        },
      };

      final record = WatchlistItemRecord.fromJson(json);

      expect(record.id, 'witem-1');
      expect(record.mediaId, 'anilist-101922');
      expect(record.status, 'WATCHING');
      expect(record.score, 9.5);
      expect(record.progressEpisodes, 12);
      expect(record.startedAt, '2025-01-01');
      expect(record.media, isNotNull);
      expect(record.media?.title.userPreferred, 'Kimetsu no Yaiba');
      expect(record.media?.coverImage.extraLarge, 'https://example.com/cover_xl.jpg');
    });

    test('parses successfully with fallback media key', () {
      final json = {
        'id': 'witem-2',
        'userId': 'user-456',
        'mediaId': 'anilist-154587',
        'status': 'COMPLETED',
        'score': 10.0,
        'progressEpisodes': 28,
        'media': {
          'id': 'anilist-154587',
          'title': {
            'userPreferred': 'Sousou no Frieren',
            'romaji': 'Sousou no Frieren',
            'english': 'Frieren: Beyond Journey\'s End',
          },
          'coverImage': {
            'large': 'https://example.com/frieren.jpg',
          },
          'format': 'TV',
          'episodes': 28,
        },
      };

      final record = WatchlistItemRecord.fromJson(json);

      expect(record.id, 'witem-2');
      expect(record.mediaId, 'anilist-154587');
      expect(record.media, isNotNull);
      expect(record.media?.title.userPreferred, 'Sousou no Frieren');
      expect(record.media?.coverImage.large, 'https://example.com/frieren.jpg');
      expect(record.media?.episodes, 28);
    });

    test('handles missing media gracefully without crashing', () {
      final json = {
        'id': 'witem-3',
        'userId': 'user-789',
        'mediaId': 'anilist-999999',
        'status': 'PLAN_TO_WATCH',
      };

      final record = WatchlistItemRecord.fromJson(json);

      expect(record.id, 'witem-3');
      expect(record.mediaId, 'anilist-999999');
      expect(record.media, isNull);
    });
  });

  group('WatchOrderPresetItem.fromJson Tests', () {
    test('parses preset item with mediaItem map', () {
      final json = {
        'id': 'item-1',
        'presetId': 'preset-1',
        'mediaId': 'anilist-113415',
        'position': 1,
        'isCanon': true,
        'mediaItem': {
          'title': {'userPreferred': 'Jujutsu Kaisen'},
          'coverImage': {'large': 'https://example.com/jjk.jpg'},
          'format': 'TV',
          'year': 2020,
        },
      };

      final item = WatchOrderPresetItem.fromJson(json);

      expect(item.mediaId, 'anilist-113415');
      expect(item.title, 'Jujutsu Kaisen');
      expect(item.coverImage, 'https://example.com/jjk.jpg');
      expect(item.format, 'TV');
      expect(item.year, 2020);
    });

    test('parses preset item with fallback media map', () {
      final json = {
        'mediaId': 'anilist-16498',
        'position': 2,
        'media': {
          'title': {'romaji': 'Shingeki no Kyojin'},
          'coverImage': {'medium': 'https://example.com/aot.jpg'},
          'format': 'TV',
          'year': 2013,
        },
      };

      final item = WatchOrderPresetItem.fromJson(json);

      expect(item.mediaId, 'anilist-16498');
      expect(item.title, 'Shingeki no Kyojin');
      expect(item.coverImage, 'https://example.com/aot.jpg');
    });

    test('parses preset item with string title and coverImage', () {
      final json = {
        'mediaId': 'custom-1',
        'position': 3,
        'media': {
          'title': 'Direct String Title',
          'coverImage': 'https://example.com/direct.jpg',
        },
      };

      final item = WatchOrderPresetItem.fromJson(json);

      expect(item.title, 'Direct String Title');
      expect(item.coverImage, 'https://example.com/direct.jpg');
    });
  });

  group('MediaRelation and MediaCharacter Tests', () {
    test('parses MediaRelation with all fields correctly', () {
      final json = {
        'id': 'anilist-145064',
        'anilistId': 145064,
        'relationType': 'SEQUEL',
        'title': 'Jujutsu Kaisen Season 2',
        'format': 'TV',
        'type': 'ANIME',
        'status': 'FINISHED',
        'releaseYear': 2023,
        'coverImage': 'https://media.kitsu.app/anime/poster_images/45532/medium.jpg',
      };

      final rel = MediaRelation.fromJson(json);

      expect(rel.id, 'anilist-145064');
      expect(rel.anilistId, 145064);
      expect(rel.relationType, 'SEQUEL');
      expect(rel.title, 'Jujutsu Kaisen Season 2');
      expect(rel.format, 'TV');
      expect(rel.releaseYear, 2023);
      expect(rel.coverImage, 'https://media.kitsu.app/anime/poster_images/45532/medium.jpg');
    });

    test('parses MediaCharacter with voiceActor correctly', () {
      final json = {
        'id': 105898,
        'name': 'Satoru Gojou',
        'image': 'https://media.kitsu.app/character/105898/image.jpg',
        'role': 'MAIN',
        'voiceActor': {
          'id': 72,
          'name': 'Yuuichi Nakamura',
          'image': 'https://media.kitsu.app/people/images/72.jpg',
          'language': 'Japanese',
        },
      };

      final char = MediaCharacter.fromJson(json);

      expect(char.id, 105898);
      expect(char.name, 'Satoru Gojou');
      expect(char.role, 'MAIN');
      expect(char.voiceActor, isNotNull);
      expect(char.voiceActor?.name, 'Yuuichi Nakamura');
      expect(char.voiceActor?.language, 'Japanese');
    });
  });
}
