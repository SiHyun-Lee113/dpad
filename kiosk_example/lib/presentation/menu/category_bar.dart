import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../domain/entities/menu_item.dart';

/// 카테고리 칩. [DpadEdgeBehavior.wrap] + [DpadRegion.memoryKey].
///
/// [ListView]를 쓰지 않습니다. 가로 스크롤이 포커스를 가로채면
/// 위 키에서 헤더로 못 가고 포커스가 비는 것처럼 보입니다.
class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<MenuCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      debugLabel: 'categories',
      ttsLabel: '카테고리',
      memoryKey: 'kiosk-categories',
      horizontalEdge: DpadEdgeBehavior.wrap,
      enter: DpadEnterBehavior.restore,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Row(
          children: [
            for (int i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _CategoryChip(
                category: categories[i],
                selected: categories[i].id == selectedId,
                onSelect: () => onSelected(categories[i].id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onSelect,
  });

  final MenuCategory category;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      debugLabel: 'category:${category.label}',
      ttsLabel: category.label,
      onSelect: onSelect,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kioskAccent : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? kioskAccent : kioskLine,
          ),
        ),
        child: Text(
          category.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kioskBrown,
          ),
        ),
      ),
    );
  }
}
