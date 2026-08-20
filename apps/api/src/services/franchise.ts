import { WatchOrderGuide, WatchOrderNode, MediaItem } from '@kurogane/shared';
import { dbService } from './db';

const FRANCHISE_GUIDES: Record<string, WatchOrderGuide> = {
  'naruto-series': {
    franchiseId: 'naruto-series',
    franchiseName: 'Universul Naruto',
    description: 'Calea Ninja a lui Naruto Uzumaki către titlul de Hokage și generația lui Boruto.',
    communityTip:
      '✨ Ghid Naruto: Ordinea canonică este Naruto (Ep. 1-220) ➔ Naruto Shippuuden (Ep. 1-500) ➔ The Last: Naruto the Movie (Vizionează după ep. 493 Shippuuden!) ➔ Boruto: Naruto Next Generations.',
    paths: {
      RECOMMENDED: [
        {
          id: 'naruto-original',
          mediaId: 'anilist-20',
          title: 'Naruto',
          type: 'TV',
          episodesInfo: '220 Episoade (Anii 2002–2007)',
          releaseYear: 2002,
          coverImage: 'https://cdn.myanimelist.net/images/anime/13/11403.jpg',
          orderIndex: 1,
          note: 'Partea I: Copilăria lui Naruto. Episoadele 136-219 sunt filler opțional.',
          isCanon: true,
        },
        {
          id: 'naruto-shippuuden',
          mediaId: 'anilist-1735',
          title: 'Naruto: Shippuuden',
          type: 'TV',
          episodesInfo: '500 Episoade (Anii 2007–2017)',
          releaseYear: 2007,
          coverImage: 'https://cdn.myanimelist.net/images/anime/5/17407.jpg',
          orderIndex: 2,
          note: 'Partea II: Naruto la adolescență și Marele Război Shinobi.',
          isCanon: true,
        },
        {
          id: 'naruto-the-last',
          mediaId: 'anilist-20596',
          title: 'The Last: Naruto the Movie',
          type: 'MOVIE',
          episodesInfo: '1 Film (112 min)',
          releaseYear: 2014,
          coverImage: 'https://cdn.myanimelist.net/images/anime/10/69661.jpg',
          orderIndex: 3,
          note: 'Canon oficial de la Kishimoto: Vizionează înainte de ultimele episoade Shippuuden (ep 494+)!',
          isCanon: true,
        },
        {
          id: 'boruto-movie',
          mediaId: 'anilist-21040',
          title: 'Boruto: Naruto the Movie',
          type: 'MOVIE',
          episodesInfo: '1 Film (95 min)',
          releaseYear: 2015,
          coverImage: 'https://cdn.myanimelist.net/images/anime/4/75806.jpg',
          orderIndex: 4,
          note: 'Examenul Chunin al fiului lui Naruto, Boruto Uzumaki.',
          isCanon: true,
        },
        {
          id: 'boruto-tv',
          mediaId: 'anilist-97938',
          title: 'Boruto: Naruto Next Generations',
          type: 'TV',
          episodesInfo: '293 Episoade',
          releaseYear: 2017,
          coverImage: 'https://cdn.myanimelist.net/images/anime/9/84933.jpg',
          orderIndex: 5,
          note: 'Seria TV a noii generații de ninja din Konoha.',
          isCanon: true,
        },
      ],
      CHRONOLOGICAL: [
        {
          id: 'n-c1',
          mediaId: 'anilist-20',
          title: 'Naruto (Partea I)',
          type: 'TV',
          episodesInfo: '220 Episoade',
          releaseYear: 2002,
          orderIndex: 1,
          isCanon: true,
        },
        {
          id: 'n-c2',
          mediaId: 'anilist-1735',
          title: 'Naruto: Shippuuden (Partea II)',
          type: 'TV',
          episodesInfo: '500 Episoade',
          releaseYear: 2007,
          orderIndex: 2,
          isCanon: true,
        },
        {
          id: 'n-c3',
          mediaId: 'anilist-20596',
          title: 'The Last: Naruto the Movie',
          type: 'MOVIE',
          episodesInfo: '1 Film',
          releaseYear: 2014,
          orderIndex: 3,
          isCanon: true,
        },
        {
          id: 'n-c4',
          mediaId: 'anilist-97938',
          title: 'Boruto: Naruto Next Generations',
          type: 'TV',
          episodesInfo: '293 Episoade',
          releaseYear: 2017,
          orderIndex: 4,
          isCanon: true,
        },
      ],
      RELEASE: [
        {
          id: 'n-r1',
          mediaId: 'anilist-20',
          title: 'Naruto (2002)',
          type: 'TV',
          episodesInfo: '220 Episoade',
          releaseYear: 2002,
          orderIndex: 1,
          isCanon: true,
        },
        {
          id: 'n-r2',
          mediaId: 'anilist-1735',
          title: 'Naruto: Shippuuden (2007)',
          type: 'TV',
          episodesInfo: '500 Episoade',
          releaseYear: 2007,
          orderIndex: 2,
          isCanon: true,
        },
        {
          id: 'n-r3',
          mediaId: 'anilist-20596',
          title: 'The Last: Naruto the Movie (2014)',
          type: 'MOVIE',
          episodesInfo: '1 Film',
          releaseYear: 2014,
          orderIndex: 3,
          isCanon: true,
        },
        {
          id: 'n-r4',
          mediaId: 'anilist-97938',
          title: 'Boruto: Naruto Next Generations (2017)',
          type: 'TV',
          episodesInfo: '293 Episoade',
          releaseYear: 2017,
          orderIndex: 4,
          isCanon: true,
        },
      ],
    },
  },

  'fate-series': {
    franchiseId: 'fate-series',
    franchiseName: 'Universul Fate / Stay Night',
    description: 'Războiul Sfântului Graal: O franciză legendară cu rute multiple, prequel-uri și universuri paralele.',
    communityTip:
      '✨ Ghid Fate: Seria Fate este faimoasă pentru opiniile divizate ale comunității. Ordinea Recomandată (UBW ➔ Heaven\'s Feel ➔ Fate/Zero) previne spoilerele majore din povestea principală. Dacă preferi linia cronologică a evenimentelor istorice, alege Ordinea Cronologică (Fate/Zero [1994] ➔ UBW [2004]).',
    paths: {
      RECOMMENDED: [
        {
          id: 'fate-ubw',
          mediaId: 'anilist-20755',
          title: 'Fate/stay night: Unlimited Blade Works',
          type: 'TV',
          episodesInfo: '25 Episoade (Sezoanele 1 & 2)',
          releaseYear: 2014,
          coverImage: 'https://cdn.myanimelist.net/images/anime/10/67671.jpg',
          orderIndex: 1,
          note: 'Punctul ideal de start! Prezintă universul și ruta lui Rin Tohsaka fără spoilere din VN.',
          isCanon: true,
        },
        {
          id: 'fate-hf-1',
          mediaId: 'anilist-21717',
          title: 'Fate/stay night: Heaven\'s Feel - I. Presage Flower',
          type: 'MOVIE',
          episodesInfo: 'Trilogia de filme (Filmul 1)',
          releaseYear: 2017,
          coverImage: 'https://cdn.myanimelist.net/images/anime/8/88099.jpg',
          orderIndex: 2,
          note: 'Ruta întunecată a Sakurei Matou. Vizionează toate cele 3 filme Heaven\'s Feel aici.',
          isCanon: true,
        },
        {
          id: 'fate-zero',
          mediaId: 'anilist-10087',
          title: 'Fate/Zero',
          type: 'TV',
          episodesInfo: '25 Episoade (Al IV-lea Război)',
          releaseYear: 2011,
          coverImage: 'https://cdn.myanimelist.net/images/anime/2/33947.jpg',
          orderIndex: 3,
          note: 'Prequel-ul maestru regizat de ufotable. Dezvăluie originile lui Kiritsugu și Seiba.',
          isCanon: true,
        },
        {
          id: 'fate-2006',
          mediaId: 'anilist-356',
          title: 'Fate/stay night (Studio Deen)',
          type: 'TV',
          episodesInfo: '24 Episoade (Ruta Saber)',
          releaseYear: 2006,
          coverImage: 'https://cdn.myanimelist.net/images/anime/13/11690.jpg',
          orderIndex: 4,
          note: 'Prima adaptare TV (Ruta originală Saber). Opțională datorită animației mai vechi.',
          isCanon: true,
        },
      ],
      CHRONOLOGICAL: [
        {
          id: 'fate-zero-c',
          mediaId: 'anilist-10087',
          title: 'Fate/Zero (Anul 1994 - Al IV-lea Război)',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2011,
          coverImage: 'https://cdn.myanimelist.net/images/anime/2/33947.jpg',
          orderIndex: 1,
          note: 'Cronologic primul eveniment istoric. Avertisment: conține spoilere pentru finalul Heaven\'s Feel!',
          isCanon: true,
        },
        {
          id: 'fate-ubw-c',
          mediaId: 'anilist-20755',
          title: 'Fate/stay night: Unlimited Blade Works (Anul 2004)',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2014,
          coverImage: 'https://cdn.myanimelist.net/images/anime/10/67671.jpg',
          orderIndex: 2,
          note: 'Evenimentele din al V-lea Război al Graalului la 10 ani după Fate/Zero.',
          isCanon: true,
        },
        {
          id: 'fate-hf-c',
          mediaId: 'anilist-21717',
          title: 'Fate/stay night: Heaven\'s Feel Trilogy',
          type: 'MOVIE',
          episodesInfo: '3 Filme',
          releaseYear: 2017,
          coverImage: 'https://cdn.myanimelist.net/images/anime/8/88099.jpg',
          orderIndex: 3,
          note: 'Concluzia adevărată a războiului din 2004.',
          isCanon: true,
        },
      ],
      RELEASE: [
        {
          id: 'fate-r1',
          mediaId: 'anilist-356',
          title: 'Fate/stay night (2006)',
          type: 'TV',
          episodesInfo: '24 Episoade',
          releaseYear: 2006,
          coverImage: 'https://cdn.myanimelist.net/images/anime/13/11690.jpg',
          orderIndex: 1,
          isCanon: true,
        },
        {
          id: 'fate-r2',
          mediaId: 'anilist-10087',
          title: 'Fate/Zero (2011)',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2011,
          coverImage: 'https://cdn.myanimelist.net/images/anime/2/33947.jpg',
          orderIndex: 2,
          isCanon: true,
        },
        {
          id: 'fate-r3',
          mediaId: 'anilist-20755',
          title: 'Fate/stay night: UBW (2014)',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2014,
          coverImage: 'https://cdn.myanimelist.net/images/anime/10/67671.jpg',
          orderIndex: 3,
          isCanon: true,
        },
        {
          id: 'fate-r4',
          mediaId: 'anilist-21717',
          title: 'Fate/stay night: Heaven\'s Feel Trilogy (2017-2020)',
          type: 'MOVIE',
          episodesInfo: '3 Filme',
          releaseYear: 2017,
          coverImage: 'https://cdn.myanimelist.net/images/anime/8/88099.jpg',
          orderIndex: 4,
          isCanon: true,
        },
      ],
    },
    spinOffs: [
      {
        id: 'fate-apocrypha',
        mediaId: 'anilist-98035',
        title: 'Fate/Apocrypha',
        type: 'TV',
        episodesInfo: '25 Episoade',
        releaseYear: 2017,
        coverImage: 'https://cdn.myanimelist.net/images/anime/4/87023.jpg',
        orderIndex: 1,
        note: 'Univers paralel: Război 7 vs 7 Servanți în România (Trifas).',
        isCanon: false,
      },
      {
        id: 'fate-fgo-babylonia',
        mediaId: 'anilist-103275',
        title: 'Fate/Grand Order: Babylonia',
        type: 'TV',
        episodesInfo: '21 Episoade',
        releaseYear: 2019,
        coverImage: 'https://cdn.myanimelist.net/images/anime/1376/103606.jpg',
        orderIndex: 2,
        note: 'Bazat pe jocul mobil FGO (Singularitatea 7 - Babilonul antic).',
        isCanon: false,
      },
    ],
  },

  'demon-slayer': {
    franchiseId: 'demon-slayer',
    franchiseName: 'Demon Slayer (Kimetsu no Yaiba)',
    description: 'Călătoria lui Tanjiro Kamado pentru răzbunarea familiei și vindecarea surorii sale Nezuko.',
    communityTip:
      '✨ Ghid Demon Slayer: Ordinea este simplă și liniară. Vizionează Sezonul 1 ➔ Filmul Mugen Train (sau varianta TV) ➔ Sezonul 2 (Entertainment District) ➔ Sezonul 3 (Swordsmith Village) ➔ Sezonul 4 (Hashira Training).',
    paths: {
      RECOMMENDED: [
        {
          id: 'ds-s1',
          mediaId: 'anilist-101922',
          title: 'Demon Slayer: Kimetsu no Yaiba (Sezonul 1)',
          type: 'TV',
          episodesInfo: '26 Episoade',
          releaseYear: 2019,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1286/99889.jpg',
          orderIndex: 1,
          note: 'Începutul poveștii și antrenamentul lui Tanjiro.',
          isCanon: true,
        },
        {
          id: 'ds-mugen',
          mediaId: 'anilist-112151',
          title: 'Demon Slayer: Mugen Train Movie',
          type: 'MOVIE',
          episodesInfo: '1 Film (117 min)',
          releaseYear: 2020,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1704/106947.jpg',
          orderIndex: 2,
          note: 'Misiunea alături de Rengoku Kyojuro (Flame Hashira).',
          isCanon: true,
        },
        {
          id: 'ds-s2',
          mediaId: 'anilist-129874',
          title: 'Demon Slayer: Entertainment District Arc (Sezonul 2)',
          type: 'TV',
          episodesInfo: '11 Episoade',
          releaseYear: 2021,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1908/120036.jpg',
          orderIndex: 3,
          note: 'Lupta spectaculoasă alături de Tengen Uzui (Sound Hashira).',
          isCanon: true,
        },
        {
          id: 'ds-s3',
          mediaId: 'anilist-145139',
          title: 'Demon Slayer: Swordsmith Village Arc (Sezonul 3)',
          type: 'TV',
          episodesInfo: '11 Episoade',
          releaseYear: 2023,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1765/135099.jpg',
          orderIndex: 4,
          note: 'Satul făurarilor de săbii, Muichiro și Mitsuri.',
          isCanon: true,
        },
        {
          id: 'ds-s4',
          mediaId: 'anilist-166240',
          title: 'Demon Slayer: Hashira Training Arc (Sezonul 4)',
          type: 'TV',
          episodesInfo: '8 Episoade',
          releaseYear: 2024,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1899/141695.jpg',
          orderIndex: 5,
          note: 'Antrenamentul intensiv înainte de bătălia finală.',
          isCanon: true,
        },
      ],
      CHRONOLOGICAL: [
        {
          id: 'ds-c1',
          mediaId: 'anilist-101922',
          title: 'Demon Slayer (Sezonul 1)',
          type: 'TV',
          episodesInfo: '26 Episoade',
          releaseYear: 2019,
          orderIndex: 1,
          isCanon: true,
        },
        {
          id: 'ds-c2',
          mediaId: 'anilist-112151',
          title: 'Mugen Train Movie',
          type: 'MOVIE',
          episodesInfo: '1 Film',
          releaseYear: 2020,
          orderIndex: 2,
          isCanon: true,
        },
        {
          id: 'ds-c3',
          mediaId: 'anilist-129874',
          title: 'Entertainment District Arc',
          type: 'TV',
          episodesInfo: '11 Episoade',
          releaseYear: 2021,
          orderIndex: 3,
          isCanon: true,
        },
        {
          id: 'ds-c4',
          mediaId: 'anilist-145139',
          title: 'Swordsmith Village Arc',
          type: 'TV',
          episodesInfo: '11 Episoade',
          releaseYear: 2023,
          orderIndex: 4,
          isCanon: true,
        },
      ],
      RELEASE: [
        {
          id: 'ds-r1',
          mediaId: 'anilist-101922',
          title: 'Demon Slayer S1 (2019)',
          type: 'TV',
          episodesInfo: '26 Episoade',
          releaseYear: 2019,
          orderIndex: 1,
          isCanon: true,
        },
        {
          id: 'ds-r2',
          mediaId: 'anilist-112151',
          title: 'Mugen Train Movie (2020)',
          type: 'MOVIE',
          episodesInfo: '1 Film',
          releaseYear: 2020,
          orderIndex: 2,
          isCanon: true,
        },
        {
          id: 'ds-r3',
          mediaId: 'anilist-129874',
          title: 'Entertainment District Arc (2021)',
          type: 'TV',
          episodesInfo: '11 Episoade',
          releaseYear: 2021,
          orderIndex: 3,
          isCanon: true,
        },
      ],
    },
  },

  'attack-on-titan': {
    franchiseId: 'attack-on-titan',
    franchiseName: 'Attack on Titan (Shingeki no Kyojin)',
    description: 'Lupta omenirii împotriva titanilor din spatele Zidurilor.',
    communityTip:
      '✨ Ghid Attack on Titan: Seria se vizionează în ordinea sezoanelor: Sezonul 1 ➔ Sezonul 2 ➔ Sezonul 3 (Partea 1 & 2) ➔ The Final Season (Partea 1, 2, 3, 4).',
    paths: {
      RECOMMENDED: [
        {
          id: 'aot-s1',
          mediaId: 'anilist-16498',
          title: 'Attack on Titan (Sezonul 1)',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2013,
          coverImage: 'https://cdn.myanimelist.net/images/anime/10/47347.jpg',
          orderIndex: 1,
          note: 'Căderea Zidului Maria și căderea districtului Shiganshina.',
          isCanon: true,
        },
        {
          id: 'aot-s2',
          mediaId: 'anilist-20958',
          title: 'Attack on Titan (Sezonul 2)',
          type: 'TV',
          episodesInfo: '12 Episoade',
          releaseYear: 2017,
          coverImage: 'https://cdn.myanimelist.net/images/anime/4/84177.jpg',
          orderIndex: 2,
          note: 'Descoperirea titanilor din interiorul zidurilor.',
          isCanon: true,
        },
        {
          id: 'aot-s3',
          mediaId: 'anilist-99147',
          title: 'Attack on Titan (Sezonul 3)',
          type: 'TV',
          episodesInfo: '22 Episoade (Part 1 & 2)',
          releaseYear: 2018,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1517/92363.jpg',
          orderIndex: 3,
          note: 'Recucerirea districtului Shiganshina și adevărul din subsol.',
          isCanon: true,
        },
        {
          id: 'aot-final',
          mediaId: 'anilist-110277',
          title: 'Attack on Titan: The Final Season',
          type: 'TV',
          episodesInfo: '28 Episoade + Speciale Finale',
          releaseYear: 2020,
          coverImage: 'https://cdn.myanimelist.net/images/anime/1000/110531.jpg',
          orderIndex: 4,
          note: 'Războiul din Marley și Zguduirea Lumii (Rumbling).',
          isCanon: true,
        },
      ],
      CHRONOLOGICAL: [
        {
          id: 'aot-c1',
          mediaId: 'anilist-16498',
          title: 'Attack on Titan S1',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2013,
          orderIndex: 1,
          isCanon: true,
        },
        {
          id: 'aot-c2',
          mediaId: 'anilist-20958',
          title: 'Attack on Titan S2',
          type: 'TV',
          episodesInfo: '12 Episoade',
          releaseYear: 2017,
          orderIndex: 2,
          isCanon: true,
        },
        {
          id: 'aot-c3',
          mediaId: 'anilist-99147',
          title: 'Attack on Titan S3',
          type: 'TV',
          episodesInfo: '22 Episoade',
          releaseYear: 2018,
          orderIndex: 3,
          isCanon: true,
        },
      ],
      RELEASE: [
        {
          id: 'aot-r1',
          mediaId: 'anilist-16498',
          title: 'Attack on Titan S1 (2013)',
          type: 'TV',
          episodesInfo: '25 Episoade',
          releaseYear: 2013,
          orderIndex: 1,
          isCanon: true,
        },
      ],
    },
  },
};

