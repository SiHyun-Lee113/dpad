import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../core/utils/format_price.dart';
import '../../domain/entities/cart_line.dart';
import '../quantity/quantity_dialog.dart';

/// 장바구니. [DpadRegionKind.list] / [item] — 화면 상/하에서 한 밴드입니다.
class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.lines,
    required this.total,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSetCount,
    required this.onRemove,
    required this.onPay,
  });

  final List<CartLine> lines;
  final int total;
  final int count;
  final void Function(CartLine line) onDecrement;
  final void Function(CartLine line) onIncrement;
  final void Function(CartLine line, int count) onSetCount;
  final void Function(CartLine line) onRemove;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '장바구니  $count개',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kioskBrown,
              ),
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(28, 8, 28, 8),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '메뉴를 선택하세요',
                        style: TextStyle(fontSize: 16, color: kioskMuted),
                      ),
                    ),
                  )
                : DpadRegion(
                    kind: DpadRegionKind.list,
                    debugLabel: 'cart',
                    ttsLabel: '장바구니',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Column(
                        children: [
                          for (int index = 0; index < lines.length; index++) ...[
                            if (index > 0) const SizedBox(height: 8),
                            _CartRow(
                              line: lines[index],
                              index: index,
                              onDecrement: () => onDecrement(lines[index]),
                              onIncrement: () => onIncrement(lines[index]),
                              onEditCount: () async {
                                final CartLine line = lines[index];
                                final int? next = await showQuantityDialog(
                                  context,
                                  title: '${line.item.name} 수량',
                                  value: line.count,
                                  min: 1,
                                  max: 99,
                                );
                                if (next != null) {
                                  onSetCount(line, next);
                                }
                              },
                              onRemove: () => onRemove(lines[index]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          DpadRegion(
            debugLabel: 'pay',
            ttsLabel: '결제',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: DpadFocusable(
                enabled: onPay != null,
                debugLabel: '결제하기',
                ttsLabel: '결제하기, 합계 ${formatPrice(total)}원',
                onSelect: onPay,
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: onPay == null
                          ? const Color(0xFFDDD4CA)
                          : kioskAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        onPay == null
                            ? '결제하기'
                            : '결제하기  ${formatPrice(total)}원',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.line,
    required this.index,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEditCount,
    required this.onRemove,
  });

  final CartLine line;
  final int index;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEditCount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String options = line.options.summary(line.item.options);
    return DpadRegion(
      kind: DpadRegionKind.item,
      debugLabel: 'cart-row-$index',
      ttsLabel:
          '${line.item.name}, ${line.count}개, ${formatPrice(line.lineTotal)}원',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kioskFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Text(line.item.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${line.item.name}  ×${line.count}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kioskBrown,
                          ),
                        ),
                        if (options.isNotEmpty)
                          Text(
                            options,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: kioskMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatPrice(line.lineTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kioskAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _CartIconButton(
                    label: '−',
                    debugLabel: 'cart-minus-$index',
                    ttsLabel: '${line.item.name} 수량 감소',
                    onSelect: onDecrement,
                  ),
                  _CartIconButton(
                    label: '${line.count}',
                    debugLabel: 'cart-count-$index',
                    ttsLabel: '${line.item.name} 수량 ${line.count}, 누르면 직접 입력',
                    wide: true,
                    onSelect: onEditCount,
                  ),
                  _CartIconButton(
                    label: '＋',
                    debugLabel: 'cart-plus-$index',
                    ttsLabel: '${line.item.name} 수량 증가',
                    onSelect: onIncrement,
                  ),
                  _CartIconButton(
                    label: '삭제',
                    debugLabel: 'cart-delete-$index',
                    ttsLabel: '${line.item.name} 삭제',
                    wide: true,
                    onSelect: onRemove,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton({
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
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: DpadFocusable(
        debugLabel: debugLabel,
        ttsLabel: ttsLabel,
        onSelect: onSelect,
        child: SizedBox(
          width: wide ? 64 : 44,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kioskLine),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kioskBrown,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
