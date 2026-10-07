import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';
import 'profile_models.dart';

final appUserProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final row = await client.from('users').select().eq('id', user.id).maybeSingle();
  if (row == null) {
    // 트리거 지연 대비: 최소 행 upsert
    await client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'provider': user.appMetadata['provider'] ?? 'oauth',
    });
    final created =
        await client.from('users').select().eq('id', user.id).single();
    return AppUser.fromJson(created);
  }
  return AppUser.fromJson(row);
});

class UserRepository {
  UserRepository(this._client);
  final SupabaseClient _client;

  Future<void> saveMyProfile(String userId, MyProfile profile) async {
    await _client.from('users').update({
      'my_profile': profile.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(supabaseClientProvider));
});
