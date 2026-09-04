import '../entities/cart_line.dart';
import '../entities/menu_item.dart';
import '../entities/selected_options.dart';

abstract class CartRepository {
  List<CartLine> get lines;

  int get itemCount;

  int get total;

  void add(MenuItem item, SelectedOptions options);

  void setCount(CartLine line, int count);

  void clear();
}
