/// 포커스된 칸을 읽어 주는 TTS 백엔드. [Dpad]가 호출합니다.
///
/// 이 라이브러리는 음성 엔진을 포함하지 않습니다. `flutter_tts`,
/// Android `TextToSpeech`, 테스트용 fake, 캡션 바 등을
/// [Dpad.ttsService] / [Dpad.wrap]으로 주입하세요.
///
/// ```dart
/// class FlutterTtsService implements DpadTtsService {
///   final FlutterTts _tts = FlutterTts();
///
///   @override
///   void speak(String text) {
///     // 음성이 끝날 때까지 기다리지 말 것 — 키 이동이 막힙니다.
///     _tts.stop();
///     _tts.speak(text);
///   }
///
///   @override
///   void stop() {
///     _tts.stop();
///   }
/// }
///
/// MaterialApp(
///   builder: Dpad.wrap(ttsService: FlutterTtsService()),
/// )
/// ```
///
/// [Dpad]는 [DpadFocusable.ttsLabel]이 있는 칸이 포커스를 받으면 [speak]를
/// 호출하고, 포커스를 잃거나 새 칸에 라벨이 없으면 [stop]을 호출합니다.
/// 호출은 **포커스 이동이 한 프레임 그려진 뒤**에 일어나므로, TTS가
/// 키 입력·하이라이트를 막으면 안 됩니다.
/// 사용자가 빠르게 움직이면 [speak]가 연속 호출되므로, 이전 발화를
/// 큐에 쌓거나 끝날 때까지 기다리지 말고 즉시 중단하세요.
abstract class DpadTtsService {
  /// 새로 포커스된 칸의 [text]를 읽습니다.
  void speak(String text);

  /// 진행 중인 발화를 중단합니다.
  void stop();
}
