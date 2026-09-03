import '../../models/media_item.dart';

/// Helper dinamic pentru detectarea și formatarea sezonului și episodului.
/// ZERO HARDCODING:
/// 1. Extrage numărul sezonului din titlu conform convențiilor internaționale (Season 3, 3rd Season, Part 2, Cifre romane III/IV/V etc.).
/// 2. Verifică graful de relații (prequel-uri TV în lanț) dacă titlul nu are indicator numeric.
/// 3. Formatează adecvat în funcție de tipul media:
///    - Anime / TV episodic: "S3 E5", "S1 E18"
///    - Filme (MOVIE): "Movie"
///    - Manga / Manhwa / Webtoon: "Ch. 5"
///    - OVA / ONA / Special: "OVA E2", "ONA E5", "Special E1"
class MediaProgressFormatter {
  /// Extrage dinamic numărul sezonului (1, 2, 3...) pe baza titlurilor și a arborelui de relații.
  static int extractSeasonNumber({
    required String title,
    String? englishTitle,
    String? romajiTitle,
    List<MediaRelation>? relations,
  }) {
    final candidateTitles = [title, englishTitle ?? '', romajiTitle ?? '']
        .where((t) => t.trim().isNotEmpty)
        .toList();

    for (final t in candidateTitles) {
      // 1. Pattern direct: "Season 3", "Season 03", "S3", "S03"
      final sMatch = RegExp(r'(?:\bSeason\s*|\bS)(\d{1,2})\b', caseSensitive: false).firstMatch(t);
      if (sMatch != null) {
        final val = int.tryParse(sMatch.group(1)!);
        if (val != null && val > 0 && val < 50) return val;
      }

      // 2. Pattern ordinal: "2nd Season", "3rd Season", "4th Season", "1st Season"
      final ordinalMatch = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)\s+Season\b', caseSensitive: false).firstMatch(t);
      if (ordinalMatch != null) {
        final val = int.tryParse(ordinalMatch.group(1)!);
        if (val != null && val > 0 && val < 50) return val;
      }

      // 3. Pattern de continuare: "Part 2", "Part 3", "Cour 2", "Cour 3"
      final partMatch = RegExp(r'\b(?:Part|Cour)\s*(\d{1,2})\b', caseSensitive: false).firstMatch(t);
      if (partMatch != null) {
        final val = int.tryParse(partMatch.group(1)!);
        if (val != null && val > 0 && val < 50) return val;
      }

      // 4. Cifre romane izolate sau la final de titlu (ex: "Overlord IV", "Mob Psycho 100 III", "Date A Live V", "Working!!")
      final romanMatch = RegExp(
        r'(?:^|[\s:_\-–—])(X|IX|VIII|VII|VI|V|IV|III|II)(?:$|[\s:_\-–—])',
        caseSensitive: true,
      ).firstMatch(t);
      if (romanMatch != null) {
        final roman = romanMatch.group(1)!;
        switch (roman) {
          case 'II': return 2;
          case 'III': return 3;
          case 'IV': return 4;
          case 'V': return 5;
          case 'VI': return 6;
          case 'VII': return 7;
          case 'VIII': return 8;
          case 'IX': return 9;
          case 'X': return 10;
        }
      }
    }

    // 5. Analiză relații canonice (Prequels): dacă titlul nu specifică numărul,
    // numărăm câte prequel-uri TV există în arborele de relații al seriei
    if (relations != null && relations.isNotEmpty) {
      int prequels = 0;
      for (final rel in relations) {
        final type = rel.relationType.toUpperCase();
        if (type == 'PREQUEL' || type == 'PARENT') {
          final fmt = rel.format?.toUpperCase();
          if (fmt == 'TV' || fmt == 'TV_SHORT' || fmt == 'ONA' || fmt == null) {
            prequels++;
          }
        }
      }
      if (prequels > 0) {
        return prequels + 1;
      }
    }

    // 6. Implicit: primul sezon pentru serii episodice
    return 1;
  }

  /// Formatează eticheta dinamică de progres:
  /// - TV / Anime episodic: "S3 E5" (sau "S1 E18")
  /// - Movie: "Movie"
  /// - Manga / Manhwa / Webtoon: "Ch. 5"
  /// - OVA / ONA / Special: "OVA E2" / "Special E1"
  static String formatSeasonEpisode({
    MediaItem? media,
    required int episodeProgress,
    String? fallbackTitle,
    String? fallbackFormat,
    String? fallbackType,
  }) {
    final format = (media?.format ?? fallbackFormat ?? '').toUpperCase();
    final type = (media?.type ?? fallbackType ?? 'ANIME').toUpperCase();

    // 1. Filme
    if (format == 'MOVIE' || type == 'MOVIE') {
      return 'Movie';
    }

    // 2. Literatură / Benzi desenate asiatice (Manga, Manhwa, Manhua, Webtoon)
    if (type == 'MANGA' || type == 'MANHWA' || type == 'MANHUA' || type == 'WEBTOON') {
      final ch = episodeProgress > 0 ? episodeProgress : 1;
      return 'Ch. $ch';
    }

    // 3. Format OVA
    if (format == 'OVA') {
      final ep = episodeProgress > 0 ? episodeProgress : 1;
      return 'OVA E$ep';
    }

    // 4. Format ONA
    if (format == 'ONA') {
      final ep = episodeProgress > 0 ? episodeProgress : 1;
      final s = extractSeasonNumber(
        title: media?.title.userPreferred ?? fallbackTitle ?? '',
        englishTitle: media?.title.english,
        romajiTitle: media?.title.romaji,
        relations: media?.relations,
      );
      return s > 1 ? 'S$s E$ep' : 'ONA E$ep';
    }

    // 5. Speciale
    if (format == 'SPECIAL') {
      final ep = episodeProgress > 0 ? episodeProgress : 1;
      return 'Special E$ep';
    }

    // 6. Serii TV standard / Anime episodic
    final title = media?.title.userPreferred ?? fallbackTitle ?? '';
    final s = extractSeasonNumber(
      title: title,
      englishTitle: media?.title.english,
      romajiTitle: media?.title.romaji,
      relations: media?.relations,
    );
    final ep = episodeProgress > 0 ? episodeProgress : 1;

    return 'S$s E$ep';
  }
}
