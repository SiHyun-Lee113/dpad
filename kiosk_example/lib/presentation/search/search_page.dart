import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/selected_options.dart';
import '../../domain/usecases/get_menus.dart';
import '../cart/cart_scope.dart';
import '../menu/kiosk_header.dart';
import '../menu/menu_card.dart';
import '../options/option_dialog.dart';

/// 검색. [DpadFocusable.excludeChildFocus] = false 로 TextField와 D-pad를 함께 씁니다.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.getMenus});

  final GetMenus getMenus;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(MenuItem item) async {
    final SelectedOptions? options = await showOptionDialog(
      context,
      item: item,
    );
    if (!mounted || options == null) {
      return;
    }
    CartScope.of(context).add(item, options);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<MenuItem> results = widget.getMenus(query: _query);

    return Scaffold(
      body: Column(
        children: [
          KioskHeader(
            title: '검색',
            onHome: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: DpadFocusable(
              autofocus: true,
              excludeChildFocus: false,
              debugLabel: 'search-field',
              ttsLabel: '검색어 입력',
              child: TextField(
                controller: _controller,
                onChanged: (String value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '메뉴 이름',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '입력 중에는 화살표가 캐럿을 움직입니다. 가장자리와 아래 키에서 필드를 떠납니다.',
              style: TextStyle(fontSize: 13, color: kioskMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length}개',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kioskBrown,
                ),
              ),
            ),
          ),
          Expanded(
            child: DpadRegion(
              debugLabel: 'search-results',
              memoryKey: 'kiosk-search-results',
              flow: DpadRegionFlow.readingOrder,
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final MenuItem menu = results[index];
                  return MenuCard(
                    menu: menu,
                    onSelect: () => _pick(menu),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
