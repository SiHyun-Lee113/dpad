import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'key_set.dart';
import 'marks.dart';
import 'region.dart';
import 'root.dart';
import 'scroll.dart';
import 'theme.dart';

/// [DpadFocusable]의 포커스 표현을 완전히 직접 그리는 시그니처.
typedef DpadFocusableBuilder = Widget Function(
  BuildContext context,
  DpadFocusState state,
  Widget child,
);

/// 포커스된 칸에서 방향 키를 가로채는 시그니처.
///
/// `true`를 반환하면 키를 소비합니다 (포커스가 움직이지 않음).
/// `false`면 일반 D-pad 탐색이 진행됩니다.
typedef DpadDirectionCallback = bool Function(TraversalDirection direction);

/// [child]을 TV 포커스 타깃으로 만듭니다. D-pad로 이동하고, 리모컨 가운데
/// 버튼으로 선택하며, 포커스 이펙트로 꾸밉니다.
///
/// 대부분의 칸은 이 최소 형태면 충분합니다:
///
/// ```dart
/// DpadFocusable(
///   ttsLabel: '재생',
///   onSelect: () => playMovie(movie),
///   child: PosterCard(movie),
/// )
/// ```
///
/// ### 비주얼
///
/// 기본값은 가장 가까운 [DpadTheme]의 이펙트입니다 (기본적으로 스케일 + 테두리).
/// 칸마다 [effects]로 덮어쓰거나, [builder]로 전부 직접 그리세요.
/// [builder]는 선택 키 pressed 상태를 포함한 실시간 [DpadFocusState]를 받습니다.
///
/// ### 상호작용
///
/// * [onSelect] — 가운데 버튼 (또는 터치 탭).
/// * [onLongSelect] — 가운데 버튼을 길게; 컨텍스트 메뉴에 적합합니다.
/// * [onDirection] — 포커스 중 화살표를 가로챕니다. 예: 좌/우를 소비하는 슬라이더.
/// * [ttsLabel] — 포커스되면 [Dpad.ttsService]가 읽는 문자열.
///
/// ### [DpadRegion] 안에서
///
/// 칸은 영역의 포커스 메모리에 자동으로 등록됩니다.
/// 영역당 한 칸에 [entry]를 주면 [DpadEnterBehavior.entry]의 착지 타깃이 됩니다
/// ([DpadEnterBehavior.restore]의 폴백이기도 함).
///
/// ### 위젯 하나, 포커스 타깃 하나
///
/// 기본값으로 자손 포커스는 제외됩니다 ([excludeChildFocus]).
/// 그래서 `Card`, `Image`, Material 버튼을 감싸도 D-pad 경로에 칸이 두 개가 되지 않습니다.
/// 자식의 `onPressed` 대신 [onSelect]에 동작을 연결하세요.
/// 자식이 스스로 포커스를 관리해야 하면 ([TextField] 등)
/// [excludeChildFocus]를 `false`로 하세요.
class DpadFocusable extends StatefulWidget {
  /// [child]을 감싸는 TV 포커스 타깃을 만듭니다.
  const DpadFocusable({
    super.key,
    required this.child,
    this.effects,
    this.builder,
    this.onSelect,
    this.onLongSelect,
    this.onFocusChange,
    this.onDirection,
    this.autofocus = false,
    this.enabled = true,
    this.entry = false,
    this.focusNode,
    this.debugLabel,
    required this.ttsLabel,
    this.autoScroll = true,
    this.scrollPadding,
    this.scrollDuration,
    this.scrollCurve,
    this.excludeChildFocus = true,
    this.tapToSelect = true,
  }) : assert(
          effects == null || builder == null,
          'Provide either effects or builder, not both.',
        );

  /// 포커스 가능하게 만들 콘텐츠.
  final Widget child;

  /// 이 칸의 포커스 이펙트. 첫 이펙트가 가장 바깥입니다.
  ///
  /// null이고 [builder]도 null이면 [DpadThemeData.effects]가 적용됩니다.
  final List<DpadEffect>? effects;

  /// 실시간 [DpadFocusState]로 표현을 완전히 직접 그립니다.
  /// [effects]와 동시에 쓸 수 없습니다.
  final DpadFocusableBuilder? builder;

  /// 선택 키를 누르거나 (또는 칸을 탭할 때) 호출됩니다.
  final VoidCallback? onSelect;

  /// 선택 키를 [DpadThemeData.longSelectDuration]만큼 누르고 있을 때
  /// (또는 롱프레스) 호출됩니다.
  ///
  /// 이 콜백이 있으면 [onSelect]는 키를 뗄 때 발생해, 두 제스처가 겹치지 않습니다.
  final VoidCallback? onLongSelect;

  /// 칸이 포커스를 얻으면 `true`, 잃으면 `false`.
  final ValueChanged<bool>? onFocusChange;

  /// 이 칸이 포커스일 때 방향 키를 가로챕니다. `true`를 반환하면 키를 소비합니다.
  /// 키를 누르고 있는 동안의 repeat도 전달됩니다.
  final DpadDirectionCallback? onDirection;

