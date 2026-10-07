class MyProfile {
  const MyProfile({
    this.name = '',
    this.hanja = '',
    this.gender = '',
    this.birthDate = '',
    this.birthTime = '',
    this.isLunar = false,
    this.mbti = '',
  });

  final String name;
  final String hanja;
  final String gender;
  final String birthDate; // yyyy-MM-dd
  final String birthTime; // HH:mm or empty
  final bool isLunar;
  final String mbti;

  bool get isComplete =>
      name.trim().isNotEmpty &&
      gender.trim().isNotEmpty &&
      birthDate.trim().isNotEmpty;

  factory MyProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MyProfile();
    return MyProfile(
      name: (json['name'] as String?) ?? '',
      hanja: (json['hanja'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? '',
      birthDate: (json['birthDate'] as String?) ?? '',
      birthTime: (json['birthTime'] as String?) ?? '',
      isLunar: (json['isLunar'] as bool?) ?? false,
      mbti: (json['mbti'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hanja': hanja,
        'gender': gender,
        'birthDate': birthDate,
        'birthTime': birthTime,
        'isLunar': isLunar,
        'mbti': mbti,
      };

  MyProfile copyWith({
    String? name,
    String? hanja,
    String? gender,
    String? birthDate,
    String? birthTime,
    bool? isLunar,
    String? mbti,
  }) {
    return MyProfile(
      name: name ?? this.name,
      hanja: hanja ?? this.hanja,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      isLunar: isLunar ?? this.isLunar,
      mbti: mbti ?? this.mbti,
    );
  }
}

class Member {
  const Member({
    required this.id,
    required this.userId,
    required this.name,
    this.hanja = '',
    this.relation = '',
    this.priority = 0,
    this.birthDate = '',
    this.birthTime = '',
    this.isLunar = false,
    this.gender = '',
    this.mbti = '',
    this.kind = 'family',
  });

  final String id;
  final String userId;
  final String name;
  final String hanja;
  final String relation;
  final int priority;
  final String birthDate;
  final String birthTime;
  final bool isLunar;
  final String gender;
  final String mbti;
  final String kind;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: (json['name'] as String?) ?? '',
      hanja: (json['hanja'] as String?) ?? '',
      relation: (json['relation'] as String?) ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      birthDate: _dateOnly(json['birth_date']),
      birthTime: (json['birth_time'] as String?) ?? '',
      isLunar: (json['is_lunar'] as bool?) ?? false,
      gender: (json['gender'] as String?) ?? '',
      mbti: (json['mbti'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'family',
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'name': name,
        'hanja': hanja,
        'relation': relation,
        'priority': priority,
        'birth_date': birthDate.isEmpty ? null : birthDate,
        'birth_time': birthTime,
        'is_lunar': isLunar,
        'gender': gender,
        'mbti': mbti,
        'kind': kind,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'hanja': hanja,
        'relation': relation,
        'birth_date': birthDate.isEmpty ? null : birthDate,
        'birth_time': birthTime,
        'is_lunar': isLunar,
        'gender': gender,
        'mbti': mbti,
        'kind': kind,
      };

  Member copyWith({
    String? id,
    String? userId,
    String? name,
    String? hanja,
    String? relation,
    int? priority,
    String? birthDate,
    String? birthTime,
    bool? isLunar,
    String? gender,
    String? mbti,
    String? kind,
  }) {
    return Member(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      hanja: hanja ?? this.hanja,
      relation: relation ?? this.relation,
      priority: priority ?? this.priority,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      isLunar: isLunar ?? this.isLunar,
      gender: gender ?? this.gender,
      mbti: mbti ?? this.mbti,
      kind: kind ?? this.kind,
    );
  }

  static String _dateOnly(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
    }
    final text = value.toString();
    return text.length >= 10 ? text.substring(0, 10) : text;
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.amuletCount,
    required this.riceCount,
    required this.passActive,
    required this.myProfile,
    this.email,
    this.provider,
    this.passExpiredAt,
  });

  final String id;
  final String? email;
  final String? provider;
  final int amuletCount;
  final int riceCount;
  final bool passActive;
  final DateTime? passExpiredAt;
  final MyProfile myProfile;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      provider: json['provider'] as String?,
      amuletCount: (json['amulet_count'] as num?)?.toInt() ?? 0,
      riceCount: (json['rice_count'] as num?)?.toInt() ?? 0,
      passActive: (json['pass_active'] as bool?) ?? false,
      passExpiredAt: json['pass_expired_at'] != null
          ? DateTime.tryParse(json['pass_expired_at'] as String)
          : null,
      myProfile: MyProfile.fromJson(
        (json['my_profile'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }
}
