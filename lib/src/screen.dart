import 'package:flutter/widgets.dart';

/// 한 화면(또는 다이얼로그)의 [DpadRegion]들을 묶습니다.
///
/// [Dpad] → **[DpadScreen]** → [DpadRegion] → [DpadFocusable]
///
/// 스크린은 **포커스되지 않습니다.** 탐색 타깃이 아니며, 칸이 어느 화면
/// 아래 있는지 알기 위한 선언입니다. 다이얼로그도 같은 위젯으로 감싸면
/// 새 화면으로 취급됩니다.
///
/// [ttsLabel]이 있으면 이 화면으로 **처음 들어올 때** 영역·칸 라벨보다
/// 먼저 읽습니다. 같은 화면 안에서 영역만 바꾸면 스크린 라벨은 다시
/// 읽지 않습니다.
///
/// ```dart
/// DpadScreen(
///   ttsLabel: '메뉴 선택',
///   child: Column(
///     children: [
///       DpadRegion(ttsLabel: '카테고리', child: categoryRow),
///       DpadRegion(ttsLabel: '메뉴', child: menuGrid),
///     ],
///   ),
/// )
/// ```
class DpadScreen extends StatefulWidget {
  /// [child]을 한 화면으로 묶습니다.
  const DpadScreen({
    super.key,
    required this.child,
    this.debugLabel,
    this.ttsLabel,
  });

  /// 이 화면에 속하는 영역·칸의 서브트리.
  final Widget child;

  /// 포커스 디버그 출력에 보이는 라벨.
  final String? debugLabel;

  /// 이 화면으로 들어올 때 [Dpad.ttsService]가 먼저 읽는 문구.
  final String? ttsLabel;

  /// 가장 가까운 조상 [DpadScreen]의 state. 없으면 `null`.
  ///
  /// 빌드 의존성을 만들지 않습니다.
  static DpadScreenState? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadScreenScope>()?.state;
  }

  /// [node]가 속한 화면. 없으면 `null`.
  static DpadScreenState? ofNode(FocusNode node) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return null;
    }
    return maybeOf(context);
  }

  @override
  State<DpadScreen> createState() => DpadScreenState();
}

/// [DpadScreen]의 런타임 상태.
class DpadScreenState extends State<DpadScreen> {
  /// 이 화면의 TTS 문구.
  String? get ttsLabel => widget.ttsLabel;

  @override
  Widget build(BuildContext context) {
    return _DpadScreenScope(state: this, child: widget.child);
  }
}

class _DpadScreenScope extends InheritedWidget {
  const _DpadScreenScope({
    required this.state,
    required super.child,
  });

  final DpadScreenState state;

  @override
  bool updateShouldNotify(_DpadScreenScope oldWidget) =>
      !identical(state, oldWidget.state);
}
