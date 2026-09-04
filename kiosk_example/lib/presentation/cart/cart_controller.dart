import 'package:flutter/foundation.dart';

import '../../domain/entities/cart_line.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/selected_options.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/cart_usecases.dart';

class CartController extends ChangeNotifier {
  CartController(CartRepository cart)
      : _add = AddCartLine(cart),
        _update = UpdateCartCount(cart),
        _clear = ClearCart(cart),
        _cart = cart;

  final CartRepository _cart;
  final AddCartLine _add;
  final UpdateCartCount _update;
  final ClearCart _clear;

  List<CartLine> get lines => _cart.lines;

  int get itemCount => _cart.itemCount;

  int get total => _cart.total;

  void add(MenuItem item, SelectedOptions options) {
    _add(item, options);
    notifyListeners();
  }

  void setCount(CartLine line, int count) {
    _update(line, count);
    notifyListeners();
  }

  void clear() {
    _clear();
    notifyListeners();
  }
}
