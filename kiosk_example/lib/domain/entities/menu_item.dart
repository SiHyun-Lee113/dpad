import 'option.dart';

class MenuCategory {
  const MenuCategory({required this.id, required this.label});

  final String id;
  final String label;
}

const MenuCategory kCategoryAll = MenuCategory(id: 'all', label: '전체');
const MenuCategory kCategoryCoffee = MenuCategory(id: 'coffee', label: '커피');
const MenuCategory kCategoryDrink = MenuCategory(id: 'drink', label: '음료');

const List<MenuCategory> kMenuCategories = [
  kCategoryAll,
  kCategoryCoffee,
  kCategoryDrink,
];

class MenuItem {
  const MenuItem({
    required this.name,
    required this.price,
    required this.emoji,
    required this.category,
    this.options = kDefaultOptions,
  });

  final String name;
  final int price;
  final String emoji;
  final MenuCategory category;
  final List<OptionGroup> options;
}
