import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anon = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (url.isEmpty || anon.isEmpty) {
      throw StateError('SUPABASE_URL / SUPABASE_ANON_KEY 가 .env 에 없습니다.');
    }
    await Supabase.initialize(url: url, publishableKey: anon);
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Android/iOS OAuth 복귀 딥링크.
  /// 패키지명 `com.janny.gahwa_luck` 의 `_` 는 URI 스킴에 쓸 수 없다.
  /// 콜백 500(`site url is improperly formatted`)은 앱 스킴이 아니라
  /// Supabase 대시보드 Site URL 이 잘못된 형식일 때 난다. HTTPS 로 둬야 한다.
  static const redirectTo = 'com.janny.gahwa-luck://login-callback/';
}
