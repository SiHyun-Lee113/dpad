import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'key_set.dart';
import 'marks.dart';
import 'nav_policy.dart';
import 'region.dart';
import 'screen.dart';
import 'scroll.dart';
import 'theme.dart';
import 'traversal.dart';
import 'tts.dart';

/// D-pad 시스템의 루트.
///
/// 페이지 위에 [Dpad]를 하나 둡니다. 권장 위치는 [WidgetsApp.builder] /
/// `MaterialApp.builder`입니다. 그래야 모든 라우트, 다이얼로그, 오버레이가 포함됩니다:
///
/// ```dart
/// MaterialApp(
///   builder: Dpad.wrap(),
///   home: const HomePage(),
/// )
/// ```
///
/// [Dpad]가 제공하는 것:
///
/// * **TV에 맞는 방향 탐색** — 서브트리 전체에 [DpadTraversalPolicy].
///   화살표 키, 리모컨 D-pad, 게임패드가 모든 플랫폼에서 동작합니다
///   (웹 포함. Flutter는 기본적으로 화살표를 포커스에 매핑하지 않음).
/// * **리모컨 키 의미** — 뒤로/메뉴 콜백과 앱 수준 [shortcuts].
///   텍스트 필드를 편집하는 동안에는 자동으로 내려가, 입력을 가로채지 않습니다.
/// * **포커스 복원** — 포커스된 위젯이 사라지거나(리스트 갱신, 다이얼로그 닫힘)
///   앱이 백그라운드에서 돌아오면, 포커스를 잃지 않고 가까운 칸으로 복원합니다.
///   그렇지 않으면 리모컨이 먹통이 됩니다.
/// * **접근성 TTS** — [DpadTtsService]를 주입하고 칸에 [DpadFocusable.ttsLabel]을
///   두면, 포커스를 받을 때 라벨을 읽습니다.
/// * **프로그래밍 제어** — [Dpad.of]: `Dpad.of(context).moveDown()`,
///   `.select()`, `.requestFocus(...)`, `.requestFirstFocus()`.
///
/// 모든 [DpadFocusable]의 스타일 기본값은 [theme]에 있습니다.
class Dpad extends StatefulWidget {
  /// [child]을 감싸는 D-pad 루트를 만듭니다.
  const Dpad({
    super.key,
    required this.child,
    this.enabled = true,
    this.keySet = const DpadKeySet(),
    this.theme,
    this.onBack,
    this.onMenu,
    this.onFocusChange,
    this.ttsService,
    this.shortcuts = const <LogicalKeyboardKey, VoidCallback>{},
    this.restoreFocus = true,
    this.debugOverlay = false,
    this.navPolicy = DpadNavPolicy.tv,
  });

  /// 제어할 서브트리. 보통 앱의 `Navigator` (`MaterialApp.builder`를 통해)
  /// 또는 `MaterialApp` 전체입니다.
  final Widget child;

  /// `false`이면 [Dpad]는 스코프만 제공합니다 ([Dpad.of]는 동작).
  /// 키 처리는 건드리지 않습니다.
  final bool enabled;

  /// 리모컨 키 매핑. [DpadKeySet]을 보세요.
  final DpadKeySet keySet;

  /// 자손 [DpadFocusable]의 기본 스타일과 타이밍.
  final DpadThemeData? theme;

  /// 뒤로 키 ([DpadKeySet.back])가 눌렸을 때 호출됩니다.
  ///
  /// `true`를 반환하면 키를 소비합니다. `false`면 프레임워크가 계속합니다
  /// (다이얼로그 닫기, 뒤로를 키 이벤트로 주는 플랫폼에서 라우트 pop).
  /// null이면 뒤로 키를 가로채지 않습니다.
  final bool Function()? onBack;

  /// 메뉴 키 ([DpadKeySet.menu])가 눌렸을 때 호출됩니다.
  final VoidCallback? onMenu;

  /// 포커스가 바뀔 때마다 새 노드를 받습니다 (실제 포커스가 없으면 `null`).
  ///
  /// 앱 전역 포커스 "틱" 사운드, 햅틱, 분석에 자연스러운 자리입니다:
  ///
  /// ```dart
  /// Dpad.wrap(
  ///   onFocusChange: (node) {
  ///     if (node != null) audio.playTick();
  ///   },
  /// )
  /// ```
  final ValueChanged<FocusNode?>? onFocusChange;

