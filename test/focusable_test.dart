import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  group('selection', () {
    testWidgets('select key fires onSelect exactly once per press',
        (tester) async {
      final node = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: item('a', node, autofocus: true, onSelect: () => selected++),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('held select key does not repeat onSelect', (tester) async {
      final node = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: item('a', node, autofocus: true, onSelect: () => selected++),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
    });

    testWidgets('holding select fires onLongSelect instead of onSelect',
        (tester) async {
      final node = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        home: item(
          'a',
          node,
          autofocus: true,
          onSelect: () => selected++,
          onLongSelect: () => longSelected++,
        ),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(longSelected, 1);
      expect(selected, 0);
    });

    testWidgets(
        'quick press with onLongSelect set fires onSelect on '
        'release', (tester) async {
      final node = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        home: item(
          'a',
          node,
          autofocus: true,
          onSelect: () => selected++,
          onLongSelect: () => longSelected++,
        ),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
      expect(longSelected, 0);
    });

    testWidgets('tapping the item focuses it and fires onSelect',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true),
            item('b', b, onSelect: () => selected++),
          ],
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('b'));
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(selected, 1);
    });
  });

  group('keys on the item', () {
    testWidgets('onDirection can consume directional presses', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final seen = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item(
              'a',
              a,
              autofocus: true,
              onDirection: (direction) {
                seen.add(direction);
                return direction == TraversalDirection.right;
              },
            ),
            item('b', b),
          ],
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seen, [TraversalDirection.right]);
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'consumed press must not move focus');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(seen, [TraversalDirection.right, TraversalDirection.down]);
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'no target below, focus stays put');
    });
  });

  group('focus state', () {
    testWidgets('onFocusChange reports gain and loss', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final log = <bool>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true, onFocusChange: log.add),
            item('b', b),
          ],
        ),
      ));
      await tester.pump();
      expect(log, [true]);

      b.requestFocus();
      await tester.pump();
      expect(log, [true, false]);
    });

    testWidgets('builder receives the pressed state', (tester) async {
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: node,
          autofocus: true,
          onSelect: () {},
          builder: (context, state, child) =>
              Text(state.pressed ? 'pressed' : 'idle'),
          child: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.text('idle'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('pressed'), findsOneWidget);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('idle'), findsOneWidget);
    });

    testWidgets('theme effects apply when the item declares none',
        (tester) async {
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: node,
          autofocus: true,
          child: const SizedBox(width: 60, height: 60),
        ),
      ));
      await tester.pump();

      final scale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(DpadFocusable),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(scale.scale, const DpadScaleEffect().scale);
    });

    testWidgets('border effect overlay uses fill and inside stroke when focused',
        (tester) async {
      const fill = Color(0x263749FF);
      const border = Color(0xFF3749FF);
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        theme: const DpadThemeData(
          effects: [
            DpadBorderEffect(
              color: border,
              fillColor: fill,
              width: 6,
              borderRadius: BorderRadius.zero,
              duration: Duration.zero,
            ),
          ],
        ),
        home: DpadFocusable(
          focusNode: node,
          autofocus: true,
          child: const SizedBox(width: 60, height: 60),
        ),
      ));
      await tester.pump();

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(DpadFocusable),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final BoxDecoration decoration =
          container.foregroundDecoration! as BoxDecoration;
      expect(decoration.color, fill);
      expect(decoration.borderRadius, BorderRadius.zero);
      final BorderSide side = (decoration.border! as Border).top;
      expect(side.color, border);
      expect(side.width, 6);
      expect(side.strokeAlign, BorderSide.strokeAlignInside);
    });

    testWidgets('child focusables are excluded by default', (tester) async {
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: node,
          autofocus: true,
          effects: const <DpadEffect>[],
          child: ElevatedButton(onPressed: () {}, child: const Text('go')),
        ),
      ));
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);

      // 감싼 버튼이 D-pad 두 번째 칸이 되면 안 됨.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('disabling a focused item releases focus handling',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      bool enabled = true;
      late StateSetter setState;

      await tester.pumpWidget(tvApp(
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return Row(
              children: [
                item('a', a, autofocus: true, enabled: enabled),
                item('b', b),
              ],
            );
          },
        ),
      ));
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      setState(() => enabled = false);
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isFalse);
    });
  });
}
