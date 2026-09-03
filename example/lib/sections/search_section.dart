import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets/poster_card.dart';

/// D-pad 탐색과 텍스트 입력이 함께 동작함을 보여 줍니다. 필드를 편집하는 동안
/// 화살표는 캐럿을 움직이고 앱 단축키는 멈춥니다. 포커스가 나가면 다시
/// 리모컨이 그리드를 움직입니다.
class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = [
      for (final row in homeRows)
        for (final movie in row.movies)
          if (_query.isEmpty ||
              movie.title.toLowerCase().contains(_query.toLowerCase()))
            movie,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 480,
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search titles…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white.withAlpha(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'While typing, arrows move the caret — at the edges of the text '
            '(and with ↓) they leave the field. You are never trapped.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            '${results.length} title${results.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DpadRegion(
              debugLabel: 'search-results',
              memoryKey: 'search-results',
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 240 / 124,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) => PosterCard(
                  movie: results[index],
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
