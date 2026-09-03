import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'pages/home_page.dart';
import 'widgets/tts_caption_bar.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(const DpadTvApp());

class DpadTvApp extends StatelessWidget {
  const DpadTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dpad TV',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1116),
        useMaterial3: true,
      ),
      // builder 하나가 모든 라우트·다이얼로그·시트에 TV 탐색을 설치합니다.
      // (`Dpad.wrap()`도 한 줄로 같습니다. 여기선 포커스 인스펙터를
      // 실시간으로 켜고 끄려고 위젯을 직접 씁니다.)
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: showFocusInspector,
          builder: (context, inspector, _) => Dpad(
            // 모든 DpadFocusable의 앱 전역 스타일·타이밍 기본값.
            theme: const DpadThemeData(scrollPadding: 56),
            // 뒤로 키는 TV 리모컨처럼: 열린 것을 pop하고, 홈에서는
            // 앱을 나가기 전에 확인합니다.
            onBack: _handleBack,
            // 메뉴 키는 도움말 다이얼로그를 엽니다.
            onMenu: _showAbout,
            // 읽어 줄 문구는 DpadFocusable.ttsLabel에서 옵니다.
            ttsService: appTts,
            // 포커스가 움직일 때마다 나는 전형적인 "틱" 소리.
            onFocusChange: (node) {
              if (node != null && clickSounds.value) {
                SystemSound.play(SystemSoundType.click);
              }
            },
            // 앱 수준 단축키 (Search에서 타이핑 중에는 자동으로 멈춤).
            shortcuts: {
              LogicalKeyboardKey.keyH: () => activeSection.value = 0,
              LogicalKeyboardKey.keyL: () => activeSection.value = 1,
              LogicalKeyboardKey.keyS: () => activeSection.value = 2,
              LogicalKeyboardKey.keyD: () => activeSection.value = 3,
              LogicalKeyboardKey.keyI: () =>
                  showFocusInspector.value = !showFocusInspector.value,
              LogicalKeyboardKey.f1: _showAbout,
            },
            // 내장 포커스 인스펙터. Settings에서 켜고 끕니다.
            debugOverlay: inspector,
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const TtsCaptionBar(),
              ],
            ),
          ),
        );
      },
      home: const HomePage(),
    );
  }

  static bool _handleBack() {
    final NavigatorState navigator = _navigatorKey.currentState!;
    if (navigator.canPop()) {
      navigator.pop();
      return true;
    }
    showDialog<void>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        title: const Text('Leave Dpad TV?'),
        content: const Text('Dialogs trap d-pad focus automatically — '
            'try navigating outside.'),
        actions: [
          _DialogAction(
            label: 'Stay',
            autofocus: true,
            onSelect: () => Navigator.pop(context),
          ),
          _DialogAction(
            label: 'Exit',
            onSelect: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    return true;
  }

  static void _showAbout() {
    final BuildContext? context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        title: const Text('Dpad TV demo'),
        content: const Text(
          'Built with the dpad package.\n\n'
          '• Arrow keys / d-pad — move focus\n'
          '• Enter / center — select\n'
          '• Hold center — context menu on posters\n'
          '• Esc / back — back\n'
          '• Menu key or F1 — this dialog\n'
          '• H / L / S / D — jump to a section\n'
          '• I — toggle the focus inspector',
        ),
        actions: [
          _DialogAction(
            label: 'Close',
            autofocus: true,
            onSelect: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onSelect,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      ttsLabel: label,
      onSelect: onSelect,
      effects: const [
        DpadTintEffect(
            opacity: 0.25, borderRadius: BorderRadius.all(Radius.circular(8))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(label),
      ),
    );
  }
}
