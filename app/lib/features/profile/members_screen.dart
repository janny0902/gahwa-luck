import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hanji_background.dart';
import 'member_edit_screen.dart';
import 'member_repository.dart';
import 'profile_models.dart';
import 'profile_pickers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  List<Member> _items = [];
  var _usingLocal = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(membersProvider, (prev, next) {
      next.whenData((members) {
        if (!mounted) return;
        setState(() {
          _items = List.of(members);
          _usingLocal = true;
        });
      });
    });

    final async = ref.watch(membersProvider);

    return HanjiBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('가족·지인'),
          actions: [
            IconButton(
              tooltip: '추가',
              onPressed: () => _openEdit(),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ],
        ),
        body: async.when(
          loading: () => _usingLocal
              ? _listBody(_items)
              : const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '목록을 불러오지 못했습니다.\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (members) {
            final items = _usingLocal ? _items : members;
            return _listBody(items);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEdit(),
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('추가'),
        ),
      ),
    );
  }

  Widget _listBody(List<Member> items) {
    if (items.isEmpty) {
      return _EmptyState(onAdd: () => _openEdit());
    }
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            '가까운 순서로 길게 눌러 옮기세요. 궁합에서 이 목록을 불러옵니다.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) => _onReorder(items, oldIndex, newIndex),
            buildDefaultDragHandles: true,
            itemBuilder: (context, index) {
              final m = items[index];
              return Card(
                key: ValueKey(m.id),
                color: Colors.white.withValues(alpha: 0.72),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  title: Text(
                    m.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(_subtitle(m)),
                  onTap: () => _openEdit(existing: m),
                  trailing: IconButton(
                    tooltip: '삭제',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(m),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _subtitle(Member m) {
    final bits = <String>[
      ProfilePickers.kindLabel(m.kind),
      if (m.relation.isNotEmpty) m.relation,
      if (m.birthDate.isNotEmpty) m.birthDate,
    ];
    return bits.join(' · ');
  }

  Future<void> _openEdit({Member? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberEditScreen(existing: existing),
      ),
    );
  }

  void _onReorder(List<Member> source, int oldIndex, int newIndex) {
    setState(() {
      final current = List.of(source);
      var dest = newIndex;
      if (dest > oldIndex) dest -= 1;
      final item = current.removeAt(oldIndex);
      current.insert(dest, item);
      _items = current;
      _usingLocal = true;
    });
    unawaited(_persistOrder());
  }

  Future<void> _persistOrder() async {
    try {
      await ref.read(memberRepositoryProvider).reorder(_items);
      ref.invalidate(membersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('순서 저장 실패: $e')),
      );
      ref.invalidate(membersProvider);
    }
  }

  Future<void> _confirmDelete(Member member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: Text('${member.name} 님을 목록에서 빼면 다시 입력해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(memberRepositoryProvider).delete(member.id);
      setState(() {
        final current = _usingLocal
            ? _items
            : List<Member>.of(
                ref.read(membersProvider).asData?.value ?? const <Member>[],
              );
        _items = current.where((e) => e.id != member.id).toList();
        _usingLocal = true;
      });
      ref.invalidate(membersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 48, color: AppColors.crimson),
            const SizedBox(height: 16),
            const Text(
              '등록한 가족·지인이 없습니다.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '궁합에 쓸 사람을 추가해 주세요.',
              style: TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAdd, child: const Text('추가하기')),
          ],
        ),
      ),
    );
  }
}
