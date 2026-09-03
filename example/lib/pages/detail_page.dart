import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets/tv_button.dart';

/// 포스터를 선택하면 push되는 타이틀 페이지.
///
/// 공짜로 얻는 것: 이 라우트가 pop되면 포커스가 연 바로 그 포스터로 돌아갑니다.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.movie});

  final Movie movie;

  static void open(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => DetailPage(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              movie.colors.first.withAlpha(115),
              const Color(0xFF0E1116),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 56),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(movie.icon,
                      size: 96, color: Colors.white.withAlpha(230)),
                  const SizedBox(height: 24),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${movie.year}  ·  ${movie.rating}  ·  ${movie.duration}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 640,
                    child: Text(
                      movie.tagline,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  DpadRegion(
                    debugLabel: 'detail-actions',
                    enter: DpadEnterBehavior.entry,
                    child: Row(
                      children: [
                        TvButton(
                          label: 'Play',
                          icon: Icons.play_arrow_rounded,
                          autofocus: true,
                          entry: true,
                          onSelect: () =>
                              _toast(context, 'Playing ${movie.title}'),
                        ),
                        const SizedBox(width: 12),
                        TvButton(
                          label: 'My list',
                          icon: Icons.add_rounded,
                          onSelect: () => _toast(context, 'Added to your list'),
                        ),
                        const SizedBox(width: 12),
                        TvButton(
                          label: 'Back',
                          icon: Icons.arrow_back_rounded,
                          onSelect: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Episodes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This row wraps around: keep pressing right.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            DpadRegion(
              debugLabel: 'episodes',
              horizontalEdge: DpadEdgeBehavior.wrap,
              child: SizedBox(
                // 카드 높이 + 여유. 포커스 이펙트가 잘리지 않게.
                height: 96 + 28,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
                  itemCount: 8,
                  itemBuilder: (context, index) => _EpisodeCard(
                    movie: movie,
                    index: index,
                    onSelect: () =>
                        _toast(context, 'Playing episode ${index + 1}'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          width: 420,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.movie,
    required this.index,
    required this.onSelect,
  });

  final Movie movie;
  final int index;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: DpadFocusable(
        onSelect: onSelect,
        ttsLabel: 'Episode ${index + 1}',
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Episode ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${22 + (index * 3) % 18} min',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
