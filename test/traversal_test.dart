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

      // 2x3 grid:
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

      // Walk right far beyond the initially built children.
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
        'focus returns to the remembered item when re-entering '
        'a region', (tester) async {
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
              child: Column(children: [item('s1', s1), item('s2', s2)]),
            ),
            const SizedBox(width: 40),
            DpadRegion(
              debugLabel: 'content',
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
      expect(s2.hasPrimaryFocus, isTrue,
          reason: 'left from c2 lands on the in-beam sidebar item because '
              'the sidebar holds no memory yet');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c2.hasPrimaryFocus, isTrue,
          reason: 're-entering the content region must restore c2');

      // The sidebar now remembers s2; entering it again must restore that
      // even from a different row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(c3.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(s2.hasPrimaryFocus, isTrue,
          reason: 'sidebar restores its own memory');
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
              child: Column(children: [item('s1', s1)]),
            ),
            DpadRegion(
              enter: DpadEnterBehavior.entry,
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
      // Build memory inside content, then leave and re-enter.
      c2.requestFocus();
      await tester.pump();
      s1.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c1.hasPrimaryFocus, isTrue,
          reason: 'entry behavior ignores memory and picks the entry item');
    });

    testWidgets('DpadEnterBehavior.nearest picks the geometric target',
        (tester) async {
      final s2 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              child: Column(
                children: [item('s1', FocusNode()), item('s2', s2)],
              ),
            ),
            DpadRegion(
              enter: DpadEnterBehavior.nearest,
              child: Column(children: [item('c1', c1), item('c2', c2)]),
            ),
          ],
        ),
      ));
      // Remember c1, then approach from s2 (in beam with c2).
      c1.requestFocus();
      await tester.pump();
      s2.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c2.hasPrimaryFocus, isTrue);
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

    testWidgets('leave edge (default) crosses into the neighbor region',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadRegion(child: item('a', a)),
            DpadRegion(child: item('b', b)),
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
}
