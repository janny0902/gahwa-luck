import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import '../profile/onboarding_screen.dart';
import '../profile/user_repository.dart';
import 'auth_providers.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('인증 오류: $e')),
      ),
      data: (state) {
        final session = state.session ??
            ref.read(supabaseClientProvider).auth.currentSession;
        if (session == null) return const LoginScreen();

        final userAsync = ref.watch(appUserProvider);
        return userAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text('프로필 로드 실패: $e')),
          ),
          data: (appUser) {
            if (appUser == null) return const LoginScreen();
            if (!appUser.myProfile.isComplete) {
              return OnboardingScreen(initial: appUser.myProfile);
            }
            return const HomeShell();
          },
        );
      },
    );
  }
}
