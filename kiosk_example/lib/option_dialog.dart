import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'quantity_dialog.dart';
import 'theme.dart';

/// 메뉴 선택 후 뜨는 옵션 다이얼로그.
/// 단일 선택 · 복수 선택 · 수량형을 한 화면에 모아 키오스크 탐색을 시험합니다.
Future<SelectedOptions?> showOptionDialog(
  BuildContext context, {
  required MenuItem item,
}) {
  return showDialog<SelectedOptions>(
    context: context,
    builder: (BuildContext context) => OptionDialog(item: item),
  );
}

class OptionDialog extends StatefulWidget {
  const OptionDialog({super.key, required this.item});

  final MenuItem item;

  @override
  State<OptionDialog> createState() => _OptionDialogState();
}

class _OptionDialogState extends State<OptionDialog> {
  late SelectedOptions _selected = SelectedOptions.defaults(widget.item.options);

  int get _unitPrice =>
      widget.item.price + _selected.extraPrice(widget.item.options);

  void _selectSingle(OptionGroup group, String id) {
    setState(() {
      _selected = _selected.copyWith(
        singles: <String, String>{..._selected.singles, group.id: id},
      );
    });
  }

  void _toggleMulti(OptionGroup group, String id) {
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
  }

  void _setQuantity(OptionGroup group, int value) {
    final int clamped = value.clamp(group.min, group.max);
    setState(() {
      _selected = _selected.copyWith(
        quantities: <String, int>{..._selected.quantities, group.id: clamped},
      );
    });
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 72, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
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
                        Text(
                          '옵션을 고른 뒤 담기',
                          style:
                              const TextStyle(fontSize: 14, color: kioskMuted),
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
                      selected: _selected.singles[group.id] == group.choices[i].id,
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
  });

  final String label;
  final String debugLabel;
  final bool filled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
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
