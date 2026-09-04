import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'key_set.dart';
import 'marks.dart';
import 'scroll.dart';
import 'theme.dart';
import 'traversal.dart';

/// [DpadRegion] 가장자리에 D-pad 탐색이 닿았을 때, 그 축에서 할 일.
enum DpadEdgeBehavior {
  /// 포커스가 영역을 떠나, 그 방향에서 가장 가까운 [DpadRegion]으로 갑니다.
  /// 직선 빔이 먼저 닿는 칸이 아니라 영역 단위로 고릅니다.
  /// **세로** 축의 기본값입니다.
  leave,

  /// 포커스는 그대로입니다. 키는 소비되고 [DpadRegion.onEdge]가 호출됩니다.
  /// 가장자리 "bump" 애니메이션이나 효과음에 쓰세요.
  ///
  /// 실수로 빠져나가면 안 되는 패널에 맞습니다.
  /// **가로** 축의 기본값입니다 (좌/우는 현재 영역에 머무름).
  stop,

  /// 캐러셀처럼 영역 반대편으로 포커스가 돌아갑니다.
  ///
  /// 해당 축에서 wrap이 켜져 있으면, 그 축으로는 영역을 떠나지 않습니다.
  wrap,
}

/// [DpadRegion] 안에서 방향키가 칸을 고르는 방식.
enum DpadRegionFlow {
  /// 기하 탐색 (기본값). Android `FocusFinder`처럼 빔·거리로 고릅니다.
  ///
  /// 4×2 그리드에서 4번 칸의 오른쪽은 비어 있으므로 우 키는 이동하지 않고,
  /// 아래 줄의 5번으로 가지 않습니다.
  geometric,

  /// 읽기 순서. 영역 안 칸을 위→아래, 같은 줄은 왼→오른쪽으로 한 줄로 보고
  /// **좌우 키만**으로 이동합니다. 4×2 그리드에서 4번 우 키는 5번으로 갑니다.
  ///
  /// 마지막 칸에서 우(또는 첫 칸에서 좌)를 누르면 반대쪽 끝으로 순환합니다.
  /// 상/하 키는 영역 안 칸을 고르지 않고 [DpadRegion.verticalEdge]를 따릅니다.
  readingOrder,
}

/// 다른 영역에서 [DpadRegion]으로 들어올 때, 어느 칸에 포커스를 줄지.
enum DpadEnterBehavior {
  /// 이 영역이 마지막으로 포커스를 가졌던 칸으로 복원합니다.
  /// TV 포스터 줄·사이드바에서 기대하는 동작입니다.
  ///
  /// 복원할 것이 없으면 entry 칸([DpadFocusable.entry]), 그다음
  /// 기하학적으로 가장 가까운 칸으로 떨어집니다.
  restore,

  /// 항상 영역의 첫 칸: [DpadFocusable.entry]가 있으면 그 칸,
  /// 없으면 가장 왼쪽 위 칸.
  ///
  /// 기본값입니다. 가로 축 [DpadEdgeBehavior.stop]과 함께 쓰면
  /// 상/하는 영역을 바꾸고 첫 칸에 착지하고, 좌/우는 현재 영역에 머무릅니다.
  first,

  /// 항상 영역의 entry 칸([DpadFocusable.entry]).
  /// 표시된 칸이 없으면 기하학적으로 가장 가까운 칸.
  entry,

  /// 기하학적으로 가장 가까운 칸. 일반 Flutter 탐색과 같습니다.
  nearest,
}

/// [DpadRegion]이 화면 탐색에서 하는 역할.
enum DpadRegionKind {
  /// 일반 영역. 키오스크 상/하에서 한 밴드입니다.
  /// 안의 칸은 바로 포커스됩니다.
  surface,

  /// 세로 목록 (장바구니). 화면 상/하에서는 **한 밴드**입니다.
  /// 들어오면 첫 [DpadRegionKind.item] 줄이 선택되고,
  /// Enter로 그 줄 안 위젯에 들어갑니다.
  list,

