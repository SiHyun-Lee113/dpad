/// Flutter TV 앱용 D-pad 내비게이션 — Android TV, Fire TV, Apple TV,
/// 리모컨·게임패드가 있는 모든 환경.
///
/// ## 빠른 시작
///
/// 1. `MaterialApp.builder`에 루트를 설치합니다:
///
/// ```dart
/// MaterialApp(
///   builder: Dpad.wrap(),
///   home: const HomePage(),
/// )
/// ```
///
/// 2. 위젯을 포커스 가능하게 만듭니다:
///
/// ```dart
/// DpadFocusable(
///   autofocus: true,
///   onSelect: () => playMovie(movie),
///   child: PosterCard(movie),
/// )
/// ```
///
/// 3. 화면을 영역으로 나눕니다:
///
/// ```dart
/// DpadRegion(            // 위치를 기억하는 포스터 줄
///   child: SizedBox(
///     height: 200,
///     child: ListView(scrollDirection: Axis.horizontal, children: cards),
///   ),
/// )
/// ```
///
/// ## 구성 요소
///
/// * [Dpad] — 루트: 키 처리, 포커스 복구, [Dpad.of]로 프로그래밍 제어,
///   접근성 안내용 [DpadTtsService] (선택). 화면을 바꾸면 새 페이지에
///   포커스가 착지하고, 이전 페이지 마지막 칸에 남지 않습니다.
/// * [DpadScreen] — 화면(또는 다이얼로그) 묶음. 포커스되지 않습니다.
///   안의 [DpadRegion]이 어느 화면 아래 있는지 표시하고, 화면 진입 시
///   [DpadScreen.ttsLabel]을 영역·칸보다 먼저 읽습니다.
/// * [DpadFocusable] — 포커스 칸: 선택 / 롱셀렉트, pressed 상태,
///   포커스 이펙트, [DpadFocusable.ttsLabel] (선택).
/// * [DpadRegion] — TV 의미의 구역: 포커스 메모리([DpadEnterBehavior])와
///   축별 가장자리 규칙([DpadEdgeBehavior]), 그리드용
///   [DpadRegionFlow.readingOrder], 화면 진입용 [DpadRegion.autofocus],
///   장바구니 같은 세로 목록용 [DpadRegionKind.list] / [item].
/// * [DpadEffect] — 조합 가능한 포커스 비주얼 ([DpadScaleEffect],
///   [DpadGlowEffect], [DpadBorderEffect] 등). [DpadTheme]으로 테마 지정.
/// * [DpadTraversalPolicy] — TV에 맞는 방향 탐색 엔진.
///   [Dpad]과 [DpadRegion]이 자동으로 설치합니다.
library;

export 'src/effects.dart';
export 'src/focusable.dart';
export 'src/key_set.dart';
export 'src/nav_policy.dart';
export 'src/region.dart';
export 'src/root.dart';
export 'src/screen.dart';
export 'src/scroll.dart';
export 'src/theme.dart';
export 'src/traversal.dart';
export 'src/tts.dart';
