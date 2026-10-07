import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';
import 'profile_models.dart';

class MemberRepository {
  MemberRepository(this._client);
  final SupabaseClient _client;

  Future<List<Member>> list(String userId) async {
    final rows = await _client
        .from('members')
        .select()
        .eq('user_id', userId)
        .order('priority')
        .order('created_at');
    return [
      for (final row in rows) Member.fromJson(row),
    ];
  }

  Future<void> add(String userId, Member member) async {
    final existing = await list(userId);
    await _client.from('members').insert(
      member.copyWith(priority: existing.length).toInsertJson(userId),
    );
  }

  Future<void> update(Member member) async {
    await _client.from('members').update(member.toUpdateJson()).eq('id', member.id);
  }

  Future<void> delete(String id) async {
    await _client.from('members').delete().eq('id', id);
  }

  Future<void> reorder(List<Member> ordered) async {
    await Future.wait([
      for (var i = 0; i < ordered.length; i++)
        _client.from('members').update({'priority': i}).eq('id', ordered[i].id),
    ]);
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(supabaseClientProvider));
});

final membersProvider = FutureProvider.autoDispose<List<Member>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(memberRepositoryProvider).list(user.id);
});