  /// 처음 나타날 때 이 칸이 포커스를 가져갈지.
  ///
  /// 화면당 정확히 한 칸에 `autofocus: true`를 주세요. 헤더의 "처음으로"
  /// 처럼 기하학적으로 왼쪽 위에 있는 크롬보다 이 칸이 이깁니다.
  /// 키오스크는 메뉴 첫 버튼, 대기 화면은 시작 버튼에 둡니다.
  ///
  /// [Navigator]로 다음 페이지를 열면 이전 페이지 위젯은 스택에 남습니다.
  /// 이 플래그를 새 화면 시작 칸에 두면 그 칸이 포커스를 가져갑니다.
  /// 없어도 [Dpad]는 새 라우트의 첫 칸에 착지하고, 이전 페이지 마지막
  /// 포커스로 돌아가지 않습니다.
  final bool autofocus;

  /// 이 칸에 포커스를 줄 수 있는지. 비활성 칸은 탐색에서 완전히 건너뜁니다.
  final bool enabled;

  /// 이 칸을 영역의 입구 타깃으로 표시합니다. [DpadEnterBehavior.entry]를 보세요.
  /// 영역당 하나.
  final bool entry;

  /// 내부 노드 대신 쓸 외부 포커스 노드.
  final FocusNode? focusNode;

  /// 포커스 디버그 출력에 보이는 라벨.
  final String? debugLabel;

  /// 이 칸이 포커스를 받으면 [Dpad.ttsService]가 읽습니다.
  ///
  /// 배리어프리 안내 문구입니다. 비어 있으면 안내하지 않고 이전 발화를
  /// 중단합니다.
  final String ttsLabel;

  /// 포커스를 받을 때 이펙트 여백을 두고 화면에 보이게 스크롤할지.
  /// 기본값은 `true`.
  final bool autoScroll;

  /// 자동 스크롤 시 뷰포트 패딩. 기본값은 [DpadThemeData.scrollPadding].
  final double? scrollPadding;

  /// 자동 스크롤 애니메이션 시간. 기본값은 [DpadThemeData.scrollDuration].
  final Duration? scrollDuration;

  /// 자동 스크롤 애니메이션 커브. 기본값은 [DpadThemeData.scrollCurve].
  final Curve? scrollCurve;

  /// 자손을 포커스 트리에서 빼, 이 위젯이 D-pad 한 칸이 되게 할지.
  /// 기본값은 `true`.
  final bool excludeChildFocus;

  /// 탭이 칸에 포커스를 주고 [onSelect]를 호출할지.
  /// 터치/포인터 기기와 데스크톱 디버깅용. 기본값은 `true`.
  final bool tapToSelect;

  @override
  State<DpadFocusable> createState() => _DpadFocusableState();
}

class _DpadFocusableState extends State<DpadFocusable> {
  FocusNode? _internalNode;
  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  DpadRegionState? _region;
  bool _focused = false;
  bool _pressed = false;
  bool _selectKeyDown = false;
  bool _longSelectFired = false;
  bool _claimedAutofocus = false;
  Timer? _longSelectTimer;

  @override
  void initState() {
    super.initState();
    _mark(_node);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _region = DpadRegion.maybeOf(context);
    _scheduleAutofocusClaim();
  }

