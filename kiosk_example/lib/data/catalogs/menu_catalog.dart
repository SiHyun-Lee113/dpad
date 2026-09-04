import '../../domain/entities/menu_item.dart';

const List<MenuItem> kMenus = [
  MenuItem(
    name: '아메리카노',
    price: 2000,
    emoji: '☕',
    category: kCategoryCoffee,
  ),
  MenuItem(
    name: '카페라떼',
    price: 2500,
    emoji: '🥛',
    category: kCategoryCoffee,
  ),
  MenuItem(
    name: '카푸치노',
    price: 2500,
    emoji: '☕',
    category: kCategoryCoffee,
  ),
  MenuItem(
    name: '바닐라라떼',
    price: 3000,
    emoji: '🍦',
    category: kCategoryCoffee,
  ),
  MenuItem(
    name: '녹차라떼',
    price: 2800,
    emoji: '🍵',
    category: kCategoryCoffee,
  ),
  MenuItem(
    name: '초콜릿라떼',
    price: 3000,
    emoji: '🍫',
    category: kCategoryCoffee,
  ),
  MenuItem(
    name: '레몬에이드',
    price: 2700,
    emoji: '🍋',
    category: kCategoryDrink,
  ),
  MenuItem(
    name: '딸기스무디',
    price: 3500,
    emoji: '🍓',
    category: kCategoryDrink,
  ),
];
