import 'package:flutter/foundation.dart';

/// The active sidebar section (0 = For you, 1 = Library, 2 = Search,
/// 3 = Settings). Lifted to a notifier so app-level key shortcuts can
/// switch sections too.
final ValueNotifier<int> activeSection = ValueNotifier<int>(0);

/// Runtime toggle for the built-in focus inspector
/// ([Dpad.debugOverlay]) — flip it from the Settings section.
final ValueNotifier<bool> showFocusInspector = ValueNotifier<bool>(false);

/// Runtime toggle for the focus "tick" sound played through
/// [Dpad.onFocusChange].
final ValueNotifier<bool> clickSounds = ValueNotifier<bool>(true);
