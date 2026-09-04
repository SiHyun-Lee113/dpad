import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';

/// 장바구니 수량·옵션 수량형에서 쓰는 숫자 키패드.
/// [DpadRegionFlow.readingOrder] + 다이얼로그 [FocusScope] 가둠을 보여 줍니다.
Future<int?> showQuantityDialog(
  BuildContext context, {
  required String title,
  required int value,
  int min = 1,
  int max = 99,
}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext context) => DpadScreen(
      debugLabel: 'quantity',
      ttsLabel: '$title 입력',
      child: QuantityDialog(
        title: title,
        value: value,
        min: min,
        max: max,
      ),
    ),
  );
}

class QuantityDialog extends StatefulWidget {
  const QuantityDialog({
    super.key,
    required this.title,
    required this.value,
    this.min = 1,
    this.max = 99,
  });

  final String title;
  final int value;
  final int min;
  final int max;

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  static const List<List<String>> _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', 'OK'],
  ];

  late String _digits = widget.value.toString();
  bool _replaceOnNextDigit = true;

  int get _parsed {
    if (_digits.isEmpty) {
      return widget.min;
    }
    return int.tryParse(_digits) ?? widget.min;
  }

  void _onKey(String key) {
    switch (key) {
      case 'C':
        setState(() {
          _digits = '';
          _replaceOnNextDigit = false;
        });
      case 'OK':
        final int clamped = _parsed.clamp(widget.min, widget.max);
        Navigator.pop(context, clamped);
      default:
        setState(() {
          final String next =
              (_replaceOnNextDigit || _digits.isEmpty || _digits == '0')
                  ? key
                  : '$_digits$key';
          _replaceOnNextDigit = false;
          final int? parsed = int.tryParse(next);
          if (parsed == null) {
            return;
          }
          if (parsed > widget.max) {
            _digits = widget.max.toString();
          } else {
            _digits = next;
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kioskBrown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.min} ~ ${widget.max}',
                style: const TextStyle(fontSize: 14, color: kioskMuted),
              ),
              const SizedBox(height: 16),
              Text(
                _digits.isEmpty ? '0' : _digits,
                key: const Key('quantity-display'),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: kioskAccent,
                ),
              ),
              const SizedBox(height: 16),
              DpadRegion(
                debugLabel: 'quantity-keypad',
                ttsLabel: '숫자 키패드',
                autofocus: true,
                flow: DpadRegionFlow.readingOrder,
                child: Column(
                  children: [
                    for (int row = 0; row < _keys.length; row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            for (int col = 0; col < _keys[row].length; col++)
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: _KeypadKey(
                                    label: _keys[row][col],
                                    autofocus: row == 0 && col == 0,
                                    onSelect: () => _onKey(_keys[row][col]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'C 지우기 · OK 확정',
                style: TextStyle(fontSize: 13, color: kioskMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.onSelect,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final bool special = label == 'C' || label == 'OK';
    return DpadFocusable(
      autofocus: autofocus,
      debugLabel: 'qty:$label',
      ttsLabel: switch (label) {
        'C' => '지우기',
        'OK' => '확인',
        _ => label,
      },
      onSelect: onSelect,
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: special ? const Color(0xFFF4E6D8) : const Color(0xFFF4F2EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: special ? kioskAccent : kioskBrown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
