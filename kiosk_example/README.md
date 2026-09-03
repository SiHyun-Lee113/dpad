# Dpad Kiosk example

키오스크 메뉴 선택 화면으로 [`dpad`](https://pub.dev/packages/dpad)의
`DpadNavPolicy.kiosk`, `DpadRegionFlow.readingOrder`,
`DpadRegionKind.list` / `item`을 보여 줍니다.

## 동작

**메뉴 그리드** (4×2, `readingOrder`)

- 좌/우만으로 칸을 걷습니다. **4번에서 → 는 5번**으로 갑니다.
- **마지막 칸에서 → 는 첫 칸**으로 순환합니다.
- 선택하면 옵션 다이얼로그가 열립니다.

**옵션 다이얼로그**

- 온도: 단일 선택
- 추가 옵션: 복수 선택
- 에스프레소 샷: 수량형 (`−` / 숫자 / `＋`, 숫자 칸은 키패드)

**장바구니** (`DpadRegionKind.list`)

- 화면 상/하에서 한 밴드입니다. 착지 시 줄 전체가 선택됩니다.
- Enter로 줄 안 `−` / 수량 / `＋` / 삭제로 들어갑니다.
- 수량 칸을 누르면 숫자 키패드로 개수를 입력합니다.
- 줄에서 상/하는 다음·이전 상품으로 갑니다.

## 실행

```bash
cd kiosk_example
flutter run -d windows
```
