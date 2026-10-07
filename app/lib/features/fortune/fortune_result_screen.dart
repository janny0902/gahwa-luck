import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/legal_links.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glossary_text.dart';
import '../profile/user_repository.dart';
import 'fortune_api.dart';
import 'fortune_models.dart';

class FortuneResultScreen extends ConsumerStatefulWidget {
  const FortuneResultScreen({super.key, required this.record});

  final FortuneRecord record;

  @override
  ConsumerState<FortuneResultScreen> createState() => _FortuneResultScreenState();
}

class _FortuneResultScreenState extends ConsumerState<FortuneResultScreen> {
  late FortuneRecord _record;
  final _question = TextEditingController();
  final _scroll = ScrollController();
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await ref.read(fortuneApiProvider).chats(_record.id);
      if (!mounted) return;
      setState(() => _record = _record.copyWith(chats: chats));
    } catch (_) {}
  }

  @override
  void dispose() {
    _question.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String text) async {
    final question = text.trim();
    if (question.length < 2 || _asking) return;
    if (_record.remainingRiceTurns < 1) {
      _toast('이 운세의 추가 질문 5회를 모두 썼습니다');
      return;
    }
    setState(() => _asking = true);
    try {
      final answer = await ref.read(fortuneApiProvider).ask(
            fortuneId: _record.id,
            question: question,
            category: _record.category,
          );
      if (!mounted) return;
      setState(() {
        _record = _record.copyWith(
          remainingRiceTurns: answer.remaining,
          suggestedQuestions: answer.questions,
          chats: [..._record.chats, answer.chat],
        );
        _question.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      });
      ref.invalidate(appUserProvider);
    } on FortuneException catch (error) {
      _toast(error.message);
    } catch (error) {
      _toast('$error');
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _chatCard(FortuneChat chat) {
    final answer = chat.answer.trim();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q. ${chat.question}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (answer.isEmpty)
            const Text(
              '답을 불러오지 못했습니다. 다른 질문을 눌러 보세요.',
              style: TextStyle(fontSize: 16, height: 1.45),
            )
          else
            GlossaryText(answer, style: const TextStyle(fontSize: 16, height: 1.45)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = FortuneCategory.byId(_record.category);
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _record.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _record.pillarLabel,
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          GlossaryText(_record.summary, style: const TextStyle(fontSize: 16, height: 1.45)),
          for (final section in _record.sections) ...[
            const SizedBox(height: 18),
            Text(
              section.heading,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.crimson),
            ),
            const SizedBox(height: 6),
            GlossaryText(section.body, style: const TextStyle(fontSize: 16, height: 1.45)),
          ],
          const SizedBox(height: 24),
          Text(
            '추가 질문 · 쌀알 1개 · 남은 ${_record.remainingRiceTurns}회',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            '쉬운 질문을 눌러 답을 받아 보세요',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final question in displayFollowupQuestions(
                _record.category,
                _record.suggestedQuestions,
              ))
                ActionChip(
                  label: Text(question),
                  onPressed: _asking ? null : () => _ask(question),
                ),
            ],
          ),
          if (_record.chats.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final chat in _record.chats) _chatCard(chat),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _question,
            decoration: const InputDecoration(
              labelText: '직접 질문',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _asking ? null : () => _ask(_question.text),
            child: _asking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('쌀알로 물어보기'),
          ),
          const SizedBox(height: 24),
          const Text(
            '밑줄 친 말을 누르면 뜻을 볼 수 있습니다.\n$entertainmentDisclaimer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class FortuneHistoryScreen extends ConsumerWidget {
  const FortuneHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('지난 운세')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('아직 본 운세가 없습니다.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final when = item.createdAt;
              final date = when == null
                  ? ''
                  : '${when.year}.${when.month}.${when.day}';
              return ListTile(
                title: Text(item.title),
                subtitle: Text('${FortuneCategory.byId(item.category).label} · $date'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FortuneResultScreen(record: item),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

final _historyProvider = FutureProvider.autoDispose<List<FortuneRecord>>((ref) {
  return ref.watch(fortuneApiProvider).history();
});