  /// 칸이 포커스를 받을 때 [DpadFocusable.ttsLabel]을 읽는 접근성 백엔드.
  /// null이면 안내하지 않습니다 (기본값).
  ///
  /// ```dart
  /// Dpad.wrap(
  ///   ttsService: MyTtsService(),
  /// )
  /// ```
  final DpadTtsService? ttsService;

  /// 앱 수준 키 단축키. 예: 검색 키, 컬러 버튼.
  ///
  /// 텍스트 필드가 포커스되면 자동으로 일시 중지됩니다.
  final Map<LogicalKeyboardKey, VoidCallback> shortcuts;

  /// D-pad 시스템이 스스로 포커스를 살릴지. 기본값 `true`이며 다음을 보장합니다:
  ///
  /// * 앱이 시작할 때 무언가에 포커스가 있음 (`autofocus` 칸이 이김);
  /// * `autofocus` 없는 라우트에도 초기 포커스가 감;
  /// * 화면이 바뀌어도 보이는 포커스가 사라지지 않음. 다음 키를 기다리지 않고
  ///   [DpadFocusable.autofocus] / [DpadRegion.autofocus] / entry 칸으로 착지.
  ///   기하학적인 왼쪽 위(헤더 "처음으로" 등)는 지정한 칸이 없을 때만 씁니다;
  /// * 포커스된 위젯이 dispose되면 가장 가까운 남은 이웃으로 이동 —
  ///   맞는 칸이 없으면 지정한 시작 칸, 그다음 왼쪽 위.
  ///   **아이들 타임아웃은 없습니다.** 잠시 뒤 첫 칸으로 점프한다면
  ///   이 복원 경로입니다 (리스트가 리빌드되었거나 현재 노드가 unfocus됨);
  /// * 백그라운드에서 돌아오면 이전 포커스를 복원.
  ///
  /// `false`여도 **화면(라우트)이 바뀌면** 이전 페이지 포커스를 유지하지
  /// 않습니다. 새 페이지의 `autofocus` 칸, 없으면 그 페이지 첫 칸에
  /// 착지합니다. 리스트 칸이 사라진 뒤 이웃으로 옮기는 동작만 꺼집니다.
  final bool restoreFocus;

  /// 방향키 탐색 방식. 기본값은 [DpadNavPolicy.tv]입니다.
  /// 키오스크는 [DpadNavPolicy.kiosk]를 씁니다.
  final DpadNavPolicy navPolicy;

  /// 포커스된 노드의 라벨과 기하를 그리는 개발자 오버레이.
  /// TV 포커스 버그는 이것 없이는 보이지 않습니다.
  ///
  /// 디버그 빌드에서만 켜세요:
  ///
  /// ```dart
  /// Dpad.wrap(debugOverlay: kDebugMode)
  /// ```
  final bool debugOverlay;

  /// 가장 가까운 조상 [Dpad]의 [DpadController].
  static DpadController of(BuildContext context) {
    final DpadController? controller = maybeOf(context);
    assert(
      controller != null,
      'Dpad.of() called with a context that has no Dpad ancestor.\n'
      'Install one with MaterialApp(builder: Dpad.wrap()) or by wrapping '
      'your page tree in a Dpad widget.',
    );
    return controller!;
  }

