import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_example/dpad_tts_service_impl.dart';

import 'menu_page.dart';

final GlobalKey<NavigatorState> kioskNavigatorKey = GlobalKey<NavigatorState>();
final DpadTtsServiceImpl kioskTts = DpadTtsServiceImpl();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const KioskExampleApp());
}

class KioskExampleApp extends StatelessWidget {
  const KioskExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dpad Kiosk',
      debugShowCheckedModeBanner: false,
      navigatorKey: kioskNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEE7203),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F2EF),
      ),
      builder: Dpad.wrap(
        ttsService: kioskTts,
        navPolicy: DpadNavPolicy.kiosk,
        onBack: () {
          final NavigatorState? navigator = kioskNavigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return true;
          }
          return false;
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
      ),
      home: const MenuPage(),
    );
  }
}
