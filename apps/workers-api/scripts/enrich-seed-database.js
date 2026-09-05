const fs = require('fs');
const path = require('path');

const seedPath = path.join(__dirname, '../src/data/seed-anime-rich.json');
const raw = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

// 17. Fate/Zero (10087)
if (raw['10087']) {
  raw['10087'].characters = [
    {
      id: 15001,
      name: "Kiritsugu Emiya",
      image: "https://media.kitsu.app/characters/images/15001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 701, name: "Rikiya Koyama", image: "https://media.kitsu.app/people/images/701/original.jpg", language: "Japanese" }
    },
    {
      id: 15002,
      name: "Saber (Artoria Pendragon)",
      image: "https://media.kitsu.app/characters/images/15002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 702, name: "Ayako Kawasumi", image: "https://media.kitsu.app/people/images/702/original.jpg", language: "Japanese" }
    },
    {
      id: 15003,
      name: "Kirei Kotomine",
      image: "https://media.kitsu.app/characters/images/15003/original.jpg",
      role: "MAIN",
      voiceActor: { id: 703, name: "Jouji Nakata", image: "https://media.kitsu.app/people/images/703/original.jpg", language: "Japanese" }
    },
    {
      id: 15004,
      name: "Irisviel von Einzbern",
      image: "https://media.kitsu.app/characters/images/15004/original.jpg",
      role: "SUPPORTING",
      voiceActor: { id: 704, name: "Sayaka Ohara", image: "https://media.kitsu.app/people/images/704/original.jpg", language: "Japanese" }
    }
  ];
  raw['10087'].relations = [
    {
      id: "anilist-11741",
      anilistId: 11741,
      relationType: "SEQUEL",
      title: "Fate/Zero Season 2",
      format: "TV",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2012,
      coverImage: "https://media.kitsu.app/anime/poster_images/6575/medium.jpg"
    },
    {
      id: "anilist-19603",
      anilistId: 19603,
      relationType: "SEQUEL",
      title: "Fate/stay night: Unlimited Blade Works",
      format: "TV",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2014,
      coverImage: "https://media.kitsu.app/anime/poster_images/8089/medium.jpg"
    }
  ];
}

// 18. Koe no Katachi (20954)
if (raw['20954']) {
  raw['20954'].characters = [
    {
      id: 16001,
      name: "Shouya Ishida",
      image: "https://media.kitsu.app/characters/images/16001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 801, name: "Miyu Irino", image: "https://media.kitsu.app/people/images/801/original.jpg", language: "Japanese" }
    },
    {
      id: 16002,
      name: "Shouko Nishimiya",
      image: "https://media.kitsu.app/characters/images/16002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 802, name: "Saori Hayami", image: "https://media.kitsu.app/people/images/802/original.jpg", language: "Japanese" }
    },
    {
      id: 16003,
      name: "Yuzuru Nishimiya",
      image: "https://media.kitsu.app/characters/images/16003/original.jpg",
      role: "SUPPORTING",
      voiceActor: { id: 803, name: "Aoi Yuuki", image: "https://media.kitsu.app/people/images/803/original.jpg", language: "Japanese" }
    }
  ];
  raw['20954'].relations = [
    {
      id: "anilist-85135",
      anilistId: 85135,
      relationType: "ADAPTATION",
      title: "Koe no Katachi Manga",
      format: "MANGA",
      type: "MANGA",
      status: "FINISHED",
      releaseYear: 2013,
      coverImage: "https://media.kitsu.app/manga/poster_images/20954/medium.jpg"
    }
  ];
}

