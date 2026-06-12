import 'package:flutter/material.dart';

import '../app_state.dart';
import '../sections/for_you_section.dart';
import '../sections/library_section.dart';
import '../sections/search_section.dart';
import '../sections/settings_section.dart';
import '../widgets/sidebar.dart';

/// The app shell: navigation rail on the left, the active section on the
/// right. Browsing the rail switches sections instantly; pressing select
/// (or right) dives into the content.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _destinations = [
    SidebarDestination(Icons.home_filled, 'For you'),
    SidebarDestination(Icons.video_library_rounded, 'Library'),
    SidebarDestination(Icons.search_rounded, 'Search'),
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
                _ => const SettingsSection(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