  /// 목록의 한 줄. 같은 [DpadRegionKind.list] 안에서 상/하로
  /// 이웃 줄로 이동합니다. 줄이 선택되면 줄 전체가 하이라이트되고,
  /// Enter로 줄 안 [DpadFocusable]로 들어갑니다. 들어간 뒤에는
  /// 줄 하이라이트는 끄고 자식 칸만 표시합니다.
  item,
}

/// 포커스 칸들을 TV 의미의 탐색 구역으로 묶습니다.
///
/// 실제 TV UI는 *영역*으로 구성됩니다 — 사이드바, 포스터 줄, 설정 그리드.
/// [DpadRegion]은 서브트리에 그 의미를 선언적으로 줍니다:
///
/// * **영역 우선 탐색** — 지금 [DpadRegion] 안 후보가, 거리와 관계없이
///   바깥 후보보다 항상 이깁니다.
/// * **포커스 메모리** — 다시 들어올 때 [enter]가 착지 칸을 고릅니다
///   (기본값 [DpadEnterBehavior.first]).
/// * **가장자리 제어** — 축마다 leave / stop / wrap ([DpadEdgeBehavior]).
///   가로는 기본 **stop**이라 좌/우가 줄을 벗어나지 않고,
///   세로는 기본 **leave**라 상/하가 영역 사이를 이동합니다.
/// * **읽기 순서 흐름** — [DpadRegionFlow.readingOrder]면 그리드에서도
///   좌우만으로 칸을 걷고, 마지막 칸의 다음 방향은 첫 칸으로 순환합니다.
///
/// ```dart
/// DpadRegion(
///   // 캐러셀: 가로는 wrap, 선택한 포스터를 기억.
///   horizontalEdge: DpadEdgeBehavior.wrap,
///   child: SizedBox(
///     height: 200,
///     child: ListView(scrollDirection: Axis.horizontal, children: posters),
///   ),
/// )
/// ```
///
/// 장바구니처럼 세로 목록은 [DpadRegionKind.list]로 감싸고,
/// 각 상품 줄은 [DpadRegionKind.item]입니다. 키오스크에서 목록에
/// 들어오면 첫 줄 전체가 선택되고, Enter로 줄 안 [DpadFocusable]에
/// 들어갑니다. 줄에서 상/하는 다음/이전 상품으로 갑니다.
///
/// 영역은 중첩됩니다. 각 [DpadFocusable]은 *가장 가까운* 조상 영역에 속합니다.
class DpadRegion extends StatefulWidget {
  /// [child]을 감싸는 탐색 영역을 만듭니다.
  const DpadRegion({
    super.key,
    required this.child,
    this.autofocus = false,
    this.enter = DpadEnterBehavior.first,
    this.flow = DpadRegionFlow.geometric,
    this.horizontalEdge = DpadEdgeBehavior.stop,
    this.verticalEdge = DpadEdgeBehavior.leave,
    this.kind = DpadRegionKind.surface,
    this.memoryKey,
    this.onEdge,
    this.onFocusChange,
    this.debugLabel,
    this.ttsLabel,
  });

  /// 이 영역에 속하는 포커스 칸들의 서브트리.
  final Widget child;

  /// `true`이면 이 영역이 **처음 나타날 때** 첫 칸에 포커스를 줍니다.
  ///
  /// 키오스크처럼 헤더에 "처음으로"가 있는 화면에서, 본문 영역에 이 플래그를
  /// 두면 기하학적인 왼쪽 위 크롬이 아니라 메뉴/개발자가 지정한 칸에서
  /// 시작합니다. 착지 칸은 [DpadFocusable.autofocus], 없으면 [entry],
  /// 없으면 영역 안 왼쪽 위입니다.
  ///
  /// [Navigator]로 화면을 바꿀 때도 새 페이지가 이 플래그로 포커스를
  /// 가져갑니다. 이전 페이지 마지막 칸에 포커스가 남지 않습니다.
  ///
  /// 영역 [State]가 살아 있는 동안에는 다시 클레임하지 않습니다.
  /// 화면을 바꿀 때 새 영역이 마운트되면 그때 다시 가져갑니다.
  final bool autofocus;

