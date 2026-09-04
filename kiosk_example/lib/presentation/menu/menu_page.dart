import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/in_memory_menu_repository.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/selected_options.dart';
import '../../domain/usecases/get_menus.dart';
import '../cart/cart_panel.dart';
import '../cart/cart_scope.dart';
import '../checkout/order_complete_page.dart';
import '../options/option_dialog.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import 'category_bar.dart';
import 'kiosk_header.dart';
import 'menu_card.dart';

/// 키오스크 홈.
///
/// * 그리드: [DpadRegionFlow.readingOrder]
/// * 카테고리: [DpadEdgeBehavior.wrap] + [DpadRegion.memoryKey]
/// * 장바구니: [DpadRegionKind.list] / [item]
/// * 처음으로: [DpadController.requestFirstFocus]
class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    this.getMenus = const GetMenus(InMemoryMenuRepository()),
    this.getCategories = const GetCategories(InMemoryMenuRepository()),
  });

  final GetMenus getMenus;
  final GetCategories getCategories;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final GlobalKey<DpadRegionState> _menuRegionKey =
      GlobalKey<DpadRegionState>();

  String _categoryId = kCategoryAll.id;

  List<MenuItem> get _menus =>
      widget.getMenus(categoryId: _categoryId);

  Future<void> _pick(MenuItem item) async {
    final SelectedOptions? options = await showOptionDialog(
      context,
      item: item,
    );
    if (!mounted || options == null) {
      return;
    }
    CartScope.of(context).add(item, options);
  }

  void _quickAdd(MenuItem item) {
    CartScope.of(context).add(item, SelectedOptions.defaults(item.options));
  }

  void _goHome() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    Dpad.of(context).requestFirstFocus(_menuRegionKey.currentContext);
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchPage(getMenus: widget.getMenus),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsPage(),
      ),
    );
  }

  void _pay() {
    final cart = CartScope.of(context);
    final int total = cart.total;
    final int count = cart.itemCount;
    if (count == 0) {
      return;
    }
    cart.clear();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => OrderCompletePage(
          total: total,
          count: count,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final List<MenuItem> menus = _menus;

    return DpadScreen(
      debugLabel: 'menu',
      ttsLabel: '메뉴 선택',
      child: Scaffold(
      body: Column(
        children: [
          KioskHeader(
            title: '메뉴 선택',
            onHome: _goHome,
            onSearch: _openSearch,
            onSettings: _openSettings,
          ),
          CategoryBar(
            categories: widget.getCategories(),
            selectedId: _categoryId,
            onSelected: (String id) => setState(() => _categoryId = id),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: DpadRegion(
                key: _menuRegionKey,
                debugLabel: 'menu-grid',
                ttsLabel: '메뉴',
                memoryKey: 'kiosk-menu-grid',
                autofocus: true,
                flow: DpadRegionFlow.readingOrder,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menus.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final MenuItem menu = menus[index];
                    return MenuCard(
                      key: ValueKey<String>('menu-$index'),
                      menu: menu,
                      autofocus: index == 0,
                      entry: index == 0,
                      onSelect: () => _pick(menu),
                      onLongSelect: () => _quickAdd(menu),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: CartPanel(
              lines: cart.lines,
              total: cart.total,
              count: cart.itemCount,
              onDecrement: (line) => cart.setCount(line, line.count - 1),
              onIncrement: (line) => cart.setCount(line, line.count + 1),
              onSetCount: cart.setCount,
              onRemove: (line) => cart.setCount(line, 0),
              onPay: cart.itemCount == 0 ? null : _pay,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
