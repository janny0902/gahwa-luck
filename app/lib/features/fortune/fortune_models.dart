class FortuneCategory {
  const FortuneCategory(this.id, this.label);

  final String id;
  final String label;

  static const myFortune = FortuneCategory('my_fortune', '내 운세');
  static const family = FortuneCategory('family', '가족궁합');
  static const colleague = FortuneCategory('colleague', '동료궁합');
  static const datePick = FortuneCategory('date_pick', '날 받기');
  static const naming = FortuneCategory('naming', '이름받기');
  static const thingName = FortuneCategory('thing_name', '애견·차 이름');
  static const dream = FortuneCategory('dream', '꿈해몽');

  static const all = [myFortune, family, colleague, datePick, naming, thingName, dream];

  static FortuneCategory byId(String id) {
    return all.firstWhere((item) => item.id == id, orElse: () => myFortune);
  }
}

class FortuneSection {
  const FortuneSection(this.heading, this.body);
  final String heading;
  final String body;
}

const _hardFollowupTerms = [
  '오행',
  '십신',
  '용신',
  '희신',
  '편재',
  '식신',
  '상관',
  '정재',
  '비겁',
  '편관',
  '정관',
  '인성',
  '비견',
  '겁재',
  '원진',
  '도화',
  '역마',
  '괴강',
  '천을',
  '신살',
  '대운',
  '월건',
  '세운',
  '일간',
  '간지',
  '충합',
  '형충',
];

List<String> easyFollowupQuestions(String category) {
  switch (category) {
    case 'family':
      return ['누구랑 조심할까요?', '오늘은 무슨 말을 할까요?', '집안 분위기는?'];
    case 'colleague':
      return ['누구랑 잘 맞아요?', '회식은 어때요?', '일 얘기 팁은?'];
    case 'date_pick':
      return ['다른 날도 있어요?', '피하면 좋은 때는?', '몇 시가 좋아요?'];
    case 'naming':
      return ['다른 이름은요?', '부르기 쉬운가요?', '한자 뜻은 어때요?'];
    case 'thing_name':
      return ['더 웃긴 이름은?', '더 짧은 이름은?', '부르기 쉬운 건?'];
    case 'dream':
      return ['좋은 꿈인가요?', '오늘 어떻게 하면 돼요?', '또 무슨 뜻일까요?'];
    default:
      return ['오늘 조심할 일은?', '돈 흐름은 어때요?', '쉬는 게 나을까요?'];
  }
}

String? _questionText(dynamic item) {
  if (item is String) return item.trim();
  if (item is Map) {
    for (final key in ['question', 'q', 'text']) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
  }
  return null;
}

bool _isEasyFollowup(String question) {
  if (question.isEmpty || question.length > 28) return false;
  return !_hardFollowupTerms.any(question.contains);
}

List<String> parseSuggestedQuestions(dynamic raw) {
  if (raw is! List) return const [];
  final questions = <String>[];
  for (final item in raw) {
    final text = _questionText(item)?.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');
    if (text == null || text.isEmpty) continue;
    questions.add(text);
  }
  return questions;
}

List<String> displayFollowupQuestions(String category, List<String> fromModel) {
  final kept = <String>[];
  for (final question in fromModel) {
    if (!_isEasyFollowup(question) || kept.contains(question)) continue;
    kept.add(question);
    if (kept.length >= 3) return kept;
  }
  for (final question in easyFollowupQuestions(category)) {
    if (kept.contains(question)) continue;
    kept.add(question);
    if (kept.length >= 3) break;
  }
  return kept;
}

class FortuneChat {
  const FortuneChat({
    required this.turn,
    required this.question,
    required this.answer,
  });

  final int turn;
  final String question;
  final String answer;

  factory FortuneChat.fromJson(Map<String, dynamic> json) {
    return FortuneChat(
      turn: (json['turn_index'] as num?)?.toInt() ?? 0,
      question: (json['user_question'] as String?) ?? '',
      answer: (json['ai_answer'] as String?) ?? '',
    );
  }
}

class FortuneRecord {
  const FortuneRecord({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.sections,
    required this.suggestedQuestions,
    required this.remainingRiceTurns,
    required this.createdAt,
    required this.pillarLabel,
    this.chats = const [],
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final List<FortuneSection> sections;
  final List<String> suggestedQuestions;
  final int remainingRiceTurns;
  final DateTime? createdAt;
  final String pillarLabel;
  final List<FortuneChat> chats;

  FortuneRecord copyWith({
    int? remainingRiceTurns,
    List<String>? suggestedQuestions,
    List<FortuneChat>? chats,
  }) {
    return FortuneRecord(
      id: id,
      category: category,
      title: title,
      summary: summary,
      sections: sections,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      remainingRiceTurns: remainingRiceTurns ?? this.remainingRiceTurns,
      createdAt: createdAt,
      pillarLabel: pillarLabel,
      chats: chats ?? this.chats,
    );
  }

  factory FortuneRecord.fromRow(Map<String, dynamic> row) {
    final result = (row['result_json'] as Map?)?.cast<String, dynamic>() ?? {};
    final pillars = (row['four_pillars'] as Map?)?.cast<String, dynamic>() ?? {};
    final sections = <FortuneSection>[];
    final rawSections = result['sections'];
    if (rawSections is List) {
      for (final item in rawSections) {
        if (item is Map) {
          sections.add(FortuneSection(
            (item['heading'] as String?) ?? '',
            (item['body'] as String?) ?? '',
          ));
        }
      }
    }
    final questions = displayFollowupQuestions(
      (result['menu'] as String?) == 'thing_name'
          ? 'thing_name'
          : ((row['category'] as String?) ?? 'my_fortune'),
      parseSuggestedQuestions(result['suggested_questions']),
    );
    final hour = pillars['hour'] as String?;
    final pillarLabel = [
      pillars['year'],
      pillars['month'],
      pillars['day'],
      if (hour != null && hour.isNotEmpty) hour else '시 모름',
    ].whereType<String>().join(' ');
    return FortuneRecord(
      id: row['id'] as String,
      category: (result['menu'] as String?) == 'thing_name'
          ? 'thing_name'
          : ((row['category'] as String?) ?? 'my_fortune'),
      title: (result['title'] as String?) ?? '운세',
      summary: (result['summary'] as String?) ?? (row['result_text'] as String?) ?? '',
      sections: sections,
      suggestedQuestions: questions,
      remainingRiceTurns: (row['remaining_rice_turns'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
      pillarLabel: pillarLabel,
    );
  }
}
