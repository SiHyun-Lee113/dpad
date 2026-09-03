/// 옵션 그룹 종류. 키오스크 옵션 다이얼로그에서 각각 다른 입력 방식을 씁니다.
enum OptionKind {
  /// 라디오. 그룹에서 하나만 고릅니다.
  single,

  /// 체크박스. 여러 개를 동시에 고를 수 있습니다.
  multi,

  /// 수량. − / 숫자 / ＋ 로 개수를 바꿉니다.
  quantity,
}

class OptionChoice {
  const OptionChoice({
    required this.id,
    required this.label,
    this.price = 0,
  });

  final String id;
  final String label;
  final int price;
}

class OptionGroup {
  const OptionGroup({
    required this.id,
    required this.title,
    required this.kind,
    this.choices = const <OptionChoice>[],
    this.min = 0,
    this.max = 9,
    this.unitPrice = 0,
    this.unitLabel = '개',
  });

  final String id;
  final String title;
  final OptionKind kind;
  final List<OptionChoice> choices;
  final int min;
  final int max;
  final int unitPrice;
  final String unitLabel;
}

class MenuItem {
  const MenuItem({
    required this.name,
    required this.price,
    required this.emoji,
    this.options = kDefaultOptions,
  });

  final String name;
  final int price;
  final String emoji;
  final List<OptionGroup> options;
}

/// 모든 음료에 공통으로 붙는 옵션. 키오스크에서 세 종류를 한 다이얼로그로 시험합니다.
const List<OptionGroup> kDefaultOptions = [
  OptionGroup(
    id: 'temp',
    title: '온도 (단일 선택)',
    kind: OptionKind.single,
    choices: [
      OptionChoice(id: 'hot', label: '핫'),
      OptionChoice(id: 'ice', label: '아이스'),
    ],
  ),
  OptionGroup(
    id: 'extra',
    title: '추가 옵션 (복수 선택)',
    kind: OptionKind.multi,
    choices: [
      OptionChoice(id: 'syrup', label: '시럽', price: 300),
      OptionChoice(id: 'whip', label: '휘핑', price: 400),
      OptionChoice(id: 'drizzle', label: '드리즐', price: 500),
    ],
  ),
  OptionGroup(
    id: 'shot',
    title: '에스프레소 샷 (수량)',
    kind: OptionKind.quantity,
    min: 0,
    max: 5,
    unitPrice: 500,
    unitLabel: '샷',
  ),
];

const List<MenuItem> kMenus = [
  MenuItem(name: '아메리카노', price: 2000, emoji: '☕'),
  MenuItem(name: '카페라떼', price: 2500, emoji: '🥛'),
  MenuItem(name: '카푸치노', price: 2500, emoji: '☕'),
  MenuItem(name: '바닐라라떼', price: 3000, emoji: '🍦'),
  MenuItem(name: '녹차라떼', price: 2800, emoji: '🍵'),
  MenuItem(name: '초콜릿라떼', price: 3000, emoji: '🍫'),
  MenuItem(name: '레몬에이드', price: 2700, emoji: '🍋'),
  MenuItem(name: '딸기스무디', price: 3500, emoji: '🍓'),
];

/// 옵션 다이얼로그에서 고른 값. 같은 메뉴라도 옵션이 다르면 장바구니 줄이 갈립니다.
class SelectedOptions {
  const SelectedOptions({
    required this.singles,
    required this.multis,
    required this.quantities,
  });

  factory SelectedOptions.defaults(List<OptionGroup> groups) {
    final Map<String, String> singles = <String, String>{};
    final Map<String, Set<String>> multis = <String, Set<String>>{};
    final Map<String, int> quantities = <String, int>{};
    for (final OptionGroup group in groups) {
      switch (group.kind) {
        case OptionKind.single:
          singles[group.id] = group.choices.first.id;
        case OptionKind.multi:
          multis[group.id] = <String>{};
        case OptionKind.quantity:
          quantities[group.id] = group.min;
      }
    }
    return SelectedOptions(
      singles: singles,
      multis: multis,
      quantities: quantities,
    );
  }

  final Map<String, String> singles;
  final Map<String, Set<String>> multis;
  final Map<String, int> quantities;

  SelectedOptions copyWith({
    Map<String, String>? singles,
    Map<String, Set<String>>? multis,
    Map<String, int>? quantities,
  }) {
    return SelectedOptions(
      singles: singles ?? this.singles,
      multis: multis ?? this.multis,
      quantities: quantities ?? this.quantities,
    );
  }

  int extraPrice(List<OptionGroup> groups) {
    int extra = 0;
    for (final OptionGroup group in groups) {
      switch (group.kind) {
        case OptionKind.single:
          final String? id = singles[group.id];
          extra += group.choices
              .firstWhere(
                (OptionChoice c) => c.id == id,
                orElse: () => group.choices.first,
              )
              .price;
        case OptionKind.multi:
          final Set<String> picked = multis[group.id] ?? const <String>{};
          for (final OptionChoice choice in group.choices) {
            if (picked.contains(choice.id)) {
              extra += choice.price;
            }
          }
        case OptionKind.quantity:
          extra += (quantities[group.id] ?? group.min) * group.unitPrice;
      }
    }
    return extra;
  }

  String summary(List<OptionGroup> groups) {
    final List<String> parts = <String>[];
    for (final OptionGroup group in groups) {
      switch (group.kind) {
        case OptionKind.single:
          final String? id = singles[group.id];
          final OptionChoice choice = group.choices.firstWhere(
            (OptionChoice c) => c.id == id,
            orElse: () => group.choices.first,
          );
          parts.add(choice.label);
        case OptionKind.multi:
          final Set<String> picked = multis[group.id] ?? const <String>{};
          for (final OptionChoice choice in group.choices) {
            if (picked.contains(choice.id)) {
              parts.add(choice.label);
            }
          }
        case OptionKind.quantity:
          final int count = quantities[group.id] ?? group.min;
          if (count > 0) {
            parts.add('${group.unitLabel} $count');
          }
      }
    }
    return parts.join(' · ');
  }

  String get signature {
    final List<String> chunks = <String>[];
    final List<String> singleKeys = singles.keys.toList()..sort();
    for (final String key in singleKeys) {
      chunks.add('s:$key=${singles[key]}');
    }
    final List<String> multiKeys = multis.keys.toList()..sort();
    for (final String key in multiKeys) {
      final List<String> ids = (multis[key] ?? const <String>{}).toList()
        ..sort();
      chunks.add('m:$key=${ids.join(",")}');
    }
    final List<String> qtyKeys = quantities.keys.toList()..sort();
    for (final String key in qtyKeys) {
      chunks.add('q:$key=${quantities[key]}');
    }
    return chunks.join('|');
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedOptions && signature == other.signature;
  }

  @override
  int get hashCode => signature.hashCode;
}

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

String formatPrice(int price) {
  final String raw = price.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int fromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
