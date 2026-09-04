import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../core/utils/format_price.dart';

/// 결제 후 화면. 새 라우트의 [DpadRegion.autofocus]로 포커스가 넘어옵니다.
class OrderCompletePage extends StatelessWidget {
  const OrderCompletePage({
    super.key,
    required this.total,
    required this.count,
  });

  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return DpadScreen(
      debugLabel: 'order-complete',
      ttsLabel: '주문 완료',
      child: Scaffold(
        body: DpadRegion(
          debugLabel: 'order-complete',
          ttsLabel: '처음으로',
          autofocus: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    '주문이 완료되었습니다',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kioskBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count개 · ${formatPrice(total)}원',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kioskAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  DpadFocusable(
                    autofocus: true,
                    debugLabel: 'complete-home',
                    ttsLabel: '처음으로',
                    onSelect: () {
                      Navigator.of(context).popUntil((Route<void> route) {
                        return route.isFirst;
                      });
                    },
                    child: const SizedBox(
                      width: 240,
                      height: 64,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: kioskAccent,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Center(
                          child: Text(
                            '처음으로',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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
}
