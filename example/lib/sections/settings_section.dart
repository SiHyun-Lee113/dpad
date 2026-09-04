import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';

/// TV용 설정 패턴:
///
/// * 서브트리 모든 줄을 한 번에 꾸미는 [DpadTheme] 오버라이드,
/// * [DpadFocusable.onSelect]로 동작하는 토글 줄,
/// * 탐색이 건너뛰는 비활성 줄,
/// * [DpadFocusable.onDirection]으로 좌/우를 소비하는 볼륨 슬라이더,
/// * [DpadController.requestFocus]로 프로그래밍 포커스,
/// * 실시간 포커스 이펙트 갤러리 ([DpadCustomEffect] 포함),
/// * 포커스 인스펙터·클릭 소리 런타임 토글.
class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _autoplay = true;
  bool _subtitles = false;
  int _volume = 12;
  int _effectIndex = 0;

  /// 외부 포커스 노드. "Jump to volume"이
  /// `Dpad.of(context).requestFocus(...)`를 보여 줍니다.
  final FocusNode _volumeNode = FocusNode(debugLabel: 'volume');

  static const List<(String, List<DpadEffect>)> _effectChoices = [
    ('Scale + border', [DpadScaleEffect(), DpadBorderEffect()]),
    ('Glow', [DpadGlowEffect()]),
    ('Elevation', [DpadScaleEffect(scale: 1.04), DpadElevationEffect()]),
    ('Spotlight', [DpadOpacityEffect(idleOpacity: 0.45)]),
    ('Tint', [DpadTintEffect()]),
    // builder로 표현할 수 있으면 이펙트가 됩니다:
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
            color: Theme.of(context).colorScheme.primary,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 32),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Playback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            // 프로그래밍 포커스: 볼륨 슬라이더로 바로 점프.
            DpadFocusable(
              ttsLabel: 'Jump to volume',
              onSelect: () => Dpad.of(context).requestFocus(_volumeNode),
              effects: const [DpadBorderEffect()],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  'Jump to volume ↓',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 이 서브트리의 모든 포커스 칸을 DpadTheme 하나로 꾸밉니다.
        // 칸마다 `effects:`가 필요 없습니다.
        DpadTheme(
          data: const DpadThemeData(
            effects: [DpadTintEffect(opacity: 0.16)],
          ),
          child: DpadRegion(
            ttsLabel: 'Playback',
            debugLabel: 'settings-playback',
            memoryKey: 'settings-playback',
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.skip_next_rounded,
                  title: 'Autoplay next episode',
                  value: _autoplay,
                  autofocus: true,
                  onChanged: (value) => setState(() => _autoplay = value),
                ),
                _ToggleRow(
                  icon: Icons.subtitles_outlined,
                  title: 'Subtitles',
                  value: _subtitles,
                  onChanged: (value) => setState(() => _subtitles = value),
                ),
                // 비활성 칸은 탐색에서 완전히 건너뜁니다.
                _ToggleRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Parental controls (coming soon)',
                  value: false,
                  enabled: false,
                  onChanged: (_) {},
                ),
                _VolumeRow(
                  focusNode: _volumeNode,
                  volume: _volume,
                  onChanged: (value) => setState(() => _volume = value),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: clickSounds,
                  builder: (context, value, _) => _ToggleRow(
                    icon: Icons.music_note_rounded,
                    title: 'Focus click sounds (Dpad.onFocusChange)',
                    value: value,
                    onChanged: (v) => clickSounds.value = v,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: showFocusInspector,
                  builder: (context, value, _) => _ToggleRow(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Focus inspector (Dpad.debugOverlay)',
                    value: value,
                    onChanged: (v) => showFocusInspector.value = v,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: appTts.enabled,
                  builder: (context, value, _) => _ToggleRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'TTS captions (DpadTtsService)',
                    value: value,
                    onChanged: (v) {
                      appTts.enabled.value = v;
                      if (!v) {
                        appTts.stop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Focus effect',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a style, then look at the preview card below. '
          'This chip row wraps around at its edges.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        DpadRegion(
          ttsLabel: 'Focus effect',
          debugLabel: 'settings-effects',
          // 캐러셀식 wrap, 바깥에서 들어올 때는 기하적으로 가까운 칸.
          horizontalEdge: DpadEdgeBehavior.wrap,
          enter: DpadEnterBehavior.nearest,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < _effectChoices.length; i++)
                DpadFocusable(
                  ttsLabel: _effectChoices[i].$1,
                  onSelect: () => setState(() => _effectIndex = i),
                  builder: (context, state, child) {
                    final selected = i == _effectIndex;
                    final scheme = Theme.of(context).colorScheme;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: state.focused
                            ? scheme.primary
                            : Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        _effectChoices[i].$1,
                        style: TextStyle(
                          color:
                              state.focused ? scheme.onPrimary : Colors.white,
                          fontWeight: FontWeight.w600,
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
        const SizedBox(height: 28),
        Center(
          child: DpadFocusable(
            effects: _effectChoices[_effectIndex].$2,
            ttsLabel: 'Preview, ${_effectChoices[_effectIndex].$1}',
            onSelect: () {},
            child: Container(
              width: 320,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF42275A), Color(0xFF734B6D)],
                ),
              ),
              child: const Center(
                child: Text(
                  'Preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Hold SELECT on any poster for options · MENU or F1 for help · '
            'H / L / S / D jump between sections',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  final IconData icon;
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
        ttsLabel: title,
        onSelect: () => onChanged(!value),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(title)),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DpadFocusable(
        focusNode: focusNode,
        ttsLabel: 'Volume $volume',
        // 좌/우는 값을 바꾸고 포커스는 유지. 상/하는 떠남.
        // 전형적인 TV 슬라이더.
        onDirection: (direction) {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.volume_up_rounded, size: 22),
              const SizedBox(width: 14),
              const Expanded(child: Text('Volume  (← → to adjust)')),
              SizedBox(
                width: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: volume / _max,
                    minHeight: 8,
                    backgroundColor: Colors.white.withAlpha(20),
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                child: Text('$volume', textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
