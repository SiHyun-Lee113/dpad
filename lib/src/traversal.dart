import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'marks.dart';
import 'nav_policy.dart';
import 'region.dart';
import 'scroll.dart';

/// TV 플랫폼처럼 탐색하는 [FocusTraversalPolicy].
///
/// Flutter 기본 방향 정책은 기하적으로 가장 가까운 노드를 고릅니다.
/// 실제 TV 레이아웃에서는 사이드바와 콘텐츠 사이 "레인 점프", 줄 건너뛰기,
/// 캐러셀 이탈이 생깁니다. 이 정책은 Android `FocusFinder`와 Leanback 모델을 따릅니다:
///
/// 1. **영역 우선** — 지금 [DpadRegion] 안 후보는 거리와 관계없이 바깥보다 이깁니다.
/// 2. **빔 우선** — 영역 *안*에서는 교차축에서 포커스 칸과 겹치는 후보("빔 안")가
///    대각선 후보를 이깁니다.
/// 3. **가장자리 동작** — 영역 경계에서 leave / stop / wrap ([DpadEdgeBehavior]).
/// 4. **읽기 순서** — [DpadRegionFlow.readingOrder] 영역은 기하 대신
///    좌우로만 칸을 걷고, 마지막 칸의 다음 방향은 첫 칸으로 순환합니다.
/// 5. **영역 핸드오프** — 영역을 떠날 때는 직선 빔이 닿는 칸이 아니라,
///    그 방향에서 가장 가까운 [DpadRegion]을 고른 뒤 **항상 그 영역의 첫 칸**에
///    착지합니다.
/// 6. **진입 동작** — 영역으로 넘어갈 때 착지 칸을 영역이 고릅니다
///    (메모리 복원 / entry / 최근접).
/// 7. **지연 리스트** — 후보가 없어도 그 방향으로 스크롤할 수 있으면 스크롤 후 재시도해,
///    캐시 밖 `ListView.builder` 줄에도 도달합니다.
///
/// [Dpad]와 [DpadRegion]이 이 정책을 자동으로 설치하므로 직접 만들 일은 거의 없습니다.
/// 수동으로 쓰려면:
///
/// ```dart
/// FocusTraversalGroup(
///   policy: DpadTraversalPolicy(),
///   child: ...,
/// )
/// ```
///
/// Tab / 스크린 리더 순서는 [ReadingOrderTraversalPolicy]로 떨어집니다.
class DpadTraversalPolicy extends ReadingOrderTraversalPolicy {
  /// TV 탐색 정책을 만듭니다.
  DpadTraversalPolicy();

  static const double _kAxisEpsilon = 0.01;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // 아직 실제 포커스가 없으면 합리적인 첫 칸에 착지.
    if (currentNode is FocusScopeNode) {
      final FocusNode? inner = currentNode.focusedChild;
      if (inner != null) {
        return inDirection(inner, direction);
      }
      return _focusInitial(currentNode, direction);
    }

    final FocusScopeNode? scope = currentNode.nearestScope;
    final Rect? currentRect = DpadMarks.rectOf(currentNode);
    if (scope == null || currentRect == null) {
      return super.inDirection(currentNode, direction);
    }

    final List<FocusNode> candidates = scope.traversalDescendants
        .where((FocusNode node) => !identical(node, currentNode))
        .toList();

    if (_isKiosk(currentNode)) {
      return _inKioskDirection(
        currentNode,
        currentRect,
        <FocusNode>[currentNode, ...candidates],
        direction,
      );
    }

    final DpadRegionState? region = DpadRegion.ofNode(currentNode);

