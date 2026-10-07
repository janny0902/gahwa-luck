import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';
import 'fortune_models.dart';

class FortuneApi {
  FortuneApi(this._client);
  final SupabaseClient _client;

  Future<FortuneRecord> generate({
    required String category,
    required Map<String, dynamic> input,
    required Map<String, dynamic> fourPillars,
  }) async {
    final data = await _invoke('generate-fortune', {
      'category': category,
      'input': input,
      'four_pillars': fourPillars,
    });
    final fortune = (data['fortune'] as Map?)?.cast<String, dynamic>();
    if (fortune == null) {
      throw FortuneException('운세 결과를 받지 못했습니다');
    }
    return FortuneRecord.fromRow(fortune);
  }

  Future<({FortuneChat chat, int remaining, List<String> questions})> ask({
    required String fortuneId,
    required String question,
    String category = 'my_fortune',
  }) async {
    final data = await _invoke('ask-followup', {
      'fortune_id': fortuneId,
      'question': question,
    });
    final chat = FortuneChat.fromJson(
      (data['chat'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final result = (data['result'] as Map?)?.cast<String, dynamic>() ?? {};
    final questions = displayFollowupQuestions(
      category,
      parseSuggestedQuestions(result['suggested_questions']),
    );
    return (
      chat: chat,
      remaining: (data['remaining_rice_turns'] as num?)?.toInt() ?? 0,
      questions: questions,
    );
  }

  Future<List<FortuneRecord>> history() async {
    final rows = await _client
        .from('fortunes')
        .select(
          'id, category, result_json, result_text, four_pillars, remaining_rice_turns, created_at',
        )
        .order('created_at', ascending: false)
        .limit(50);
    return [
      for (final row in rows) FortuneRecord.fromRow(Map<String, dynamic>.from(row)),
    ];
  }

  Future<List<FortuneChat>> chats(String fortuneId) async {
    final rows = await _client
        .from('fortune_chats')
        .select('turn_index, user_question, ai_answer')
        .eq('fortune_id', fortuneId)
        .order('turn_index');
    return [
      for (final row in rows) FortuneChat.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  Future<Map<String, dynamic>> _invoke(String name, Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(name, body: body);
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw FortuneException(data['error'].toString());
      }
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw FortuneException('서버 응답을 읽지 못했습니다');
    } on FortuneException {
      rethrow;
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw FortuneException(details['error'].toString());
      }
      throw FortuneException(_functionMessage(error));
    }
  }

  String _functionMessage(FunctionException error) {
    if (error.status == 404) {
      return '운세 서버가 아직 배포되지 않았습니다';
    }
    return '운세 서버 오류 (${error.status})';
  }
}

class FortuneException implements Exception {
  FortuneException(this.message);
  final String message;
  @override
  String toString() => message;
}

final fortuneApiProvider = Provider<FortuneApi>((ref) {
  return FortuneApi(ref.watch(supabaseClientProvider));
});
