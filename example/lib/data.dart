import 'package:flutter/material.dart';

/// 가짜 카탈로그 항목. 포스터는 그라데이션으로 그려 데모가 오프라인에서도 돕니다.
class Movie {
  const Movie({
    required this.title,
    required this.tagline,
    required this.colors,
    required this.icon,
    required this.year,
    required this.rating,
    required this.duration,
    this.progress,
  });

  final String title;
  final String tagline;
  final List<Color> colors;
  final IconData icon;
  final int year;
  final String rating;
  final String duration;

  /// "Continue Watching" 줄의 시청 진행도 0..1.
  final double? progress;
}

class MovieRow {
  const MovieRow(this.title, this.movies);

  final String title;
  final List<Movie> movies;
}

const _palettes = <List<Color>>[
  [Color(0xFF7F00FF), Color(0xFFE100FF)],
  [Color(0xFF396AFC), Color(0xFF2948FF)],
  [Color(0xFFFF512F), Color(0xFFDD2476)],
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFFFC4A1A), Color(0xFFF7B733)],
  [Color(0xFF360033), Color(0xFF0B8793)],
  [Color(0xFF834D9B), Color(0xFFD04ED6)],
  [Color(0xFF0F2027), Color(0xFF2C5364)],
  [Color(0xFF42275A), Color(0xFF734B6D)],
  [Color(0xFF141E30), Color(0xFF243B55)],
];

const _icons = <IconData>[
  Icons.rocket_launch,
  Icons.landscape,
  Icons.bolt,
  Icons.sailing,
  Icons.castle,
  Icons.psychology,
  Icons.public,
  Icons.theater_comedy,
  Icons.directions_car,
  Icons.pets,
];

Movie _movie(int seed, String title, String tagline, {double? progress}) {
  return Movie(
    title: title,
    tagline: tagline,
    colors: _palettes[seed % _palettes.length],
    icon: _icons[seed % _icons.length],
    year: 2017 + seed % 9,
    rating: ['G', 'PG', 'PG-13', 'TV-MA'][seed % 4],
    duration: '${1 + seed % 2} h ${10 + (seed * 7) % 50} min',
    progress: progress,
  );
}

final Movie featured = _movie(
  6,
  'Signals from Andromeda',
  'A lone radio operator hears something that was never meant for Earth.',
);

final List<MovieRow> homeRows = [
  MovieRow('Continue Watching', [
    _movie(0, 'Neon Tide', 'The city sleeps. The grid does not.',
        progress: 0.35),
    _movie(3, 'Greenline', 'Hope grows in unlikely places.', progress: 0.8),
    _movie(7, 'Half Past Twelve', 'A heist with a deadline.', progress: 0.1),
    _movie(9, 'North of Nowhere', 'Two strangers, one storm.', progress: 0.55),
  ]),
  MovieRow('Trending Now', [
    for (int i = 0; i < 12; i++)
      _movie(i + 1, _trendingTitles[i], 'Everyone is watching this one.'),
  ]),
  MovieRow('New Releases', [
    for (int i = 0; i < 12; i++)
      _movie(i + 5, _newTitles[i], 'Fresh from the festival circuit.'),
  ]),
  MovieRow('Critically Acclaimed', [
    for (int i = 0; i < 12; i++)
      _movie(i + 3, _acclaimedTitles[i], 'Five stars across the board.'),
  ]),
];

final List<Movie> library = [
  for (int i = 0; i < 24; i++)
    _movie(
        i, _libraryTitles[i % _libraryTitles.length], 'Saved to your library.'),
];

const _trendingTitles = [
  'Ash & Ember',
  'The Long Orbit',
  'Paper Lanterns',
  'Velocity',
  'Quiet Harbor',
  'The Cartographer',
  'Midnight Sun',
  'Glass Forest',
  'Echo Chamber',
  'The Last Tram',
  'Salt & Stone',
  'Wavelength',
];

const _newTitles = [
  'First Light',
  'The Apiary',
  'Drift',
  'Copper Canyon',
  'Night Market',
  'The Understudy',
  'Polar Low',
  'Sundial',
  'The Archivist',
  'Monsoon Season',
  'Blue Hour',
  'Terminal West',
];

const _acclaimedTitles = [
  'The Weight of Water',
  'Small Hours',
  'A Field in Winter',
  'The Translator',
  'Open Country',
  'The Lighthouse Keeper',
  'Second Spring',
  'Stillwater',
  'The Orchard',
  'Distant Thunder',
  'The Night Garden',
  'Homecoming',
];

const _libraryTitles = [
  'Afterglow',
  'The Silent Coast',
  'Ironwood',
  'Borrowed Time',
  'The Glass Key',
  'Far Country',
  'Lantern Hill',
  'The Hollow Crown',
];