  /// 리빌드 후에도 이 영역의 포커스 메모리를 유지합니다.
  ///
  /// 키가 없으면 메모리는 [State]에만 있어, 서브트리를 처음부터 다시 만들면
  /// 사라집니다 — `IndexedStack` 없는 탭처럼 섹션을 바꾸면 위치를 잊는
  /// TV의 전형적인 함정입니다. 앱 안에서 유일한 안정적인 문자열을 주면
  /// 어떤 리빌드에도 메모리가 남습니다:
  ///
  /// ```dart
  /// DpadRegion(
  ///   memoryKey: 'home/trending-row',
  ///   child: trendingRow,
  /// )
  /// ```
  ///
  /// 복원은 위치를 봅니다. 정확한 인스턴스가 없어져도(리빌드),
  /// 기억한 좌표에 가장 가까운 칸을 고릅니다.
  final String? memoryKey;

  /// 바깥에서 이 영역으로 들어올 때 착지 방식.
  /// 기본값은 [DpadEnterBehavior.first] (첫 칸 / 왼쪽 위).
  final DpadEnterBehavior enter;

  /// 영역 안에서 방향키가 다음 칸을 고르는 방식.
  /// 기본값은 [DpadRegionFlow.geometric].
  ///
  /// 키오스크 메뉴 그리드처럼 줄이 바뀌어도 좌우로만 걷게 하려면
  /// [DpadRegionFlow.readingOrder]를 씁니다.
  final DpadRegionFlow flow;

  /// 영역의 마지막 칸에서 좌/우로 더 나갈 때의 동작.
  final DpadEdgeBehavior horizontalEdge;

  /// 영역의 마지막 칸에서 상/하로 더 나갈 때의 동작.
  final DpadEdgeBehavior verticalEdge;

  /// [DpadEdgeBehavior.stop] 가장자리에 닿거나,
  /// wrap할 칸이 없는 [DpadEdgeBehavior.wrap]에서 호출됩니다.
  final ValueChanged<TraversalDirection>? onEdge;

  /// 포커스가 영역에 들어오면 `true`, 나가면 `false`.
  /// 활성 섹션 강조에 쓰세요.
  final ValueChanged<bool>? onFocusChange;

  /// 포커스 디버그 출력에 보이는 라벨.
  final String? debugLabel;

  /// 이 영역으로 들어올 때 [Dpad.ttsService]가 읽는 문구.
  ///
  /// 같은 화면 안에서 영역이 바뀌면 스크린 라벨 없이 이 문구와 칸
  /// 라벨을 이어서 읽습니다. [DpadRegionKind.item] 줄이 선택됐을 때도
  /// 줄 호스트의 안내로 쓰입니다.
  final String? ttsLabel;

  /// 화면 탐색에서 이 영역의 역할. 기본값은 [DpadRegionKind.surface].
  ///
  /// 장바구니처럼 세로 목록이면 바깥은 [DpadRegionKind.list],
  /// 각 상품 줄은 [DpadRegionKind.item]입니다.
  final DpadRegionKind kind;

  /// 가장 가까운 조상 [DpadRegion]의 state. 없으면 `null`.
  ///
  /// 빌드 의존성을 만들지 않습니다.
  static DpadRegionState? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadRegionScope>()?.state;
  }

  /// [node]가 속한 영역. 없으면 `null`.
  static DpadRegionState? ofNode(FocusNode node) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return null;
    }
    return maybeOf(context);
  }

  @override
  State<DpadRegion> createState() => DpadRegionState();
}

