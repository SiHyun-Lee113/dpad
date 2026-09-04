import 'option.dart';

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
