import 'package:flutter/material.dart';

/// [DpadFocusable]의 상호작용 상태. 포커스 이펙트와 커스텀 빌더에 전달됩니다.
///
/// TV UI는 상태를 둘로 나눕니다:
///
/// * [focused] — 지금 D-pad 커서가 이 칸에 있음.
/// * [pressed] — 선택 키(또는 탭)를 이 칸에서 누르고 있음.
///   네이티브 TV처럼 "눌림" 피드백에 사용합니다.
@immutable
class DpadFocusState {
  /// 상호작용 상태 스냅샷을 만듭니다.
  const DpadFocusState({required this.focused, required this.pressed});

  /// 포커스도 pressed도 아닌 상태.
  static const DpadFocusState idle =
      DpadFocusState(focused: false, pressed: false);

  /// 지금 D-pad 포커스를 가지고 있는지.
  final bool focused;

  /// 선택 키 또는 포인터가 이 칸에서 눌려 있는지.
  final bool pressed;

  @override
  bool operator ==(Object other) {
    return other is DpadFocusState &&
        other.focused == focused &&
        other.pressed == pressed;
  }

  @override
  int get hashCode => Object.hash(focused, pressed);

  @override
  String toString() => 'DpadFocusState(focused: $focused, pressed: $pressed)';
}

/// 커스텀 포커스 표현을 만드는 시그니처.
///
/// [child]는 감싼 콘텐츠입니다. [state]에 맞게 꾸며 반환하세요.
typedef DpadEffectBuilder = Widget Function(
  BuildContext context,
  DpadFocusState state,
  Widget child,
);

/// [DpadFocusState]에 따라 [DpadFocusable]에 적용하는, 조합 가능한 불변 이펙트.
///
/// 이펙트는 const 객체라 [DpadThemeData.effects]로 공유하거나 인라인으로 넘깁니다:
///
/// ```dart
/// DpadFocusable(
///   effects: const [
///     DpadScaleEffect(scale: 1.1),
///     DpadGlowEffect(),
///   ],
///   child: PosterCard(...),
/// )
/// ```
///
/// 여러 이펙트를 합치면 리스트의 **첫 번째**가 가장 바깥 래퍼입니다.
/// [DpadScaleEffect] 같은 변환 이펙트를 앞에 두면 꾸며진 결과 전체가 확대됩니다.
abstract class DpadEffect {
  /// 서브클래스용 const 생성자.
  const DpadEffect();

  /// 주어진 [state]로 [child]를 이 이펙트로 감쌉니다.
  Widget build(BuildContext context, DpadFocusState state, Widget child);

  /// [effects]를 [child]에 적용합니다. 첫 이펙트가 가장 바깥입니다.
  static Widget wrap(
    BuildContext context,
    List<DpadEffect> effects,
    DpadFocusState state,
    Widget child,
  ) {
    Widget result = child;
    for (int i = effects.length - 1; i >= 0; i--) {
      result = effects[i].build(context, state, result);
    }
    return result;
  }
}

/// 포커스되면 확대하고, 누르면 살짝 줄어듭니다 — TV의 "들어 올리고 누르기".
class DpadScaleEffect extends DpadEffect {
  /// 스케일 이펙트를 만듭니다.
  const DpadScaleEffect({
    this.scale = 1.08,
    this.pressedScale,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeOutCubic,
  });

  /// 포커스일 때 배율.
  final double scale;

  /// 눌렸을 때 배율.
  ///
  /// 기본값은 `1.0`과 [scale]의 중간으로, 선택 키를 누르는 동안
  /// 살짝 내려가는 느낌입니다.
  final double? pressedScale;

  /// 애니메이션 시간.
  final Duration duration;

  /// 애니메이션 커브.
  final Curve curve;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final double target = state.pressed
        ? (pressedScale ?? (1.0 + (scale - 1.0) * 0.5))
        : state.focused
            ? scale
            : 1.0;
    return AnimatedScale(
      scale: target,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

/// 포커스일 때 칸 위에 테두리(와 선택적 배경)를 그립니다.
///
/// 전경 데코레이션이라 켜도 레이아웃이 밀리지 않습니다.
/// 키오스크 배리어프리 하이라이트는 [fillColor] + 안쪽 정렬 두꺼운
/// 테두리 + [BorderRadius.zero] 조합입니다.
class DpadBorderEffect extends DpadEffect {
  /// 테두리 이펙트를 만듭니다.
  const DpadBorderEffect({
    this.color,
    this.fillColor,
    this.width = 2.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.strokeAlign = BorderSide.strokeAlignInside,
    this.duration = const Duration(milliseconds: 150),
  });

  /// 테두리 색. 기본값은 [ColorScheme.primary].
  final Color? color;

  /// 포커스일 때 칸을 덮는 배경색. null이면 배경을 그리지 않습니다.
  final Color? fillColor;

  /// 포커스일 때 테두리 두께.
  final double width;

  /// 테두리 모서리 반경. 키오스크 하이라이트는 [BorderRadius.zero].
  final BorderRadius borderRadius;

  /// 테두리 정렬. 기본값은 안쪽이라 레이아웃이 커지지 않습니다.
  final double strokeAlign;

  /// 애니메이션 시간.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final Color resolved = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: duration,
      foregroundDecoration: BoxDecoration(
        color: state.focused ? fillColor : null,
        borderRadius: borderRadius,
        border: Border.all(
          color: state.focused ? resolved : const Color(0x00000000),
          width: state.focused ? width : 0,
          strokeAlign: strokeAlign,
        ),
      ),
      child: child,
    );
  }
}

