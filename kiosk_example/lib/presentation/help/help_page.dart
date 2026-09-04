import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../../core/theme/kiosk_colors.dart';
import '../menu/kiosk_header.dart';

/// 메뉴 키 / F1. 이 예제가 커버하는 dpad API를 한 화면에 모아 둡니다.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DpadScreen(
      debugLabel: 'help',
      ttsLabel: '도움말',
      child: Scaffold(
      body: Column(
        children: [
          KioskHeader(
            title: '도움말',
            onHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: DpadRegion(
              debugLabel: 'help',
              ttsLabel: '안내',
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: const [
                  _HelpBlock(
                    title: '루트 · Dpad.wrap',
                    body:
                        'navPolicy.kiosk, theme, TTS, onBack, onMenu, shortcuts, '
                        'onFocusChange, debugOverlay. F1 도움말 · F2 검색 · F3 설정 · '
                        '뒤로 키는 열려 있는 화면을 닫습니다.',
                  ),
                  _HelpBlock(
                    title: '영역 · DpadRegion',
                    body:
                        '메뉴 그리드는 readingOrder. 카테고리는 wrap + memoryKey. '
                        '장바구니는 list/item. 처음으로 버튼은 requestFirstFocus.',
                  ),
                  _HelpBlock(
                    title: '칸 · DpadFocusable',
                    body:
                        '선택하면 옵션 다이얼로그. 길게 누르면 기본 옵션으로 바로 담기. '
                        '설정 슬라이더는 onDirection. 검색 필드는 excludeChildFocus: false.',
                  ),
                  _HelpBlock(
                    title: '이펙트 · DpadTheme',
                    body:
                        '앱 기본은 두꺼운 파란 테두리. 설정에서 Scale/Glow/Elevation/'
                        'Opacity/Tint/Custom을 고르고 미리보기를 확인하세요.',
                  ),
                  _HelpBlock(
                    title: '라우트 포커스',
                    body:
                        '결제 완료 화면이 열리면 새 페이지의 autofocus 칸으로 착지합니다. '
                        '뒤로 가면 이전 칸이 복원됩니다.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: DpadRegion(
              debugLabel: 'help-close',
              ttsLabel: '닫기',
              child: DpadFocusable(
              autofocus: true,
              debugLabel: '도움말-닫기',
              ttsLabel: '닫기',
              onSelect: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kioskAccent,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Center(
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _HelpBlock extends StatelessWidget {
  const _HelpBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kioskBrown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: kioskMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
