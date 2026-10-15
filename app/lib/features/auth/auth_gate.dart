import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/hanji_background.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import '../profile/onboarding_screen.dart';
import '../profile/user_repository.dart';
import '../wallet/wallet_api.dart';
import 'auth_providers.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const _GateMessage(child: CircularProgressIndicator()),
      error: (e, _) => _GateMessage(child: Text('인증 오류: $e')),
      data: (state) {
        final session = state.session ??
            ref.read(supabaseClientProvider).auth.currentSession;
        if (session == null) return const LoginScreen();
        return const _SignedInGate();
      },
    );
  }
}

/// 프로필을 확인하고, 매일 지급이 끝난 뒤에만 메인을 연다.
class _SignedInGate extends ConsumerStatefulWidget {
  const _SignedInGate();

  @override
  ConsumerState<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends ConsumerState<_SignedInGate> {
  var _grantStarted = false;
  var _homeReady = false;

  void _startGrantOnce() {
    if (_grantStarted || _homeReady) return;
    _grantStarted = true;
    () async {
      try {
        await ref.read(walletApiProvider).dailyGrant();
        ref.invalidate(appUserProvider);
        await ref.read(appUserProvider.future);
      } catch (_) {}
      if (mounted) setState(() => _homeReady = true);
    }();
  }

  @override
  Widget build(BuildContext context) {
    if (_homeReady) return const HomeShell();

    final userAsync = ref.watch(appUserProvider);
    return userAsync.when(
      loading: () => const _GateMessage(child: CircularProgressIndicator()),
      error: (e, _) => _GateMessage(child: Text('프로필 로드 실패: $e')),
      data: (appUser) {
        if (appUser == null) return const LoginScreen();
        if (!appUser.myProfile.isComplete) {
          return OnboardingScreen(initial: appUser.myProfile);
        }
        _startGrantOnce();
        return const _GateMessage(child: CircularProgressIndicator());
      },
    );
  }
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HanjiBackground(
      child: Scaffold(body: Center(child: child)),
    );
  }
}
