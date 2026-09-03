import 'package:flutter/widgets.dart';

/// [FocusNode]에 붙는 내부 표시. [DpadFocusable]과 탐색 엔진이
/// 서로를 import하지 않고 정보를 공유하기 위한 용도입니다.
abstract final class DpadMarks {
  /// `DpadFocusable`이 소유한 노드. 이 노드들은 스스로 자동 스크롤하므로
  /// 탐색 정책이 추가로 스크롤하면 안 됩니다.
  static final Expando<bool> managed = Expando<bool>('dpad.managed');

  /// 해당 region의 입구 칸 (`DpadFocusable(entry: true)`).
  static final Expando<bool> entry = Expando<bool>('dpad.entry');

  /// 화면·패널이 나타날 때 개발자가 지정한 첫 칸
  /// (`DpadFocusable.autofocus: true`).
  static final Expando<bool> autofocus = Expando<bool>('dpad.autofocus');

  /// 접근성 안내 문구 (`DpadFocusable.ttsLabel`).
  /// 포커스가 바뀌면 [Dpad]가 읽어, 주입된 [DpadTtsService]가 안내합니다.
  static final Expando<String> ttsLabel = Expando<String>('dpad.ttsLabel');

  /// [DpadRegionKind.item] 줄의 호스트 노드. 줄 전체 선택용.
  static final Expando<bool> regionHost = Expando<bool>('dpad.regionHost');

  /// [node]의 글로벌 좌표. 레이아웃되지 않았거나 트리에서 떨어졌으면 `null`.
  static Rect? rectOf(FocusNode node) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return null;
    }
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    );
  }

  /// 지금 [node]에 포커스를 줄 수 있는지.
  ///
  /// 포커스 트리에 붙어 있어야 합니다([FocusNode.parent]가 있어야 함).
  /// `Focus` 위젯이 외부 노드를 반환한 뒤에도 `context`는 재사용된
  /// 엘리먼트를 가리킬 수 있으므로, context만으로는 살아 있다고 볼 수 없습니다.
  static bool isUsable(FocusNode? node) {
    if (node == null || node.parent == null) {
      return false;
    }
    final BuildContext? context = node.context;
    return context != null && context.mounted && node.canRequestFocus;
  }

  /// 화면에 하이라이트를 그릴 수 있는 칸인지.
  ///
  /// [FocusScopeNode]와 `skipTraversal` 노드(키 리스너 등)는 포커스를
  /// 들고 있어도 D-pad 칸이 아닙니다. 이 값이 `false`이면 보이는
  /// 포커스가 없는 것과 같습니다.
  static bool isDrivable(FocusNode? node) {
    if (node == null || node is FocusScopeNode || node.skipTraversal) {
      return false;
    }
    return isUsable(node);
  }

  /// 영역 안에서 고를 칸: [entry] → 가장 왼쪽 위.
  /// 방향키로 영역에 들어올 때와 [DpadRegionState.requestFirstFocus]가 씁니다.
  static FocusNode? initialCandidate(Iterable<FocusNode> candidates) {
    FocusNode? entryNode;
    FocusNode? topLeft;
    Rect? topLeftRect;
    for (final FocusNode node in candidates) {
      if (entryNode == null && (entry[node] ?? false)) {
        entryNode = node;
      }
      final Rect? rect = rectOf(node);
      if (rect == null) {
        continue;
      }
      if (topLeftRect == null ||
          rect.top < topLeftRect.top - 0.01 ||
          (rect.top <= topLeftRect.top + 0.01 &&
              rect.left < topLeftRect.left)) {
        topLeft = node;
        topLeftRect = rect;
      }
    }
    return entryNode ?? topLeft;
  }

  /// 화면이 나타날 때 고를 칸: [autofocus] → [entry] → 가장 왼쪽 위.
  /// 헤더 크롬보다 개발자가 지정한 시작 칸이 이깁니다.
  static FocusNode? preferredInitial(Iterable<FocusNode> candidates) {
    for (final FocusNode node in candidates) {
      if (autofocus[node] ?? false) {
        return node;
      }
    }
    return initialCandidate(candidates);
  }
}
