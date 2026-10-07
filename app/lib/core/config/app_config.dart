/// 앱 설정 키 (값은 `.env` / 시크릿에서 로드)
class AppConfig {
  AppConfig._();

  static const supabaseUrl = 'SUPABASE_URL';
  static const supabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const admobAppId = 'ADMOB_APP_ID';
  static const admobBannerId = 'ADMOB_BANNER_ID';
  static const admobRewardId = 'ADMOB_REWARD_ID';
  static const admobNativeId = 'ADMOB_NATIVE_ID';
}
