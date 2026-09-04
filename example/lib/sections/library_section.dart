import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets/poster_card.dart';

/// 리모컨이 자유롭게 다니는 그리드: 영역 하나, 다시 들어올 때 포커스 메모리,
/// 포커스된 타일이 뷰포트 가장자리에 붙지 않게 자동 스크롤.
class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      ttsLabel: 'Library',
      debugLabel: 'library',
      memoryKey: 'library',
      child: GridView.builder(
        // 패딩을 스크롤 안에 두면, 가장자리 카드가 스케일·글로우해도 잘리지 않습니다.
        padding: const EdgeInsets.all(36),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          childAspectRatio: 240 / 124,
        ),
        itemCount: library.length,
        itemBuilder: (context, index) => PosterCard(
          movie: library[index],
          width: double.infinity,
        ),
      ),
    );
  }
}
