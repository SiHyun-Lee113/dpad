import 'package:dpad_example/app_state.dart';
import 'package:dpad_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    activeSection.value = 0;
    showFocusInspector.value = false;
    appTts.enabled.value = true;
    appTts.stop();
  });

  testWidgets('the demo app is fully drivable with a remote', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    // 피처드 Play 버튼이 초기 포커스라 사이드바는 접혀 있음
    // (워드마크는 포커스가 안에 있을 때만 보임).
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('DPAD TV'), findsNothing);

    // 아래로 첫 포스터 줄, 오른쪽으로 한 칸.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // 선택하면 상세 페이지가 열림.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Episodes'), findsOneWidget);

    // 뒤로 가면 pop되고 포커스는 포스터 줄로 돌아옴.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Episodes'), findsNothing);
    expect(find.text('FEATURED'), findsOneWidget);

    // 왼쪽은 포스터 줄에 머무름. 위는 Play, 그다음 왼쪽으로 사이드바
    // (배너 영역이 가로 leave를 허용).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);

    // 홈에서 뒤로 키는 종료 다이얼로그를 열고, 포커스를 가둡니다.
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

    activeSection.value = 4;
    await tester.pumpAndSettle();
    expect(find.text('Playback'), findsOneWidget);

    // Autoplay가 autofocus. 비활성 "Parental controls" 줄을 건너뛰어
    // 아래 두 번이면 Volume.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // 오른쪽은 포커스 대신 볼륨을 바꿈.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // 오버레이 토글 후에도 상태가 남는지 확인하려고 볼륨을 한 칸 올림.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);

    // 포커스 인스펙터 토글은 오버레이만 그리고 앱 상태는 리셋하지 않음
    // (다시 끄면 settle).
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

  testWidgets('d-pad drives a PIN keypad shown in a dialog', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    activeSection.value = 3;
    await tester.pumpAndSettle();
    expect(find.text('PIN keypad'), findsOneWidget);

    // PIN 데모 줄이 autofocus. 선택하면 오버레이 키패드가 열림.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Enter PIN'), findsOneWidget);

    // '1'이 autofocus. 선택하면 입력, 오른쪽 후 선택하면 '2'.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('1···'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('12··'), findsOneWidget);

    // 포커스는 다이얼로그에 갇힘: '2'에서 왼쪽은 '1'로, 뒤 사이드바로 새지 않음.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.text('DPAD TV'), findsNothing);

    // '1'에서 아래 세 번이면 'C', 오른쪽 두 번이면 OK.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Enter PIN'), findsNothing);
    expect(find.text('Last PIN: 12'), findsOneWidget);
  });
}
