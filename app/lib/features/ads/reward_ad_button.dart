import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_theme.dart';
import '../profile/user_repository.dart';
import '../wallet/wallet_api.dart';

const _testReward = 'ca-app-pub-3940256099942544/5224354917';
const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
const _testNative = 'ca-app-pub-3940256099942544/2247696110';
const _releaseReward = 'ca-app-pub-3648414759201370/7470051588';
const _releaseBanner = 'ca-app-pub-3648414759201370/8702030759';
const _releaseNative = 'ca-app-pub-3648414759201370/8399989874';

String _adUnit(String envKey, String testId, String releaseId) {
  if (kDebugMode) return testId;
  final unit = dotenv.env[envKey]?.trim();
  if (unit == null || unit.isEmpty || unit.contains('3940256099942544')) {
    return releaseId;
  }
  return unit;
}

Future<void> showRewardChoices(BuildContext context, WidgetRef ref) async {
  final kind = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('광고를 보면 충전됩니다'),
              subtitle: Text(kDebugMode ? '오늘 10회까지. 테스트 광고입니다.' : '오늘 10회까지.'),
            ),
            ListTile(
              title: const Text('부적 1개'),
              onTap: () => Navigator.pop(ctx, 'amulet'),
            ),
            ListTile(
              title: const Text('쌀알 3개'),
              onTap: () => Navigator.pop(ctx, 'rice'),
            ),
          ],
        ),
      );
    },
  );
  if (kind == null || !context.mounted) return;
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('광고 충전은 폰 앱에서 됩니다')),
    );
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final adUnit = _adUnit('ADMOB_REWARD_ID', _testReward, _releaseReward);
  var earned = false;
  RewardedAd.load(
    adUnitId: adUnit,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (rewarded) {
        rewarded.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            if (!earned) {
              messenger.showSnackBar(
                const SnackBar(content: Text('광고를 끝까지 보면 충전됩니다')),
              );
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            messenger.showSnackBar(
              const SnackBar(content: Text('현재 불러올 수 있는 광고가 없습니다. 잠시 후 다시 시도해 주세요')),
            );
          },
        );
        rewarded.show(onUserEarnedReward: (ad, reward) async {
          earned = true;
          try {
            await ref.read(walletApiProvider).claimReward(kind);
            ref.invalidate(appUserProvider);
            messenger.showSnackBar(
              SnackBar(content: Text(kind == 'amulet' ? '부적 1개를 받았습니다' : '쌀알 3개를 받았습니다')),
            );
          } catch (error) {
            messenger.showSnackBar(SnackBar(content: Text('$error')));
          }
        });
      },
      onAdFailedToLoad: (error) {
        messenger.showSnackBar(
          const SnackBar(content: Text('현재 불러올 수 있는 광고가 없습니다. 잠시 후 다시 시도해 주세요')),
        );
      },
    ),
  );
}

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key, required this.visible});

  final bool visible;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  BannerAd? _ad;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible && !kIsWeb) _load();
  }

  @override
  void didUpdateWidget(HomeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && _ad == null && !kIsWeb) _load();
    if (!widget.visible) {
      _ad?.dispose();
      _ad = null;
      _ready = false;
    }
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: _adUnit('ADMOB_BANNER_ID', _testBanner, _releaseBanner),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!widget.visible || !_ready || ad == null) return const SizedBox.shrink();
    return ColoredBox(
      color: AppColors.beige,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

class NativeLoadingAd extends StatefulWidget {
  const NativeLoadingAd({super.key});

  @override
  State<NativeLoadingAd> createState() => _NativeLoadingAdState();
}

class _NativeLoadingAdState extends State<NativeLoadingAd> {
  NativeAd? _ad;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    final ad = NativeAd(
      adUnitId: _adUnit('ADMOB_NATIVE_ID', _testNative, _releaseNative),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.medium),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_ready || ad == null) return const SizedBox.shrink();
    return SizedBox(height: 280, child: AdWidget(ad: ad));
  }
}