// 19. Kimi no Na wa. (21519)
if (raw['21519']) {
  raw['21519'].characters = [
    {
      id: 17001,
      name: "Taki Tachibana",
      image: "https://media.kitsu.app/characters/images/17001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 901, name: "Ryunosuke Kamiki", image: "https://media.kitsu.app/people/images/901/original.jpg", language: "Japanese" }
    },
    {
      id: 17002,
      name: "Mitsuha Miyamizu",
      image: "https://media.kitsu.app/characters/images/17002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 902, name: "Mone Kamishiraishi", image: "https://media.kitsu.app/people/images/902/original.jpg", language: "Japanese" }
    },
    {
      id: 17003,
      name: "Miki Okudera",
      image: "https://media.kitsu.app/characters/images/17003/original.jpg",
      role: "SUPPORTING",
      voiceActor: { id: 903, name: "Masami Nagasawa", image: "https://media.kitsu.app/people/images/903/original.jpg", language: "Japanese" }
    }
  ];
  raw['21519'].relations = [
    {
      id: "anilist-106286",
      anilistId: 106286,
      relationType: "OTHER",
      title: "Tenki no Ko (Weathering With You)",
      format: "MOVIE",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2019,
      coverImage: "https://media.kitsu.app/anime/poster_images/41992/medium.jpg"
    },
    {
      id: "anilist-87399",
      anilistId: 87399,
      relationType: "ADAPTATION",
      title: "Kimi no Na wa. Manga",
      format: "MANGA",
      type: "MANGA",
      status: "FINISHED",
      releaseYear: 2016,
      coverImage: "https://media.kitsu.app/manga/poster_images/21519/medium.jpg"
    }
  ];
}

// 20. Kaguya-sama (101921)
if (raw['101921']) {
  raw['101921'].characters = [
    {
      id: 18001,
      name: "Kaguya Shinomiya",
      image: "https://media.kitsu.app/characters/images/18001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 951, name: "Aoi Koga", image: "https://media.kitsu.app/people/images/951/original.jpg", language: "Japanese" }
    },
    {
      id: 18002,
      name: "Miyuki Shirogane",
      image: "https://media.kitsu.app/characters/images/18002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 952, name: "Makoto Furukawa", image: "https://media.kitsu.app/people/images/952/original.jpg", language: "Japanese" }
    },
    {
      id: 18003,
      name: "Chika Fujiwara",
      image: "https://media.kitsu.app/characters/images/18003/original.jpg",
      role: "MAIN",
      voiceActor: { id: 953, name: "Konomi Kohara", image: "https://media.kitsu.app/people/images/953/original.jpg", language: "Japanese" }
    },
    {
      id: 18004,
      name: "Yuu Ishigami",
      image: "https://media.kitsu.app/characters/images/18004/original.jpg",
      role: "MAIN",
      voiceActor: { id: 954, name: "Ryouta Suzuki", image: "https://media.kitsu.app/people/images/954/original.jpg", language: "Japanese" }
    }
  ];
  raw['101921'].relations = [
    {
      id: "anilist-112641",
      anilistId: 112641,
      relationType: "SEQUEL",
      title: "Kaguya-sama: Love is War? (Season 2)",
      format: "TV",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2020,
      coverImage: "https://media.kitsu.app/anime/poster_images/42598/medium.jpg"
    },
    {
      id: "anilist-125367",
      anilistId: 125367,
      relationType: "SEQUEL",
      title: "Kaguya-sama: Love is War - Ultra Romantic - (Season 3)",
      format: "TV",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2022,
      coverImage: "https://media.kitsu.app/anime/poster_images/43860/medium.jpg"
    }
  ];
}

// 21. Cyberpunk: Edgerunners (117718)
if (raw['117718']) {
  raw['117718'].characters = [
    {
      id: 19001,
      name: "David Martinez",
      image: "https://media.kitsu.app/characters/images/19001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 971, name: "KENN", image: "https://media.kitsu.app/people/images/971/original.jpg", language: "Japanese" }
    },
    {
      id: 19002,
      name: "Lucy",
      image: "https://media.kitsu.app/characters/images/19002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 972, name: "Aoi Yuuki", image: "https://media.kitsu.app/people/images/972/original.jpg", language: "Japanese" }
    },
    {
      id: 19003,
      name: "Rebecca",
      image: "https://media.kitsu.app/characters/images/19003/original.jpg",
      role: "MAIN",
      voiceActor: { id: 973, name: "Tomoyo Kurosawa", image: "https://media.kitsu.app/people/images/973/original.jpg", language: "Japanese" }
    }
  ];
  raw['117718'].relations = [
    {
      id: "anilist-117719",
      anilistId: 117719,
      relationType: "OTHER",
      title: "Cyberpunk 2077 (Original Video Game)",
      format: "SPECIAL",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2020,
      coverImage: "https://media.kitsu.app/anime/poster_images/43316/medium.jpg"
    }
  ];
}

