import 'package:dpad/dpad.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// [flutter_tts]를 [DpadTtsService]에 붙입니다.
///
/// [speak] / [stop]은 await 하지 않습니다. 끝나면 다음 키를 막는
/// `awaitSpeakCompletion(true)`도 켜지 않습니다.
class DpadTtsServiceImpl implements DpadTtsService {
  DpadTtsServiceImpl() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> _init() async {
    await _tts.awaitSpeakCompletion(false);
    await _tts.setLanguage('ko-KR');
  }

  @override
  void speak(String text) {
    if (text.isEmpty) {
      stop();
      return;
    }
    _tts.stop();
    _tts.speak(text);
  }

  @override
  void stop() {
    _tts.stop();
  }
}
