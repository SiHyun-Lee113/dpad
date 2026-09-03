import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

class _RecordingTts implements DpadTtsService {
  final List<String> spoken = <String>[];
  int stops = 0;

  @override
  void speak(String text) => spoken.add(text);

  @override
  void stop() => stops++;
}

void main() {
  testWidgets('speaks ttsLabel when a focusable gains focus', (tester) async {
    final a = FocusNode();
    final b = FocusNode();
    final tts = _RecordingTts();

    await tester.pumpWidget(tvApp(
      ttsService: tts,
      home: Row(
        children: [
          item('a', a, autofocus: true, ttsLabel: 'Alpha'),
          item('b', b, ttsLabel: 'Bravo'),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(tts.spoken, ['Alpha']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(tts.spoken, ['Alpha', 'Bravo']);
    expect(b.hasPrimaryFocus, isTrue);
  });

  testWidgets('stops speech when the focused item has no ttsLabel',
      (tester) async {
    final a = FocusNode();
    final b = FocusNode();
    final tts = _RecordingTts();

    await tester.pumpWidget(tvApp(
      ttsService: tts,
      home: Row(
        children: [
          item('a', a, autofocus: true, ttsLabel: 'Alpha'),
          item('b', b),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(tts.spoken, ['Alpha']);
    expect(tts.stops, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(tts.spoken, ['Alpha']);
    expect(tts.stops, greaterThan(0));
  });

  testWidgets('empty ttsLabel is not announced', (tester) async {
    final a = FocusNode();
    final tts = _RecordingTts();

    await tester.pumpWidget(tvApp(
      ttsService: tts,
      home: item('a', a, autofocus: true, ttsLabel: ''),
    ));
    await tester.pumpAndSettle();

    expect(tts.spoken, isEmpty);
  });
}