  /// 가장 가까운 조상 [Dpad]의 [DpadController]. 없으면 `null`.
  static DpadController? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadScope>()?.controller;
  }

  /// [context]의 활성 [DpadKeySet]. [Dpad] 조상이 없으면 기본값.
  static DpadKeySet keySetOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadScope>()?.keySet ??
        const DpadKeySet();
  }

  /// `MaterialApp.builder`로 [Dpad]를 설치하는 편의 메서드:
  ///
  /// ```dart
  /// MaterialApp(
  ///   builder: Dpad.wrap(theme: const DpadThemeData(...)),
  ///   home: const HomePage(),
  /// )
  /// ```
  static TransitionBuilder wrap({
    bool enabled = true,
    DpadKeySet keySet = const DpadKeySet(),
    DpadThemeData? theme,
    bool Function()? onBack,
    VoidCallback? onMenu,
    ValueChanged<FocusNode?>? onFocusChange,
    DpadTtsService? ttsService,
    Map<LogicalKeyboardKey, VoidCallback> shortcuts =
        const <LogicalKeyboardKey, VoidCallback>{},
    bool restoreFocus = true,
    bool debugOverlay = false,
    DpadNavPolicy navPolicy = DpadNavPolicy.tv,
  }) {
    return (BuildContext context, Widget? child) {
      return Dpad(
        enabled: enabled,
        keySet: keySet,
        theme: theme,
        onBack: onBack,
        onMenu: onMenu,
        onFocusChange: onFocusChange,
        ttsService: ttsService,
        shortcuts: shortcuts,
        restoreFocus: restoreFocus,
        debugOverlay: debugOverlay,
        navPolicy: navPolicy,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  State<Dpad> createState() => _DpadState();
}

class _DpadState extends State<Dpad> with WidgetsBindingObserver {
  late final DpadController _controller = DpadController._(this);
  final DpadTraversalPolicy _policy = DpadTraversalPolicy();

  FocusNode? _lastFocus;
  Rect? _lastRect;
  FocusScopeNode? _lastDrivableScope;
  bool _restoreScheduled = false;
  bool _fallbackFocus = false;
  bool _restoring = false;
  int _restoreAttempts = 0;
  int _ttsAnnounceEpoch = 0;
  DpadScreenState? _lastTtsScreen;
  DpadRegionState? _lastTtsRegion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_handleGlobalFocusChange);
    // TV 앱은 첫 키를 누르기 전에도 보이는 포커스가 있어야 합니다.
    // 없으면 리모컨 이벤트를 전달할 앵커가 없습니다.
    _scheduleRestore(resumed: true);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleGlobalFocusChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // 포커스 복원
  // -----------------------------------------------------------------------

  void _handleGlobalFocusChange() {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (DpadMarks.isDrivable(primary)) {
      if (!_restoring) {
        _fallbackFocus = false;
      }
      _lastFocus = primary;
      _lastRect = DpadMarks.rectOf(primary!) ?? _lastRect;
      _lastDrivableScope = primary.nearestScope;
      _restoreAttempts = 0;
      widget.onFocusChange?.call(primary);
      _announceFocus(primary);
      return;
    }
    if (primary != null && primary is! FocusScopeNode) {
      widget.onFocusChange?.call(primary);
    } else {
      widget.onFocusChange?.call(null);
    }
    widget.ttsService?.stop();
    if (widget.enabled) {
      _scheduleRestore();
    }
  }

  void _announceFocus(FocusNode node) {
    final DpadScreenState? screen = DpadScreen.ofNode(node);
    final DpadRegionState? region = DpadRegion.ofNode(node);
    final bool screenChanged = !identical(screen, _lastTtsScreen);
    final bool regionChanged = !identical(region, _lastTtsRegion);
    _lastTtsScreen = screen;
    _lastTtsRegion = region;

    final DpadTtsService? tts = widget.ttsService;
    if (tts == null) {
      return;
    }
    final String? label = composeTtsAnnouncement(
      screenChanged: screenChanged,
      regionChanged: regionChanged,
      screenLabel: screen?.ttsLabel,
      regionLabel: region?.widget.ttsLabel,
      tileLabel: DpadMarks.ttsLabel[node],
      tileIsRegionHost: DpadMarks.regionHost[node] == true,
    );
    final int epoch = ++_ttsAnnounceEpoch;
    // 키/포커스 처리와 같은 턴에서 플랫폼 TTS를 부르면 Windows SAPI가
    // 메시지 루프를 막아, 다음 프레임(하이라이트)까지 멈춥니다.
    // 이번 프레임을 그린 뒤에 최신 라벨만 읽습니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _ttsAnnounceEpoch) {
        return;
      }
      if (label == null || label.isEmpty) {
        tts.stop();
        return;
      }
      tts.speak(label);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        widget.restoreFocus &&
        widget.enabled) {
      _scheduleRestore(resumed: true);
    }
  }

  void _scheduleRestore({bool resumed = false}) {
    if (_restoreScheduled) {
      return;
    }
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 마이크로태스크 hop으로 대기 중인 `autofocus`와 명시적 포커스 요청이
      // 먼저 자리 잡게 해, 폴백보다 항상 이기게 합니다.
      scheduleMicrotask(() {
        _restoreScheduled = false;
        if (mounted && widget.enabled) {
          _restoreFocus(resumed: resumed);
        }
      });
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _restoreFocus({required bool resumed}) {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (DpadMarks.isDrivable(primary)) {
      return;
    }
    final FocusScopeNode scope = primary is FocusScopeNode
        ? primary
        : (primary?.nearestScope ?? FocusManager.instance.rootScope);

    final FocusNode? last = _lastFocus;
    final bool lastDrivable = DpadMarks.isDrivable(last);
    final FocusScopeNode? previousScope =
        lastDrivable ? last!.nearestScope : _lastDrivableScope;
    final bool sameScope =
        lastDrivable && identical(previousScope, scope);
    final bool crossedRoute =
        previousScope != null && !identical(previousScope, scope);

    // 키 리스너처럼 skipTraversal 노드가 primary를 가져가도, 있던 칸을
    // 숨기지 않고 바로 되돌립니다. 다음 입력을 기다리지 않습니다.
    if (primary != null &&
        primary.skipTraversal &&
        lastDrivable &&
        sameScope) {
      _focusRestored(last!, fallback: false);
      return;
    }

    // Navigator.push 등으로 화면이 바뀌면 이전 페이지 칸을 유지하지 않습니다.
    // 새 스코프의 autofocus / 첫 칸(또는 pop이면 기억된 focusedChild)에 착지.
    if (crossedRoute) {
      _landOnScope(scope, preferNearby: false);
      return;
    }

    if (lastDrivable) {
      if (resumed) {
        _focusRestored(last!, fallback: false);
        return;
      }
      if (sameScope) {
        // unfocus가 의도적임 (예: clearFocus, 텍스트 필드 닫기).
        return;
      }
    }

    if (!widget.restoreFocus && !resumed) {
      return;
    }

    _landOnScope(scope, preferNearby: widget.restoreFocus);
  }

  void _landOnScope(FocusScopeNode scope, {required bool preferNearby}) {
    FocusNode? remembered = scope.focusedChild;
    while (remembered != null &&
        remembered is FocusScopeNode &&
        !DpadMarks.isDrivable(remembered)) {
      remembered = remembered.focusedChild;
    }
    if (DpadMarks.isDrivable(remembered)) {
      _focusRestored(remembered!, fallback: false);
      return;
    }

    final List<FocusNode> candidates = scope.traversalDescendants
        .where((FocusNode node) => DpadMarks.isDrivable(node))
        .toList();
    if (candidates.isEmpty) {
      if (_restoreAttempts < 4) {
        _restoreAttempts++;
        _scheduleRestore();
      }
      return;
    }
    _restoreAttempts = 0;

    FocusNode? target;
    // 리스트 칸이 그 자리에서 죽은 경우에만 옛 위치로 치우칩니다.
    // 거리가 칸 크기보다 훨씬 크면 화면이 바뀐 것으로 보고, 크롬(처음으로)
    // 대신 autofocus / entry를 씁니다.
    final FocusNode? last = _lastFocus;
    final bool lastDetached = last != null && !DpadMarks.isDrivable(last);
    final Rect? memory = _lastRect;
    if (preferNearby && lastDetached && memory != null) {
      FocusNode? nearby;
      double best = double.infinity;
      Rect? nearbyRect;
      for (final FocusNode node in candidates) {
        final Rect? rect = DpadMarks.rectOf(node);
        if (rect == null) {
          continue;
        }
        final double distance = (rect.center - memory.center).distanceSquared;
        if (distance < best) {
          best = distance;
          nearby = node;
          nearbyRect = rect;
        }
      }
      if (nearby != null && nearbyRect != null) {
        final double span = nearbyRect.longestSide * 1.5;
        if ((nearbyRect.center - memory.center).distance <= span) {
          target = nearby;
        }
      }
    }
    target ??= DpadMarks.preferredInitial(candidates) ?? candidates.first;
    final bool fallback = DpadMarks.autofocus[target] != true &&
        DpadMarks.entry[target] != true;
    _focusRestored(target, fallback: fallback);
  }

  void _focusRestored(FocusNode target, {required bool fallback}) {
    _restoring = true;
    _fallbackFocus = fallback;
    DpadRegion.ofNode(target)?.noteFocus(target);
    target.requestFocus();
    _lastDrivableScope = target.nearestScope;
    _restoring = false;
  }

  // -----------------------------------------------------------------------
  // 키 처리
  // -----------------------------------------------------------------------

  EditableTextState? get _focusedEditable {
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext == null || !focusContext.mounted) {
      return null;
    }
    return focusContext.findAncestorStateOfType<EditableTextState>();
  }

  bool get _keysActive => widget.enabled && _focusedEditable == null;

  /// 텍스트 필드 안에서의 TV식 화살표: 텍스트 중간에서는 캐럿을 움직이고,
  /// 더 갈 곳이 없으면 *필드를 떠납니다* — 그렇지 않으면 리모컨만 쓰는
  /// 사용자가 필드에 갇힙니다.
  bool _directionAllowed(TraversalDirection direction) {
    if (!widget.enabled) {
      return false;
    }
    final EditableTextState? editable = _focusedEditable;
    if (editable == null) {
      return true;
    }
    final TextEditingValue value = editable.textEditingValue;
    if (value.composing.isValid) {
      return false; // 조합 중에는 IME가 모든 키를 소유.
    }
    final TextSelection selection = value.selection;
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.down:
        // 한 줄 필드는 세로 캐럿 이동이 없음: 탐색으로 넘김.
        return editable.widget.maxLines == 1;
      case TraversalDirection.left:
        return selection.isValid &&
            selection.isCollapsed &&
            selection.baseOffset <= 0;
      case TraversalDirection.right:
        return selection.isValid &&
            selection.isCollapsed &&
            selection.baseOffset >= value.text.length;
    }
  }

  bool _move(TraversalDirection direction) {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (!DpadMarks.isDrivable(primary)) {
      _restoreFocus(resumed: true);
      return true;
    }
    _fallbackFocus = false;
    return primary!.focusInDirection(direction);
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    final Map<ShortcutActivator, Intent> map = <ShortcutActivator, Intent>{};
    void mapDirection(List<LogicalKeyboardKey> keys, TraversalDirection d) {
      for (final LogicalKeyboardKey key in keys) {
        map[SingleActivator(key)] = _DpadDirectionalIntent(d);
      }
    }

    mapDirection(widget.keySet.up, TraversalDirection.up);
    mapDirection(widget.keySet.down, TraversalDirection.down);
    mapDirection(widget.keySet.left, TraversalDirection.left);
    mapDirection(widget.keySet.right, TraversalDirection.right);

    for (final LogicalKeyboardKey key in widget.keySet.back) {
      map[SingleActivator(key, includeRepeats: false)] =
          const _DpadBackIntent();
    }
    for (final LogicalKeyboardKey key in widget.keySet.menu) {
      map[SingleActivator(key, includeRepeats: false)] =
          const _DpadMenuIntent();
    }
    for (final MapEntry<LogicalKeyboardKey, VoidCallback> entry
        in widget.shortcuts.entries) {
      map[SingleActivator(entry.key, includeRepeats: false)] =
          _DpadCallbackIntent(entry.value);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // 아래 트리는 설정과 관계없이 구조가 같습니다. 런타임에 `enabled`나
    // `debugOverlay`를 바꿔도 앱 서브트리를 재부모화(그리고 리셋)하지 않습니다.
    // 비활성 분기는 없는 게 아니라 동작만 멈춘 상태입니다.
    return DpadNavScope(
      policy: widget.navPolicy,
      child: _DpadScope(
      controller: _controller,
      keySet: widget.keySet,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          DpadTheme(
            data: widget.theme ?? const DpadThemeData(),
            child: Actions(
              actions: <Type, Action<Intent>>{
                _DpadDirectionalIntent: _DpadDirectionalAction(this),
                _DpadBackIntent: _DpadBackAction(this),
                _DpadMenuIntent: _DpadMenuAction(this),
                _DpadCallbackIntent: _DpadCallbackAction(this),
              },
              child: Shortcuts(
                debugLabel: 'Dpad',
                shortcuts: widget.enabled
                    ? _buildShortcuts()
                    : const <ShortcutActivator, Intent>{},
                child: FocusTraversalGroup(
                  policy: _policy,
                  child: widget.child,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: widget.debugOverlay
                ? const _DpadDebugOverlay()
                : const SizedBox.shrink(),
          ),
        ],
      ),
      ),
    );
  }
}

class _DpadDebugOverlay extends StatefulWidget {
  const _DpadDebugOverlay();

  @override
  State<_DpadDebugOverlay> createState() => _DpadDebugOverlayState();
}

class _DpadDebugOverlayState extends State<_DpadDebugOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // 매 프레임 다시 그립니다. 포커스 박스는 포커스 변경뿐 아니라
    // 스크롤·애니메이션 중에도 움직입니다. 디버그 도구 오버헤드만.
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode? node = FocusManager.instance.primaryFocus;
    final Rect? rect = (node == null || node is FocusScopeNode)
        ? null
        : DpadMarks.rectOf(node);
    if (node == null || rect == null) {
      return const SizedBox.shrink();
    }
    final DpadRegionState? region = DpadRegion.ofNode(node);
    final DpadScreenState? screen = DpadScreen.ofNode(node);
    final String label = <String?>[
      node.debugLabel,
      if (screen != null)
        'screen: ${screen.widget.debugLabel ?? screen.hashCode}',
      if (region != null)
        'region: ${region.widget.debugLabel ?? region.hashCode}',
      '${rect.width.round()}×${rect.height.round()}',
    ].whereType<String>().join('  ·  ');

    return IgnorePointer(
      child: Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Positioned.fromRect(
            rect: rect.inflate(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                border: Border.all(color: const Color(0xFFFF1744), width: 2),
              ),
            ),
          ),
          Positioned(
            left: rect.left,
            top: rect.bottom + 6,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xDD000000),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 11,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DpadScope extends InheritedWidget {
  const _DpadScope({
    required this.controller,
    required this.keySet,
    required super.child,
  });

  final DpadController controller;
  final DpadKeySet keySet;

  @override
  bool updateShouldNotify(_DpadScope oldWidget) =>
      keySet != oldWidget.keySet || controller != oldWidget.controller;
}

// ---------------------------------------------------------------------------
// Intent와 Action
// ---------------------------------------------------------------------------

class _DpadDirectionalIntent extends Intent {
  const _DpadDirectionalIntent(this.direction);

  final TraversalDirection direction;
}

class _DpadBackIntent extends Intent {
  const _DpadBackIntent();
}

class _DpadMenuIntent extends Intent {
  const _DpadMenuIntent();
}

class _DpadCallbackIntent extends Intent {
  const _DpadCallbackIntent(this.callback);

  final VoidCallback callback;
}

class _DpadDirectionalAction extends Action<_DpadDirectionalIntent> {
  _DpadDirectionalAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadDirectionalIntent intent) =>
      state._directionAllowed(intent.direction);

  @override
  Object? invoke(_DpadDirectionalIntent intent) {
    state._move(intent.direction);
    return null;
  }
}