export class FranchiseService {
  /**
   * Returns Watch Order Guide for a given media ID
   */
  public getWatchOrderGuide(mediaId: string): WatchOrderGuide | null {
    const item = dbService.getMediaById(mediaId);
    const titleLower = item?.title.userPreferred.toLowerCase() || '';

    // 1. Check explicit pre-configured guides
    if (
      mediaId.includes('20') ||
      mediaId.includes('1735') ||
      mediaId.includes('20596') ||
      titleLower.includes('naruto') ||
      titleLower.includes('boruto')
    ) {
      return FRANCHISE_GUIDES['naruto-series'];
    }

    if (
      mediaId.includes('10087') ||
      mediaId.includes('20755') ||
      mediaId.includes('21717') ||
      mediaId.includes('356') ||
      mediaId.includes('98035') ||
      titleLower.includes('fate/')
    ) {
      return FRANCHISE_GUIDES['fate-series'];
    }

    if (
      mediaId.includes('101922') ||
      mediaId.includes('112151') ||
      mediaId.includes('129874') ||
      mediaId.includes('145139') ||
      titleLower.includes('demon slayer') ||
      titleLower.includes('kimetsu no yaiba')
    ) {
      return FRANCHISE_GUIDES['demon-slayer'];
    }

    if (
      mediaId.includes('16498') ||
      mediaId.includes('20958') ||
      mediaId.includes('99147') ||
      titleLower.includes('attack on titan') ||
      titleLower.includes('shingeki no kyojin')
    ) {
      return FRANCHISE_GUIDES['attack-on-titan'];
    }

    // 2. Dynamic Watch Order Builder for all other series
    if (item) {
      return this.buildDynamicWatchOrderGuide(item);
    }

    return null;
  }

