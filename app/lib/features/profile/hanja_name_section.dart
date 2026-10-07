import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'hanja_catalog.dart';

class HanjaNameSection extends StatefulWidget {
  const HanjaNameSection({
    super.key,
    required this.name,
    required this.initialHanja,
    required this.onChanged,
  });

  final String name;
  final String initialHanja;
  final void Function(String hanja, bool skipped) onChanged;

  @override
  State<HanjaNameSection> createState() => _HanjaNameSectionState();
}

class _HanjaNameSectionState extends State<HanjaNameSection> {
  late List<String> _syllables;
  late List<String> _picks;
  bool _skip = false;
  HanjaCatalog? _catalog;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _syllables = hangulSyllables(widget.name);
    _picks = picksFromSavedHanja(_syllables, widget.initialHanja);
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await HanjaCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = catalog);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  @override
  void didUpdateWidget(HanjaNameSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name == widget.name) return;
    final nextSyllables = hangulSyllables(widget.name);
    setState(() {
      _picks = realignHanjaPicks(_syllables, _picks, nextSyllables);
      _syllables = nextSyllables;
    });
    _emit();
  }

  void _emit() {
    if (_skip) {
      widget.onChanged('', true);
      return;
    }
    widget.onChanged(_picks.where((c) => c.isNotEmpty).join(), false);
  }

  Future<void> _openPicker(int index) async {
    final catalog = _catalog;
    final syllable = _syllables[index];
    final choices = catalog?.choicesFor(syllable) ?? const <HanjaChoice>[];
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.beige,
      builder: (context) => _HanjaSheet(
        syllable: syllable,
        choices: choices,
        selected: _picks[index],
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _picks[index] = picked);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _skip,
          activeColor: AppColors.crimson,
          title: const Text('한자를 모르겠어요'),
          onChanged: (v) {
            setState(() => _skip = v ?? false);
            _emit();
          },
        ),
        if (!_skip) ...[
          if (_loadError != null)
            const Text(
              '한자 목록을 불러오지 못했습니다.',
              style: TextStyle(color: AppColors.crimson),
            )
          else if (_syllables.isEmpty)
            const Text(
              '한글 이름을 입력하면 소리마다 한자를 고를 수 있습니다.',
              style: TextStyle(color: AppColors.inkSoft),
            )
          else
            for (var i = 0; i < _syllables.length; i++)
              _SyllableTile(
                syllable: _syllables[i],
                pick: _picks[i],
                meaning: _meaningOf(i),
                onTap: () => _openPicker(i),
              ),
        ],
      ],
    );
  }

  String _meaningOf(int index) {
    final pick = _picks[index];
    if (pick.isEmpty) return '';
    final choices = _catalog?.choicesFor(_syllables[index]) ?? const [];
    for (final choice in choices) {
      if (choice.character == pick) return choice.meaning;
    }
    return '';
  }
}

class _SyllableTile extends StatelessWidget {
  const _SyllableTile({
    required this.syllable,
    required this.pick,
    required this.meaning,
    required this.onTap,
  });

  final String syllable;
  final String pick;
  final String meaning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = pick.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Text(
                    syllable,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chosen ? pick : '한자 선택',
                          style: TextStyle(
                            fontSize: chosen ? 22 : 16,
                            fontWeight: FontWeight.w700,
                            color: chosen ? AppColors.crimson : AppColors.inkSoft,
                          ),
                        ),
                        if (meaning.isNotEmpty)
                          Text(
                            meaning,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HanjaSheet extends StatefulWidget {
  const _HanjaSheet({
    required this.syllable,
    required this.choices,
    required this.selected,
  });

  final String syllable;
  final List<HanjaChoice> choices;
  final String selected;

  @override
  State<_HanjaSheet> createState() => _HanjaSheetState();
}

class _HanjaSheetState extends State<_HanjaSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final shown = [
      for (final choice in widget.choices)
        if (query.isEmpty ||
            choice.character.contains(query) ||
            choice.meaning.contains(query))
          choice,
    ];
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.beigeDeep,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${widget.syllable}에 쓸 한자',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: '뜻이나 한자로 찾기',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? const Center(
                      child: Text(
                        '이 소리로 고를 수 있는 인명용 한자가 없습니다.',
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final choice = shown[index];
                        final selected = choice.character == widget.selected;
                        return ListTile(
                          minTileHeight: 56,
                          leading: Text(
                            choice.character,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          title: Text(choice.meaning),
                          trailing: selected
                              ? const Icon(Icons.check, color: AppColors.crimson)
                              : null,
                          onTap: () => Navigator.pop(context, choice.character),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
