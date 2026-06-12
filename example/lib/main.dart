import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'pages/home_page.dart';

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
      // One builder installs TV navigation for every route, dialog and
      // sheet. (`Dpad.wrap()` does the same in one line — the explicit
      // widget is used here so the focus inspector can be toggled live.)
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: showFocusInspector,
          builder: (context, inspector, _) => Dpad(
            // App-wide styling and timing defaults for every DpadFocusable.
            theme: const DpadThemeData(scrollPadding: 56),
            // Back behaves like a TV remote: pop whatever is open, confirm
            // before leaving the app from the home screen.
            onBack: _handleBack,
            // The menu key opens the help dialog.
            onMenu: _showAbout,
            // The classic focus "tick" on every move.
            onFocusChange: (node) {
              if (node != null && clickSounds.value) {
                SystemSound.play(SystemSoundType.click);
              }
            },
            // App-level shortcuts (autosuspended while typing in Search!).
            shortcuts: {
              LogicalKeyboardKey.keyH: () => activeSection.value = 0,
              LogicalKeyboardKey.keyL: () => activeSection.value = 1,
              LogicalKeyboardKey.keyS: () => activeSection.value = 2,
              LogicalKeyboardKey.keyI: () =>
                  showFocusInspector.value = !showFocusInspector.value,
              LogicalKeyboardKey.f1: _showAbout,
            },
            // The built-in focus inspector, toggled from Settings.
            debugOverlay: inspector,
            child: child ?? const SizedBox.shrink(),
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
          '• H / L / S — jump to a section\n'
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
