import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../ads/reward_ad_button.dart';
import 'shop_screen.dart';

/// 부적이 모자랄 때 패스·상점·광고 충전을 한 번에 고르게 한다.
Future<void> showAmuletPaywall(BuildContext context, WidgetRef ref) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('부적이 모두 떨어졌어요'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30일 복채 패스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.crimson)),
          SizedBox(height: 8),
          Text(
            '매일 00시에 부적 5개, 쌀알 15개까지 채워 드리고 하단 광고를 숨깁니다.',
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          SizedBox(height: 12),
          Text(
            '패스 없이도 매일 부적 1개, 쌀알 3개까지 채워 드립니다.',
            style: TextStyle(color: AppColors.inkSoft, height: 1.4),
          ),
        ],
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: 4,
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'shop'),
            child: const Text('3,300원에 30일간 누리기'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(ctx, 'ad'),
            child: const Text('광고 보고 부적 1개 받기'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == 'shop') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
  } else if (choice == 'ad') {
    await showRewardChoices(context, ref, preset: 'amulet');
  }
}