  @override
  void didUpdateWidget(DpadFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unmark(oldWidget.focusNode ?? _internalNode);
      _mark(_node);
    } else {
      if (oldWidget.entry != widget.entry) {
        DpadMarks.entry[_node] = widget.entry ? true : null;
      }
      if (oldWidget.ttsLabel != widget.ttsLabel) {
        DpadMarks.ttsLabel[_node] = _ttsMark(widget.ttsLabel);
      }
      if (oldWidget.debugLabel != widget.debugLabel &&
          widget.debugLabel != null) {
        _node.debugLabel = widget.debugLabel;
      }
      if (oldWidget.autofocus != widget.autofocus) {
        DpadMarks.autofocus[_node] = widget.autofocus ? true : null;
        if (widget.autofocus) {
          _claimedAutofocus = false;
          _scheduleAutofocusClaim();
        }
      }
    }
  }

  void _mark(FocusNode node) {
    DpadMarks.managed[node] = true;
    DpadMarks.entry[node] = widget.entry ? true : null;
    DpadMarks.autofocus[node] = widget.autofocus ? true : null;
    DpadMarks.ttsLabel[node] = _ttsMark(widget.ttsLabel);
    if (widget.debugLabel != null) {
      node.debugLabel = widget.debugLabel;
    }
  }

  void _unmark(FocusNode? node) {
    if (node == null) {
      return;
    }
    DpadMarks.managed[node] = null;
    DpadMarks.entry[node] = null;
    DpadMarks.autofocus[node] = null;
    DpadMarks.ttsLabel[node] = null;
  }

  void _scheduleAutofocusClaim([int attempt = 0]) {
    if (!widget.autofocus || _claimedAutofocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.autofocus || _claimedAutofocus) {
        return;
      }
      final DpadController? dpad = Dpad.maybeOf(context);
      if (dpad == null) {
        _claimedAutofocus = true;
        return;
      }
      if (dpad.claimAutofocus(_node)) {
        _claimedAutofocus = true;
        return;
      }
      if (attempt < 4) {
        _scheduleAutofocusClaim(attempt + 1);
      }
    });
  }

  static String? _ttsMark(String label) {
    if (label.isEmpty) {
      return null;
    }
    return label;
  }

  @override
  void dispose() {
    _longSelectTimer?.cancel();
    final FocusNode? internal = _internalNode;
    final FocusNode? node = widget.focusNode ?? internal;
    if (node != null) {
      _region?.forget(node);
    }
    _unmark(widget.focusNode);
    if (internal != null) {
      _unmark(internal);
      internal.dispose();
    }
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // 선택
  // -----------------------------------------------------------------------

  void _handleSelect() {
    if (!widget.enabled) {
      return;
    }
    widget.onSelect?.call();
  }

  void _handleLongSelect() {
    _longSelectFired = true;
    widget.onLongSelect?.call();
  }

  void _startPress() {
    _longSelectFired = false;
    _setPressed(true);
    if (widget.onLongSelect != null) {
      _longSelectTimer?.cancel();
      _longSelectTimer = Timer(
        DpadTheme.of(context).longSelectDuration,
        _handleLongSelect,
      );
    }
  }

  void _endPress({required bool canceled}) {
    _longSelectTimer?.cancel();
    _longSelectTimer = null;
    _setPressed(false);
    if (canceled || _longSelectFired) {
      return;
    }
    // 롱셀렉트 핸들러가 있으면 선택은 키를 뗄 때, 없으면 누를 때 이미 발생함.
    if (widget.onLongSelect != null) {
      _handleSelect();
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    } else {
      _pressed = value;
    }
  }

  // -----------------------------------------------------------------------
  // 키
  // -----------------------------------------------------------------------

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final DpadKeySet keys = Dpad.keySetOf(context);
    final LogicalKeyboardKey key = event.logicalKey;

    if (keys.isSelect(key)) {
      return _handleSelectKey(event);
    }

    final TraversalDirection? direction = keys.directionOf(key);
    if (direction != null &&
        widget.onDirection != null &&
        event is! KeyUpEvent) {
      if (widget.onDirection!(direction)) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSelectKey(KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      _selectKeyDown = true;
      _startPress();
      if (widget.onLongSelect == null) {
        _handleSelect();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      // 누르고 있는 동안의 repeat이 onSelect를 연타하지 않게 삼킵니다.
      return _selectKeyDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) {
      if (!_selectKeyDown) {
        // 짝이 되는 key-down은 다른 위젯에서 일어났습니다.
        return KeyEventResult.ignored;
      }
      _selectKeyDown = false;
      _endPress(canceled: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // -----------------------------------------------------------------------
  // 포커스
  // -----------------------------------------------------------------------

  void _handleFocusChange(bool focused) {
    if (!mounted) {
      return;
    }
    setState(() => _focused = focused);
    if (focused) {
      _region?.noteFocus(_node);
      if (widget.autoScroll) {
        final DpadThemeData theme = DpadTheme.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _node.hasFocus) {
            DpadScroll.ensureVisible(
              _node,
              padding: widget.scrollPadding ?? theme.scrollPadding,
              duration: widget.scrollDuration ?? theme.scrollDuration,
              curve: widget.scrollCurve ?? theme.scrollCurve,
            );
          }
        });
      }
    } else {
      _selectKeyDown = false;
      _longSelectTimer?.cancel();
      _setPressed(false);
    }
    widget.onFocusChange?.call(focused);
  }

  // -----------------------------------------------------------------------
  // 빌드
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final DpadFocusState state =
        DpadFocusState(focused: _focused, pressed: _pressed);

    Widget content = widget.child;
    if (widget.excludeChildFocus) {
      content = ExcludeFocus(child: content);
    }

    if (widget.builder != null) {
      content = widget.builder!(context, state, content);
    } else {
      content = DpadEffect.wrap(
        context,
        widget.effects ?? DpadTheme.of(context).effects,
        state,
        content,
      );
    }

    if (widget.tapToSelect) {
      content = MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (TapDownDetails details) {
                  _node.requestFocus();
                  _startPress();
                }
              : null,
          onTapUp: widget.enabled
              ? (TapUpDetails details) => _endPress(canceled: false)
              : null,
          onTapCancel: widget.enabled ? () => _endPress(canceled: true) : null,
          onTap: widget.enabled && widget.onLongSelect == null
              ? _handleSelect
              : null,
          child: content,
        ),
      );
    }

    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            _handleSelect();
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (ButtonActivateIntent intent) {
            _handleSelect();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _node,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        debugLabel: widget.debugLabel,
        onKeyEvent: _handleKeyEvent,
        onFocusChange: _handleFocusChange,
        child: content,
      ),
    );
  }
}
