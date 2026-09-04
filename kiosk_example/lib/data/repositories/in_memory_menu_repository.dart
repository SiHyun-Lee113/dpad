import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../catalogs/menu_catalog.dart';

class InMemoryMenuRepository implements MenuRepository {
  const InMemoryMenuRepository();

  @override
  List<MenuCategory> categories() => kMenuCategories;

  @override
  List<MenuItem> menus({String? categoryId, String query = ''}) {
    final String needle = query.trim().toLowerCase();
    return [
      for (final MenuItem item in kMenus)
        if ((categoryId == null ||
                categoryId == kCategoryAll.id ||
                item.category.id == categoryId) &&
            (needle.isEmpty || item.name.toLowerCase().contains(needle)))
          item,
    ];
  }
}
