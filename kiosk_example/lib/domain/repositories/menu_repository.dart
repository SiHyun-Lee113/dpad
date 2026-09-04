import '../entities/menu_item.dart';

abstract class MenuRepository {
  List<MenuCategory> categories();

  List<MenuItem> menus({String? categoryId, String query = ''});
}
