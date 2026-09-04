import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// 다이얼로그 오버레이는 자체 [FocusScope]를 가집니다. D-pad 키는
/// 다이얼로그 *안에서* 동작해야 하고, 뒤 페이지로 새면 안 됩니다.
/// 다이얼로그를 닫으면 연 칸으로 포커스가 돌아와야 합니다.
///
/// 이 섹션은 그 보장을 시험하는 놀이터입니다:
///
/// * PIN 키패드 그리드 (전형적인 TV 오버레이),
/// * 세로 선택 목록,
/// * 중첩 확인,
/// * 텍스트 필드 + 액션 버튼.
class DialogsSection extends StatefulWidget {
  const DialogsSection({super.key});

  @override
  State<DialogsSection> createState() => _DialogsSectionState();
}

class _DialogsSectionState extends State<DialogsSection> {
  String? _lastPin;
  String _quality = 'Auto';
  String _profileName = 'Family';

  static const _dialogColor = Color(0xFF161A22);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 32),
      children: [
        const Text(
          'Dialogs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Open a dialog and drive it with the remote. Focus stays trapped '
          'in the overlay — try navigating “past” the buttons. Back dismisses '
          'and returns focus here.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        DpadTheme(
          data: const DpadThemeData(
            effects: [DpadTintEffect(opacity: 0.16)],
          ),
          child: DpadRegion(
            ttsLabel: 'Dialogs',
            debugLabel: 'dialogs-demos',
            memoryKey: 'dialogs-demos',
            child: Column(
              children: [
                _DemoRow(
                  icon: Icons.pin_outlined,
                  title: 'PIN keypad',
                  subtitle: _lastPin == null
                      ? 'Numeric grid inside a dialog'
                      : 'Last PIN: $_lastPin',
                  autofocus: true,
                  onSelect: _openPinKeypad,
                ),
                _DemoRow(
                  icon: Icons.high_quality_rounded,
                  title: 'Choice list',
                  subtitle: 'Playback quality: $_quality',
                  onSelect: _openQualityDialog,
                ),
                _DemoRow(
                  icon: Icons.logout_rounded,
                  title: 'Nested dialogs',
                  subtitle: 'A confirmation stacked on another dialog',
                  onSelect: _openSignOutDialog,
                ),
                _DemoRow(
                  icon: Icons.badge_outlined,
                  title: 'Text field dialog',
                  subtitle: 'Profile name: $_profileName',
                  onSelect: _openRenameDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openPinKeypad() async {
    final String? pin = await showDialog<String>(
      context: context,
      builder: (context) => const _PinKeypadDialog(),
    );
    if (!mounted || pin == null) {
      return;
    }
    setState(() => _lastPin = pin);
  }

  Future<void> _openQualityDialog() async {
    final String? quality = await showDialog<String>(
      context: context,
      builder: (context) => _ChoiceDialog(
        title: 'Playback quality',
        options: const ['Auto', '1080p', '720p', '480p'],
        selected: _quality,
      ),
    );
    if (!mounted || quality == null) {
      return;
    }
    setState(() => _quality = quality);
  }

  Future<void> _openSignOutDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogColor,
        title: const Text('Sign out?'),
        content: const Text(
          'Select Continue to open a second dialog on top of this one. '
          'D-pad focus stays in whichever overlay is on top.',
        ),
        actions: [
          _DialogButton(
            label: 'Cancel',
            autofocus: true,
            onSelect: () => Navigator.pop(context, false),
          ),
          _DialogButton(
            label: 'Continue',
            onSelect: () async {
              final bool? ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: _dialogColor,
                  title: const Text('Are you sure?'),
                  content: const Text(
                    'This is the inner dialog. Back pops only this layer.',
                  ),
                  actions: [
                    _DialogButton(
                      label: 'Go back',
                      autofocus: true,
                      onSelect: () => Navigator.pop(context, false),
                    ),
                    _DialogButton(
                      label: 'Sign out',
                      onSelect: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (context.mounted && ok == true) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Signed out (demo)'),
          width: 320,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openRenameDialog() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: _profileName),
    );
    if (!mounted || name == null || name.isEmpty) {
      return;
    }
    setState(() => _profileName = name);
  }
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSelect,
    this.autofocus = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DpadFocusable(
        autofocus: autofocus,
        debugLabel: 'dialogs:$title',
        ttsLabel: '$title. $subtitle',
        onSelect: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3×4 숫자 키패드 — [showDialog] 이후에도 방향 포커스가 동작함을
/// 가장 분명하게 보여 주는 레이아웃.
class _PinKeypadDialog extends StatefulWidget {
  const _PinKeypadDialog();

  @override
  State<_PinKeypadDialog> createState() => _PinKeypadDialogState();
}

class _PinKeypadDialogState extends State<_PinKeypadDialog> {
  static const List<List<String>> _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', 'OK'],
  ];

  String _pin = '';

  void _onKey(String key) {
    switch (key) {
      case 'C':
        setState(() => _pin = '');
      case 'OK':
        Navigator.pop(context, _pin);
      default:
        if (_pin.length < 4) {
          setState(() => _pin += key);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: const Color(0xFF161A22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter PIN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use the d-pad. Focus cannot escape this dialog.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Text(
                _pin.isEmpty ? '····' : _pin.padRight(4, '·'),
                key: const Key('pin-display'),
                style: TextStyle(
                  fontSize: 28,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              DpadRegion(
                ttsLabel: 'PIN keypad',
                debugLabel: 'pin-keypad',
                horizontalEdge: DpadEdgeBehavior.stop,
                verticalEdge: DpadEdgeBehavior.stop,
                child: Column(
                  children: [
                    for (int row = 0; row < _keys.length; row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            for (int col = 0; col < _keys[row].length; col++)
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: _KeypadKey(
                                    label: _keys[row][col],
                                    autofocus: row == 0 && col == 0,
                                    onSelect: () => _onKey(_keys[row][col]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.onSelect,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DpadFocusable(
      autofocus: autofocus,
      debugLabel: 'pin:$label',
      ttsLabel: switch (label) {
        'C' => 'Clear',
        'OK' => 'OK',
        _ => label,
      },
      onSelect: onSelect,
      builder: (context, state, child) {
        final bool special = label == 'C' || label == 'OK';
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state.focused
                ? scheme.primary
                : Colors.white.withAlpha(special ? 28 : 14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: state.focused ? scheme.onPrimary : Colors.white,
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

class _ChoiceDialog extends StatelessWidget {
  const _ChoiceDialog({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161A22),
      title: Text(title),
      content: DpadRegion(
        ttsLabel: title,
        debugLabel: 'choice-list',
        verticalEdge: DpadEdgeBehavior.stop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DpadFocusable(
                  autofocus: options[i] == selected,
                  debugLabel: 'choice:${options[i]}',
                  ttsLabel: options[i],
                  onSelect: () => Navigator.pop(context, options[i]),
                  builder: (context, state, child) {
                    final scheme = Theme.of(context).colorScheme;
                    final bool isSelected = options[i] == selected;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: state.focused
                            ? scheme.primary
                            : Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[i],
                              style: TextStyle(
                                color: state.focused
                                    ? scheme.onPrimary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: state.focused
                                  ? scheme.onPrimary
                                  : scheme.primary,
                            ),
                        ],
                      ),
                    );
                  },
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161A22),
      title: const Text('Rename profile'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Arrows edit the caret inside the field, then leave it at '
              'the edge so you can reach Save / Cancel.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                filled: true,
                hintText: 'Profile name',
              ),
            ),
          ],
        ),
      ),
      actions: [
        _DialogButton(
          label: 'Cancel',
          onSelect: () => Navigator.pop(context),
        ),
        _DialogButton(
          label: 'Save',
          onSelect: _save,
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
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
