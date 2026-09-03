import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// TV용 "화면에 보이게" 스크롤.
///
/// [Scrollable.ensureVisible]과 다른 점:
///
/// * 칸과 뷰포트 가장자리 사이에 [padding]을 남겨, 포커스 글로우·테두리·확대가
///   잘리지 않습니다;
/// * **모든** 스크롤 조상을 한 번에 걷습니다. 세로 페이지 안의 가로 줄도
///   한 호출로 처리합니다;
/// * 역방향 스크롤을 존중합니다;
/// * 뷰포트보다 큰 칸은 가운데로 맞춥니다.
abstract final class DpadScroll {
  /// [node]의 모든 스크롤 조상을 움직여, 렌더 박스가 [padding]을 두고
  /// 완전히 보이게 합니다.
  ///
  /// [node]가 레이아웃된 렌더 오브젝트에 붙어 있지 않으면 아무 것도 하지 않습니다.
  static void ensureVisible(
    FocusNode node, {
    double padding = 48.0,
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return;
    }
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return;
    }

    final List<ScrollableState> scrollables = <ScrollableState>[];
    context.visitAncestorElements((Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        scrollables.add(element.state as ScrollableState);
      }
      return true;
    });

    for (final ScrollableState scrollable in scrollables) {
      _revealIn(
        scrollable,
        renderObject,
        padding: padding,
        duration: duration,
        curve: curve,
      );
    }
  }

  static void _revealIn(
    ScrollableState scrollable,
    RenderBox target, {
    required double padding,
    required Duration duration,
    required Curve curve,
  }) {
    final RenderObject? viewportObject = scrollable.context.findRenderObject();
    if (viewportObject is! RenderBox || !viewportObject.hasSize) {
      return;
    }
    if (!scrollable.position.hasPixels ||
        !scrollable.position.hasContentDimensions) {
      return;
    }

    final ScrollPosition position = scrollable.position;
    final AxisDirection axisDirection = scrollable.axisDirection;
    final bool horizontal =
        axisDirectionToAxis(axisDirection) == Axis.horizontal;

    final Rect bounds = MatrixUtils.transformRect(
      target.getTransformTo(viewportObject),
      Offset.zero & target.size,
    );

    final double targetStart = horizontal ? bounds.left : bounds.top;
    final double targetEnd = horizontal ? bounds.right : bounds.bottom;
    final double viewportExtent =
        horizontal ? viewportObject.size.width : viewportObject.size.height;
    final double targetExtent = targetEnd - targetStart;

    // 패딩이 남은 뷰포트 공간을 넘지 않게 해, 큰 칸도 무리 없이 처리합니다.
    final double pad = math.max(
      0.0,
      math.min(padding, (viewportExtent - targetExtent) / 2),
    );

    double geometricDelta;
    if (targetExtent + pad * 2 > viewportExtent) {
      // 뷰포트보다 크면 가운데로.
      geometricDelta = (targetStart + targetEnd) / 2 - viewportExtent / 2;
    } else if (targetStart < pad) {
      geometricDelta = targetStart - pad;
    } else if (targetEnd > viewportExtent - pad) {
      geometricDelta = targetEnd - (viewportExtent - pad);
    } else {
      return; // 이미 패딩을 두고 완전히 보임.
    }

    // 기하 델타가 양수면 콘텐츠가 시작 쪽으로 가야 합니다.
    // 정방향 축에서는 픽셀이 늘고, 역방향 축에서는 줄어듭니다.
    final bool reversed = axisDirection == AxisDirection.up ||
        axisDirection == AxisDirection.left;
    final double pixelsDelta = reversed ? -geometricDelta : geometricDelta;

    final double offset = (position.pixels + pixelsDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((offset - position.pixels).abs() < 0.5) {
      return;
    }
    if (duration == Duration.zero) {
      position.jumpTo(offset);
    } else {
      position.animateTo(offset, duration: duration, curve: curve);
    }
  }
}
