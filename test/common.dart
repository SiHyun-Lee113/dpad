import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 권장 방식(`MaterialApp.builder`)으로 D-pad 루트를 설치한 최소 TV 앱을 만듭니다.
Widget tvApp({
  required Widget home,
  DpadThemeData? theme,
  DpadKeySet keySet = const DpadKeySet(),
  Map<LogicalKeyboardKey, VoidCallback> shortcuts =
      const <LogicalKeyboardKey, VoidCallback>{},
  bool Function()? onBack,
  VoidCallback? onMenu,
  ValueChanged<FocusNode?>? onFocusChange,
  DpadTtsService? ttsService,
  bool debugOverlay = false,
  DpadNavPolicy navPolicy = DpadNavPolicy.tv,
  bool restoreFocus = true,
}) {
  return MaterialApp(
    builder: Dpad.wrap(
      theme: theme,
      keySet: keySet,
      shortcuts: shortcuts,
      onBack: onBack,
      onMenu: onMenu,
      onFocusChange: onFocusChange,
      ttsService: ttsService,
      debugOverlay: debugOverlay,
      navPolicy: navPolicy,
      restoreFocus: restoreFocus,
    ),
    home: Scaffold(body: home),
  );
}

/// 탐색 테스트용. 비주얼 이펙트 없는 포커스 가능한 네모.
Widget item(
  String id,
  FocusNode node, {
  VoidCallback? onSelect,
  VoidCallback? onLongSelect,
  ValueChanged<bool>? onFocusChange,
  DpadDirectionCallback? onDirection,
  bool autofocus = false,
  bool enabled = true,
  bool entry = false,
  String? ttsLabel,
  double size = 60,
  List<DpadEffect> effects = const <DpadEffect>[],
}) {
  return DpadFocusable(
    focusNode: node,
    autofocus: autofocus,
    enabled: enabled,
    entry: entry,
    ttsLabel: ttsLabel ?? id,
    onSelect: onSelect,
    onLongSelect: onLongSelect,
    onFocusChange: onFocusChange,
    onDirection: onDirection,
    effects: effects,
    child: SizedBox(
      width: size,
      height: size,
      child: Center(child: Text(id)),
    ),
  );
}