    if (region != null) {
      final List<FocusNode> inRegion = candidates
          .where((FocusNode node) => identical(DpadRegion.ofNode(node), region))
          .toList();

      if (region.flow == DpadRegionFlow.readingOrder) {
        if (_isHorizontal(direction)) {
          final FocusNode? next = _readingOrderNeighbor(
            currentNode,
            inRegion,
            direction,
          );
          if (next != null) {
            return _focusNode(next, direction);
          }
        }

        // 상/하는 영역 안 칸을 건너뛰고 가장자리·바깥으로.
        if (_scrollForMore(currentNode, direction, boundary: region.context)) {
          return true;
        }

        switch (region.edgeBehaviorFor(direction)) {
          case DpadEdgeBehavior.stop:
            region.notifyEdge(direction);
            return true;
          case DpadEdgeBehavior.wrap:
            final FocusNode? wrapped = _readingOrderWrap(
              currentNode,
              inRegion,
              direction,
            );
            if (wrapped != null) {
              return _focusNode(wrapped, direction);
            }
            region.notifyEdge(direction);
            return true;
          case DpadEdgeBehavior.leave:
            break;
        }
      } else {
        final FocusNode? within =
            _bestCandidate(currentRect, inRegion, direction);
        if (within != null) {
          return _focusNode(within, direction);
        }

        // 영역에 아직 빌드되지 않은 콘텐츠가 더 있을 수 있음.
        if (_scrollForMore(currentNode, direction, boundary: region.context)) {
          return true;
        }

        switch (region.edgeBehaviorFor(direction)) {
          case DpadEdgeBehavior.stop:
            region.notifyEdge(direction);
            return true;
          case DpadEdgeBehavior.wrap:
            final FocusNode? wrapped =
                _wrapCandidate(currentRect, inRegion, direction);
            if (wrapped != null) {
              return _focusNode(wrapped, direction);
            }
            region.notifyEdge(direction);
            return true;
          case DpadEdgeBehavior.leave:
            break;
        }
      }
    }

    // 영역 밖 / 전역 검색: 칸이 아니라 그 방향의 다음 영역을 고릅니다.
    final List<FocusNode> outside = region == null
        ? candidates
        : candidates
            .where(
                (FocusNode node) => !identical(DpadRegion.ofNode(node), region))
            .toList();

