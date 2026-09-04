import 'package:flutter/widgets.dart';

import 'kiosk_session.dart';

class SessionScope extends InheritedWidget {
  const SessionScope({
    super.key,
    required this.session,
    required super.child,
  });

  final KioskSession session;

  static KioskSession of(BuildContext context) {
    final SessionScope? scope =
        context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope가 없습니다.');
    return scope!.session;
  }

  @override
  bool updateShouldNotify(SessionScope oldWidget) =>
      session != oldWidget.session;
}