/// [DpadRegion]의 런타임 상태.
///
/// 포커스 메모리를 노출해, 고급 호출자와 내장 탐색 정책이
/// 조회·조종할 수 있게 합니다.
class DpadRegionState extends State<DpadRegion> {
  /// [State]가 다시 만들어져도 남는 메모리. 키는 [DpadRegion.memoryKey].
  static final Map<String, _RegionMemory> _persistentMemory =
      <String, _RegionMemory>{};

  /// [memoryKey]에 저장된 영속 메모리를 지웁니다.
  /// [memoryKey]가 null이면 모든 영역 메모리를 지웁니다.
  static void clearPersistentMemory([String? memoryKey]) {
    if (memoryKey == null) {
      _persistentMemory.clear();
    } else {
      _persistentMemory.remove(memoryKey);
    }
  }

  late final FocusNode _marker = FocusNode(
    debugLabel: 'DpadRegion(${widget.debugLabel ?? hashCode})',
  );
  late final FocusNode _host = FocusNode(
    debugLabel: 'DpadRegion.host(${widget.debugLabel ?? hashCode})',
  );

  FocusNode? _lastFocused;
  Rect? _lastFocusedRect;
  bool _autofocusClaimed = false;
  bool _entered = false;
  bool _hostFocused = false;

  @override
  void initState() {
    super.initState();
    _loadPersistentMemory();
    DpadMarks.regionHost[_host] = true;
    DpadMarks.managed[_host] = true;
    if (widget.ttsLabel != null && widget.ttsLabel!.isNotEmpty) {
      DpadMarks.ttsLabel[_host] = widget.ttsLabel;
    }
    if (widget.autofocus) {
      _scheduleAutofocusClaim();
    }
    _host.addListener(_syncHostHighlight);
  }

