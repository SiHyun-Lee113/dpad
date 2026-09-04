import '../entities/cart_line.dart';
import '../entities/menu_item.dart';
import '../entities/selected_options.dart';
import '../repositories/cart_repository.dart';

class AddCartLine {
  const AddCartLine(this._cart);

  final CartRepository _cart;

  void call(MenuItem item, SelectedOptions options) {
    _cart.add(item, options);
  }
}

class UpdateCartCount {
  const UpdateCartCount(this._cart);

  final CartRepository _cart;

  void call(CartLine line, int count) {
    _cart.setCount(line, count);
  }
}

class ClearCart {
  const ClearCart(this._cart);

  final CartRepository _cart;

  void call() {
    _cart.clear();
  }
}
