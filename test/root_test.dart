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

      // Arrow right was remapped away.
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
  });
}
