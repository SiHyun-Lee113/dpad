import 'package:flutter/material.dart';

import '../app_state.dart';

/// 마지막 [DpadTtsService.speak] 호출의 실시간 캡션.
/// 포인터를 통과시켜 포커스 칸이 되지 않습니다.
class TtsCaptionBar extends StatelessWidget {
  const TtsCaptionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appTts.enabled,
      builder: (context, enabled, _) {
        if (!enabled) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<String?>(
          valueListenable: appTts.caption,
          builder: (context, caption, _) {
            if (caption == null || caption.isEmpty) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xE6000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        child: Text(
                          'TTS  $caption',

                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
