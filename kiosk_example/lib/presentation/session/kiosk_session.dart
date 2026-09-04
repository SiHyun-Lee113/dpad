import 'package:flutter/foundation.dart';

/// 앱 전역 키오스크 설정. [Dpad.debugOverlay] / 포커스 틱에 연결합니다.
class KioskSession {
  final ValueNotifier<bool> debugOverlay = ValueNotifier<bool>(false);
  final ValueNotifier<bool> clickSounds = ValueNotifier<bool>(true);
  final ValueNotifier<bool> ttsEnabled = ValueNotifier<bool>(true);

  void dispose() {
    debugOverlay.dispose();
    clickSounds.dispose();
    ttsEnabled.dispose();
  }
}
