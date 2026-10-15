import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/features/auth/login_screen.dart';
import 'package:gahwa_luck/features/profile/member_repository.dart';
import 'package:gahwa_luck/features/profile/members_screen.dart';

void main() {
  testWidgets('Login screen shows brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('가화만사성'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
  });

  testWidgets('Members screen empty copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: MembersScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('등록한 가족·지인이 없습니다.'), findsOneWidget);
  });
}
