import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  setUp(DpadRegionState.clearPersistentMemory);

  testWidgets('memoryKey keeps region memory across full rebuilds',
      (tester) async {
    final m1 = FocusNode();
    String? focusedLabel;
    int generation = 0;
    late StateSetter setState;

    Widget content() {
      return DpadRegion(
        key: ValueKey<int>(generation),
        memoryKey: 'content',
        debugLabel: 'content',
        child: Column(
          children: [
            for (final id in const ['c1', 'c2', 'c3'])
              DpadFocusable(
                onFocusChange: (focused) {
                  if (focused) {
                    focusedLabel = id;
                  }
                },
                effects: const <DpadEffect>[],
                child: SizedBox(
                    width: 60, height: 60, child: Center(child: Text(id))),
              ),
          ],
        ),
      );
    }

    await tester.pumpWidget(tvApp(
      home: StatefulBuilder(
        builder: (context, set) {
          setState = set;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DpadRegion(child: item('m1', m1, autofocus: true)),
              const SizedBox(width: 40),
              content(),
            ],
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Focus the middle content item, then go back to the menu.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c2');
    m1.requestFocus();
    await tester.pumpAndSettle();

    // Rebuild the content region from scratch (new Key → new State and
    // brand-new focus nodes).
    setState(() => generation++);
    await tester.pumpAndSettle();

    // Re-entering must land on the new c2, via the persisted memory.
    focusedLabel = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c2');
  });

  testWidgets('a pushed route without autofocus receives initial focus',
      (tester) async {
    final a = FocusNode();
    final p1 = FocusNode();
    final p2 = FocusNode();

    await tester.pumpWidget(tvApp(
      home: item('a', a, autofocus: true),
    ));
    await tester.pumpAndSettle();
    expect(a.hasPrimaryFocus, isTrue);

    Navigator.of(tester.element(find.text('a'))).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Row(children: [item('p1', p1), item('p2', p2)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(p1.hasPrimaryFocus, isTrue,
        reason: 'a new page must be immediately drivable by the remote');
  });

  testWidgets('Dpad.onFocusChange reports every focus move', (tester) async {
    final a = FocusNode(debugLabel: 'a');
    final b = FocusNode(debugLabel: 'b');
    final log = <String?>[];

    await tester.pumpWidget(tvApp(
      onFocusChange: (node) => log.add(node?.debugLabel),
      home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
    ));
    await tester.pumpAndSettle();
    expect(log, contains('a'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(log.last, 'b');
  });

  testWidgets('debugOverlay outlines the focused node with its label',
      (tester) async {
    await tester.pumpWidget(tvApp(
      debugOverlay: true,
      home: DpadFocusable(
        autofocus: true,
        debugLabel: 'hero-button',
        effects: const <DpadEffect>[],
        child: const SizedBox(width: 60, height: 60),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('60×60'), findsOneWidget);
    expect(find.textContaining('hero-button'), findsOneWidget);
  });

  testWidgets(
      'toggling debugOverlay/enabled at runtime keeps subtree '
      'state and focus', (tester) async {
    final a = FocusNode(debugLabel: 'a');
    int selected = 0;

    Widget app({required bool overlay, required bool enabled}) {
      return MaterialApp(
        builder: Dpad.wrap(debugOverlay: overlay, enabled: enabled),
        home: Scaffold(
          body: item('a', a, autofocus: true, onSelect: () => selected++),
        ),
      );
    }

    await tester.pumpWidget(app(overlay: false, enabled: true));
    await tester.pumpAndSettle();
    expect(a.hasPrimaryFocus, isTrue);

    // Flip the overlay on: the subtree must not be rebuilt from scratch,
    // so the same node instance keeps focus and still receives keys.
    await tester.pumpWidget(app(overlay: true, enabled: true));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue,
        reason: 'structure must be stable across configuration changes');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 1);

    // Same for `enabled`.
    await tester.pumpWidget(app(overlay: false, enabled: false));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(app(overlay: false, enabled: true));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
  });
}
