import 'package:klc/klc.dart';
import 'package:saju/saju.dart';
import 'package:timezone/timezone.dart' as tz;

class PillarSet {
  const PillarSet({
    required this.year,
    required this.month,
    required this.day,
    this.hour,
  });

  final String year;
  final String month;
  final String day;
  final String? hour;

  String get label {
    final clock = hour == null ? '시 모름' : hour!;
    return '$year년 $month월 $day일 $clock시';
  }

  Map<String, String?> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
      };
}

/// 음력이면 한국천문연구원 기준으로 양력으로 바꾼 뒤 사주를 계산한다.
PillarSet pillarsFor({
  required DateTime date,
  required bool isLunar,
  int? hour,
  int minute = 0,
}) {
  final solar = isLunar ? _solarFromKoreanLunar(date) : date;
  final clockHour = hour ?? 12;
  final location = tz.getLocation('Asia/Seoul');
  final birth = tz.TZDateTime(
    location,
    solar.year,
    solar.month,
    solar.day,
    clockHour,
    minute,
  );
  final result = getFourPillars(birth);
  return PillarSet(
    year: result.pillars.year.korean,
    month: result.pillars.month.korean,
    day: result.pillars.day.korean,
    hour: hour == null ? null : result.pillars.hour.korean,
  );
}

DateTime _solarFromKoreanLunar(DateTime lunar) {
  setLunarDate(lunar.year, lunar.month, lunar.day, false);
  final iso = getSolarIsoFormat();
  final parts = iso.split('-');
  if (parts.length != 3) return lunar;
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

int? hourFromLabel(String label) {
  if (label.isEmpty || label == '모름') return null;
  final match = RegExp(r'^(\d{1,2})시').firstMatch(label);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}
