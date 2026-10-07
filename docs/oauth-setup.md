# OAuth 서비스 등록 절차 (T2)

## 지금 500이 나는 이유 (앱 재배포로 안 고쳐짐)

구글/카카오 로그인 뒤 브라우저에 500이 뜨는 것은 **앱 딥링크가 아니라 Supabase Site URL** 문제입니다.  
콜백 `https://lfruzdnubvluzsubnwsp.supabase.co/auth/v1/callback` 이 `site url is improperly formatted` 로 실패합니다.

**지금 할 일 (1분):**
1. [URL Configuration](https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp/auth/url-configuration) 열기
2. **Site URL** 을 아래 **HTTPS만** 넣고 저장 (앱 스킴·언더스코어 `_` 절대 금지)
   - `https://lfruzdnubvluzsubnwsp.supabase.co`
3. **Redirect URLs** 에 앱 복귀용만 추가 (하이픈 `-`, 언더스코어 아님)
   - `com.janny.gahwa-luck://login-callback/`

패키지명 `com.janny.gahwa_luck` 을 Site URL이나 Redirect URL에 그대로 넣으면 Go가 URL을 파싱하지 못해 콜백이 **무조건 500** 입니다.

---

## 바로가기 링크

| 용도 | 링크 |
|------|------|
| Google Cloud Console | https://console.cloud.google.com |
| Google OAuth 동의 화면 | https://console.cloud.google.com/apis/credentials/consent |
| Google 사용자 인증 정보 | https://console.cloud.google.com/apis/credentials |
| Supabase 대시보드 | https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp |
| Supabase Auth Providers | https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp/auth/providers |
| Supabase URL 설정 | https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp/auth/url-configuration |
| 카카오 개발자 콘솔 | https://developers.kakao.com |
| 카카오 내 애플리케이션 | https://developers.kakao.com/console/app |

---

앱 딥링크: `com.janny.gahwa-luck://login-callback/`  
Supabase 콜백: `https://lfruzdnubvluzsubnwsp.supabase.co/auth/v1/callback`  
패키지명: `com.janny.gahwa_luck`

아래를 **순서대로** 하고, 각 단계가 끝나면 채팅에 `구글 완료` / `카카오 완료` 라고만 적어 주세요.  
(키·시크릿은 채팅에 붙여넣지 마세요. Supabase 대시보드에만 입력.)

---

## A. Google 로그인

### A-1. Google Cloud Console
1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 프로젝트 만들기 (또는 기존 선택) — 이름 예: `gahwa-luck`
3. [OAuth 동의 화면](https://console.cloud.google.com/apis/credentials/consent)
   - User Type: **외부**
   - 앱 이름: `가화만사성`
   - 지원 이메일: 본인 메일
   - 저장 후, 테스트 사용자에 본인 Gmail 추가 (게시 전이면 필수)
4. [사용자 인증 정보](https://console.cloud.google.com/apis/credentials) → **만들기 → OAuth 클라이언트 ID**
   - 유형: **웹 애플리케이션** (Supabase용 — 필수)
   - 이름: `gahwa-supabase-web`
   - **승인된 리디렉션 URI**에 추가:
     `https://lfruzdnubvluzsubnwsp.supabase.co/auth/v1/callback`
   - 만들기 → **클라이언트 ID / 클라이언트 보안 비밀** 복사해 안전한 곳에 보관

### A-2. Supabase에 Google 연결
1. [Auth Providers](https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp/auth/providers) → **Google** → Enable
2. Client ID / Client Secret 붙여넣기 → Save
3. [URL Configuration](https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp/auth/url-configuration)
   - **Site URL (필수, 500 원인):** `https://lfruzdnubvluzsubnwsp.supabase.co`
     - `com.janny.gahwa_luck://...` 같은 앱 스킴을 넣으면 로그인 콜백이 500입니다.
   - Redirect URLs에 추가 (하이픈):
     - `com.janny.gahwa-luck://login-callback/`

끝나면: 채팅에 **`구글 완료`**

---

## B. 카카오 로그인

### B-1. 카카오 개발자 콘솔
1. [카카오 내 애플리케이션](https://developers.kakao.com/console/app) → **애플리케이션 추가**
   - 앱 이름: `가화만사성`
2. **앱 키** 화면에서 **REST API 키** 확인
3. **카카오 로그인 → 활성화 설정 ON**
4. **카카오 로그인 → Redirect URI** 등록:
   `https://lfruzdnubvluzsubnwsp.supabase.co/auth/v1/callback`
5. **제품 설정 → 카카오 로그인 → 동의항목**
   - 닉네임, 이메일(선택) 등 필요한 항목 설정
6. **보안 → Client Secret**
   - Client Secret 코드 **생성/사용함** 으로 두고 값 복사
7. (Android) **플랫폼 → Android 등록**
   - 패키지명: `com.janny.gahwa_luck`
   - 키 해시: 디버그 키해시 (아래에 명령으로 뽑음)

디버그 키해시 (Windows, 기본 디버그 키스토어):
```powershell
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android | openssl sha1 -binary | openssl base64
```
openssl이 없으면 알려주세요. 다른 방법으로 안내합니다.

### B-2. Supabase에 Kakao 연결
1. [Auth Providers](https://supabase.com/dashboard/project/lfruzdnubvluzsubnwsp/auth/providers) → **Kakao** → Enable
2. REST API Key → Client ID 칸
3. Client Secret → Secret 칸 → Save

끝나면: 채팅에 **`카카오 완료`**

---

## C. (선택) 네이버
1차 출시에서는 **보류**. 나중에 별도 안내.

---

## 지금 바로 할 일
**먼저 A(구글)만** 해주세요. 구글이 되면 앱에서 로그인 버튼을 바로 검증할 수 있습니다.  
카카오는 이어서 B 진행하면 됩니다.
