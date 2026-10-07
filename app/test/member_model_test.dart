import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/features/profile/profile_models.dart';
import 'package:gahwa_luck/features/profile/profile_pickers.dart';

void main() {
  test('Member.fromJson maps snake_case columns', () {
    final member = Member.fromJson({
      'id': 'a',
      'user_id': 'u',
      'name': '엄마',
      'hanja': '母',
      'kind': 'family',
      'priority': 1,
      'birth_date': '1960-05-01',
      'birth_time': '08시(진)',
      'is_lunar': true,
      'relation': '어머니',
      'gender': '여성',
      'mbti': 'ISFJ',
    });
    expect(member.name, '엄마');
    expect(member.userId, 'u');
    expect(member.birthDate, '1960-05-01');
    expect(member.isLunar, true);
    expect(member.relation, '어머니');
    expect(member.toInsertJson('u')['birth_date'], '1960-05-01');
  });

  test('ProfilePickers restores known birth hour', () {
    expect(ProfilePickers.hourLabelOf('08시(진)'), '08시(진)');
    expect(ProfilePickers.hourLabelOf(''), '모름');
    expect(ProfilePickers.formatBirth(DateTime(1990, 1, 9)), '1990-01-09');
  });
}
