import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/legal_links.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/currency_badge.dart';
import '../../core/widgets/hanji_background.dart';
import '../ads/reward_ad_button.dart';
import '../auth/auth_providers.dart';
import '../fortune/fortune_models.dart';
import '../fortune/fortune_result_screen.dart';
import '../fortune/fortune_runner.dart';
import '../fortune/fortune_wizard_screen.dart';
import '../profile/members_screen.dart';
import '../profile/profile_models.dart';
import '../profile/onboarding_screen.dart';
import '../profile/user_repository.dart';
import '../shop/shop_screen.dart';
import '../wallet/wallet_api.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.preview = false});

  /// 웹 디자인 확인용. 로그인 없이 샘플 수량을 보여 준다.
  final bool preview;

  static const _menus = <_MenuItem>[
    _MenuItem('내 운세', Icons.explore_outlined),
    _MenuItem('가족궁합', Icons.home_outlined),
    _MenuItem('동료궁합', Icons.groups_outlined),
    _MenuItem('날 받기', Icons.event_available_outlined),
    _MenuItem('이름받기', Icons.badge_outlined),
    _MenuItem('애견·차 이름', Icons.pets),
    _MenuItem('꿈해몽', Icons.nightlight_outlined),
  ];

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _quickBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.preview) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(walletApiProvider).dailyGrant();
        ref.invalidate(appUserProvider);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final appUser = preview ? null : ref.watch(appUserProvider).asData?.value;
    final amulet = preview ? 3 : appUser?.amuletCount;
    final rice = preview ? 12 : appUser?.riceCount;
    final name = preview ? '미리보기' : (appUser?.myProfile.name ?? '');
    final passDays = _passDaysLeft(appUser);

    return HanjiBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('가화만사성'),
        actions: [
          IconButton(
            tooltip: '설정',
            onPressed: () => _openSettings(context, ref),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '가화만사성' : '$name 님',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '우리집 궁합 · 운세 · 사주',
                    style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CurrencyBadge(kind: CurrencyKind.amulet, count: amulet),
                      CurrencyBadge(kind: CurrencyKind.rice, count: rice),
                      if (passDays != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '패스 D-$passDays',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passDays != null
                        ? '매일 00시에 부적 5개, 쌀알 15개까지 채워 드립니다.'
                        : '매일 00시에 부적 1개, 쌀알 3개까지 채워 드립니다.',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            if (!preview)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _quickBusy ? null : () => _quickFortune(appUser),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 30),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '오늘의 운세 · 복채 내기',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '부적 1개 · 입력 없이 내 프로필로 바로',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: HomeShell._menus.length,
                itemBuilder: (context, index) {
                  final item = HomeShell._menus[index];
                  return Material(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: preview
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FortuneWizardScreen(
                                    category: FortuneCategory.all[index],
                                  ),
                                ),
                              );
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 36, color: AppColors.crimson),
                            const SizedBox(height: 10),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '본 서비스의 운세 결과는 오락 목적이며, 전문적인 의료·법률·금융 결정을 대체할 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.35),
              ),
            ),
            if (!preview)
              HomeBanner(visible: !_passOn(appUser)),
          ],
        ),
      ),
    ),
    );
  }

  bool _passOn(AppUser? user) {
    if (user == null || !user.passActive) return false;
    final expired = user.passExpiredAt;
    return expired == null || expired.isAfter(DateTime.now());
  }

  int? _passDaysLeft(AppUser? user) {
    if (!_passOn(user)) return null;
    final expired = user!.passExpiredAt;
    if (expired == null) return null;
    final hours = expired.difference(DateTime.now()).inHours;
    return (hours / 24).ceil();
  }

  Future<void> _quickFortune(AppUser? user) async {
    final profile = user?.myProfile;
    if (profile == null || !profile.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필의 이름, 성별, 생년월일을 먼저 저장해 주세요')),
      );
      return;
    }
    setState(() => _quickBusy = true);
    await runFortune(
      context,
      ref,
      category: 'my_fortune',
      profile: profile,
      input: {
        ...baseFortuneInput(profile),
        'period': '오늘',
        'theme': '전체',
        'quick': true,
      },
    );
    if (mounted) setState(() => _quickBusy = false);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('계정을 탈퇴할까요?'),
          content: const Text(
            '프로필, 가족·지인, 운세 기록이 삭제됩니다. 삭제한 내용은 되돌릴 수 없습니다.',
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('탈퇴', style: TextStyle(color: AppColors.crimson)),
            ),
          ],
        );
      },
    );
    if (approved != true || !context.mounted) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client.functions.invoke(
        'delete-account',
        body: {'confirm': true},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      await client.auth.signOut();
    } on FunctionException catch (error) {
      if (!context.mounted) return;
      final details = error.details;
      final message = details is Map && details['error'] != null
          ? details['error'].toString()
          : '탈퇴를 끝내지 못했습니다. 잠시 후 다시 시도해 주세요';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    final appUser = ref.read(appUserProvider).asData?.value;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('프로필 수정'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OnboardingScreen(
                        initial: appUser?.myProfile,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('가족·지인 관리'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MembersScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('지난 운세'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FortuneHistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('상점'),
                subtitle: const Text('부적, 쌀알, 30일 패스'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShopScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.ondemand_video_outlined),
                title: const Text('광고 보고 충전'),
                subtitle: const Text('부적 1개 또는 쌀알 3개'),
                onTap: () {
                  Navigator.pop(ctx);
                  showRewardChoices(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('오락 목적 안내'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      content: const Text(entertainmentDisclaimer),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                onTap: () {
                  Navigator.pop(ctx);
                  openLegalPage(context, privacyPolicyUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('계정 삭제 안내'),
                subtitle: const Text('앱을 지운 뒤 요청하는 방법'),
                onTap: () {
                  Navigator.pop(ctx);
                  openLegalPage(context, accountDeletionUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(supabaseClientProvider).auth.signOut();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_off_outlined, color: AppColors.crimson),
                title: const Text('계정 탈퇴', style: TextStyle(color: AppColors.crimson)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref);
                },
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
