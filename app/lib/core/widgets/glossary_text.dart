import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const glossaryTerms = <String, String>{
  '사주': '태어난 해·달·날·시를 네 기둥으로 적은 것입니다. 타고난 기운을 볼 때 씁니다.',
  '팔자': '사주 네 기둥의 여덟 글자를 말합니다.',
  '오행': '나무, 불, 흙, 쇠, 물 다섯 기운입니다. 서로 돕거나 누르며 균형을 이룹니다.',
  '음양': '밝고 움직이는 기운(양)과 차분하고 모으는 기운(음)입니다.',
  '천간': '갑, 을, 병, 정처럼 하늘의 기운을 나타내는 열 글자입니다.',
  '지지': '자, 축, 인, 묘처럼 땅의 기운을 나타내는 열두 글자입니다. 띠와 같습니다.',
  '간지': '천간과 지지를 짝지은 이름입니다. 갑자, 을축처럼 씁니다.',
  '일진': '그날그날의 간지입니다. 하루의 기운을 볼 때 씁니다.',
  '일주': '태어난 날의 기둥입니다. 나 자신을 가장 잘 보여 준다고 봅니다.',
  '일간': '태어난 날 기둥의 윗글자입니다. 사주에서 나를 뜻합니다.',
  '대운': '10년마다 바뀌는 큰 흐름입니다.',
  '세운': '그해에 들어오는 기운입니다.',
  '용신': '사주의 균형을 맞추는 데 가장 도움이 되는 기운입니다.',
  '희신': '용신을 돕는 기운입니다.',
  '십신': '나와 다른 글자의 관계를 열 가지로 나눈 이름입니다.',
  '신살': '특정 글자 조합에 붙는 길하거나 조심할 표시입니다.',
  '역마': '움직임과 이동이 많은 기운입니다. 여행, 이사, 출장과 잘 맞습니다.',
  '도화': '사람을 끄는 매력의 기운입니다.',
  '천을귀인': '어려울 때 돕는 사람이 나타난다고 보는 좋은 기운입니다.',
  '삼재': '9년마다 3년씩 조심하라고 보는 시기입니다.',
  '상충': '두 기운이 부딪히는 관계입니다. 마찰이나 변화가 생기기 쉽다고 봅니다.',
  '육합': '두 지지가 잘 어울려 하나로 묶이는 관계입니다.',
  '삼합': '세 지지가 모여 한 기운을 크게 만드는 관계입니다.',
  '길일': '일을 시작하기 좋다고 보는 날입니다.',
  '황도길일': '전통 달력에서 특히 좋다고 꼽는 날입니다.',
  '손 없는 날': '귀신이 없다고 보아 이사나 큰일에 좋다고 여기는 날입니다. 음력 9, 10, 19, 20, 29, 30일입니다.',
  '택일': '좋은 날을 골라 정하는 일입니다.',
  '자원오행': '한자 글자 자체가 가진 오행입니다. 이름 지을 때 씁니다.',
  '발음오행': '이름 소리의 첫 자음이 가진 오행입니다.',
  '인명용 한자': '대법원이 이름에 쓸 수 있다고 정한 한자입니다.',
  '태몽': '아이가 생길 무렵 꾸는 꿈입니다.',
  '길몽': '좋은 일을 알린다고 보는 꿈입니다.',
  '흉몽': '조심하라고 알린다고 보는 꿈입니다. 대개 마음을 살피라는 뜻으로 풉니다.',
  '방위': '동, 서, 남, 북 같은 방향입니다.',
  '음력': '달의 모양을 기준으로 한 달력입니다.',
  '절기': '한 해를 24개로 나눈 계절 마디입니다. 사주의 달은 절기로 바뀝니다.',
};

final _termPattern = RegExp(
  (glossaryTerms.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
      .map(RegExp.escape)
      .join('|'),
);

/// 결과 본문의 어려운 말에 밑줄을 긋고, 누르면 뜻을 보여 준다.
class GlossaryText extends StatefulWidget {
  const GlossaryText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _showMeaning(String term) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(term, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(glossaryTerms[term] ?? '', style: const TextStyle(fontSize: 17, height: 1.5)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final text = widget.text;
    final spans = <InlineSpan>[];
    final seen = <String>{};
    var cursor = 0;
    for (final match in _termPattern.allMatches(text)) {
      final term = match.group(0)!;
      if (!seen.add(term)) continue;
      if (match.start > cursor) spans.add(TextSpan(text: text.substring(cursor, match.start)));
      final recognizer = TapGestureRecognizer()..onTap = () => _showMeaning(term);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: term,
        recognizer: recognizer,
        style: const TextStyle(
          decoration: TextDecoration.underline,
          decorationColor: AppColors.crimson,
          decorationStyle: TextDecorationStyle.dotted,
        ),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
