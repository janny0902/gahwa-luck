import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/manseryeok/four_pillars.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hanji_background.dart';
import '../ads/reward_ad_button.dart';
import '../profile/profile_models.dart';
import '../profile/profile_pickers.dart';
import '../profile/user_repository.dart';
import '../shop/paywall.dart';
import 'fortune_api.dart';
import 'fortune_models.dart';
import 'fortune_result_screen.dart';

PillarSet pillarsOfProfile(MyProfile profile) {
  return pillarsFor(
    date: ProfilePickers.parseBirth(profile.birthDate),
    isLunar: profile.isLunar,
    hour: hourFromLabel(profile.birthTime),
  );
}

PillarSet pillarsOfMember(Member member) {
  return pillarsFor(
    date: ProfilePickers.parseBirth(member.birthDate),
    isLunar: member.isLunar,
    hour: hourFromLabel(member.birthTime),
  );
}

Map<String, dynamic> personInput(Member member) => {
      'name': member.name,
      'hanja': member.hanja,
      'relation': member.relation,
      'gender': member.gender,
      'mbti': member.mbti,
      'pillars': pillarsOfMember(member).toJson(),
    };

Map<String, dynamic> baseFortuneInput(MyProfile profile) {
  final now = DateTime.now();
  return {
    'profile': profile.toJson(),
    'natal': pillarsOfProfile(profile).toJson(),
    'today': pillarsFor(date: now, isLunar: false, hour: now.hour).toJson(),
  };
}

bool _isOutOfAmulet(Object error) => error.toString().startsWith('부적이 없습니다');

/// 부적 확인 → 대기 화면 → 결과 화면. 부적이 없으면 결제 안내를 띄운다.
Future<void> runFortune(
  BuildContext context,
  WidgetRef ref, {
  required String category,
  required MyProfile profile,
  required Map<String, dynamic> input,
}) async {
  AppUser? user;
  try {
    user = await ref.read(appUserProvider.future);
  } catch (_) {}
  if (!context.mounted) return;
  if (user != null && user.amuletCount < 1) {
    await showAmuletPaywall(context, ref);
    return;
  }

  final task = ref.read(fortuneApiProvider).generate(
        category: category,
        input: input,
        fourPillars: pillarsOfProfile(profile).toJson(),
      );
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => FortuneLoadingScreen(task: task)),
  );
  FortuneRecord record;
  try {
    record = await task;
  } catch (error) {
    ref.invalidate(appUserProvider);
    if (!context.mounted) return;
    if (_isOutOfAmulet(error)) {
      await showAmuletPaywall(context, ref);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
    return;
  }
  ref.invalidate(appUserProvider);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => FortuneResultScreen(record: record)),
  );
}

class FortuneLoadingScreen extends StatefulWidget {
  const FortuneLoadingScreen({super.key, required this.task});

  final Future<FortuneRecord> task;

  @override
  State<FortuneLoadingScreen> createState() => _FortuneLoadingScreenState();
}

class _FortuneLoadingScreenState extends State<FortuneLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    widget.task.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HanjiBackground(
      child: Scaffold(
      appBar: AppBar(title: const Text('운세를 보는 중')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: RotationTransition(
              turns: _spin,
              child: Container(
                width: 72,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E27A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.crimson, width: 2),
                ),
                child: const Text(
                  '福',
                  style: TextStyle(fontSize: 36, color: AppColors.crimson, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '부적을 펼치는 동안 아래 안내를 보아도 됩니다.\n뒤로 가도 풀이는 이어서 만들어집니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          const NativeLoadingAd(),
        ],
      ),
      ),
    );
  }
}