  void _scheduleAutofocusClaim([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.autofocus || _autofocusClaimed) {
        return;
      }
      if (requestPreferredFocus()) {
        _autofocusClaimed = true;
        return;
      }
      if (attempt < 4) {
        _scheduleAutofocusClaim(attempt + 1);
      }
    });
  }

  @override
  void didUpdateWidget(DpadRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memoryKey != widget.memoryKey) {
      _loadPersistentMemory();
    }
    if (oldWidget.ttsLabel != widget.ttsLabel) {
      if (widget.ttsLabel != null && widget.ttsLabel!.isNotEmpty) {
        DpadMarks.ttsLabel[_host] = widget.ttsLabel;
      } else {
        DpadMarks.ttsLabel[_host] = null;
      }
    }
  }

  void _loadPersistentMemory() {
    final _RegionMemory? persisted = _persistentMemory[widget.memoryKey];
    if (persisted != null) {
      _lastFocused = persisted.node;
      _lastFocusedRect = persisted.rect;
    }
  }

  /// 이 영역에서 가장 최근에 포커스를 가졌던 칸. 아직 포커스 가능해야 합니다.
  FocusNode? get lastFocused =>
      DpadMarks.isUsable(_lastFocused) ? _lastFocused : null;

  /// 이 영역으로 들어올 때 착지 방식. [DpadRegion.enter]를 보세요.
  DpadEnterBehavior get enterBehavior => widget.enter;

  /// 영역 안 방향 탐색 방식. [DpadRegion.flow]를 보세요.
  DpadRegionFlow get flow => widget.flow;

  /// 이 영역에 속하고 지금 탐색 가능한 모든 포커스 노드
  /// (중첩된 영역이 소유한 노드는 제외).
  Iterable<FocusNode> get focusNodes {
    final FocusNode anchor =
        widget.kind == DpadRegionKind.item ? _host : _marker;
    return anchor.traversalDescendants.where(
      (FocusNode node) => identical(DpadRegion.ofNode(node), this),
    );
  }

  /// 이 영역의 역할. [DpadRegion.kind]를 보세요.
  DpadRegionKind get kind => widget.kind;

  /// [DpadRegionKind.item]이 Enter로 줄 안 위젯에 들어갔는지.
  bool get entered => _entered;

  /// [DpadRegionKind.item] 줄의 호스트 노드. 다른 kind면 `null`.
  FocusNode? get hostNode =>
      widget.kind == DpadRegionKind.item ? _host : null;

  /// [node]가 이 줄의 호스트인지.
  bool isHost(FocusNode node) =>
      widget.kind == DpadRegionKind.item && identical(node, _host);

  /// 가장 가까운 [DpadRegionKind.list] 조상. 자신이 list면 자신.
  DpadRegionState? get enclosingList {
    if (widget.kind == DpadRegionKind.list) {
      return this;
    }
    DpadRegionState? ancestor = DpadRegion.maybeOf(context);
    while (ancestor != null) {
      if (ancestor.widget.kind == DpadRegionKind.list) {
        return ancestor;
      }
      ancestor = DpadRegion.maybeOf(ancestor.context);
    }
    return null;
  }

  /// [DpadRegionKind.list] 안의 item 줄들. 위→아래 순.
  List<DpadRegionState> get childItems {
    if (widget.kind != DpadRegionKind.list) {
      return const <DpadRegionState>[];
    }
    final Map<DpadRegionState, Rect> found = <DpadRegionState, Rect>{};
    for (final FocusNode node in _marker.traversalDescendants) {
      final DpadRegionState? region = DpadRegion.ofNode(node);
      if (region == null || region.widget.kind != DpadRegionKind.item) {
        continue;
      }
      if (!identical(region.enclosingList, this)) {
        continue;
      }
      final Rect? rect = DpadMarks.rectOf(region._host) ?? DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      found[region] = rect;
    }
    final List<MapEntry<DpadRegionState, Rect>> entries = found.entries.toList()
      ..sort(
        (MapEntry<DpadRegionState, Rect> a, MapEntry<DpadRegionState, Rect> b) {
          final int top = a.value.top.compareTo(b.value.top);
          if (top != 0) {
            return top;
          }
          return a.value.left.compareTo(b.value.left);
        },
      );
    return entries.map((MapEntry<DpadRegionState, Rect> e) => e.key).toList();
  }

  /// 이 영역의 첫 칸: [DpadFocusable.entry]가 있으면 그 칸,
  /// 없으면 가장 왼쪽 위 칸.
  FocusNode? get firstFocusable {
    if (widget.kind == DpadRegionKind.list) {
      final List<DpadRegionState> items = childItems;
      if (items.isNotEmpty) {
        return items.first.hostNode;
      }
    }
    return _firstNode(focusNodes.toList());
  }

  /// 줄 안 위젯 중 첫 칸. 호스트는 제외.
  FocusNode? get firstInnerFocusable {
    return _firstNode(
      focusNodes.where((FocusNode node) => !identical(node, _host)).toList(),
    );
  }

  /// [direction]에 적용되는 가장자리 동작.
  DpadEdgeBehavior edgeBehaviorFor(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.left:
      case TraversalDirection.right:
        return widget.horizontalEdge;
      case TraversalDirection.up:
      case TraversalDirection.down:
        return widget.verticalEdge;
    }
  }

  /// [node]를 영역의 포커스 메모리로 기록합니다.
  ///
  /// 영역 안 칸이 포커스를 받을 때마다 자동으로 호출됩니다.
  void noteFocus(FocusNode node) {
    _lastFocused = node;
    _lastFocusedRect = DpadMarks.rectOf(node) ?? _lastFocusedRect;
    final String? key = widget.memoryKey;
    if (key != null) {
      _persistentMemory[key] = _RegionMemory(node, _lastFocusedRect);
    }
  }

  /// 포커스 메모리에서 [node]를 빼고, 마지막 위치는 기하 폴백으로 남깁니다.
  /// 포커스 칸이 dispose될 때 호출됩니다.
  void forget(FocusNode node) {
    if (identical(_lastFocused, node)) {
      _lastFocused = null;
    }
  }

  /// 포커스 메모리를 전부 지웁니다 ([DpadRegion.memoryKey] 영속 메모리 포함).
  void clearMemory() {
    _lastFocused = null;
    _lastFocusedRect = null;
    final String? key = widget.memoryKey;
    if (key != null) {
      _persistentMemory.remove(key);
    }
  }

  /// 탐색이 영역 가장자리에 닿았음을 [DpadRegion.onEdge]에 알립니다.
  void notifyEdge(TraversalDirection direction) {
    widget.onEdge?.call(direction);
  }

  /// 탐색이 이 영역으로 들어올 때 포커스를 받을 칸을 고릅니다.
  /// [nearest]는 기하적으로 가장 가까운 후보, [candidates]는 영역 안 후보입니다.
  ///
  /// 방향키로 영역을 옮길 때는 쓰이지 않습니다. 그때는 항상 [firstFocusable]입니다.
  FocusNode resolveEnter(FocusNode nearest, List<FocusNode> candidates) {
    switch (widget.enter) {
      case DpadEnterBehavior.nearest:
        return nearest;
      case DpadEnterBehavior.first:
        return _firstNode(candidates) ?? nearest;
      case DpadEnterBehavior.entry:
        return _entryNode(candidates) ?? nearest;
      case DpadEnterBehavior.restore:
        final FocusNode? remembered = lastFocused;
        if (remembered != null && candidates.contains(remembered)) {
          return remembered;
        }
        final FocusNode? nearLastRect = _nearestToMemory(candidates);
        if (nearLastRect != null) {
          return nearLastRect;
        }
        return _entryNode(candidates) ?? nearest;
    }
  }

  FocusNode? _firstNode(List<FocusNode> candidates) {
    return _entryNode(candidates) ?? DpadMarks.initialCandidate(candidates);
  }

  FocusNode? _entryNode(List<FocusNode> candidates) {
    for (final FocusNode node in candidates) {
      if (DpadMarks.entry[node] ?? false) {
        return node;
      }
    }
    return null;
  }

  FocusNode? _nearestToMemory(List<FocusNode> candidates) {
    final Rect? memory = _lastFocusedRect;
    if (memory == null) {
      return null;
    }
    FocusNode? best;
    double bestDistance = double.infinity;
    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      final double distance = (rect.center - memory.center).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = node;
      }
    }
    return best;
  }

  /// 이 영역의 첫 칸에 포커스를 줍니다. 외부에서 영역 입구로 점프할 때 씁니다.
  bool requestFirstFocus() {
    if (widget.kind == DpadRegionKind.list ||
        widget.kind == DpadRegionKind.item) {
      return requestLandingFocus();
    }
    final FocusNode? node = firstFocusable;
    if (node == null || !DpadMarks.isUsable(node)) {
      return false;
    }
    noteFocus(node);
    node.requestFocus();
    return true;
  }

  /// 목록/줄에 착지합니다. list는 첫 줄을 선택하고, item은 줄 전체를
  /// 선택합니다 (안쪽 위젯으로는 들어가지 않음).
  bool requestLandingFocus() {
    switch (widget.kind) {
      case DpadRegionKind.list:
        final List<DpadRegionState> items = childItems;
        if (items.isNotEmpty) {
          return items.first.requestLandingFocus();
        }
        final FocusNode? node = _firstNode(focusNodes.toList());
        if (node == null || !DpadMarks.isUsable(node)) {
          return false;
        }
        noteFocus(node);
        node.requestFocus();
        return true;
      case DpadRegionKind.item:
        _collapse();
        if (!DpadMarks.isUsable(_host)) {
          return false;
        }
        noteFocus(_host);
        _host.requestFocus();
        return true;
      case DpadRegionKind.surface:
        final FocusNode? node = firstFocusable;
        if (node == null || !DpadMarks.isUsable(node)) {
          return false;
        }
        noteFocus(node);
        node.requestFocus();
        return true;
    }
  }

  /// [DpadRegionKind.item] 줄 안 첫 위젯으로 들어갑니다. Enter가 호출합니다.
  bool enterInner() {
    if (widget.kind != DpadRegionKind.item) {
      return false;
    }
    final FocusNode? inner = firstInnerFocusable;
    if (inner == null || !DpadMarks.isUsable(inner)) {
      return false;
    }
    _entered = true;
    _hostFocused = false;
    noteFocus(inner);
    inner.requestFocus();
    _host.skipTraversal = true;
    if (mounted) {
      setState(() {});
    }
    return true;
  }

  void _collapse() {
    _entered = false;
    _host.skipTraversal = false;
  }

  /// 화면 진입용: [DpadFocusable.autofocus]가 있으면 그 칸,
  /// 없으면 [firstFocusable].
  bool requestPreferredFocus() {
    if (widget.kind == DpadRegionKind.list ||
        widget.kind == DpadRegionKind.item) {
      return requestLandingFocus();
    }
    final List<FocusNode> nodes = focusNodes.toList();
    final FocusNode? node = DpadMarks.preferredInitial(nodes);
    if (node == null || !DpadMarks.isUsable(node)) {
      return false;
    }
    noteFocus(node);
    node.requestFocus();
    return true;
  }

  /// 이 영역에 속한 [node]에 포커스를 지정합니다.
  /// 영역에 없거나 포커스를 받을 수 없으면 `false`.
  bool requestFocus(FocusNode node) {
    if (!DpadMarks.isUsable(node)) {
      return false;
    }
    if (!identical(DpadRegion.ofNode(node), this)) {
      return false;
    }
    noteFocus(node);
    node.requestFocus();
    return true;
  }

  @override
  void dispose() {
    _host.removeListener(_syncHostHighlight);
    _marker.dispose();
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget inner = widget.kind == DpadRegionKind.item
        ? _buildItemHost(widget.child)
        : Focus(
            focusNode: _marker,
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onFocusChange: widget.onFocusChange,
            child: widget.child,
          );
    return FocusTraversalGroup(
      policy: DpadTraversalPolicy(),
      child: _DpadRegionScope(state: this, child: inner),
    );
  }

  Widget _buildItemHost(Widget child) {
    return Focus(
      focusNode: _host,
      includeSemantics: false,
      onKeyEvent: _onHostKey,
      child: DpadEffect.wrap(
        context,
        DpadTheme.of(context).effects,
        DpadFocusState(focused: _hostFocused, pressed: false),
        child,
      ),
    );
  }

  /// 줄 하이라이트는 호스트가 *primary* 포커스일 때만 켭니다.
  /// 자식이 포커스를 받아도 조상 [Focus]는 `hasFocus`가 유지되므로,
  /// 그걸 쓰면 줄과 자식 하이라이트가 겹칩니다.
  void _syncHostHighlight() {
    if (!mounted || widget.kind != DpadRegionKind.item) {
      return;
    }
    final bool primary = _host.hasPrimaryFocus;
    if (primary == _hostFocused) {
      return;
    }
    setState(() {
      _hostFocused = primary;
    });
    if (primary) {
      _entered = false;
      _host.skipTraversal = false;
      noteFocus(_host);
      widget.onFocusChange?.call(true);
      _scrollHostIntoView();
    } else if (!_entered) {
      widget.onFocusChange?.call(false);
    }
  }

  void _scrollHostIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_host.hasFocus) {
        return;
      }
      final DpadThemeData theme = DpadTheme.of(context);
      DpadScroll.ensureVisible(
        _host,
        padding: theme.scrollPadding,
        duration: theme.scrollDuration,
        curve: theme.scrollCurve,
      );
    });
  }

  KeyEventResult _onHostKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (!const DpadKeySet().isSelect(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    return enterInner() ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}

class _DpadRegionScope extends InheritedWidget {
  const _DpadRegionScope({required this.state, required super.child});

  final DpadRegionState state;

  @override
  bool updateShouldNotify(_DpadRegionScope oldWidget) =>
      state != oldWidget.state;
}

class _RegionMemory {
  const _RegionMemory(this.node, this.rect);

  final FocusNode node;
  final Rect? rect;
}
