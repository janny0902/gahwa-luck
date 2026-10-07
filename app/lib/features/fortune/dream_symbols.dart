import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DreamNode {
  const DreamNode(this.label, [this.children = const []]);
  final String label;
  final List<DreamNode> children;
}

/// 자주 꾸는 재료를 먼저 보여 준다.
const frequentDreamSymbols = [
  '물', '불', '뱀', '돼지', '돈', '이빨', '조상', '아기', '금', '똥', '용', '호랑이',
];

const dreamSymbolTree = <DreamNode>[
  DreamNode('동물', [
    DreamNode('뱀', [DreamNode('큰 뱀'), DreamNode('흰 뱀'), DreamNode('구렁이'), DreamNode('뱀에 물림')]),
    DreamNode('용', [DreamNode('하늘로 오르는 용'), DreamNode('여의주'), DreamNode('용과 이야기')]),
    DreamNode('돼지', [DreamNode('새끼 돼지'), DreamNode('돼지 떼'), DreamNode('집에 들어온 돼지')]),
    DreamNode('호랑이', [DreamNode('나를 쫓는 호랑이'), DreamNode('순한 호랑이'), DreamNode('새끼 호랑이')]),
    DreamNode('물고기', [DreamNode('잉어'), DreamNode('금붕어'), DreamNode('물고기 잡기')]),
    DreamNode('새', [DreamNode('봉황'), DreamNode('까치'), DreamNode('까마귀')]),
    DreamNode('개'),
    DreamNode('고양이'),
    DreamNode('소'),
  ]),
  DreamNode('과일·음식', [
    DreamNode('사과'),
    DreamNode('딸기'),
    DreamNode('포도'),
    DreamNode('복숭아'),
    DreamNode('감'),
    DreamNode('밤'),
    DreamNode('밥·쌀'),
    DreamNode('고기'),
  ]),
  DreamNode('물건·보석', [
    DreamNode('금', [DreamNode('금반지'), DreamNode('금덩이'), DreamNode('금목걸이')]),
    DreamNode('돈', [DreamNode('지폐'), DreamNode('동전'), DreamNode('돈 줍기'), DreamNode('돈 잃기')]),
    DreamNode('진주'),
    DreamNode('보석'),
    DreamNode('신발'),
    DreamNode('거울'),
    DreamNode('열쇠'),
  ]),
  DreamNode('자연', [
    DreamNode('물', [DreamNode('맑은 물'), DreamNode('흙탕물'), DreamNode('홍수'), DreamNode('물에 빠짐')]),
    DreamNode('불', [DreamNode('집에 난 불'), DreamNode('큰불'), DreamNode('촛불')]),
    DreamNode('바다'),
    DreamNode('산'),
    DreamNode('해'),
    DreamNode('달'),
    DreamNode('별'),
    DreamNode('비'),
    DreamNode('눈'),
    DreamNode('꽃'),
  ]),
  DreamNode('사람', [
    DreamNode('아기', [DreamNode('아기를 안음'), DreamNode('아기가 웃음'), DreamNode('아기를 낳음')]),
    DreamNode('조상', [DreamNode('조상이 웃음'), DreamNode('조상이 말을 걺'), DreamNode('조상이 화냄')]),
    DreamNode('돌아가신 분'),
    DreamNode('유명인'),
    DreamNode('옛 연인'),
    DreamNode('낯선 사람'),
  ]),
  DreamNode('몸', [
    DreamNode('이빨', [DreamNode('이가 빠짐'), DreamNode('이가 흔들림'), DreamNode('새 이가 남')]),
    DreamNode('피'),
    DreamNode('머리카락'),
    DreamNode('임신'),
    DreamNode('똥'),
  ]),
];

/// 재료 고르기: 자주 나오는 것 → 분류 → 항목 → 세부. 끝까지 없으면 직접 적는다.
class DreamSymbolPicker extends StatefulWidget {
  const DreamSymbolPicker({super.key, required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<DreamSymbolPicker> createState() => _DreamSymbolPickerState();
}

class _DreamSymbolPickerState extends State<DreamSymbolPicker> {
  final _path = <DreamNode>[];
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String label) {
    final next = {...widget.selected};
    if (!next.remove(label)) next.add(label);
    widget.onChanged(next);
  }

  void _addCustom() {
    final tags = _custom.text
        .split(RegExp(r'[,#\s]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tags.isEmpty) return;
    widget.onChanged({...widget.selected, ...tags});
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final level = _path.isEmpty ? dreamSymbolTree : _path.last.children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('꿈에 나온 것', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final symbol in frequentDreamSymbols)
              FilterChip(
                label: Text(symbol),
                selected: widget.selected.contains(symbol),
                onSelected: (_) => _toggle(symbol),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _path.isEmpty ? '없으면 분류에서 찾기' : _path.map((n) => n.label).join(' › '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (_path.isNotEmpty)
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
                onPressed: () => setState(_path.removeLast),
                child: const Text('뒤로'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final node in level)
              if (node.children.isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.chevron_right, size: 18),
                  label: Text(node.label),
                  onPressed: () {
                    setState(() => _path.add(node));
                    if (_path.length > 1) _toggleIfAbsent(node.label);
                  },
                )
              else
                FilterChip(
                  label: Text(node.label),
                  selected: widget.selected.contains(node.label),
                  onSelected: (_) => _toggle(node.label),
                ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custom,
                decoration: const InputDecoration(
                  labelText: '찾는 게 없으면 직접 적기 (예: 무지개)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: OutlinedButton(onPressed: _addCustom, child: const Text('추가')),
            ),
          ],
        ),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.selected)
                InputChip(
                  label: Text('#$tag', style: const TextStyle(color: AppColors.crimson)),
                  onDeleted: () => _toggle(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _toggleIfAbsent(String label) {
    if (!widget.selected.contains(label)) _toggle(label);
  }
}
