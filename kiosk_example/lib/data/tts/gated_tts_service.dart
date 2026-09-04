import 'package:dpad/dpad.dart';
import 'package:flutter/foundation.dart';

import 'flutter_tts_service.dart';

/// [enabled]이 꺼져 있으면 읽지 않습니다.
class GatedTtsService implements DpadTtsService {
  GatedTtsService({
    DpadTtsService? inner,
    required this.enabled,
  }) : _inner = inner ?? FlutterTtsService();

  final DpadTtsService _inner;
  final ValueNotifier<bool> enabled;

  @override
  void speak(String text) {
    if (!enabled.value) {
      _inner.stop();
      return;
    }
    _inner.speak(text);
  }

  @override
  void stop() {
    _inner.stop();
  }
}