/// 포커스일 때 부드러운 글로우를 그립니다.
class DpadGlowEffect extends DpadEffect {
  /// 글로우 이펙트를 만듭니다.
  const DpadGlowEffect({
    this.color,
    this.blurRadius = 18.0,
    this.spreadRadius = 2.0,
    this.opacity = 0.55,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// 글로우 색. 기본값은 [ColorScheme.primary].
  final Color? color;

  /// 글로우 블러 반경.
  final double blurRadius;

  /// 글로우 퍼짐 반경.
  final double spreadRadius;

  /// 포커스일 때 글로우 최대 불투명도, `0.0` – `1.0`.
  final double opacity;

  /// 그림자 모양의 모서리 반경.
  final BorderRadius borderRadius;

  /// 애니메이션 시간.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final Color resolved = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: resolved.withAlpha(
              state.focused ? (opacity.clamp(0.0, 1.0) * 255).round() : 0,
            ),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 포커스일 때 Material elevation 그림자로 칸을 띄웁니다.
class DpadElevationEffect extends DpadEffect {
  /// elevation 이펙트를 만듭니다.
  const DpadElevationEffect({
    this.elevation = 12.0,
    this.idleElevation = 0.0,
    this.shadowColor = const Color(0xFF000000),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// 포커스일 때 elevation.
  final double elevation;

  /// 포커스가 아닐 때 elevation.
  final double idleElevation;

  /// 그림자 색.
  final Color shadowColor;

  /// 그림자 모양의 모서리 반경.
  final BorderRadius borderRadius;

  /// 애니메이션 시간.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return AnimatedPhysicalModel(
      duration: duration,
      curve: Curves.easeOutCubic,
      elevation: state.focused ? elevation : idleElevation,
      color: const Color(0x00000000),
      shadowColor: shadowColor,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// 포커스가 *아닌* 칸을 어둡게 해, 포커스된 칸이 돋보이게 합니다.
class DpadOpacityEffect extends DpadEffect {
  /// 불투명도 이펙트를 만듭니다.
  const DpadOpacityEffect({
    this.idleOpacity = 0.6,
    this.focusedOpacity = 1.0,
    this.duration = const Duration(milliseconds: 150),
  });

  /// 포커스가 아닐 때 불투명도.
  final double idleOpacity;

  /// 포커스일 때 불투명도.
  final double focusedOpacity;

  /// 애니메이션 시간.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return AnimatedOpacity(
      duration: duration,
      opacity: state.focused ? focusedOpacity : idleOpacity,
      child: child,
    );
  }
}

/// 포커스일 때 반투명 색을 덮습니다.
class DpadTintEffect extends DpadEffect {
  /// 틴트 이펙트를 만듭니다.
  const DpadTintEffect({
    this.color,
    this.opacity = 0.25,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// 틴트 색. 기본값은 [ColorScheme.primary].
  final Color? color;

  /// 포커스일 때 틴트 최대 불투명도, `0.0` – `1.0`.
  final double opacity;

  /// 틴트 오버레이의 모서리 반경.
  final BorderRadius borderRadius;

  /// 애니메이션 시간.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final Color resolved = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: duration,
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        color: resolved.withAlpha(
          state.focused ? (opacity.clamp(0.0, 1.0) * 255).round() : 0,
        ),
      ),
      child: child,
    );
  }
}

/// 일회성 이펙트를 위해 임의의 [DpadEffectBuilder]를 [DpadEffect]로 감쌉니다.
class DpadCustomEffect extends DpadEffect {
  /// [builder]로 동작하는 이펙트를 만듭니다.
  const DpadCustomEffect(this.builder);

  /// child를 꾸미는 함수.
  final DpadEffectBuilder builder;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return builder(context, state, child);
  }
}
