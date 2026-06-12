# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-06-13

A ground-up rewrite. 3.0 replaces the 2.x key interception and rule tables
with a TV-correct traversal engine built on Flutter's own focus primitives
(`FocusTraversalPolicy`, `Shortcuts`, `Actions`). The API is smaller,
declarative, and tuned for how TV interfaces actually behave.

Requires Flutter `>= 3.24` / Dart `>= 3.5`.

### Added

- **`DpadTraversalPolicy`** — directional navigation modeled on Android's
  `FocusFinder`/Leanback: edge-based direction tests, beam preference
  (aligned candidates beat diagonal ones) and weighted distances.
- **`DpadRegion`** — declarative navigation areas:
  - region-first traversal: focus moves within the region before
    considering outside targets;
  - per-region focus memory with `DpadEnterBehavior.restore` (default),
    `entry` and `nearest`;
  - per-axis edge control with `DpadEdgeBehavior.leave`, `stop` and `wrap`
    (carousel wrap-around);
  - `onEdge` and `onFocusChange` callbacks; nesting supported.
- **Lazy-list awareness** — when no focus candidate exists but a scrollable
  can still scroll in that direction (e.g. unbuilt `ListView.builder`
  items), the engine scrolls and retries instead of stopping.
- **Focus resilience** — guaranteed startup focus (with `autofocus` taking
  precedence), initial focus for routes pushed without `autofocus`,
  restoration when the focused widget is disposed, and restoration on app
  resume. The remote can never end up with nothing focused.
- **`DpadRegion.memoryKey`** — focus memory that persists across full
  subtree rebuilds (section/tab switchers), with position-aware
  restoration when the original items were recreated.
- **TV-correct text fields** — arrows move the caret mid-text but navigate
  away at the caret's edge (and vertically in single-line fields), so a
  remote-only user is never trapped in a search box; IME composition owns
  all keys while active.
- **`Dpad.debugOverlay`** — an on-screen focus inspector outlining the
  focused node with its label, region and geometry.
- **`Dpad.onFocusChange`** — a global hook on every focus move, for click
  sounds, haptics or analytics.
- **`DpadFocusable` interactions** — `onLongSelect` (held center button)
  with select/long-select disambiguation, pressed-state visuals,
  `onDirection` for slider-style consumption of arrows, tap/click support
  for hybrid devices, and `excludeChildFocus` (default `true`) so wrapped
  buttons never become double focus stops.
- **Class-based focus effects** — `DpadScaleEffect` (pressed push-down),
  `DpadBorderEffect` (layout-shift-free foreground border),
  `DpadGlowEffect`, `DpadElevationEffect`, `DpadOpacityEffect`,
  `DpadTintEffect`, `DpadCustomEffect`; composable via `effects:` lists.
- **`DpadTheme` / `DpadThemeData`** — app-wide defaults for effects,
  auto-scroll padding/duration/curve and long-select duration.
- **`DpadController`** (`Dpad.of(context)`) — `move*()`, `next()`,
  `previous()`, `select()`, `back()`, `requestFocus()`, `clearFocus()`,
  `ensureVisible()`, `focused`.
- **`DpadKeySet`** — semantic key mapping (up/down/left/right, select,
  back, menu) with TV-wide defaults and `copyWith` remapping.
- **Text-input safety** — directional keys, back/menu and app shortcuts
  automatically stand down while an `EditableText` is focused.
- **`Dpad.wrap()`** — one-line installation through `MaterialApp.builder`
  covering every route, dialog and overlay.
- **`DpadScroll.ensureVisible`** — padded reveal that walks all scrollable
  ancestors, honors reversed axes and centers oversized items.

### Changed

- **BREAKING** `DpadNavigator` → `Dpad` (recommended placement:
  `MaterialApp(builder: Dpad.wrap())`).
- **BREAKING** `Dpad` static helpers → instance methods on
  `Dpad.of(context)` (`navigateUp` → `moveUp`, `navigateNext` → `next`,
  `requestFocusSafely` → `requestFocus`, `scrollToFocus` →
  `ensureVisible`).
- **BREAKING** `DpadFocusable.builder` signature is now
  `(context, DpadFocusState state, child)`; `state.focused` replaces the
  `isFocused` boolean and `state.pressed` is new. `child` is required.
- **BREAKING** `onFocus`/`onBlur` merged into `onFocusChange(bool)`.
- **BREAKING** selection is delivered through Flutter's `Actions` system
  and raw key tracking instead of `consumeKeyboardToken()`; select fires
  once per press with correct repeat suppression.
- **BREAKING** `onBackPressed` → `onBack` (returns `bool`: `true`
  consumes, `false` lets the framework handle it); `onMenuPressed` →
  `onMenu`; `customShortcuts` → `shortcuts`.
- Auto-scroll defaults now come from the theme (`scrollPadding: 48`).

### Removed

- **BREAKING** `FocusEffects` closure factories — use the `DpadEffect`
  classes.
- **BREAKING** `FocusMemoryOptions`, `FocusHistoryManager`,
  `FocusHistoryEntry`, `onNavigateBack` and the global focus-history stack
  — per-region memory (`DpadRegion`) replaces them.
- **BREAKING** `RegionNavigationOptions`, `RegionNavigationRule`,
  `RegionNavigationStrategy`, `RegionNavigationManager`,
  `RegionAwareFocusTraversalPolicy`, `RegionTraversalGroup`,
  `RegionTraversalGroupScope` and the imperative node registration —
  `DpadRegion` + `DpadTraversalPolicy` replace the entire rule system.
- **BREAKING** `DpadFocusable.region` / `isEntryPoint` / `entryPriority` —
  membership now comes from the widget tree (nearest `DpadRegion`); mark
  one item per region with `entry: true`.

### Fixed

- Wrapping a focusable Material button in `DpadFocusable` no longer
  creates two d-pad stops.
- Space/Enter and arrow keys are no longer hijacked while typing in a
  `TextField`.
- Holding the select key no longer fires `onSelect` repeatedly.
- Auto-scroll now works correctly inside reversed scrollables and centers
  items larger than the viewport.
- Focus no longer dies when the focused item is removed from a refreshing
  list.
- The [Dpad] root keeps an identical widget structure for every
  configuration, so flipping `enabled` or `debugOverlay` at runtime never
  resets the application subtree.

## [2.0.2] - 2025-11-26

### Fixed
- Region navigation policy detection via `FocusTraversalGroup.maybeOf()`.

### Improved
- Streamlined navigation flow in `_navigate()`.

## [2.0.1] - 2025-11-25

### Added
- Window focus restoration on app resume.

### Improved
- Within-region navigation priority and focus history safety.

### Fixed
- Navigation after window focus loss; sidebar jump issues; focus memory
  restoration timing.

## [2.0.0] - 2025-11-25

### Added
- Region-based navigation system (`RegionNavigationOptions`,
  `RegionNavigationRule`, strategies, `RegionAwareFocusTraversalPolicy`).

## [1.2.2] - 2025-11-20

### Added
- Auto-scroll for focused widgets (`autoScroll`, `scrollPadding`,
  `Dpad.scrollToFocus`).

## [1.1.0] - 2025-11-15

### Added
- Sequential navigation (`navigateNext` / `navigatePrevious`), media key
  support, focus memory with history stack.

## [1.0.0] - 2025-11-10

- Initial release: `DpadNavigator`, `DpadFocusable`, `FocusEffects`,
  programmatic `Dpad` utilities.
