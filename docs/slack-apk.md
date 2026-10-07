# 가화만사성 Slack 개발 / APK

JADISS 집 PC 봇(`d:\jadiss-platform\infra\ops\slack-dev-bot`)의 채널 프로필을 그대로 씁니다. 봇을 새로 만들지 않습니다.

## 채널에서

| 메시지 | 동작 |
|--------|------|
| `@JADISS Dev Bot 질문` | `d:\gahwa-luck` 분석만 |
| `@JADISS Dev Bot /dev 수정 내용` | 앱 소스 수정. git push 없음 |
| `@JADISS Dev Bot /apk` | debug APK를 만들어 같은 스레드에 업로드 |

폰에서 받은 APK는 ‘알 수 없는 앱 설치’를 한 번 허용한 뒤 설치합니다.

## 연결에 필요한 값

`D:\jadiss-secrets\slack-dev-bot.env` 에 추가:

```
GAWHA_SLACK_CHANNEL_ID=Cxxxxxxxx
GAWHA_PROJECT_ROOT=d:\gahwa-luck
```

채널 ID는 Slack에서 채널 이름 클릭 → 맨 아래 채널 ID 복사.

봇 재시작:

```powershell
cd d:\jadiss-platform\infra\ops\slack-dev-bot
.\run.ps1
```

Slack 앱 Bot Token Scope에 `files:write` 가 있어야 APK 업로드가 됩니다. 없으면 api.slack.com 앱 설정에서 추가 후 워크스페이스에 재설치합니다.

가화만사성 채널에 `@JADISS Dev Bot` 을 초대해야 멘션이 도착합니다.
