# 가화만사성 (gahwa-luck)

Flutter + Supabase 기반 사주/궁합 앱.

## 문서
- [기획안](./가화만사성%20기획안.md)
- [설계안](./docs/가화만사성-설계안.md)
- [구현계획](./docs/구현계획.md)
- [RULE](./RULE.md)

## 앱 실행 (T1~T2)
```bash
cd app
# .env 에 SUPABASE_URL / SUPABASE_ANON_KEY 필요
flutter pub get
flutter run
```

OAuth 콘솔 설정: [docs/oauth-setup.md](./docs/oauth-setup.md)

## 구조
- `app/` Flutter 클라이언트 (Riverpod)
- `supabase/migrations/` DB + RLS
- `personas/` Gemini 시스템 프롬프트 (Edge에 배포 예정)
