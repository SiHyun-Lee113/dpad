import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  group('controller', () {
    testWidgets('move / select / requestFocus work programmatically',
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

      final dpad = Dpad.of(tester.element(find.text('a')));

      expect(dpad.moveRight(), isTrue);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(dpad.focused, b);

      expect(dpad.select(), isTrue);
      await tester.pump();
      expect(selected, 1);

      expect(dpad.requestFocus(a), isTrue);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      dpad.clearFocus();
      await tester.pump();
      expect(dpad.focused, isNull);
    });

    testWidgets('requestFirstFocus lands on the region\'s first item',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          child: Row(children: [
            item('a', a),
            item('b', b, autofocus: true),
            item('c', c),
          ]),
        ),
      ));
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      final dpad = Dpad.of(tester.element(find.text('b')));
      expect(dpad.requestFirstFocus(), isTrue);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      expect(dpad.requestFocus(c), isTrue);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);
    });
  });

  group('key handling', () {
    testWidgets('custom key set remaps directions', (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        keySet: const DpadKeySet().copyWith(
          right: const [LogicalKeyboardKey.keyD],
        ),
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      // 오른쪽 화살표 매핑이 제거됨.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('onBack consumes back keys when it returns true',
        (tester) async {
      final a = FocusNode();
      int backs = 0;

      await tester.pumpWidget(tvApp(
        onBack: () {
          backs++;
          return true;
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(backs, 1);
    });

    testWidgets('onMenu fires for menu keys', (tester) async {
      final a = FocusNode();
      int menus = 0;

      await tester.pumpWidget(tvApp(
        onMenu: () => menus++,
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(menus, 1);
    });

    testWidgets('app shortcuts fire, but never while editing text',
        (tester) async {
      final a = FocusNode();
      int hits = 0;
      final field = FocusNode();

      await tester.pumpWidget(tvApp(
        shortcuts: {LogicalKeyboardKey.keyG: () => hits++},
        home: Column(
          children: [
            TextField(focusNode: field),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.pump();
      expect(hits, 0, reason: 'shortcuts must stand down while typing');

      a.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.pump();
      expect(hits, 1);
    });

    testWidgets('arrow keys keep moving the caret while editing text',
        (tester) async {
      final a = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            TextField(focusNode: field, controller: controller),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(field.hasFocus, isTrue,
          reason: 'arrows must not steal focus mid-text');
      expect(controller.selection.baseOffset, 4);
    });

    testWidgets('down leaves a focused single-line text field', (tester) async {
      final a = FocusNode();
      final field = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            TextField(focusNode: field),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'a remote-only user must never be trapped in a field');
    });

    testWidgets('left at the caret start leaves the text field',
        (tester) async {
      final left = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'hi');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('left', left),
            SizedBox(
              width: 200,
              child: TextField(focusNode: field, controller: controller),
            ),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(left.hasPrimaryFocus, isTrue,
          reason: 'caret at the start: left exits the field');
    });
  });

  group('focus resilience', () {
    testWidgets('removing the focused item moves focus to its neighbor',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      bool showA = true;
      late StateSetter setState;

      await tester.pumpWidget(tvApp(
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return Row(
              children: [
                if (showA) item('a', a, autofocus: true),
                item('b', b),
              ],
            );
          },
        ),
      ));
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      setState(() => showA = false);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'focus must never die with its widget');
    });

    testWidgets('popping a route restores focus on the previous page',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      final navigator = Navigator.of(tester.element(find.text('a')));
      navigator.push(MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: DpadFocusable(
            autofocus: true,
            effects: const <DpadEffect>[],
            child: const SizedBox(width: 60, height: 60, child: Text('p')),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isFalse);

      navigator.pop();
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'route scopes remember their focused child');
    });

    testWidgets(
        'pushing a route with autofocus steals focus from the previous page',
        (tester) async {
      final a = FocusNode(debugLabel: 'prev');
      final next = FocusNode(debugLabel: 'next');

      await tester.pumpWidget(tvApp(
        restoreFocus: false,
        home: item('a', a, autofocus: true),
      ));
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue);

      Navigator.of(tester.element(find.text('a'))).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: item('next', next, autofocus: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(next.hasPrimaryFocus, isTrue);
      expect(a.hasPrimaryFocus, isFalse);
    });

    testWidgets('screen swap keeps focus on autofocus, not top-left chrome',
        (tester) async {
      final home = FocusNode(debugLabel: '처음으로');
      final waiting = FocusNode(debugLabel: 'waiting');
      final menu = FocusNode(debugLabel: 'menu');
      var onMenu = false;
      late StateSetter setState;

      await tester.pumpWidget(tvApp(
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return Column(
              children: [
                item('처음으로', home),
                if (onMenu)
                  item('menu', menu, autofocus: true)
                else
                  item('waiting', waiting, autofocus: true),
              ],
            );
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(waiting.hasPrimaryFocus, isTrue);
      expect(home.hasPrimaryFocus, isFalse);

      setState(() => onMenu = true);
      await tester.pumpAndSettle();
      expect(menu.hasPrimaryFocus, isTrue,
          reason: 'next screen must show focus immediately on the specified tile');
      expect(home.hasPrimaryFocus, isFalse,
          reason: 'chrome 처음으로 must not take first focus');
    });

    testWidgets('skipTraversal listener does not hide the focused tile',
        (tester) async {
      final listener = FocusNode(skipTraversal: true);
      final home = FocusNode();
      final menu = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Focus(
          focusNode: listener,
          autofocus: true,
          child: Column(
            children: [
              item('처음으로', home),
              item('menu', menu, autofocus: true),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(menu.hasPrimaryFocus, isTrue,
          reason: 'a key listener must not steal the visible kiosk focus');
      expect(listener.hasPrimaryFocus, isFalse);
      expect(listener.hasFocus, isTrue);
    });

    testWidgets('region autofocus lands inside the body, not chrome',
        (tester) async {
      final home = FocusNode();
      final firstMenu = FocusNode();
      final secondMenu = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            item('처음으로', home),
            DpadRegion(
              autofocus: true,
              child: Row(children: [
                item('m1', firstMenu),
                item('m2', secondMenu),
              ]),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(firstMenu.hasPrimaryFocus, isTrue);
      expect(home.hasPrimaryFocus, isFalse);
    });
  });
}
