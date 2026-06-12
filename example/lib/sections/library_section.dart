import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets/poster_card.dart';

/// A grid the remote can roam freely: one region, focus memory on re-entry,
/// auto-scroll keeping the focused tile clear of the viewport edges.
class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      debugLabel: 'library',
      memoryKey: 'library',
      child: GridView.builder(
        // Padding sits inside the scrollable, so edge cards can scale and
        // glow into it without being clipped.
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
