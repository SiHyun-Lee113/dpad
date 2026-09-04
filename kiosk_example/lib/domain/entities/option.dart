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

/// 모든 음료에 공통으로 붙는 옵션. 단일·복수·수량형을 한 다이얼로그로 시험합니다.
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
