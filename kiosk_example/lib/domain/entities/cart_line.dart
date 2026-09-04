import 'menu_item.dart';
import 'selected_options.dart';

class CartLine {
  const CartLine({
    required this.id,
    required this.item,
    required this.options,
    required this.count,
  });

  final int id;
  final MenuItem item;
  final SelectedOptions options;
  final int count;

  int get unitPrice => item.price + options.extraPrice(item.options);

  int get lineTotal => unitPrice * count;

  CartLine copyWith({int? count, SelectedOptions? options}) {
    return CartLine(
      id: id,
      item: item,
      options: options ?? this.options,
      count: count ?? this.count,
    );
  }
}
