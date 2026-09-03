import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  group('directional traversal', () {
    testWidgets('arrow keys move along a row and back', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true),
            item('b', b),
            item('c', c),
          ],
        ),
      ));
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('vertical navigation stays in the column (beam preference)',
        (tester) async {
      final nodes = List<FocusNode>.generate(6, (_) => FocusNode());

      // 2x3 그리드:
      //   0 1 2
      //   3 4 5
      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            Row(children: [
              item('0', nodes[0]),
              item('1', nodes[1], autofocus: true),
              item('2', nodes[2]),
            ]),
            Row(children: [
              item('3', nodes[3]),
              item('4', nodes[4]),
              item('5', nodes[5]),
            ]),
          ],
        ),
      ));
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[4].hasPrimaryFocus, isTrue,
          reason: 'down from 1 must land on 4, not a diagonal neighbor');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);
    });

    testWidgets(
        'startup focuses the top-left item automatically so the '
        'remote always works', (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a), item('b', b)]),
      ));
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('autofocus wins over the automatic startup focus',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a), item('b', b, autofocus: true)]),
      ));
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('disabled items are skipped', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true),
            item('b', b, enabled: false),
            item('c', c),
          ],
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);
    });

    testWidgets('lazy horizontal lists scroll to reveal unbuilt items',
        (tester) async {
      final controller = ScrollController();
      final first = FocusNode();

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 100,
          child: DpadRegion(
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: 40,
              itemBuilder: (context, index) => DpadFocusable(
                focusNode: index == 0 ? first : null,
                autofocus: index == 0,
                effects: const <DpadEffect>[],
                child: SizedBox(width: 100, child: Text('item$index')),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(first.hasPrimaryFocus, isTrue);

      // 처음에 빌드된 자식보다 훨씬 오른쪽으로 걸어감.
      for (int i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(controller.offset, greaterThan(0));
      expect(first.hasPrimaryFocus, isFalse);
    });
  });

  group('regions', () {
    testWidgets(
        'moving into a region always lands on that region\'s first item',
        (tester) async {
      final s1 = FocusNode();
      final s2 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();
      final c3 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              debugLabel: 'sidebar',
              horizontalEdge: DpadEdgeBehavior.leave,
              child: Column(children: [item('s1', s1), item('s2', s2)]),
            ),
            const SizedBox(width: 40),
            DpadRegion(
              debugLabel: 'content',
              horizontalEdge: DpadEdgeBehavior.leave,
              child: Column(
                children: [
                  item('c1', c1),
                  item('c2', c2, autofocus: true),
                  item('c3', c3),
                ],
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(c2.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(s1.hasPrimaryFocus, isTrue,
          reason: 'leaving content must land on the sidebar\'s first item');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c1.hasPrimaryFocus, isTrue,
          reason: 're-entering content must land on the first item, not c2');
    });

    testWidgets('DpadEnterBehavior.entry always lands on the entry item',
        (tester) async {
      final s1 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: Column(children: [item('s1', s1)]),
            ),
            DpadRegion(
              enter: DpadEnterBehavior.entry,
              horizontalEdge: DpadEdgeBehavior.leave,
              child: Column(
                children: [
                  item('c1', c1, entry: true),
                  item('c2', c2),
                ],
              ),
            ),
          ],
        ),
      ));
      // 콘텐츠에서 메모리를 쌓은 뒤 나갔다가 다시 들어옴.
      c2.requestFocus();
      await tester.pump();
      s1.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c1.hasPrimaryFocus, isTrue,
          reason: 'entry behavior ignores memory and picks the entry item');
    });

    testWidgets('DpadEnterBehavior.nearest is ignored; region move lands first',
        (tester) async {
      final s2 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: Column(
                children: [item('s1', FocusNode()), item('s2', s2)],
              ),
            ),
            DpadRegion(
              enter: DpadEnterBehavior.nearest,
              horizontalEdge: DpadEdgeBehavior.leave,
              child: Column(children: [item('c1', c1), item('c2', c2)]),
            ),
          ],
        ),
      ));
      c1.requestFocus();
      await tester.pump();
      s2.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c1.hasPrimaryFocus, isTrue,
          reason: 'region handoff always lands on the first item');
    });

    testWidgets(
        'readingOrder right moves 4 → 5 in a 4×2 grid and wraps last → first',
        (tester) async {
      final nodes = List<FocusNode>.generate(8, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          flow: DpadRegionFlow.readingOrder,
          child: Column(
            children: [
              Row(children: [
                for (int i = 0; i < 4; i++) item('$i', nodes[i]),
              ]),
              Row(children: [
                for (int i = 4; i < 8; i++) item('$i', nodes[i]),
              ]),
            ],
          ),
        ),
      ));
      nodes[3].requestFocus();
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[4].hasPrimaryFocus, isTrue,
          reason: 'right from 4 must land on 5, not stop at the row edge');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'left from 5 must return to 4');

      nodes[7].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue,
          reason: 'right from the last item wraps to the first');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[7].hasPrimaryFocus, isTrue,
          reason: 'left from the first item wraps to the last');
    });

    testWidgets(
        'readingOrder down leaves the region instead of moving to the cell below',
        (tester) async {
      final grid = List<FocusNode>.generate(8, (_) => FocusNode());
      final below = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            DpadRegion(
              flow: DpadRegionFlow.readingOrder,
              child: Column(
                children: [
                  Row(children: [
                    for (int i = 0; i < 4; i++) item('$i', grid[i]),
                  ]),
                  Row(children: [
                    for (int i = 4; i < 8; i++) item('$i', grid[i]),
                  ]),
                ],
              ),
            ),
            DpadRegion(child: item('pay', below)),
          ],
        ),
      ));
      grid[1].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(below.hasPrimaryFocus, isTrue,
          reason: 'down must leave the grid region, not jump to index 5');
    });

    testWidgets(
        'leaving a region prefers the nearest region, not the in-beam item',
        (tester) async {
      final one = FocusNode();
      final two = FocusNode();
      final three = FocusNode();

      // [1]
      //         [3]   ← 더 가깝지만 오른쪽으로 어긋남
      // [2]           ← 1과 같은 세로 빔, 더 아래
      await tester.pumpWidget(tvApp(
        home: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              debugLabel: 'one',
              child: item('1', one, autofocus: true),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 180),
                DpadRegion(
                  debugLabel: 'three',
                  child: item('3', three),
                ),
              ],
            ),
            const SizedBox(height: 80),
            DpadRegion(
              debugLabel: 'two',
              child: item('2', two),
            ),
          ],
        ),
      ));
      await tester.pump();
      expect(one.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(three.hasPrimaryFocus, isTrue,
          reason: 'down from 1 must enter the nearer offset region 3, '
              'not the in-beam item 2 further below');
      expect(two.hasPrimaryFocus, isFalse);
    });

    testWidgets('wrap edge cycles within the region', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.wrap,
          child: Row(
            children: [item('a', a), item('b', b), item('c', c)],
          ),
        ),
      ));
      c.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue, reason: 'right past c wraps to a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue, reason: 'left past a wraps to c');
    });

    testWidgets('stop edge consumes the key and reports onEdge',
        (tester) async {
      final outside = FocusNode();
      final a = FocusNode();
      final b = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            item('outside', outside),
            DpadRegion(
              verticalEdge: DpadEdgeBehavior.stop,
              onEdge: edges.add,
              child: Column(children: [item('a', a), item('b', b)]),
            ),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'focus must not escape a stop edge');
      expect(outside.hasPrimaryFocus, isFalse);
      expect(edges, [TraversalDirection.up]);
    });

    testWidgets('right on the last item stays inside the region',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final next = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadRegion(
              child: Row(
                children: [item('a', a, autofocus: true), item('b', b)],
              ),
            ),
            DpadRegion(child: item('next', next)),
          ],
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'horizontal stop must not leak into the next region');
      expect(next.hasPrimaryFocus, isFalse);
    });

    testWidgets(
        'down into the next region focuses that region\'s first item',
        (tester) async {
      final a1 = FocusNode();
      final a2 = FocusNode();
      final b1 = FocusNode();
      final b2 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            DpadRegion(
              child: Row(children: [
                item('a1', a1),
                item('a2', a2, autofocus: true),
              ]),
            ),
            DpadRegion(
              child: Row(children: [
                item('b1', b1, entry: true),
                item('b2', b2),
              ]),
            ),
          ],
        ),
      ));
      await tester.pump();
      expect(a2.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(b1.hasPrimaryFocus, isTrue,
          reason: 'vertical region change lands on the first item, not b2');
      expect(b2.hasPrimaryFocus, isFalse);
    });

    testWidgets('leave edge crosses into the neighbor region',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: item('a', a),
            ),
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: item('b', b),
            ),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('region onFocusChange reports enter and leave', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final log = <bool>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadRegion(
              onFocusChange: log.add,
              child: item('a', a),
            ),
            item('b', b),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();
      expect(log, [true]);

      b.requestFocus();
      await tester.pump();
      expect(log, [true, false]);
    });
  });

  group('auto scroll', () {
    testWidgets('focusing an off-screen item scrolls it into view',
        (tester) async {
      final controller = ScrollController();
      final nodes = List<FocusNode>.generate(10, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 100,
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < 10; i++) item('$i', nodes[i], size: 100),
              ],
            ),
          ),
        ),
      ));

      nodes[9].requestFocus();
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));

      nodes[0].requestFocus();
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
    });
  });

  group('kiosk navigation', () {
    testWidgets('left/right stay in the region and wrap both ways',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();
      final other = FocusNode();

      await tester.pumpWidget(tvApp(
        navPolicy: DpadNavPolicy.kiosk,
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              child: Row(children: [
                item('a', a, autofocus: true),
                item('b', b),
                item('c', c),
              ]),
            ),
            DpadRegion(child: item('other', other)),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue,
          reason: 'first item left wraps to the last, not the other region');
      expect(other.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'last item right wraps to the first, not the other region');
    });

    testWidgets('single item in a region ignores left/right', (tester) async {
      final only = FocusNode();
      final other = FocusNode();

      await tester.pumpWidget(tvApp(
        navPolicy: DpadNavPolicy.kiosk,
        home: Row(
          children: [
            DpadRegion(child: item('only', only, autofocus: true)),
            DpadRegion(child: item('other', other)),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(only.hasPrimaryFocus, isTrue);
      expect(other.hasPrimaryFocus, isFalse);
    });

    testWidgets('up/down moves between regions and wraps both ways',
        (tester) async {
      final top = FocusNode();
      final a1 = FocusNode();
      final a2 = FocusNode();
      final b1 = FocusNode();

      await tester.pumpWidget(tvApp(
        navPolicy: DpadNavPolicy.kiosk,
        home: Column(
          children: [
            item('top', top, autofocus: true),
            DpadRegion(
              child: Row(children: [item('a1', a1), item('a2', a2)]),
            ),
            DpadRegion(child: item('b1', b1)),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(top.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(top.hasPrimaryFocus, isTrue,
          reason: 'ungrouped header must not jump right into another region');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(a1.hasPrimaryFocus, isTrue,
          reason: 'down enters the next region at its first item');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(b1.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(top.hasPrimaryFocus, isTrue,
          reason: 'last region down wraps to the first band');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(b1.hasPrimaryFocus, isTrue,
          reason: 'first region up wraps to the last band');
    });

    testWidgets(
        'list landing highlights the first row; enter then down moves rows',
        (tester) async {
      final menu = FocusNode(debugLabel: 'menu');
      final minus1 = FocusNode(debugLabel: 'minus1');
      final plus1 = FocusNode(debugLabel: 'plus1');
      final minus2 = FocusNode(debugLabel: 'minus2');
      final plus2 = FocusNode(debugLabel: 'plus2');
      final pay = FocusNode(debugLabel: 'pay');

      await tester.pumpWidget(tvApp(
        navPolicy: DpadNavPolicy.kiosk,
        home: Column(
          children: [
            DpadRegion(
              debugLabel: 'menu',
              child: item('menu', menu, autofocus: true),
            ),
            DpadRegion(
              kind: DpadRegionKind.list,
              debugLabel: 'cart',
              child: Column(
                children: [
                  DpadRegion(
                    kind: DpadRegionKind.item,
                    ttsLabel: 'row1',
                    child: Row(children: [
                      item('m1', minus1),
                      item('p1', plus1),
                    ]),
                  ),
                  DpadRegion(
                    kind: DpadRegionKind.item,
                    ttsLabel: 'row2',
                    child: Row(children: [
                      item('m2', minus2),
                      item('p2', plus2),
                    ]),
                  ),
                ],
              ),
            ),
            DpadRegion(
              debugLabel: 'pay',
              child: item('pay', pay),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(menu.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_isItemHost(FocusManager.instance.primaryFocus), isTrue,
          reason: 'down into a list lands on the first row host, not minus/plus');
      expect(
        DpadRegion.ofNode(FocusManager.instance.primaryFocus!)?.widget.ttsLabel,
        'row1',
      );
      expect(minus1.hasPrimaryFocus, isFalse);
      expect(plus1.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(menu.hasPrimaryFocus, isTrue,
          reason: 'up from the first row leaves the list');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_isItemHost(FocusManager.instance.primaryFocus), isTrue,
          reason: 'left/right on a row host stay on the row');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(minus1.hasPrimaryFocus, isTrue,
          reason: 'enter moves into the first widget of the row');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(plus1.hasPrimaryFocus, isTrue,
          reason: 'after enter, left/right stay inside the row');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(minus1.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_isItemHost(FocusManager.instance.primaryFocus), isTrue,
          reason: 'down from a row selects the next product row');
      expect(
        DpadRegion.ofNode(FocusManager.instance.primaryFocus!)?.widget.ttsLabel,
        'row2',
      );
      expect(minus2.hasPrimaryFocus, isFalse);
      expect(plus2.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(minus2.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(pay.hasPrimaryFocus, isTrue,
          reason: 'down from the last row leaves the list');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_isItemHost(FocusManager.instance.primaryFocus), isTrue);
      expect(
        DpadRegion.ofNode(FocusManager.instance.primaryFocus!)?.widget.ttsLabel,
        'row1',
        reason: 're-entering the list lands on the first row',
      );
    });

    testWidgets('enter into a row shows only the child focus effect',
        (tester) async {
      const DpadEffect rowFlag = _FocusFlag('row-focus');
      const DpadEffect childFlag = _FocusFlag('child-focus');
      final inner = FocusNode(debugLabel: 'inner');

      await tester.pumpWidget(tvApp(
        navPolicy: DpadNavPolicy.kiosk,
        theme: const DpadThemeData(effects: [rowFlag]),
        home: DpadRegion(
          kind: DpadRegionKind.list,
          autofocus: true,
          child: DpadRegion(
            kind: DpadRegionKind.item,
            ttsLabel: 'row',
            child: item('inner', inner, effects: [childFlag]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(_isItemHost(FocusManager.instance.primaryFocus), isTrue);
      expect(find.text('row-focus'), findsOneWidget);
      expect(find.text('child-focus'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(inner.hasPrimaryFocus, isTrue);
      expect(find.text('row-focus'), findsNothing,
          reason: 'row host highlight must turn off after enter');
      expect(find.text('child-focus'), findsOneWidget,
          reason: 'only the inner widget should show focus');
    });
  });
}

class _FocusFlag extends DpadEffect {
  const _FocusFlag(this.label);

  final String label;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.focused) Text(label),
        child,
      ],
    );
  }
}

bool _isItemHost(FocusNode? node) {
  if (node == null) {
    return false;
  }
  final DpadRegionState? region = DpadRegion.ofNode(node);
  return region != null && region.isHost(node);
}
