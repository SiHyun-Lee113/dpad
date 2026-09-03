import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'effects.dart';

/// [DpadTheme] 아래(또는 하나를 설치하는 [Dpad] 루트 아래)의
/// 모든 [DpadFocusable]이 공유하는 기본값.
///
/// 개별 [DpadFocusable]이 자기 파라미터로 덮어씁니다.
/// `null`로 남긴 값은 테마로 떨어집니다.
@immutable
class DpadThemeData {
  /// D-pad 기본값을 만듭니다.
  const DpadThemeData({
    this.effects = defaultEffects,
    this.scrollPadding = 48.0,
    this.scrollDuration = const Duration(milliseconds: 220),
    this.scrollCurve = Curves.easeOutCubic,
    this.longSelectDuration = const Duration(milliseconds: 500),
  });

  /// 기본 포커스 표현: 약한 확대 + 테두리.
  static const List<DpadEffect> defaultEffects = <DpadEffect>[
    DpadScaleEffect(),
    DpadBorderEffect(),
  ];

  /// 자체 [DpadFocusable.effects]나 [DpadFocusable.builder]가 없는
  /// 칸에 적용되는 이펙트.
  final List<DpadEffect> effects;

  /// 자동 스크롤 시 포커스된 칸과 뷰포트 가장자리 사이에 남기는 여백.
  /// 글로우·확대된 테두리가 잘리지 않게 합니다.
  final double scrollPadding;

  /// 자동 스크롤 애니메이션 시간.
  final Duration scrollDuration;

  /// 자동 스크롤 애니메이션 커브.
  final Curve scrollCurve;

  /// 선택 키를 얼마나 눌러야 [DpadFocusable.onLongSelect]가 발생하는지.
  final Duration longSelectDuration;

  /// 지정한 필드만 바꾼 복사본을 만듭니다.
  DpadThemeData copyWith({
    List<DpadEffect>? effects,
    double? scrollPadding,
    Duration? scrollDuration,
    Curve? scrollCurve,
    Duration? longSelectDuration,
  }) {
    return DpadThemeData(
      effects: effects ?? this.effects,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      scrollDuration: scrollDuration ?? this.scrollDuration,
      scrollCurve: scrollCurve ?? this.scrollCurve,
      longSelectDuration: longSelectDuration ?? this.longSelectDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DpadThemeData &&
        listEquals(other.effects, effects) &&
        other.scrollPadding == scrollPadding &&
        other.scrollDuration == scrollDuration &&
        other.scrollCurve == scrollCurve &&
        other.longSelectDuration == longSelectDuration;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(effects),
        scrollPadding,
        scrollDuration,
        scrollCurve,
        longSelectDuration,
      );
}

/// 하위 [DpadFocusable]에 [DpadThemeData]를 제공합니다.
///
/// 아무 곳에나 중첩해 서브트리만 스타일을 바꿀 수 있습니다:
///
/// ```dart
/// DpadTheme(
///   data: const DpadThemeData(
///     effects: [DpadGlowEffect(color: Colors.amber)],
///   ),
///   child: SettingsColumn(...),
/// )
/// ```
class DpadTheme extends InheritedWidget {
  /// [data]를 자손에게 제공합니다.
  const DpadTheme({super.key, required this.data, required super.child});

  /// 이 서브트리의 기본값.
  final DpadThemeData data;

  /// 가장 가까운 [DpadTheme]의 [DpadThemeData]. 없으면 기본 [DpadThemeData].
  static DpadThemeData of(BuildContext context) {
    return maybeOf(context) ?? const DpadThemeData();
  }

  /// 가장 가까운 [DpadTheme]의 [DpadThemeData]. 없으면 `null`.
  static DpadThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DpadTheme>()?.data;
  }

  @override
  bool updateShouldNotify(DpadTheme oldWidget) => data != oldWidget.data;
}
