import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../core/utils/format_price.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/option.dart';
import '../../domain/entities/selected_options.dart';
import '../quantity/quantity_dialog.dart';

/// 단일 선택 · 복수 선택 · 수량형. 그룹마다 [DpadRegion]이라 키오스크 상/하가 밴드를 바꿉니다.
Future<SelectedOptions?> showOptionDialog(
  BuildContext context, {
  required MenuItem item,
}) {
  return showDialog<SelectedOptions>(
    context: context,
    builder: (BuildContext context) => DpadScreen(
      debugLabel: 'options',
      ttsLabel: '${item.name} 옵션',
      child: OptionDialog(item: item),
    ),
  );
}

class OptionDialog extends StatefulWidget {
  const OptionDialog({super.key, required this.item});

  final MenuItem item;

  @override
  State<OptionDialog> createState() => _OptionDialogState();
}

class _OptionDialogState extends State<OptionDialog> {
  late SelectedOptions _selected =
      SelectedOptions.defaults(widget.item.options);
  final FocusNode _addButtonNode = FocusNode(debugLabel: '담기');

  static const int _addFocusCount = 3;

  int get _unitPrice =>
      widget.item.price + _selected.extraPrice(widget.item.options);

  /// 고른 추가 옵션 개수 + 수량형 개수. 온도처럼 항상 하나인 단일 선택은 빼니다.
  int get _selectedOptionCount {
    int count = 0;
    for (final Set<String> picked in _selected.multis.values) {
      count += picked.length;
    }
    for (final int quantity in _selected.quantities.values) {
      count += quantity;
    }
    return count;
  }

  void _selectSingle(OptionGroup group, String id) {
    setState(() {
      _selected = _selected.copyWith(
        singles: <String, String>{..._selected.singles, group.id: id},
      );
    });
  }

  void _toggleMulti(OptionGroup group, String id) {
    final int previousCount = _selectedOptionCount;
    setState(() {
      final Set<String> next = Set<String>.of(
        _selected.multis[group.id] ?? const <String>{},
      );
      if (!next.add(id)) {
        next.remove(id);
      }
      _selected = _selected.copyWith(
        multis: <String, Set<String>>{..._selected.multis, group.id: next},
      );
    });
    _focusAddIfReachedCount(previousCount);
  }

  void _setQuantity(OptionGroup group, int value) {
    final int clamped = value.clamp(group.min, group.max);
    final int previousCount = _selectedOptionCount;
    setState(() {
      _selected = _selected.copyWith(
        quantities: <String, int>{..._selected.quantities, group.id: clamped},
      );
    });
    _focusAddIfReachedCount(previousCount);
  }

  void _focusAddIfReachedCount(int previousCount) {
    if (previousCount >= _addFocusCount ||
        _selectedOptionCount < _addFocusCount) {
      return;
    }
    Dpad.of(context).requestFocus(_addButtonNode);
  }

  Future<void> _editQuantity(OptionGroup group) async {
    final int current = _selected.quantities[group.id] ?? group.min;
    final int? next = await showQuantityDialog(
      context,
      title: group.title,
      value: current,
      min: group.min,
      max: group.max,
    );
    if (!mounted || next == null) {
      return;
    }
    _setQuantity(group, next);
  }

