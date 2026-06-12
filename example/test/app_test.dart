import 'package:dpad_example/app_state.dart';
import 'package:dpad_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    activeSection.value = 0;
    showFocusInspector.value = false;
  });

  testWidgets('the demo app is fully drivable with a remote', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    // The featured Play button owns the initial focus, so the sidebar is
    // collapsed (its wordmark only shows while focus is inside it).
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('DPAD TV'), findsNothing);

    // Down into the first poster row, right along it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // Select opens the detail page.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Episodes'), findsOneWidget);

    // Back pops it and focus returns to the poster row.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Episodes'), findsNothing);
    expect(find.text('FEATURED'), findsOneWidget);

    // Two lefts: back to the first poster, then out into the sidebar,
    // which expands the rail. Down switches the section on focus alone.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);

    // Back on the home screen opens the exit dialog, which traps focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Leave Dpad TV?'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Leave Dpad TV?'), findsNothing);
  });

  testWidgets('settings: disabled rows skip, slider consumes left/right',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    activeSection.value = 3;
    await tester.pumpAndSettle();
    expect(find.text('Playback'), findsOneWidget);

    // Autoplay autofocuses; two downs reach Volume because the disabled
    // "Parental controls" row is skipped.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // Right adjusts the volume instead of moving focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // Bump the volume so we can prove state survives the overlay toggle.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);

    // The focus inspector toggle paints the overlay without resetting any
    // app state (then settles after we switch it back off).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(showFocusInspector.value, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('13'), findsOneWidget,
        reason: 'toggling the inspector must not reset section state');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(showFocusInspector.value, isFalse);
    await tester.pumpAndSettle();
  });
}
