import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import 'cart_panel.dart';
import 'models.dart';
import 'option_dialog.dart';
import 'theme.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final List<CartLine> _cart = <CartLine>[];
  int _nextLineId = 0;

  int get _total =>
      _cart.fold<int>(0, (int sum, CartLine line) => sum + line.lineTotal);

  int get _count =>
      _cart.fold<int>(0, (int sum, CartLine line) => sum + line.count);

  Future<void> _pick(MenuItem item) async {
    final SelectedOptions? options = await showOptionDialog(
      context,
      item: item,
    );
    if (!mounted || options == null) {
      return;
    }
    setState(() => _add(item, options));
  }

  void _add(MenuItem item, SelectedOptions options) {
    final int index = _cart.indexWhere(
      (CartLine line) =>
          line.item.name == item.name && line.options == options,
    );
    if (index < 0) {
      _cart.add(
        CartLine(
          id: _nextLineId++,
          item: item,
          options: options,
          count: 1,
        ),
      );
    } else {
      _cart[index] = _cart[index].copyWith(count: _cart[index].count + 1);
    }
  }

  void _setCount(CartLine line, int count) {
    setState(() {
      final int index = _cart.indexWhere((CartLine item) => item.id == line.id);
      if (index < 0) {
        return;
      }
      if (count < 1) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(count: count);
      }
    });
  }

  void _clear() {
    setState(_cart.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Header(),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: DpadRegion(
                debugLabel: 'menu-grid',
                autofocus: true,
                flow: DpadRegionFlow.readingOrder,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kMenus.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final MenuItem menu = kMenus[index];
                    return _MenuCard(
                      key: ValueKey<String>('menu-$index'),
                      menu: menu,
                      autofocus: index == 0,
                      onSelect: () => _pick(menu),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: CartPanel(
              lines: _cart,
              total: _total,
              count: _count,
              onDecrement: (CartLine line) => _setCount(line, line.count - 1),
              onIncrement: (CartLine line) => _setCount(line, line.count + 1),
              onSetCount: _setCount,
              onRemove: (CartLine line) => _setCount(line, 0),
              onPay: _count == 0 ? null : _clear,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.white,
      child: Row(
        children: [
          DpadFocusable(
            debugLabel: '처음으로',
            ttsLabel: '처음으로',
            onSelect: () {},
            child: const Text(
              '처음으로',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kioskMuted,
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            '메뉴 선택',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kioskBrown,
            ),
          ),
          const Spacer(),
          const Text(
            '메뉴 선택 → 옵션 → 장바구니',
            style: TextStyle(fontSize: 16, color: kioskMuted),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    super.key,
    required this.menu,
    required this.onSelect,
    this.autofocus = false,
  });

  final MenuItem menu;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      debugLabel: menu.name,
      ttsLabel: '${menu.name}, ${formatPrice(menu.price)}원',
      onSelect: onSelect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kioskCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Text(menu.emoji, style: const TextStyle(fontSize: 48)),
                ),
              ),
              Text(
                menu.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kioskBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatPrice(menu.price)}원~',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kioskAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
