import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_example/core/constants/kiosk_size.dart';
import 'package:kiosk_example/data/repositories/in_memory_cart_repository.dart';
import 'package:kiosk_example/presentation/cart/cart_controller.dart';
import 'package:kiosk_example/presentation/cart/cart_scope.dart';
import 'package:kiosk_example/presentation/menu/menu_page.dart';

void main() {
  Future<void> pumpKiosk(WidgetTester tester) async {
    tester.view.physicalSize = const Size(kKioskWidth, kKioskHeight);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final CartController cart = CartController(InMemoryCartRepository());
    addTearDown(cart.dispose);

    await tester.pumpWidget(
      CartScope(
        controller: cart,
        child: MaterialApp(
          builder: Dpad.wrap(navPolicy: DpadNavPolicy.kiosk),
          home: const MenuPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendKey(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  Future<void> addDefaultAmericano(WidgetTester tester) async {
    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(find.text('담기'), findsOneWidget);
    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'right from the 4th menu lands on the 5th, then wraps last → first',
      (tester) async {
    await pumpKiosk(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, '바닐라라떼');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, '녹차라떼',
        reason: '2×4 그리드에서 4번 우 키는 다음 줄 5번으로 가야 함');

    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, '딸기스무디');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, '아메리카노',
        reason: '마지막 칸에서 우 키는 첫 칸으로 순환해야 함');
  });

  testWidgets('selecting a menu opens options, then 담기 adds a cart row',
      (tester) async {
    await pumpKiosk(tester);

    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(find.text('온도 (단일 선택)'), findsOneWidget);
    expect(find.text('추가 옵션 (복수 선택)'), findsOneWidget);
    expect(find.text('에스프레소 샷 (수량)'), findsOneWidget);

    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();
    expect(find.text('아메리카노  ×1'), findsOneWidget);
    expect(find.textContaining('핫'), findsWidgets);
  });

  testWidgets('option dialog: three extras move focus to 담기', (tester) async {
    await pumpKiosk(tester);
    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'option:핫');

    await tester.tap(find.textContaining('시럽'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('휘핑'));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('담기'));

    await tester.tap(find.textContaining('드리즐'));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, '담기');
  });

  testWidgets('option dialog: ice, syrup and extra shot land in the cart',
      (tester) async {
    await pumpKiosk(tester);

    await sendKey(tester, LogicalKeyboardKey.enter);
    await tester.tap(find.text('아이스'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('시럽'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('＋'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();

    expect(find.text('아메리카노  ×1'), findsOneWidget);
    expect(find.textContaining('아이스'), findsWidgets);
    expect(find.textContaining('시럽'), findsWidgets);
    expect(find.textContaining('샷 1'), findsOneWidget);
  });

  testWidgets('cart row: enter then plus increases count', (tester) async {
    await pumpKiosk(tester);
    await addDefaultAmericano(tester);
    expect(find.text('아메리카노  ×1'), findsOneWidget);

    await sendKey(tester, LogicalKeyboardKey.arrowDown);
    expect(_isItemHost(FocusManager.instance.primaryFocus), isTrue,
        reason: '메뉴에서 아래는 장바구니 첫 줄 전체 선택');

    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'cart-minus-0');

    await sendKey(tester, LogicalKeyboardKey.arrowRight);
    await sendKey(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'cart-plus-0');

    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(find.text('아메리카노  ×2'), findsOneWidget);
  });

  testWidgets('cart count opens a quantity keypad and OK applies it',
      (tester) async {
    await pumpKiosk(tester);
    await addDefaultAmericano(tester);

    await sendKey(tester, LogicalKeyboardKey.arrowDown);
    await sendKey(tester, LogicalKeyboardKey.enter);
    await sendKey(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'cart-count-0');

    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const Key('quantity-display')), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('아메리카노  ×3'), findsOneWidget);
  });

  testWidgets('cart delete removes the line', (tester) async {
    await pumpKiosk(tester);
    await addDefaultAmericano(tester);

    await sendKey(tester, LogicalKeyboardKey.arrowDown);
    await sendKey(tester, LogicalKeyboardKey.enter);
    for (int i = 0; i < 3; i++) {
      await sendKey(tester, LogicalKeyboardKey.arrowRight);
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'cart-delete-0');
    await sendKey(tester, LogicalKeyboardKey.enter);
    expect(find.text('아메리카노  ×1'), findsNothing);
    expect(find.text('메뉴를 선택하세요'), findsOneWidget);
  });
}

bool _isItemHost(FocusNode? node) {
  if (node == null) {
    return false;
  }
  final DpadRegionState? region = DpadRegion.ofNode(node);
  return region != null && region.isHost(node);
}
