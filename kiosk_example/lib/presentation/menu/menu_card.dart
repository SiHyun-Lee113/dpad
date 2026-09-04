import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../core/utils/format_price.dart';
import '../../domain/entities/menu_item.dart';

/// 메뉴 칸. 포커스 이펙트는 앱 [DpadTheme]을 그대로 씁니다.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.menu,
    required this.onSelect,
    this.onLongSelect,
    this.autofocus = false,
    this.entry = false,
  });

  final MenuItem menu;
  final VoidCallback onSelect;
  final VoidCallback? onLongSelect;
  final bool autofocus;
  final bool entry;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      entry: entry,
      debugLabel: menu.name,
      ttsLabel: '${menu.name}, ${formatPrice(menu.price)}원',
      onSelect: onSelect,
      onLongSelect: onLongSelect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kioskCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Text(menu.emoji, style: const TextStyle(fontSize: 48)),
                ),
              ),
              Text(
                menu.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kioskBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatPrice(menu.price)}원~',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kioskAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
