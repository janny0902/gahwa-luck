import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/features/profile/hanja_catalog.dart';

void main() {
  test('같은 자리 한글이면 고른 한자를 유지한다', () {
    final next = realignHanjaPicks(
      ['김', '민', '수'],
      ['金', '敏', '洙'],
      ['김', '민', '준'],
    );
    expect(next, ['金', '敏', '']);
  });

  test('저장한 한자 글자 수가 이름과 같으면 자리마다 복원한다', () {
    expect(picksFromSavedHanja(['김', '민'], '金敏'), ['金', '敏']);
    expect(picksFromSavedHanja(['김', '민'], '金'), ['', '']);
  });

  test('민 소리에는 민첩할 민이 있다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final catalog = await HanjaCatalog.load();
    final min = catalog.choicesFor('민');
    expect(min.map((c) => c.character), contains('敏'));
    expect(min.firstWhere((c) => c.character == '敏').meaning, contains('민첩'));
  });
}
