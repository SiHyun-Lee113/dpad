import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../widgets/kiosk_focus_button.dart';

/// 헤더. [DpadController.requestFirstFocus]와 검색·설정 라우트를 연결합니다.
class KioskHeader extends StatelessWidget {
  const KioskHeader({
    super.key,
    required this.title,
    this.onHome,
    this.onSearch,
    this.onSettings,
  });

  final String title;
  final VoidCallback? onHome;
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      debugLabel: 'header',
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white,
        child: Row(
          children: [
            if (onHome != null)
              SizedBox(
                width: 108,
                child: KioskFocusButton(
                  label: '처음으로',
                  debugLabel: '처음으로',
                  onSelect: onHome,
                  height: 44,
                ),
              )
            else
              DpadFocusable(
                debugLabel: '처음으로',
                ttsLabel: '처음으로',
                onSelect: () {},
                child: const Text(
                  '처음으로',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kioskMuted,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: kioskBrown,
                ),
              ),
            ),
            if (onSearch != null)
              SizedBox(
                width: 72,
                child: KioskFocusButton(
                  label: '검색',
                  onSelect: onSearch,
                  height: 44,
                ),
              ),
            if (onSettings != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: KioskFocusButton(
                  label: '설정',
                  onSelect: onSettings,
                  height: 44,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
