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
  group('composeTtsAnnouncement', () {
    test('joins screen, region, tile on screen change', () {
      expect(
        composeTtsAnnouncement(
          screenChanged: true,
          regionChanged: true,
          screenLabel: '메뉴 선택',
          regionLabel: '카테고리',
          tileLabel: '전체',
        ),
        '메뉴 선택, 카테고리, 전체',
      );
    });

    test('joins region then tile when only the region changes', () {
      expect(
        composeTtsAnnouncement(
          screenChanged: false,
          regionChanged: true,
          screenLabel: '메뉴 선택',
          regionLabel: '메뉴',
          tileLabel: '아메리카노',
        ),
        '메뉴, 아메리카노',
      );
    });

    test('speaks only the tile inside the same region', () {
      expect(
        composeTtsAnnouncement(
          screenChanged: false,
          regionChanged: false,
          screenLabel: '메뉴 선택',
          regionLabel: '메뉴',
          tileLabel: '카페라떼',
        ),
        '카페라떼',
      );
    });

    test('does not duplicate a region host label', () {
      expect(
        composeTtsAnnouncement(
          screenChanged: false,
          regionChanged: true,
          regionLabel: 'row1',
          tileLabel: 'row1',
          tileIsRegionHost: true,
        ),
        'row1',
      );
    });
  });

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
          item('b', b, ttsLabel: ''),
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

  testWidgets('DpadScreen is never the focused target', (tester) async {
    final a = FocusNode();
    final b = FocusNode();

    await tester.pumpWidget(tvApp(
      home: DpadScreen(
        ttsLabel: 'Home',
        child: Row(
          children: [
            item('a', a, autofocus: true, ttsLabel: 'Alpha'),
            item('b', b, ttsLabel: 'Bravo'),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(a.hasPrimaryFocus, isTrue);
    expect(DpadScreen.ofNode(a)?.ttsLabel, 'Home');
    expect(FocusManager.instance.primaryFocus, a);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(b.hasPrimaryFocus, isTrue);
  });

  testWidgets(
      'new screen speaks screen then region then tile, region move skips screen',
      (tester) async {
    final all = FocusNode();
    final ame = FocusNode();
    final latte = FocusNode();
    final tts = _RecordingTts();

    await tester.pumpWidget(tvApp(
      ttsService: tts,
      home: DpadScreen(
        ttsLabel: '메뉴 선택',
        child: Column(
          children: [
            DpadRegion(
              ttsLabel: '카테고리',
              child: item('all', all, autofocus: true, ttsLabel: '전체'),
            ),
            DpadRegion(
              ttsLabel: '메뉴',
              child: Row(
                children: [
                  item('ame', ame, ttsLabel: '아메리카노'),
                  item('latte', latte, ttsLabel: '카페라떼'),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tts.spoken, ['메뉴 선택, 카테고리, 전체']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ame.hasPrimaryFocus, isTrue);
    expect(tts.spoken, ['메뉴 선택, 카테고리, 전체', '메뉴, 아메리카노']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(latte.hasPrimaryFocus, isTrue);
    expect(tts.spoken.last, '카페라떼');
  });

  testWidgets('a dialog DpadScreen is announced as a new screen',
      (tester) async {
    final open = FocusNode();
    final hot = FocusNode();
    final tts = _RecordingTts();

    await tester.pumpWidget(tvApp(
      ttsService: tts,
      home: Builder(
        builder: (BuildContext context) {
          return DpadScreen(
            ttsLabel: '홈',
            child: item(
              'open',
              open,
              autofocus: true,
              ttsLabel: '열기',
              onSelect: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: DpadScreen(
                        ttsLabel: '옵션',
                        child: DpadRegion(
                          ttsLabel: '온도',
                          child: item(
                            'hot',
                            hot,
                            autofocus: true,
                            ttsLabel: '핫',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(tts.spoken, ['홈, 열기']);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(hot.hasPrimaryFocus, isTrue);
    expect(tts.spoken.last, '옵션, 온도, 핫');
    expect(DpadScreen.ofNode(hot)?.ttsLabel, '옵션');
  });
}
