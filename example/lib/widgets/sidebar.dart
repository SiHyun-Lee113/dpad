import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class SidebarDestination {
  const SidebarDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// 전형적인 TV 내비게이션 레일: 포커스가 안에 있으면 펼쳐지고,
/// 선택한 목적지를 기억하며, 화면 위·아래로 포커스가 떨어지지 않습니다.
class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _expanded = false;
  double _bump = 0;

  /// stop 가장자리에 닿으면 살짝 세로로 "bump" — 침묵 대신 TV 사용자가
  /// 기대하는 시각 피드백.
  Future<void> _onEdge(TraversalDirection direction) async {
    setState(() => _bump = direction == TraversalDirection.up ? -6 : 6);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _bump = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      ttsLabel: 'Sidebar',
      debugLabel: 'sidebar',
      // 끝에서 위/아래는 그대로: 리모컨이 메뉴에서 "떨어지지" 않음.
      // 오른쪽은 콘텐츠로 나갑니다 (가로 stop이 영역 기본값이라 명시해야 함).
      verticalEdge: DpadEdgeBehavior.stop,
      horizontalEdge: DpadEdgeBehavior.leave,
      onEdge: _onEdge,
      onFocusChange: (inside) => setState(() => _expanded = inside),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: _expanded ? 240 : 88,
        color: const Color(0xFF11141B),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _bump, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: _expanded ? 12 : 0, bottom: 28),
                child: Row(
                  // 접힌 상태: 로고가 아이콘처럼 레일 한가운데.
                  mainAxisAlignment: _expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32),
                    if (_expanded) ...[
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'DPAD TV',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (int i = 0; i < widget.destinations.length; i++)
                _SidebarItem(
                  destination: widget.destinations[i],
                  selected: i == widget.selectedIndex,
                  expanded: _expanded,
                  // 사용자가 포커스 메모리를 쌓기 전까지, 첫 목적지가 착지 칸.
                  entry: i == 0,
                  onFocused: () => widget.onSelected(i),
                  onSelect: () {
                    widget.onSelected(i);
                    // 목적지에서 가운데 버튼 → 콘텐츠로 들어감.
                    // 컨트롤러로 프로그래밍 탐색.
                    Dpad.of(context).moveRight();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.entry,
    required this.onFocused,
    required this.onSelect,
  });

  final SidebarDestination destination;
  final bool selected;
  final bool expanded;
  final bool entry;
  final VoidCallback onFocused;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DpadFocusable(
        entry: entry,
        debugLabel: 'sidebar:${destination.label}',
        ttsLabel: destination.label,
        onSelect: onSelect,
        // 메뉴를 훑으면 섹션이 바로 바뀜. Android TV 런처와 같음.
        onFocusChange: (focused) {
          if (focused) {
            onFocused();
          }
        },
        builder: (context, state, child) {
          final Color background = state.focused
              ? scheme.primary
              : selected
                  ? Colors.white.withAlpha(18)
                  : Colors.transparent;
          final Color foreground = state.focused
              ? scheme.onPrimary
              : selected
                  ? Colors.white
                  : Colors.white70;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              // 접힌 상태: 왼쪽이 아니라 가운데 하이라이트 안의 아이콘.
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 22, color: foreground),
                if (expanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
