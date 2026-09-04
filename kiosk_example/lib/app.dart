import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/repositories/in_memory_cart_repository.dart';
import 'data/repositories/in_memory_menu_repository.dart';
import 'data/tts/gated_tts_service.dart';
import 'domain/usecases/get_menus.dart';
import 'presentation/cart/cart_controller.dart';
import 'presentation/cart/cart_scope.dart';
import 'presentation/help/help_page.dart';
import 'presentation/menu/menu_page.dart';
import 'presentation/search/search_page.dart';
import 'presentation/session/kiosk_session.dart';
import 'presentation/session/session_scope.dart';
import 'presentation/settings/settings_page.dart';

/// 합성 루트. 의존성을 여기서만 만듭니다.
///
/// ```
/// Dpad.wrap  →  SessionScope  →  CartScope  →  MenuPage
/// ```
class KioskApp extends StatefulWidget {
  const KioskApp({super.key});

  @override
  State<KioskApp> createState() => _KioskAppState();
}

class _KioskAppState extends State<KioskApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final KioskSession _session = KioskSession();
  final CartController _cart = CartController(InMemoryCartRepository());
  final GetMenus _getMenus = const GetMenus(InMemoryMenuRepository());
  late final GatedTtsService _tts = GatedTtsService(
    enabled: _session.ttsEnabled,
  );

  @override
  void dispose() {
    _session.dispose();
    _cart.dispose();
    super.dispose();
  }

  NavigatorState? get _nav => _navigatorKey.currentState;

  void _push(Widget page) {
    _nav?.push(
      MaterialPageRoute<void>(builder: (BuildContext context) => page),
    );
  }

  bool _onBack() {
    final NavigatorState? navigator = _nav;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: CartScope(
        controller: _cart,
        child: MaterialApp(
          title: 'Dpad Kiosk',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFEE7203),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF4F2EF),
          ),
          builder: (BuildContext context, Widget? child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _session.debugOverlay,
              builder: (BuildContext context, bool overlay, _) {
                return Dpad(
                  ttsService: _tts,
                  navPolicy: DpadNavPolicy.kiosk,
                  debugOverlay: overlay,
                  onBack: _onBack,
                  onMenu: () => _push(const HelpPage()),
                  onFocusChange: (FocusNode? node) {
                    if (node != null && _session.clickSounds.value) {
                      SystemSound.play(SystemSoundType.click);
                    }
                  },
                  shortcuts: <LogicalKeyboardKey, VoidCallback>{
                    LogicalKeyboardKey.f1: () => _push(const HelpPage()),
                    LogicalKeyboardKey.f2: () =>
                        _push(SearchPage(getMenus: _getMenus)),
                    LogicalKeyboardKey.f3: () => _push(const SettingsPage()),
                  },
                  theme: const DpadThemeData(
                    effects: [
                      DpadBorderEffect(
                        color: Color(0xFF3749FF),
                        fillColor: Color(0x263749FF),
                        width: 6,
                        borderRadius: BorderRadius.zero,
                        duration: Duration.zero,
                      ),
                    ],
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
          home: MenuPage(getMenus: _getMenus),
        ),
      ),
    );
  }
}