class _DpadBackAction extends Action<_DpadBackIntent> {
  _DpadBackAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadBackIntent intent) =>
      state._keysActive && state.widget.onBack != null;

  @override
  Object? invoke(_DpadBackIntent intent) => state.widget.onBack!();

  @override
  KeyEventResult toKeyEventResult(
    _DpadBackIntent intent,
    covariant Object? invokeResult,
  ) {
    return invokeResult == true
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }
}

class _DpadMenuAction extends Action<_DpadMenuIntent> {
  _DpadMenuAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadMenuIntent intent) =>
      state._keysActive && state.widget.onMenu != null;

  @override
  Object? invoke(_DpadMenuIntent intent) {
    state.widget.onMenu!();
    return null;
  }
}

class _DpadCallbackAction extends Action<_DpadCallbackIntent> {
  _DpadCallbackAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadCallbackIntent intent) => state._keysActive;

  @override
  Object? invoke(_DpadCallbackIntent intent) {
    intent.callback();
    return null;
  }
}

// ---------------------------------------------------------------------------
// 컨트롤러
// ---------------------------------------------------------------------------

/// [Dpad.of]로 얻는 프로그래밍 D-pad 제어.
///
/// ```dart
/// final dpad = Dpad.of(context);
/// dpad.moveDown();
/// dpad.select();
/// dpad.requestFocus(searchFieldNode);
/// dpad.requestFirstFocus(menuRegionContext);
/// ```
class DpadController {
  DpadController._(this._state);

