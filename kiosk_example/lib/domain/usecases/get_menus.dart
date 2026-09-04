import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

class GetMenus {
  const GetMenus(this._menus);

  final MenuRepository _menus;

  List<MenuItem> call({String? categoryId, String query = ''}) {
    return _menus.menus(categoryId: categoryId, query: query);
  }
}

class GetCategories {
  const GetCategories(this._menus);

  final MenuRepository _menus;

  List<MenuCategory> call() => _menus.categories();
}
