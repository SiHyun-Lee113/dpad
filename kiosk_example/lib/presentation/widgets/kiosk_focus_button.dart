import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';

/// 키오스크 버튼. 포커스 이펙트는 [DpadTheme]에 맡깁니다.
class KioskFocusButton extends StatelessWidget {
  const KioskFocusButton({
    super.key,
    required this.label,
    required this.onSelect,
    this.debugLabel,
    this.ttsLabel,
    this.autofocus = false,
    this.enabled = true,
    this.filled = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onSelect;
  final String? debugLabel;
  final String? ttsLabel;
  final bool autofocus;
  final bool enabled;
  final bool filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color background = !enabled
        ? const Color(0xFFDDD4CA)
        : filled
            ? kioskAccent
            : Colors.white;
    return DpadFocusable(
      autofocus: autofocus,
      enabled: enabled,
      debugLabel: debugLabel ?? label,
      ttsLabel: ttsLabel ?? label,
      onSelect: onSelect,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: kioskLine, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: filled || !enabled ? Colors.white : kioskBrown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
