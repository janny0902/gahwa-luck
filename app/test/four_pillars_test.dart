import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/core/manseryeok/four_pillars.dart';
import 'package:saju/saju.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('2000-01-01 18시 서울 사주가 계산된다', () {
    tzdata.initializeTimeZones();
    final result = getFourPillars(
      tz.TZDateTime(tz.getLocation('Asia/Seoul'), 2000, 1, 1, 18, 0),
    );
    expect(result.pillars.year.korean, '기묘');
    expect(result.pillars.month.korean, '병자');
    expect(result.pillars.day.korean, '무오');
    expect(result.pillars.hour.korean, isNotEmpty);
  });

  test('시 라벨에서 시를 읽는다', () {
    expect(hourFromLabel('08시(진)'), 8);
    expect(hourFromLabel('모름'), isNull);
  });
}
