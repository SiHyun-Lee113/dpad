import 'package:dpad/dpad.dart';
import 'package:flutter/foundation.dart';

/// 예제 [DpadTtsService]: 실제 음성 엔진 대신 캡션으로 보여 줍니다.
/// 프로덕션에서는 `flutter_tts`(또는 플랫폼 TTS)로 바꾸세요.
class CaptionTtsService implements DpadTtsService {
  /// [Dpad]가 안내하라고 한 마지막 문자열. 대기/중단이면 null.
  final ValueNotifier<String?> caption = ValueNotifier<String?>(null);

  /// false면 [speak]를 무시합니다. Settings에서 데모를 끌 수 있습니다.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  @override
  void speak(String text) {
    if (!enabled.value) {
      return;
    }
    caption.value = text;
  }

  @override
  void stop() {
    caption.value = null;
  }

  void dispose() {
    caption.dispose();
    enabled.dispose();
  }
}
