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
/// [Dpad]는 포커스가 바뀌면 안내 문구를 조합해 [speak]를 호출합니다.
///
/// * **화면 진입** ([DpadScreen]이 바뀜) — 스크린 → 영역 → 칸 순.
/// * **영역 이동** (같은 화면) — 영역 → 칸 순.
/// * **같은 영역 안** — 칸만.
///
/// 빈 라벨은 건너뜁니다. 포커스를 잃거나 읽을 문구가 없으면 [stop]을
/// 호출합니다. 호출은 **포커스 이동이 한 프레임 그려진 뒤**에 일어나므로,
/// TTS가 키 입력·하이라이트를 막으면 안 됩니다.
/// 사용자가 빠르게 움직이면 [speak]가 연속 호출되므로, 이전 발화를
/// 큐에 쌓거나 끝날 때까지 기다리지 말고 즉시 중단하세요.
abstract class DpadTtsService {
  /// 새로 포커스된 칸의 [text]를 읽습니다.
  void speak(String text);

  /// 진행 중인 발화를 중단합니다.
  void stop();
}

/// 화면 / 영역 / 칸 TTS 조각을 한 문장으로 만듭니다.
///
/// 읽을 조각이 없으면 `null`입니다. 같은 문구가 연속이면 한 번만 넣습니다.
String? composeTtsAnnouncement({
  required bool screenChanged,
  required bool regionChanged,
  String? screenLabel,
  String? regionLabel,
  String? tileLabel,
  bool tileIsRegionHost = false,
}) {
  final List<String> parts = <String>[];
  if (screenChanged) {
    _addTtsPart(parts, screenLabel);
  }
  if (screenChanged || regionChanged) {
    _addTtsPart(parts, regionLabel);
  }
  if (!tileIsRegionHost) {
    _addTtsPart(parts, tileLabel);
  } else if (parts.isEmpty) {
    _addTtsPart(parts, tileLabel);
  }
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(', ');
}

void _addTtsPart(List<String> parts, String? label) {
  if (label == null || label.isEmpty) {
    return;
  }
  if (parts.isNotEmpty && parts.last == label) {
    return;
  }
  parts.add(label);
}
