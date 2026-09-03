import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// D-pad 시스템이 인식하는 리모컨 키 묶음.
///
/// TV 리모컨, 게임패드, 키보드는 같은 의미의 버튼을 서로 다른
/// [LogicalKeyboardKey]로 보냅니다. [DpadKeySet]은 키 코드 대신
/// "선택", "뒤로" 같은 *의미*로 묶습니다.
///
/// 기본 생성자는 Android TV, Fire TV, Apple TV(웹), 일반 게임패드,
/// 데스크톱 키보드를 커버합니다. 기기가 특이한 키 코드를 쓰면 커스텀하세요:
///
/// ```dart
/// Dpad(
///   keySet: const DpadKeySet().copyWith(
///     select: [LogicalKeyboardKey.f1, ...DpadKeySet.defaultSelect],
///   ),
///   child: ...,
/// )
/// ```
@immutable
class DpadKeySet {
  /// 키 세트를 만듭니다. 생략한 값은 플랫폼 기본값입니다.
  const DpadKeySet({
    this.up = defaultUp,
    this.down = defaultDown,
    this.left = defaultLeft,
    this.right = defaultRight,
    this.select = defaultSelect,
    this.back = defaultBack,
    this.menu = defaultMenu,
  });

  /// 포커스를 위로 옮기는 기본 키.
  static const List<LogicalKeyboardKey> defaultUp = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowUp,
  ];

  /// 포커스를 아래로 옮기는 기본 키.
  static const List<LogicalKeyboardKey> defaultDown = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowDown,
  ];

  /// 포커스를 왼쪽으로 옮기는 기본 키.
  static const List<LogicalKeyboardKey> defaultLeft = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowLeft,
  ];

  /// 포커스를 오른쪽으로 옮기는 기본 키.
  static const List<LogicalKeyboardKey> defaultRight = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowRight,
  ];

  /// 포커스된 칸을 확인 / 누르는 기본 키.
  ///
  /// 리모컨 가운데 버튼([LogicalKeyboardKey.select]), 키보드 확인 키,
  /// 게임패드 `A`를 포함합니다.
  static const List<LogicalKeyboardKey> defaultSelect = <LogicalKeyboardKey>[
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  ];

  /// 뒤로 가기를 요청하는 기본 키.
  static const List<LogicalKeyboardKey> defaultBack = <LogicalKeyboardKey>[
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.goBack,
    LogicalKeyboardKey.gameButtonB,
  ];

  /// 컨텍스트 메뉴를 여는 기본 키.
  static const List<LogicalKeyboardKey> defaultMenu = <LogicalKeyboardKey>[
    LogicalKeyboardKey.contextMenu,
  ];

  /// 포커스를 위로 옮기는 키.
  final List<LogicalKeyboardKey> up;

  /// 포커스를 아래로 옮기는 키.
  final List<LogicalKeyboardKey> down;

  /// 포커스를 왼쪽으로 옮기는 키.
  final List<LogicalKeyboardKey> left;

  /// 포커스를 오른쪽으로 옮기는 키.
  final List<LogicalKeyboardKey> right;

  /// 포커스된 칸을 확인 / 누르는 키.
  final List<LogicalKeyboardKey> select;

  /// 뒤로 가기를 요청하는 키.
  final List<LogicalKeyboardKey> back;

  /// 컨텍스트 메뉴를 여는 키.
  final List<LogicalKeyboardKey> menu;

  /// [key]에 매핑된 [TraversalDirection]. 방향 키가 아니면 `null`.
  TraversalDirection? directionOf(LogicalKeyboardKey key) {
    if (up.contains(key)) {
      return TraversalDirection.up;
    }
    if (down.contains(key)) {
      return TraversalDirection.down;
    }
    if (left.contains(key)) {
      return TraversalDirection.left;
    }
    if (right.contains(key)) {
      return TraversalDirection.right;
    }
    return null;
  }

  /// [key]가 이 세트의 선택 키인지.
  bool isSelect(LogicalKeyboardKey key) => select.contains(key);

  /// [key]가 이 세트의 뒤로 가기 키인지.
  bool isBack(LogicalKeyboardKey key) => back.contains(key);

  /// [key]가 이 세트의 메뉴 키인지.
  bool isMenu(LogicalKeyboardKey key) => menu.contains(key);

  /// 지정한 필드만 바꾼 복사본을 만듭니다.
  DpadKeySet copyWith({
    List<LogicalKeyboardKey>? up,
    List<LogicalKeyboardKey>? down,
    List<LogicalKeyboardKey>? left,
    List<LogicalKeyboardKey>? right,
    List<LogicalKeyboardKey>? select,
    List<LogicalKeyboardKey>? back,
    List<LogicalKeyboardKey>? menu,
  }) {
    return DpadKeySet(
      up: up ?? this.up,
      down: down ?? this.down,
      left: left ?? this.left,
      right: right ?? this.right,
      select: select ?? this.select,
      back: back ?? this.back,
      menu: menu ?? this.menu,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DpadKeySet &&
        listEquals(other.up, up) &&
        listEquals(other.down, down) &&
        listEquals(other.left, left) &&
        listEquals(other.right, right) &&
        listEquals(other.select, select) &&
        listEquals(other.back, back) &&
        listEquals(other.menu, menu);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(up),
        Object.hashAll(down),
        Object.hashAll(left),
        Object.hashAll(right),
        Object.hashAll(select),
        Object.hashAll(back),
        Object.hashAll(menu),
      );
}