// 22. Horimiya (124080)
if (raw['124080']) {
  raw['124080'].characters = [
    {
      id: 20001,
      name: "Kyouko Hori",
      image: "https://media.kitsu.app/characters/images/20001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 981, name: "Haruka Tomatsu", image: "https://media.kitsu.app/people/images/981/original.jpg", language: "Japanese" }
    },
    {
      id: 20002,
      name: "Izumi Miyamura",
      image: "https://media.kitsu.app/characters/images/20002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 982, name: "Kouki Uchiyama", image: "https://media.kitsu.app/people/images/982/original.jpg", language: "Japanese" }
    }
  ];
  raw['124080'].relations = [
    {
      id: "anilist-163132",
      anilistId: 163132,
      relationType: "ALTERNATIVE",
      title: "Horimiya: Piece",
      format: "TV",
      type: "ANIME",
      status: "FINISHED",
      releaseYear: 2023,
      coverImage: "https://media.kitsu.app/anime/poster_images/47266/medium.jpg"
    },
    {
      id: "anilist-44701",
      anilistId: 44701,
      relationType: "ADAPTATION",
      title: "Horimiya Manga",
      format: "MANGA",
      type: "MANGA",
      status: "FINISHED",
      releaseYear: 2011,
      coverImage: "https://media.kitsu.app/manga/poster_images/14701/medium.jpg"
    }
  ];
}

// 23. Jigokuraku (145064)
if (raw['145064']) {
  raw['145064'].characters = [
    {
      id: 21001,
      name: "Gabimaru",
      image: "https://media.kitsu.app/characters/images/21001/original.jpg",
      role: "MAIN",
      voiceActor: { id: 991, name: "Chiaki Kobayashi", image: "https://media.kitsu.app/people/images/991/original.jpg", language: "Japanese" }
    },
    {
      id: 21002,
      name: "Sagiri Yamada Asaemon",
      image: "https://media.kitsu.app/characters/images/21002/original.jpg",
      role: "MAIN",
      voiceActor: { id: 992, name: "Yumiri Hanamori", image: "https://media.kitsu.app/people/images/992/original.jpg", language: "Japanese" }
    },
    {
      id: 21003,
      name: "Yuzuriha",
      image: "https://media.kitsu.app/characters/images/21003/original.jpg",
      role: "MAIN",
      voiceActor: { id: 993, name: "Rie Takahashi", image: "https://media.kitsu.app/people/images/993/original.jpg", language: "Japanese" }
    }
  ];
  raw['145064'].relations = [
    {
      id: "anilist-166240",
      anilistId: 166240,
      relationType: "SEQUEL",
      title: "Jigokuraku (Hell's Paradise) Season 2",
      format: "TV",
      type: "ANIME",
      status: "UPCOMING",
      releaseYear: 2026,
      coverImage: "https://media.kitsu.app/anime/poster_images/47416/medium.jpg"
    },
    {
      id: "anilist-100994",
      anilistId: 100994,
      relationType: "ADAPTATION",
      title: "Jigokuraku Manga",
      format: "MANGA",
      type: "MANGA",
      status: "FINISHED",
      releaseYear: 2018,
      coverImage: "https://media.kitsu.app/manga/poster_images/39994/medium.jpg"
    }
  ];
}

// Write enriched file to both locations
fs.writeFileSync(seedPath, JSON.stringify(raw, null, 2), 'utf8');
const scriptsSeedPath = path.join(__dirname, 'seed-anime-rich.json');
if (fs.existsSync(scriptsSeedPath)) {
  fs.writeFileSync(scriptsSeedPath, JSON.stringify(raw, null, 2), 'utf8');
}

console.log('All remaining seed items successfully enriched!');
