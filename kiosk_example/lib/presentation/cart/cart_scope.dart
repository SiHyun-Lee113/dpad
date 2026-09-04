import 'package:flutter/widgets.dart';

import 'cart_controller.dart';

class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    super.key,
    required CartController controller,
    required super.child,
  }) : super(notifier: controller);

  static CartController of(BuildContext context) {
    final CartScope? scope =
        context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'CartScope가 없습니다.');
    return scope!.notifier!;
  }
}
