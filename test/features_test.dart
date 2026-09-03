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
        enter: DpadEnterBehavior.restore,
        horizontalEdge: DpadEdgeBehavior.leave,
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
              DpadRegion(
                horizontalEdge: DpadEdgeBehavior.leave,
                child: item('m1', m1, autofocus: true),
              ),
              const SizedBox(width: 40),
              content(),
            ],
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    // 가운데 콘텐츠 칸에 포커스를 준 뒤 메뉴로 돌아감.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c2');
    m1.requestFocus();
    await tester.pumpAndSettle();

    // 콘텐츠 영역을 처음부터 다시 만듦 (새 Key → 새 State, 새 포커스 노드).
    setState(() => generation++);
    await tester.pumpAndSettle();

    // 방향키로 다시 들어오면 항상 영역의 첫 칸(c1)에 착지.
    focusedLabel = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c1');
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

  testWidgets(
      'a pushed route takes focus even when restoreFocus is off and '
      'the new page has no autofocus', (tester) async {
    final a = FocusNode(debugLabel: 'prev');
    final p1 = FocusNode(debugLabel: 'p1');
    final p2 = FocusNode(debugLabel: 'p2');

    await tester.pumpWidget(tvApp(
      restoreFocus: false,
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
        reason: 'next page must receive focus, not the previous page');
    expect(a.hasPrimaryFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(p2.hasPrimaryFocus, isTrue,
        reason: 'arrows must move on the new page, not jump back');
    expect(a.hasPrimaryFocus, isFalse);
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

    // 오버레이를 켬: 서브트리를 처음부터 리빌드하면 안 됨.
    // 같은 노드 인스턴스가 포커스를 유지하고 키를 받아야 함.
    await tester.pumpWidget(app(overlay: true, enabled: true));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue,
        reason: 'structure must be stable across configuration changes');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 1);

    // `enabled`도 같음.
    await tester.pumpWidget(app(overlay: false, enabled: false));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(app(overlay: false, enabled: true));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
  });
}
