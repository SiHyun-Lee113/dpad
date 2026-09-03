import 'package:flutter/widgets.dart';

/// [Dpad] 방향키 탐색 방식.
enum DpadNavPolicy {
  /// TV 기본. 영역 안은 기하/읽기 순서, 가장자리는
  /// [DpadEdgeBehavior] (가로 stop, 세로 leave).
  tv,

  /// 키오스크.
  ///
  /// * **좌/우** — 같은 [DpadRegion] 안에서만 이동합니다. 끝에서 더 가면
  ///   반대쪽 끝으로 순환합니다. 칸이 하나면 이동하지 않습니다.
  /// * **상/하** — 화면의 region끼리 이동합니다. 끝에서 더 가면 반대쪽
  ///   region으로 순환합니다. region이 하나면 이동하지 않습니다.
  /// * **[DpadRegionKind.list] / [item]** — 목록은 화면에서 한 밴드입니다.
  ///   착지 시 첫 줄 전체가 선택되고, Enter로 줄 안 위젯에 들어갑니다.
  ///   줄에서 상/하는 다음/이전 상품 줄로 갑니다.
  kiosk,
}

/// [Dpad.navPolicy]를 서브트리에 제공합니다.
class DpadNavScope extends InheritedWidget {
  /// [policy]를 자손에게 넘깁니다.
  const DpadNavScope({
    super.key,
    required this.policy,
    required super.child,
  });

  /// 이 서브트리의 탐색 정책.
  final DpadNavPolicy policy;

  /// [context]의 [DpadNavPolicy]. [Dpad]가 없으면 [DpadNavPolicy.tv].
  ///
  /// 빌드 의존성을 만들지 않습니다.
  static DpadNavPolicy of(BuildContext context) {
    final DpadNavScope? scope =
        context.getInheritedWidgetOfExactType<DpadNavScope>();
    return scope?.policy ?? DpadNavPolicy.tv;
  }

  @override
  bool updateShouldNotify(DpadNavScope oldWidget) => policy != oldWidget.policy;
}