    final FocusNode? target =
        _bestOutsideTarget(currentRect, outside, direction);
    if (target == null) {
      // 어디에도 없음 — 바깥 페이지 스크롤이 지연 빌드된 줄·그리드를 드러낼 수 있음.
      return _scrollForMore(currentNode, direction);
    }
    return _focusNode(target, direction);
  }

  // ---------------------------------------------------------------------
  // 포커스 + 초기 착지
  // ---------------------------------------------------------------------

  bool _focusNode(FocusNode node, TraversalDirection direction) {
    DpadRegion.ofNode(node)?.noteFocus(node);
    node.requestFocus();
    // DpadFocusable 노드는 포커스 시 자체 패딩 스크롤을 합니다.
    // 일반 Focus 노드는 잘리지 않게 기본 스크롤만 합니다.
    if (DpadMarks.managed[node] != true) {
      DpadScroll.ensureVisible(node);
    }
    return true;
  }

  bool _focusInitial(FocusScopeNode scope, TraversalDirection direction) {
    final FocusNode? target =
        DpadMarks.initialCandidate(scope.traversalDescendants);
    if (target == null) {
      return false;
    }
    return _focusNode(target, direction);
  }

  // ---------------------------------------------------------------------
  // 기하 — Android FocusFinder 모델
  // ---------------------------------------------------------------------

  /// [candidate]가 [source]에서 [direction] 방향에 있는지.
  ///
  /// 가장자리 기준이라, 큰 타일·배너처럼 소스를 일부 겹쳐도 후보가 됩니다.
  static bool _isCandidate(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.left:
        return (source.right > candidate.right ||
                source.left >= candidate.right) &&
            source.left > candidate.left;
      case TraversalDirection.right:
        return (source.left < candidate.left ||
                source.right <= candidate.left) &&
            source.right < candidate.right;
      case TraversalDirection.up:
        return (source.bottom > candidate.bottom ||
                source.top >= candidate.bottom) &&
            source.top > candidate.top;
      case TraversalDirection.down:
        return (source.top < candidate.top ||
                source.bottom <= candidate.bottom) &&
            source.bottom < candidate.bottom;
    }
  }

  /// 탐색 축에서 소스 앞쪽 가장자리에서 후보 뒤쪽 가장자리까지 거리.
  /// 겹치면 0으로 클램프합니다.
  static double _majorDistance(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    final double distance;
    switch (direction) {
      case TraversalDirection.left:
        distance = source.left - candidate.right;
      case TraversalDirection.right:
        distance = candidate.left - source.right;
      case TraversalDirection.up:
        distance = source.top - candidate.bottom;
      case TraversalDirection.down:
        distance = candidate.top - source.bottom;
    }
    return distance < 0 ? 0 : distance;
  }

  /// 교차축에서 중심 사이 거리.
  static double _minorDistance(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.left:
      case TraversalDirection.right:
        return (candidate.center.dy - source.center.dy).abs();
      case TraversalDirection.up:
      case TraversalDirection.down:
        return (candidate.center.dx - source.center.dx).abs();
    }
  }

  /// [candidate]가 교차축에서 [source]와 겹치는지.
  static bool _inBeam(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.left:
      case TraversalDirection.right:
        return candidate.bottom > source.top && candidate.top < source.bottom;
      case TraversalDirection.up:
      case TraversalDirection.down:
        return candidate.right > source.left && candidate.left < source.right;
    }
  }

  /// Android의 가중 거리: 주축 진행이 크고, 교차축 이탈로 동점을 가릅니다.
  static double _weightedDistance(double major, double minor) {
    return 13 * major * major + minor * minor;
  }

  FocusNode? _bestCandidate(
    Rect source,
    List<FocusNode> candidates,
    TraversalDirection direction,
  ) {
    FocusNode? best;
    bool bestInBeam = false;
    double bestScore = double.infinity;

    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null || rect == source) {
        continue;
      }
      if (!_isCandidate(source, rect, direction)) {
        continue;
      }
      final bool inBeam = _inBeam(source, rect, direction);
      final double score = _weightedDistance(
        _majorDistance(source, rect, direction),
        _minorDistance(source, rect, direction),
      );
      // 빔 안 후보는 빔 밖 후보를 무조건 이깁니다.
      if (best == null ||
          (inBeam && !bestInBeam) ||
          (inBeam == bestInBeam && score < bestScore)) {
        best = node;
        bestInBeam = inBeam;
        bestScore = score;
      }
    }
    return best;
  }

  /// 영역 밖 타깃: 직선 빔이 닿는 칸이 아니라, 그 방향에서 가장 가까운 영역.
  ///
  /// 바깥에 [DpadRegion]이 하나도 없으면 기존 빔 탐색으로 떨어집니다.
  FocusNode? _bestOutsideTarget(
    Rect source,
    List<FocusNode> outside,
    TraversalDirection direction,
  ) {
    final List<_RegionGroup> groups = _groupByRegion(outside);
    if (groups.isEmpty) {
      return null;
    }
    if (groups.every((_RegionGroup group) => group.region == null)) {
      return _bestCandidate(source, outside, direction);
    }

    _RegionGroup? best;
    double bestMajor = double.infinity;
    double bestMinor = double.infinity;

    for (final _RegionGroup group in groups) {
      if (!_isCandidate(source, group.bounds, direction)) {
        continue;
      }
      final double major = _majorDistance(source, group.bounds, direction);
      final double minor = _minorDistance(source, group.bounds, direction);
      final bool better;
      if (best == null) {
        better = true;
      } else if ((major - bestMajor).abs() > _kAxisEpsilon) {
        better = major < bestMajor;
      } else {
        better = minor < bestMinor;
      }
      if (better) {
        best = group;
        bestMajor = major;
        bestMinor = minor;
      }
    }
    if (best == null) {
      return null;
    }

    final FocusNode geometric = _bestCandidate(source, best.nodes, direction) ??
        DpadMarks.initialCandidate(best.nodes) ??
        best.nodes.first;
    final DpadRegionState? region = best.region;
    if (region == null) {
      return geometric;
    }
    return region.firstFocusable ?? geometric;
  }

  List<_RegionGroup> _groupByRegion(List<FocusNode> nodes) {
    final Map<DpadRegionState, List<FocusNode>> regions =
        <DpadRegionState, List<FocusNode>>{};
    final List<_RegionGroup> groups = <_RegionGroup>[];

    for (final FocusNode node in nodes) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      final DpadRegionState? region = DpadRegion.ofNode(node);
      if (region == null) {
        groups.add(
          _RegionGroup(
            region: null,
            nodes: <FocusNode>[node],
            bounds: rect,
          ),
        );
        continue;
      }
      regions.putIfAbsent(region, () => <FocusNode>[]).add(node);
    }

    for (final MapEntry<DpadRegionState, List<FocusNode>> entry
        in regions.entries) {
      final Rect? bounds = _unionRect(entry.value);
      if (bounds == null) {
        continue;
      }
      groups.add(
        _RegionGroup(
          region: entry.key,
          nodes: entry.value,
          bounds: bounds,
        ),
      );
    }
    return groups;
  }

  static Rect? _unionRect(List<FocusNode> nodes) {
    Rect? bounds;
    for (final FocusNode node in nodes) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds;
  }

  /// wrap 타깃: 탐색 축에서 소스 *뒤쪽*으로 가장 먼 영역 안 칸.
  /// 소스의 빔을 우선합니다.
  FocusNode? _wrapCandidate(
    Rect source,
    List<FocusNode> candidates,
    TraversalDirection direction,
  ) {
    final TraversalDirection reverse = _reverseOf(direction);
    FocusNode? best;
    bool bestInBeam = false;
    double bestMajor = -1;
    double bestMinor = double.infinity;

    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null || rect == source) {
        continue;
      }
      if (!_isCandidate(source, rect, reverse)) {
        continue;
      }
      final bool inBeam = _inBeam(source, rect, direction);
      final double major = _majorDistance(source, rect, reverse);
      final double minor = _minorDistance(source, rect, reverse);

      final bool better;
      if (best == null) {
        better = true;
      } else if (inBeam != bestInBeam) {
        better = inBeam;
      } else if ((major - bestMajor).abs() > _kAxisEpsilon) {
        better = major > bestMajor;
      } else {
        better = minor < bestMinor;
      }
      if (better) {
        best = node;
        bestInBeam = inBeam;
        bestMajor = major;
        bestMinor = minor;
      }
    }
    return best;
  }

  static TraversalDirection _reverseOf(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.up:
        return TraversalDirection.down;
      case TraversalDirection.down:
        return TraversalDirection.up;
      case TraversalDirection.left:
        return TraversalDirection.right;
      case TraversalDirection.right:
        return TraversalDirection.left;
    }
  }

  static bool _isHorizontal(TraversalDirection direction) {
    return direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
  }

  static bool _isKiosk(FocusNode node) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return false;
    }
    return DpadNavScope.of(context) == DpadNavPolicy.kiosk;
  }

  /// 키오스크: 좌우는 같은 영역, 상하는 영역 순환.
  bool _inKioskDirection(
    FocusNode current,
    Rect currentRect,
    List<FocusNode> all,
    TraversalDirection direction,
  ) {
    if (_isHorizontal(direction)) {
      return _kioskHorizontal(current, all, direction);
    }
    return _kioskVertical(current, all, direction);
  }

  bool _kioskHorizontal(
    FocusNode current,
    List<FocusNode> all,
    TraversalDirection direction,
  ) {
    final List<FocusNode> peers = _kioskHorizontalPeers(current, all);
    if (peers.length <= 1) {
      return true;
    }
    final List<FocusNode> ordered = _readingOrder(peers);
    final int index = ordered.indexOf(current);
    if (index < 0) {
      return true;
    }
    final int next = _wrapIndex(
      index,
      ordered.length,
      forward: direction == TraversalDirection.right,
    );
    if (next == index) {
      return true;
    }
    return _focusNode(ordered[next], direction);
  }

  List<FocusNode> _kioskHorizontalPeers(FocusNode current, List<FocusNode> all) {
    final DpadRegionState? item = _itemRegion(current);
    if (item != null) {
      if (item.isHost(current)) {
        return <FocusNode>[current];
      }
      return all
          .where(
            (FocusNode node) =>
                !item.isHost(node) &&
                _isKioskTraversable(node) &&
                identical(DpadRegion.ofNode(node), item),
          )
          .toList();
    }
    final DpadRegionState? region = DpadRegion.ofNode(current);
    if (region != null) {
      return all
          .where(
            (FocusNode node) =>
                _isKioskTraversable(node) &&
                identical(DpadRegion.ofNode(node), region),
          )
          .toList();
    }
    final Rect? currentRect = DpadMarks.rectOf(current);
    if (currentRect == null) {
      return <FocusNode>[current];
    }
    return all.where((FocusNode node) {
      if (!_isKioskTraversable(node)) {
        return false;
      }
      if (DpadRegion.ofNode(node) != null) {
        return false;
      }
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        return false;
      }
      return _sameRow(currentRect, rect);
    }).toList();
  }

  bool _kioskVertical(
    FocusNode current,
    List<FocusNode> all,
    TraversalDirection direction,
  ) {
    final DpadRegionState? item = _itemRegion(current);
    if (item != null) {
      return _kioskItemVertical(item, current, all, direction);
    }
    return _kioskVerticalBands(current, all, direction);
  }

  bool _kioskItemVertical(
    DpadRegionState item,
    FocusNode current,
    List<FocusNode> all,
    TraversalDirection direction,
  ) {
    final DpadRegionState? list = item.enclosingList;
    final List<DpadRegionState> items =
        list?.childItems ?? <DpadRegionState>[item];
    final int index = items.indexWhere(
      (DpadRegionState region) => identical(region, item),
    );
    if (index < 0) {
      return true;
    }
    if (direction == TraversalDirection.down && index + 1 < items.length) {
      return items[index + 1].requestLandingFocus();
    }
    if (direction == TraversalDirection.up && index > 0) {
      return items[index - 1].requestLandingFocus();
    }
    final FocusNode from = item.hostNode ?? current;
    return _kioskVerticalBands(from, all, direction);
  }

  bool _kioskVerticalBands(
    FocusNode current,
    List<FocusNode> all,
    TraversalDirection direction,
  ) {
    final List<_KioskBand> bands = _kioskBands(all);
    if (bands.length <= 1) {
      return true;
    }
    final int index = bands.indexWhere(
      (_KioskBand band) => band.contains(current),
    );
    if (index < 0) {
      return true;
    }
    final int next = _wrapIndex(
      index,
      bands.length,
      forward: direction == TraversalDirection.down,
    );
    if (next == index) {
      return true;
    }
    return _focusKioskBand(bands[next], direction);
  }

  bool _focusKioskBand(_KioskBand band, TraversalDirection direction) {
    if (band.region != null) {
      if (band.region!.requestLandingFocus()) {
        return true;
      }
    }
    if (band.nodes.isEmpty) {
      return true;
    }
    final FocusNode target = DpadMarks.preferredInitial(band.nodes) ??
        band.nodes.first;
    if (!DpadMarks.isUsable(target)) {
      return true;
    }
    return _focusNode(target, direction);
  }

  bool _isKioskTraversable(FocusNode node) {
    return DpadMarks.isUsable(node) && !node.skipTraversal;
  }

  DpadRegionState? _itemRegion(FocusNode node) {
    final DpadRegionState? region = DpadRegion.ofNode(node);
    if (region != null && region.kind == DpadRegionKind.item) {
      return region;
    }
    return null;
  }

  List<_KioskBand> _kioskBands(List<FocusNode> all) {
    final Set<DpadRegionState> lists = <DpadRegionState>{};
    final Map<DpadRegionState, List<FocusNode>> byRegion =
        <DpadRegionState, List<FocusNode>>{};
    final List<FocusNode> ungrouped = <FocusNode>[];

    for (final FocusNode node in all) {
      final DpadRegionState? region = DpadRegion.ofNode(node);
      final DpadRegionState? list = region?.enclosingList;
      if (list != null) {
        lists.add(list);
        continue;
      }
      if (region != null && region.kind == DpadRegionKind.item) {
        final FocusNode? host = region.hostNode;
        if (host != null && DpadMarks.isUsable(host)) {
          byRegion.putIfAbsent(region, () => <FocusNode>[host]);
        }
        continue;
      }
      if (!_isKioskTraversable(node) || DpadMarks.rectOf(node) == null) {
        continue;
      }
      if (region == null) {
        ungrouped.add(node);
      } else {
        byRegion.putIfAbsent(region, () => <FocusNode>[]).add(node);
      }
    }

    final List<_KioskBand> bands = <_KioskBand>[];
    for (final DpadRegionState list in lists) {
      final List<FocusNode> nodes = _listBandNodes(list);
      if (nodes.isNotEmpty) {
        bands.add(_KioskBand(region: list, nodes: nodes));
      }
    }
    for (final MapEntry<DpadRegionState, List<FocusNode>> entry
        in byRegion.entries) {
      bands.add(_KioskBand(region: entry.key, nodes: entry.value));
    }
    for (final List<FocusNode> row in _clusterRows(ungrouped)) {
      bands.add(_KioskBand(region: null, nodes: row));
    }

    bands.sort((_KioskBand a, _KioskBand b) {
      if (_sameRow(a.bounds, b.bounds)) {
        return a.bounds.left.compareTo(b.bounds.left);
      }
      return a.bounds.top.compareTo(b.bounds.top);
    });
    return bands;
  }

  List<FocusNode> _listBandNodes(DpadRegionState list) {
    final List<FocusNode> nodes = <FocusNode>[];
    for (final DpadRegionState item in list.childItems) {
      final FocusNode? host = item.hostNode;
      if (host != null && DpadMarks.isUsable(host)) {
        nodes.add(host);
      }
    }
    return nodes;
  }

  static bool _sameRow(Rect a, Rect b) {
    final double overlap =
        math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
    final double minHeight = math.min(a.height, b.height);
    return overlap > minHeight * 0.5;
  }

  static int _wrapIndex(int index, int length, {required bool forward}) {
    if (length <= 0) {
      return index;
    }
    if (forward) {
      return (index + 1) % length;
    }
    return (index - 1 + length) % length;
  }

  List<List<FocusNode>> _clusterRows(List<FocusNode> nodes) {
    final List<FocusNode> ordered = _readingOrder(nodes);
    final List<List<FocusNode>> rows = <List<FocusNode>>[];
    for (final FocusNode node in ordered) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      if (rows.isNotEmpty) {
        final Rect rowBounds = _boundsOf(rows.last);
        if (_sameRow(rowBounds, rect)) {
          rows.last.add(node);
          continue;
        }
      }
      rows.add(<FocusNode>[node]);
    }
    return rows;
  }

  static Rect _boundsOf(List<FocusNode> nodes) {
    Rect? bounds;
    for (final FocusNode node in nodes) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds ?? Rect.zero;
  }

  /// [DpadRegionFlow.readingOrder]용. 좌우는 읽기 순서로 한 칸 이동하고,
  /// 끝에서는 반대편으로 순환합니다.
  FocusNode? _readingOrderNeighbor(
    FocusNode current,
    List<FocusNode> others,
    TraversalDirection direction,
  ) {
    final List<FocusNode> ordered =
        _readingOrder(<FocusNode>[current, ...others]);
    if (ordered.isEmpty) {
      return null;
    }
    final int index = ordered.indexOf(current);
    if (index < 0) {
      return null;
    }
    if (direction == TraversalDirection.right) {
      return ordered[(index + 1) % ordered.length];
    }
    if (direction == TraversalDirection.left) {
      return ordered[(index - 1 + ordered.length) % ordered.length];
    }
    return null;
  }

  /// 읽기 순서 영역에서 상/하 wrap: 아래는 첫 칸, 위는 마지막 칸.
  FocusNode? _readingOrderWrap(
    FocusNode current,
    List<FocusNode> others,
    TraversalDirection direction,
  ) {
    final List<FocusNode> ordered =
        _readingOrder(<FocusNode>[current, ...others]);
    if (ordered.length < 2) {
      return null;
    }
    switch (direction) {
      case TraversalDirection.down:
      case TraversalDirection.right:
        return ordered.first;
      case TraversalDirection.up:
      case TraversalDirection.left:
        return ordered.last;
    }
  }

  /// 위→아래, 같은 줄은 왼→오른쪽.
  List<FocusNode> _readingOrder(List<FocusNode> nodes) {
    final List<({FocusNode node, Rect rect})> located =
        <({FocusNode node, Rect rect})>[];
    for (final FocusNode node in nodes) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect != null) {
        located.add((node: node, rect: rect));
      }
    }
    located.sort((a, b) {
      final double overlap = math.min(a.rect.bottom, b.rect.bottom) -
          math.max(a.rect.top, b.rect.top);
      final double minHeight = math.min(a.rect.height, b.rect.height);
      if (overlap > minHeight * 0.5) {
        return a.rect.left.compareTo(b.rect.left);
      }
      return a.rect.top.compareTo(b.rect.top);
    });
    return located.map((e) => e.node).toList();
  }

  // ---------------------------------------------------------------------
  // 지연 콘텐츠 스크롤
  // ---------------------------------------------------------------------

  /// 후보가 없으면, 노드와 [boundary] 사이에서 같은 축의 가장 가까운
  /// 스크롤을 한 칸 더 움직인 뒤, 새 콘텐츠가 레이아웃되면 검색을 다시 합니다.
  ///
  /// 스크롤을 시작했으면 `true`를 반환하고, 키는 소비됩니다.
  bool _scrollForMore(
    FocusNode node,
    TraversalDirection direction, {
    BuildContext? boundary,
  }) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return false;
    }

    ScrollableState? match;
    context.visitAncestorElements((Element element) {
      if (boundary != null && identical(element, boundary)) {
        return false;
      }
      if (element is StatefulElement && element.state is ScrollableState) {
        final ScrollableState scrollable = element.state as ScrollableState;
        if (_canScrollToward(scrollable, direction)) {
          match = scrollable;
          return false;
        }
      }
      return true;
    });

    final ScrollableState? scrollable = match;
    if (scrollable == null) {
      return false;
    }

    final ScrollPosition position = scrollable.position;
    final bool forward = _isForward(scrollable.axisDirection, direction);
    final double step = position.viewportDimension * 0.8;
    final double offset = (position.pixels + (forward ? step : -step)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    position
        .animateTo(
      offset,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      // 새로 빌드된 콘텐츠가 자리 잡으면 한 번 더 시도.
      if (!node.hasPrimaryFocus || node.context == null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (node.hasPrimaryFocus && node.context != null) {
          inDirection(node, direction);
        }
      });
    });
    return true;
  }

  static bool _canScrollToward(
    ScrollableState scrollable,
    TraversalDirection direction,
  ) {
    final Axis axis = axisDirectionToAxis(scrollable.axisDirection);
    final bool horizontal = direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    if (horizontal != (axis == Axis.horizontal)) {
      return false;
    }
    final ScrollPosition position = scrollable.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }
    final bool forward = _isForward(scrollable.axisDirection, direction);
    return forward
        ? position.pixels < position.maxScrollExtent - 1.0
        : position.pixels > position.minScrollExtent + 1.0;
  }

  /// [direction]으로 움직이는 것이 주어진 [axisDirection]에서
  /// 스크롤 픽셀을 늘리는 방향인지.
  static bool _isForward(
    AxisDirection axisDirection,
    TraversalDirection direction,
  ) {
    switch (axisDirection) {
      case AxisDirection.down:
        return direction == TraversalDirection.down;
      case AxisDirection.up:
        return direction == TraversalDirection.up;
      case AxisDirection.right:
        return direction == TraversalDirection.right;
      case AxisDirection.left:
        return direction == TraversalDirection.left;
    }
  }
}

class _RegionGroup {
  const _RegionGroup({
    required this.region,
    required this.nodes,
    required this.bounds,
  });

  final DpadRegionState? region;
  final List<FocusNode> nodes;
  final Rect bounds;
}

class _KioskBand {
  _KioskBand({required this.region, required this.nodes})
      : bounds = DpadTraversalPolicy._boundsOf(nodes);

  final DpadRegionState? region;
  final List<FocusNode> nodes;
  final Rect bounds;

  bool contains(FocusNode node) => nodes.contains(node);
}
