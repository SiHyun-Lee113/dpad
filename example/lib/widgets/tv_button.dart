import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// A remote-friendly button built on [DpadFocusable.builder], showing how to
/// take full control of the focus presentation (including the pressed
/// state of the select key).
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onSelect,
    this.icon,
    this.autofocus = false,
    this.entry = false,
  });

  final String label;
  final VoidCallback onSelect;
  final IconData? icon;
  final bool autofocus;
  final bool entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DpadFocusable(
      autofocus: autofocus,
      entry: entry,
      onSelect: onSelect,
      builder: (context, state, child) {
        final Color background = state.focused
            ? (state.pressed ? scheme.primary.withAlpha(204) : scheme.primary)
            : Colors.white.withAlpha(20);
        final Color foreground =
            state.focused ? scheme.onPrimary : Colors.white;
        return AnimatedScale(
          scale: state.pressed
              ? 0.97
              : state.focused
                  ? 1.04
                  : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