  final _DpadState _state;

  /// 지금 포커스를 가진 노드. 실제 포커스가 없으면 `null`.
  FocusNode? get focused {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    return primary is FocusScopeNode ? null : primary;
  }

  /// 리모컨 키를 누른 것과 같이 [direction]으로 포커스를 한 칸 옮깁니다.
  /// 포커스가 움직였거나 키가 의미 있게 소비되었으면 `true`.
  bool move(TraversalDirection direction) => _state._move(direction);

  /// 포커스를 위로. `move(TraversalDirection.up)`와 같습니다.
  bool moveUp() => move(TraversalDirection.up);

  /// 포커스를 아래로. `move(TraversalDirection.down)`와 같습니다.
  bool moveDown() => move(TraversalDirection.down);

  /// 포커스를 왼쪽으로. `move(TraversalDirection.left)`와 같습니다.
  bool moveLeft() => move(TraversalDirection.left);

  /// 포커스를 오른쪽으로. `move(TraversalDirection.right)`와 같습니다.
  bool moveRight() => move(TraversalDirection.right);

  /// 읽기 순서의 다음 칸으로 (Tab과 같음).
  bool next() => focused?.nextFocus() ?? false;

  /// 읽기 순서의 이전 칸으로 (Shift+Tab과 같음).
  bool previous() => focused?.previousFocus() ?? false;