  private buildDynamicWatchOrderGuide(item: MediaItem): WatchOrderGuide | null {
    const rootTitle = this.sanitizeRoot(item.title.userPreferred || '');
    if (!rootTitle || rootTitle.length < 3) return null;

    const allLocal = dbService.getAllOfflineMedia();
    const relatedItems = allLocal.filter((m) => {
      const mRoot = this.sanitizeRoot(m.title.userPreferred || '');
      return mRoot.length >= 3 && (mRoot === rootTitle || mRoot.includes(rootTitle) || rootTitle.includes(mRoot));
    });

    if (relatedItems.length === 0) return null;

    // Sort by release year
    const sorted = relatedItems.sort((a, b) => (a.year || 9999) - (b.year || 9999));

    const nodes: WatchOrderNode[] = sorted.map((m, index) => {
      const isMovie = m.format === 'MOVIE';
      const isSpecial = m.format === 'SPECIAL' || m.format === 'OVA';
      return {
        id: `dyn-${m.id}`,
        mediaId: m.id,
        title: m.title.userPreferred,
        type: m.format || 'TV',
        episodesInfo: m.episodes ? `${m.episodes} Episoade` : isMovie ? 'Film' : 'Special / OVA',
        releaseYear: m.year,
        coverImage: m.coverImage?.large,
        orderIndex: index + 1,
        note: isMovie ? 'Film de colecție / Canon' : isSpecial ? 'Episod Special / OVA' : `Sezon lansat în ${m.year || 'N/A'}`,
        isCanon: !isSpecial,
      };
    });

    const mainNodes = nodes.filter((n) => n.isCanon);
    const spinOffs = nodes.filter((n) => !n.isCanon);

    const baseName = item.title.userPreferred.split(/[:\-]/)[0].trim();

    return {
      franchiseId: `dynamic-${rootTitle}`,
      franchiseName: `Universul ${baseName}`,
      description: `Ghidul cronologic și de lansare pentru seria ${baseName}.`,
      communityTip: `✨ Ghid ${baseName}: Ordine cronologică generată pe baza anilor de lansare și a continuității seriei.`,
      paths: {
        RECOMMENDED: nodes,
        CHRONOLOGICAL: nodes,
        RELEASE: nodes,
      },
      spinOffs: spinOffs.length > 0 ? spinOffs : undefined,
    };
  }

  private extractBaseTitle(title: string): string {
    return title
      .replace(/:\s*Shippuuden/i, '')
      .replace(/:\s*Next Generations/i, '')
      .replace(/\s+Season\s+\d+/i, '')
      .replace(/\s+Part\s+\d+/i, '')
      .trim();
  }

  private sanitizeRoot(title: string): string {
    if (!title) return '';
    return title
      .toLowerCase()
      .replace(/:\s*(season|part|cour)\s*\d+/gi, '')
      .replace(/\s+\d+(st|nd|rd|th)?\s+(season|part|cour)/gi, '')
      .replace(/\s+(season|part|cour)\s+\d+/gi, '')
      .replace(/[:\-].*$/, '')
      .replace(/[^a-z0-9]/gi, '');
  }
}

export const franchiseService = new FranchiseService();

