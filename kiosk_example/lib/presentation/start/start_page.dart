import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../domain/usecases/get_menus.dart';
import '../menu/menu_page.dart';
import '../widgets/kiosk_focus_button.dart';

/// 대기 화면. [DpadScreen] 진입 TTS를 확인합니다.
class StartPage extends StatelessWidget {
  const StartPage({
    super.key,
    required this.getMenus,
  });

  final GetMenus getMenus;

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MenuPage(getMenus: getMenus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DpadScreen(
      debugLabel: 'start',
      ttsLabel: '주문 시작',
      child: Scaffold(
        backgroundColor: kioskFill,
        body: DpadRegion(
          debugLabel: 'start-action',
          ttsLabel: '시작',
          autofocus: true,
          child: Center(
            child: SizedBox(
              width: 280,
              child: KioskFocusButton(
                label: '주문하기',
                autofocus: true,
                filled: true,
                height: 72,
                onSelect: () => _start(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
