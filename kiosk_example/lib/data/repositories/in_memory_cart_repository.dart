import '../../domain/entities/cart_line.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/selected_options.dart';
import '../../domain/repositories/cart_repository.dart';

class InMemoryCartRepository implements CartRepository {
  final List<CartLine> _lines = <CartLine>[];
  int _nextId = 0;

  @override
  List<CartLine> get lines => List<CartLine>.unmodifiable(_lines);

  @override
  int get itemCount =>
      _lines.fold<int>(0, (int sum, CartLine line) => sum + line.count);

  @override
  int get total =>
      _lines.fold<int>(0, (int sum, CartLine line) => sum + line.lineTotal);

  @override
  void add(MenuItem item, SelectedOptions options) {
    final int index = _lines.indexWhere(
      (CartLine line) =>
          line.item.name == item.name && line.options == options,
    );
    if (index < 0) {
      _lines.add(
        CartLine(id: _nextId++, item: item, options: options, count: 1),
      );
    } else {
      _lines[index] = _lines[index].copyWith(count: _lines[index].count + 1);
    }
  }

  @override
  void setCount(CartLine line, int count) {
    final int index = _lines.indexWhere((CartLine item) => item.id == line.id);
    if (index < 0) {
      return;
    }
    if (count < 1) {
      _lines.removeAt(index);
    } else {
      _lines[index] = _lines[index].copyWith(count: count);
    }
  }

  @override
  void clear() {
    _lines.clear();
  }
}