  @override
  void dispose() {
    _addButtonNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(widget.item.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: kioskBrown,
                          ),
                        ),
                        const Text(
                          '옵션을 고른 뒤 담기',
                          style: TextStyle(fontSize: 14, color: kioskMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatPrice(_unitPrice)}원',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kioskAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (int i = 0; i < widget.item.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildGroup(
                          widget.item.options[i],
                          autofocusRegion: i == 0,
                        ),
                      ),
                  ],
                ),
              ),
              DpadRegion(
                debugLabel: 'option-actions',
                ttsLabel: '하단바 영역',
                child: Row(
                  children: [
                    Expanded(
                      child: _DialogAction(
                        label: '취소',
                        debugLabel: '취소',
                        filled: false,
                        onSelect: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogAction(
                        label: '담기',
                        debugLabel: '담기',
                        filled: true,
                        focusNode: _addButtonNode,
                        onSelect: () => Navigator.pop(context, _selected),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(OptionGroup group, {required bool autofocusRegion}) {
    switch (group.kind) {
      case OptionKind.single:
        return _OptionBlock(
          title: group.title,
          debugLabel: 'option-${group.id}',
          autofocus: autofocusRegion,
          child: Row(
            children: [
              for (int i = 0; i < group.choices.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == group.choices.length - 1 ? 0 : 10,
                    ),
                    child: _ChoiceChip(
                      choice: group.choices[i],
                      selected:
                          _selected.singles[group.id] == group.choices[i].id,
                      autofocus: autofocusRegion && i == 0,
                      debugLabel: 'option:${group.choices[i].label}',
                      onSelect: () => _selectSingle(group, group.choices[i].id),
                    ),
                  ),
                ),
            ],
          ),
        );
      case OptionKind.multi:
        return _OptionBlock(
          title: group.title,
          debugLabel: 'option-${group.id}',
          child: Row(
            children: [
              for (int i = 0; i < group.choices.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == group.choices.length - 1 ? 0 : 10,
                    ),
                    child: _ChoiceChip(
                      choice: group.choices[i],
                      selected: _selected.multis[group.id]
                              ?.contains(group.choices[i].id) ??
                          false,
                      debugLabel: 'option:${group.choices[i].label}',
                      onSelect: () => _toggleMulti(group, group.choices[i].id),
                    ),
                  ),
                ),
            ],
          ),
        );
      case OptionKind.quantity:
        final int count = _selected.quantities[group.id] ?? group.min;
        return _OptionBlock(
          title: group.title,
          debugLabel: 'option-${group.id}',
          child: Row(
            children: [
              Text(
                group.unitPrice > 0
                    ? '+${formatPrice(group.unitPrice)}원 / ${group.unitLabel}'
                    : group.unitLabel,
                style: const TextStyle(fontSize: 15, color: kioskMuted),
              ),
              const Spacer(),
              _QtyButton(
                label: '−',
                debugLabel: 'option-qty-minus',
                ttsLabel: '${group.title} 감소',
                onSelect: () => _setQuantity(group, count - 1),
              ),
              const SizedBox(width: 8),
              _QtyButton(
                label: '$count',
                debugLabel: 'option-qty-count',
                ttsLabel: '${group.title} $count, 누르면 직접 입력',
                wide: true,
                onSelect: () => _editQuantity(group),
              ),
              const SizedBox(width: 8),
              _QtyButton(
                label: '＋',
                debugLabel: 'option-qty-plus',
                ttsLabel: '${group.title} 증가',
                onSelect: () => _setQuantity(group, count + 1),
              ),
            ],
          ),
        );
    }
  }
}

class _OptionBlock extends StatelessWidget {
  const _OptionBlock({
    required this.title,
    required this.debugLabel,
    required this.child,
    this.autofocus = false,
  });

  final String title;
  final String debugLabel;
  final Widget child;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      debugLabel: debugLabel,
      ttsLabel: title,
      autofocus: autofocus,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kioskFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kioskBrown,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.choice,
    required this.selected,
    required this.onSelect,
    required this.debugLabel,
    this.autofocus = false,
  });

  final OptionChoice choice;
  final bool selected;
  final VoidCallback onSelect;
  final String debugLabel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final String price =
        choice.price > 0 ? '  +${formatPrice(choice.price)}' : '';
    return DpadFocusable(
      autofocus: autofocus,
      debugLabel: debugLabel,
      ttsLabel: '${choice.label}$price${selected ? ', 선택됨' : ''}',
      onSelect: onSelect,
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF1E4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kioskAccent : kioskLine,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              '${choice.label}$price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? kioskAccent : kioskBrown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.label,
    required this.debugLabel,
    required this.ttsLabel,
    required this.onSelect,
    this.wide = false,
  });

  final String label;
  final String debugLabel;
  final String ttsLabel;
  final VoidCallback onSelect;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      debugLabel: debugLabel,
      ttsLabel: ttsLabel,
      onSelect: onSelect,
      child: SizedBox(
        width: wide ? 88 : 56,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kioskLine),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kioskBrown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.debugLabel,
    required this.filled,
    required this.onSelect,
    this.focusNode,
  });

  final String label;
  final String debugLabel;
  final bool filled;
  final VoidCallback onSelect;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      focusNode: focusNode,
      debugLabel: debugLabel,
      ttsLabel: label,
      onSelect: onSelect,
      child: SizedBox(
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: filled ? kioskAccent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: kioskLine, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : kioskBrown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
