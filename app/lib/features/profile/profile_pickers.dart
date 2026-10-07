/// 사주 프로필·멤버 입력용 선택지. 직접 입력은 최후 수단.
abstract final class ProfilePickers {
  static const genders = ['남성', '여성', '기타'];

  static const mbtis = [
    '모름',
    'ISTJ',
    'ISFJ',
    'INFJ',
    'INTJ',
    'ISTP',
    'ISFP',
    'INFP',
    'INTP',
    'ESTP',
    'ESFP',
    'ENFP',
    'ENTP',
    'ESTJ',
    'ESFJ',
    'ENFJ',
    'ENTJ',
  ];

  static const hours = [
    '모름',
    '00시(자)',
    '01시',
    '02시(축)',
    '03시',
    '04시(인)',
    '05시',
    '06시(묘)',
    '07시',
    '08시(진)',
    '09시',
    '10시(사)',
    '11시',
    '12시(오)',
    '13시',
    '14시(미)',
    '15시',
    '16시(신)',
    '17시',
    '18시(유)',
    '19시',
    '20시(술)',
    '21시',
    '22시(해)',
    '23시',
  ];

  static const kinds = <(String, String)>[
    ('family', '가족'),
    ('colleague', '동료'),
    ('other', '기타'),
  ];

  static const relations = [
    '배우자',
    '아버지',
    '어머니',
    '아들',
    '딸',
    '형제',
    '자매',
    '조부모',
    '손주',
    '친구',
    '동료',
    '상사',
    '기타',
  ];

  static String kindLabel(String kind) {
    for (final item in kinds) {
      if (item.$1 == kind) return item.$2;
    }
    return '기타';
  }

  static String hourLabelOf(String birthTime) {
    if (birthTime.isEmpty) return '모름';
    if (hours.contains(birthTime)) return birthTime;
    return '모름';
  }

  static DateTime parseBirth(String birthDate, {DateTime? fallback}) {
    final parts = birthDate.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return fallback ?? DateTime(1990, 1, 1);
  }

  static String formatBirth(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