  /// 포커스된 칸을 활성화합니다 — 리모컨 가운데 버튼을 누른 것과 같습니다.
  /// 무언가가 처리했으면 `true`.
  bool select() {
    final BuildContext? context = focused?.context;
    if (context == null || !context.mounted) {
      return false;
    }
    if (Actions.maybeFind<ActivateIntent>(context) == null) {
      return false;
    }
    Actions.maybeInvoke(context, const ActivateIntent());
    return true;
  }

  /// [Dpad.onBack] 핸들러를 실행합니다. 이벤트를 소비했으면 `true`.
  bool back() => _state.widget.onBack?.call() ?? false;

  /// 지금 포커스를 받을 수 있으면 [node]에 포커스를 지정합니다.
  /// 영역 메모리도 함께 갱신합니다.
  ///
  /// ```dart
  /// Dpad.of(context).requestFocus(confirmButtonNode);
  /// ```
  bool requestFocus(FocusNode node) {
    if (!DpadMarks.isUsable(node)) {
      return false;
    }
    _state._fallbackFocus = false;
    DpadRegion.ofNode(node)?.noteFocus(node);
    node.requestFocus();
    return true;
  }

  /// [DpadFocusable.autofocus] 칸이 나타났을 때 호출됩니다.
  ///
  /// 같은 화면(포커스 스코프)에 이미 사용자가 고른 칸이 있으면 건드리지
  /// 않습니다. 새 라우트·다이얼로그처럼 **다른 스코프**에서 클레임하면
  /// 이전 페이지 포커스를 가져옵니다.
  /// 복원이 왼쪽 위 크롬으로 떨어진 뒤(`_fallbackFocus`)에도 가져갑니다.
  bool claimAutofocus(FocusNode node) {
    if (!DpadMarks.isUsable(node)) {
      return false;
    }
    final FocusNode? current = focused;
    if (DpadMarks.isDrivable(current) && !_state._fallbackFocus) {
      if (identical(current!.nearestScope, node.nearestScope)) {
        return true;
      }
    }
    return requestFocus(node);
  }

  /// [context]가 속한 [DpadRegion]의 첫 칸에 포커스를 줍니다.
  /// [context]가 없으면 현재 포커스가 속한 영역을 씁니다.
  ///
  /// ```dart
  /// Dpad.of(context).requestFirstFocus(menuGridContext);
  /// ```
  bool requestFirstFocus([BuildContext? context]) {
    _state._fallbackFocus = false;
    final DpadRegionState? region = context != null
        ? DpadRegion.maybeOf(context)
        : (focused == null ? null : DpadRegion.ofNode(focused!));
    return region?.requestFirstFocus() ?? false;
  }

  /// 지금 포커스된 칸에서 포커스를 뗍니다.
  void clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// [node] (또는 현재 포커스된 노드)를 이펙트 여백을 두고 완전히 보이게 스크롤합니다.
  void ensureVisible({
    FocusNode? node,
    double padding = 48.0,
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    final FocusNode? target = node ?? focused;
    if (target != null) {
      DpadScroll.ensureVisible(
        target,
        padding: padding,
        duration: duration,
        curve: curve,
      );
    }
  }
}
