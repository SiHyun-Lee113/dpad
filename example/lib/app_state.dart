import 'package:flutter/foundation.dart';

import 'tts/caption_tts_service.dart';

/// 사이드바에서 선택한 섹션 (0 = For you, 1 = Library, 2 = Search,
/// 3 = Dialogs, 4 = Settings). 앱 수준 키 단축키로도 바꿀 수 있게
/// notifier로 올렸습니다.
final ValueNotifier<int> activeSection = ValueNotifier<int>(0);

/// 내장 포커스 인스펙터 ([Dpad.debugOverlay]) 런타임 토글.
/// Settings 섹션에서 켭니다.
final ValueNotifier<bool> showFocusInspector = ValueNotifier<bool>(false);

/// [Dpad.onFocusChange]로 재생하는 포커스 "틱" 소리 런타임 토글.
final ValueNotifier<bool> clickSounds = ValueNotifier<bool>(true);

/// [Dpad.ttsService]에 주입합니다. 캡션 바로 보여주고,
/// 실제 엔진은 프로덕션에서 바꾸세요.
final CaptionTtsService appTts = CaptionTtsService();
