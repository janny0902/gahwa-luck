import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/features/fortune/fortune_models.dart';

void main() {
  test('hard jargon followups are replaced with easy defaults', () {
    expect(
      displayFollowupQuestions('my_fortune', ['편재와 식신의 합이 재물 흐름에 미치는 영향은?']),
      ['오늘 조심할 일은?', '돈 흐름은 어때요?', '쉬는 게 나을까요?'],
    );
  });

  test('simple followups are kept and filled to three', () {
    expect(
      displayFollowupQuestions('family', ['누구랑 조심할까요?']),
      ['누구랑 조심할까요?', '오늘은 무슨 말을 할까요?', '집안 분위기는?'],
    );
  });

  test('object-shaped questions are parsed', () {
    expect(
      parseSuggestedQuestions([
        {'question': '돈 흐름은 어때요?'},
        '쉬는 게 나을까요?',
      ]),
      ['돈 흐름은 어때요?', '쉬는 게 나을까요?'],
    );
  });
}
