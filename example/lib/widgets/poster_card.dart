import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../pages/detail_page.dart';

/// A poster tile driven entirely by [DpadFocusable].
///
/// * select  → opens the detail page
/// * long-select → opens a context sheet (a very TV pattern)
/// * effects come from the app-wide [DpadTheme] unless [effects] overrides
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.movie,
    this.width = 220,
    this.height = 124,
    this.margin = EdgeInsets.zero,
    this.effects,
    this.autofocus = false,
    this.showProgress = false,
  });

  final Movie movie;
  final double width;
  final double height;
  final EdgeInsetsGeometry margin;
  final List<DpadEffect>? effects;
  final bool autofocus;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DpadFocusable(
        autofocus: autofocus,
        effects: effects,
        debugLabel: 'poster:${movie.title}',
        onSelect: () => DetailPage.open(context, movie),
        onLongSelect: () => _showOptions(context),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: movie.colors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    bottom: -12,
                    child: Icon(
                      movie.icon,
                      size: height * 0.85,
                      color: Colors.white.withAlpha(46),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  if (showProgress && movie.progress != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: movie.progress,
                        minHeight: 4,
                        backgroundColor: Colors.black.withAlpha(102),
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.play_arrow_rounded,
                  label: 'Play from beginning',
                  autofocus: true,
                  onSelect: () => Navigator.pop(context),
                ),
                _SheetAction(
                  icon: Icons.add_rounded,
                  label: 'Add to my list',
                  onSelect: () => Navigator.pop(context),
                ),
                _SheetAction(
                  icon: Icons.thumb_up_alt_outlined,
                  label: 'Rate this title',
                  onSelect: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      effects: const [DpadTintEffect(opacity: 0.18)],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            SizedBox(width: 240, child: Text(label)),
          ],
        ),
      ),
    );
  }
}
