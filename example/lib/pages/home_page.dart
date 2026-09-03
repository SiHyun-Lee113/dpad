import 'package:flutter/material.dart';

import '../app_state.dart';
import '../sections/dialogs_section.dart';
import '../sections/for_you_section.dart';
import '../sections/library_section.dart';
import '../sections/search_section.dart';
import '../sections/settings_section.dart';
import '../widgets/sidebar.dart';

/// 앱 셸: 왼쪽 내비게이션 레일, 오른쪽 활성 섹션.
/// 레일을 훑으면 섹션이 바로 바뀌고, 선택(또는 오른쪽)으로 콘텐츠에 들어갑니다.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _destinations = [
    SidebarDestination(Icons.home_filled, 'For you'),
    SidebarDestination(Icons.video_library_rounded, 'Library'),
    SidebarDestination(Icons.search_rounded, 'Search'),
    SidebarDestination(Icons.chat_bubble_outline_rounded, 'Dialogs'),
    SidebarDestination(Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: activeSection,
        builder: (context, section, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Sidebar(
              destinations: _destinations,
              selectedIndex: section,
              onSelected: (index) => activeSection.value = index,
            ),
            Expanded(
              child: switch (section) {
                0 => const ForYouSection(),
                1 => const LibrarySection(),
                2 => const SearchSection(),
                3 => const DialogsSection(),
                _ => const SettingsSection(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
