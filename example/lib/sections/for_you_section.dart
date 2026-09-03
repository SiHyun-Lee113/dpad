import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../pages/detail_page.dart';
import '../widgets/poster_card.dart';
import '../widgets/tv_button.dart';

/// 랜딩 섹션: 피처드 배너와 지연 로딩 포스터 줄.
///
/// 각 줄은 자기 [DpadRegion]입니다. 좌/우는 줄 안에 머물고, 상/하는
/// 다음 줄로 가며 그 줄의 첫 포스터에 착지합니다.
class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 가로 패딩은 이 페이지 리스트가 아니라 *각 줄 ListView 안*에 둡니다.
    // 스케일·글로우 이펙트가 줄 가장자리에서 잘리지 않고 패딩으로 그려집니다.
    // Flutter에서 TV 선반을 배치하는 표준 방식입니다.
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: _FeaturedBanner(movie: featured),
        ),
        const SizedBox(height: 24),
        for (final row in homeRows) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 36, 0),
            child: Text(
              row.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _PosterRow(row: row, showProgress: row.title == 'Continue Watching'),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.row, required this.showProgress});

  final MovieRow row;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      debugLabel: 'row:${row.title}',
      memoryKey: 'for-you/${row.title}',
      child: SizedBox(
        // 124px 카드 + 양쪽 16px 여유. 포커스된 카드의 스케일·글로우가
        // 클립 안에 남습니다.
        height: 124 + 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          itemCount: row.movies.length,
          itemBuilder: (context, index) => PosterCard(
            movie: row.movies[index],
            margin: const EdgeInsets.only(right: 16),
            showProgress: showProgress,
            entry: index == 0,
            // 첫 "Continue Watching" 포스터는 테마를 덮어 칸별 이펙트를 보여 줍니다.
            effects: showProgress && index == 0
                ? const [
                    DpadScaleEffect(scale: 1.06),
                    DpadGlowEffect(color: Colors.white, opacity: 0.4),
                    DpadBorderEffect(color: Colors.white),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: movie.colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              movie.icon,
              size: 240,
              color: Colors.white.withAlpha(38),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 48),
              const Text(
                'FEATURED',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 520,
                child: Text(
                  movie.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              const SizedBox(height: 20),
              // 배너 버튼은 자기 영역. Play의 `entry: true`가 착지 타깃이고,
              // autofocus가 앱 전체의 첫 포커스입니다.
              DpadRegion(
                debugLabel: 'banner-actions',
                enter: DpadEnterBehavior.entry,
                // Play에서 왼쪽으로 사이드바에 갈 수 있게.
                horizontalEdge: DpadEdgeBehavior.leave,
                child: Row(
                  children: [
                    TvButton(
                      label: 'Play',
                      icon: Icons.play_arrow_rounded,
                      autofocus: true,
                      entry: true,
                      onSelect: () => DetailPage.open(context, movie),
                    ),
                    const SizedBox(width: 12),
                    TvButton(
                      label: 'More info',
                      icon: Icons.info_outline_rounded,
                      onSelect: () => DetailPage.open(context, movie),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
