# Dpad Kiosk example

키오스크 메뉴 선택 화면으로 [`dpad`](https://pub.dev/packages/dpad)의
공개 API를 한 앱에서 확인합니다. 폴더는 클린 아키텍처라서
**어디에 무엇을 붙이는지** 파일 위치로 읽을 수 있습니다.

## 폴더 구조

```
lib/
  main.dart                          엔트리. 방향 고정 후 KioskApp 실행
  app.dart                           합성 루트 (의존성 조립 + Dpad.wrap)
  core/                              화면·도메인에 묶이지 않는 공통
    constants/kiosk_size.dart        720×1280
    theme/kiosk_colors.dart
    utils/format_price.dart
  domain/                            앱이 dpad 없이 표현하는 규칙
    entities/                        메뉴, 옵션, 장바구니 줄
    repositories/                    추상 저장소
    usecases/                        메뉴 조회, 장바구니 변경
  data/                              domain 구현
    catalogs/menu_catalog.dart       메모리 메뉴
    repositories/                    InMemory*Repository
    tts/                             DpadTtsService ← flutter_tts
  presentation/                      위젯. 여기서 dpad를 씁니다
    start/                           주문 시작 ([DpadScreen] 진입 TTS)
    cart/                            list / item 장바구니
    options/                         단일·복수·수량 다이얼로그
    quantity/                        숫자 키패드 다이얼로그
    search/                          TextField + excludeChildFocus: false
    settings/                        이펙트 갤러리, onDirection, requestFocus
    help/                            onMenu / F1
    checkout/                        라우트 포커스 핸드오프
    session/                         debugOverlay, TTS, 틱 사운드
    widgets/                         DpadFocusable.builder 버튼
```

의존성 방향은 `presentation → domain ← data` 입니다.
`app.dart`만 data와 presentation을 함께 생성합니다.

## dpad API 위치

| API | 화면 |
| --- | --- |
| `DpadScreen` + 영역 `ttsLabel` | 주문 시작, 메뉴, 다이얼로그 |
| `onBack` / `onMenu` / `shortcuts` / `onFocusChange` / `debugOverlay` | `app.dart`, 설정에서 토글 |
| `DpadRegionFlow.readingOrder` | 메뉴 그리드 |
| `DpadEdgeBehavior.wrap` + `memoryKey` | 카테고리 칩 |
| `requestFirstFocus` | 헤더 「처음으로」 |
| `onSelect` / `onLongSelect` / `entry` | 메뉴 칸 (길게 = 기본 옵션 담기). 포커스 이펙트는 앱 테마 |
| `DpadRegionKind.list` / `item` | 장바구니 |
| `excludeChildFocus: false` | 검색 필드 |
| `onDirection` / `enabled: false` / `DpadTheme` / 이펙트 갤러리 / `requestFocus` / `onEdge` | 설정 |
| 라우트 포커스 핸드오프 | 결제 완료 |

단축키: **F1** 도움말, **F2** 검색, **F3** 설정. 리모컨 메뉴 키도 도움말입니다.

## 동작

**주문 시작**

- 가운데 **주문하기**만 있습니다. 선택하면 메뉴 화면으로 들어갑니다.
- 화면 진입 시 TTS는 `주문 시작, 시작, 주문하기` 순으로 읽습니다.

**메뉴 그리드** (2열, `readingOrder`)

- 좌/우만으로 칸을 걷습니다. **4번에서 → 는 5번**으로 갑니다.
- **마지막 칸에서 → 는 첫 칸**으로 순환합니다.
- 선택하면 옵션 다이얼로그. 길게 누르면 기본 옵션으로 바로 담습니다.

**옵션 다이얼로그**

- 온도: 단일 선택
- 추가 옵션: 복수 선택
- 에스프레소 샷: 수량형 (`−` / 숫자 / `＋`, 숫자 칸은 키패드)

**장바구니** (`DpadRegionKind.list`)

- 화면 상/하에서 한 밴드입니다. 착지 시 줄 전체가 선택됩니다.
- Enter로 줄 안 `−` / 수량 / `＋` / 삭제로 들어갑니다.
- 수량 칸을 누르면 숫자 키패드로 개수를 입력합니다.

## 실행

```bash
cd kiosk_example
flutter run -d windows
```

Windows 창은 **720×1280** 세로 키오스크 크기이며, 사용자가 크기를 바꿀 수 없습니다.
