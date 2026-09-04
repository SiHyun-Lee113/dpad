import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../menu/kiosk_header.dart';
import '../session/session_scope.dart';

/// 설정. 테마 오버라이드, 비활성 칸, [onDirection] 슬라이더,
/// [DpadController.requestFocus], 이펙트 갤러리, 디버그 오버레이를 보여 줍니다.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FocusNode _volumeNode = FocusNode(debugLabel: 'volume');
  int _volume = 12;
  int _effectIndex = 0;
  String? _lastEdge;

  static const List<(String, List<DpadEffect>)> _effectChoices = [
    ('Scale + border', [DpadScaleEffect(), DpadBorderEffect()]),
    ('Glow', [DpadGlowEffect()]),
    ('Elevation', [DpadScaleEffect(scale: 1.04), DpadElevationEffect()]),
    ('Spotlight', [DpadOpacityEffect(idleOpacity: 0.45)]),
    ('Tint', [DpadTintEffect()]),
    ('Custom', [DpadCustomEffect(_underlineEffect)]),
  ];

  static Widget _underlineEffect(
    BuildContext context,
    DpadFocusState state,
    Widget child,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 4,
          width: state.focused ? 120 : 0,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: kioskAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _volumeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return DpadScreen(
      debugLabel: 'settings',
      ttsLabel: '설정',
      child: Scaffold(
      body: Column(
        children: [
          KioskHeader(
            title: '설정',
            onHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '접근성',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kioskBrown,
                        ),
                      ),
                    ),
                    DpadFocusable(
                      ttsLabel: '안내 음량으로 이동',
                      onSelect: () => Dpad.of(context).requestFocus(_volumeNode),
                      effects: const [DpadBorderEffect()],
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          '음량으로 ↓',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kioskMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DpadTheme(
                  data: const DpadThemeData(
                    effects: [DpadTintEffect(opacity: 0.12, color: kioskAccent)],
                  ),
                  child: DpadRegion(
                    debugLabel: 'settings-a11y',
                    ttsLabel: '접근성',
                    memoryKey: 'kiosk-settings-a11y',
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: session.ttsEnabled,
                          builder: (BuildContext context, bool value, _) {
                            return _ToggleRow(
                              title: 'TTS 안내 (DpadTtsService)',
                              value: value,
                              autofocus: true,
                              onChanged: (bool next) =>
                                  session.ttsEnabled.value = next,
                            );
                          },
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: session.clickSounds,
                          builder: (BuildContext context, bool value, _) {
                            return _ToggleRow(
                              title: '포커스 틱 (Dpad.onFocusChange)',
                              value: value,
                              onChanged: (bool next) =>
                                  session.clickSounds.value = next,
                            );
                          },
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: session.debugOverlay,
                          builder: (BuildContext context, bool value, _) {
                            return _ToggleRow(
                              title: '포커스 인스펙터 (Dpad.debugOverlay)',
                              value: value,
                              onChanged: (bool next) =>
                                  session.debugOverlay.value = next,
                            );
                          },
                        ),
                        const _ToggleRow(
                          title: '관리자 잠금 (준비 중)',
                          value: false,
                          enabled: false,
                          onChanged: _ignore,
                        ),
                        _VolumeRow(
                          focusNode: _volumeNode,
                          volume: _volume,
                          onChanged: (int value) =>
                              setState(() => _volume = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '가장자리 onEdge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kioskBrown,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '가로 stop. 끝에서 좌/우를 누르면 포커스는 남고 onEdge가 호출됩니다.',
                  style: TextStyle(fontSize: 13, color: kioskMuted),
                ),
                const SizedBox(height: 12),
                DpadRegion(
                  debugLabel: 'settings-edge',
                  ttsLabel: '가장자리',
                  horizontalEdge: DpadEdgeBehavior.stop,
                  onEdge: (TraversalDirection direction) {
                    setState(() => _lastEdge = direction.name);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: DpadFocusable(
                          debugLabel: 'edge-left',
                          ttsLabel: '왼쪽 끝',
                          onSelect: () {},
                          child: const _EdgeChip(label: '왼쪽 끝'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DpadFocusable(
                          debugLabel: 'edge-right',
                          ttsLabel: '오른쪽 끝',
                          onSelect: () {},
                          child: const _EdgeChip(label: '오른쪽 끝'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lastEdge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'onEdge: $_lastEdge',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kioskAccent,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                const Text(
                  '포커스 이펙트',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kioskBrown,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '칩 줄은 가로 wrap입니다. 고른 뒤 아래 미리보기를 보세요.',
                  style: TextStyle(fontSize: 13, color: kioskMuted),
                ),
                const SizedBox(height: 12),
                DpadRegion(
                  debugLabel: 'settings-effects',
                  ttsLabel: '포커스 이펙트',
                  horizontalEdge: DpadEdgeBehavior.wrap,
                  enter: DpadEnterBehavior.nearest,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < _effectChoices.length; i++)
                        DpadFocusable(
                          ttsLabel: _effectChoices[i].$1,
                          onSelect: () => setState(() => _effectIndex = i),
                          builder: (
                            BuildContext context,
                            DpadFocusState state,
                            Widget child,
                          ) {
                            final bool selected = i == _effectIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: state.focused
                                    ? kioskAccent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: selected ? kioskBrown : kioskLine,
                                ),
                              ),
                              child: Text(
                                _effectChoices[i].$1,
                                style: TextStyle(
                                  color: state.focused
                                      ? Colors.white
                                      : kioskBrown,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                          child: const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: DpadFocusable(
                    effects: _effectChoices[_effectIndex].$2,
                    ttsLabel: '미리보기, ${_effectChoices[_effectIndex].$1}',
                    onSelect: () {},
                    child: Container(
                      width: 280,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE4CC), Color(0xFFFFF1E4)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _effectChoices[_effectIndex].$1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: kioskBrown,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

void _ignore(bool value) {}

class _EdgeChip extends StatelessWidget {
  const _EdgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kioskLine),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kioskBrown,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DpadFocusable(
        autofocus: autofocus,
        enabled: enabled,
        debugLabel: title,
        ttsLabel: title,
        onSelect: () => onChanged(!value),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kioskLine),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kioskBrown,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Switch(value: value, onChanged: (_) {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.focusNode,
    required this.volume,
    required this.onChanged,
  });

  final FocusNode focusNode;
  final int volume;
  final ValueChanged<int> onChanged;

  static const int _max = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DpadFocusable(
        focusNode: focusNode,
        debugLabel: 'volume',
        ttsLabel: '안내 음량 $volume',
        onDirection: (TraversalDirection direction) {
          switch (direction) {
            case TraversalDirection.left:
              onChanged((volume - 1).clamp(0, _max));
              return true;
            case TraversalDirection.right:
              onChanged((volume + 1).clamp(0, _max));
              return true;
            case TraversalDirection.up:
            case TraversalDirection.down:
              return false;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kioskLine),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '안내 음량  (← →)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kioskBrown,
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: volume / _max,
                    minHeight: 8,
                    backgroundColor: kioskFill,
                    color: kioskAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                child: Text(
                  '$volume',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kioskBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
