# 원천청년부 앱 — iOS 배포 자동화 파이프라인

> 참고 출처: 드림어스컴퍼니(FLO) iOS 팀 블로그
> https://www.blog-dreamus.com/post/github-action-slack-api-aws-lambda를-활용한-ios-배포-자동화

---

## 1. 전체 파이프라인 구조

```
개발자가 Slack에서 /distribute 입력
  └─ Slack Slash Command
       └─ AWS Lambda (Slack Bot 서버)
            └─ Slack Block Kit 메시지 (배포 버튼 포함)
                 └─ 버튼 클릭 → Modal (branch, type 입력)
                      └─ Lambda → GitHub Actions workflow_dispatch 트리거
                           └─ GitHub Actions Runner (macOS)
                                └─ Fastlane → TestFlight 업로드
                                     └─ Slack 알림 ("배포 완료 ✅")
```

---

## 2. 구성 요소별 역할

| 구성 요소 | 역할 |
|---|---|
| Slack App (Bot) | 배포 트리거 진입점. Slash Command + Interactive 메시지 |
| AWS Lambda | Slack 이벤트 수신 및 처리, GitHub Actions 트리거 |
| GitHub Actions | 실제 빌드/테스트/배포 실행 (macOS Runner) |
| Fastlane | 빌드, 코드 서명, TestFlight 업로드 자동화 |
| Slack Block Kit | 배포 UI (버튼, Modal) 구성 |

---

## 3. 단계별 세팅 가이드

### Step 1. Slack App 생성

1. https://api.slack.com/apps 접속 → **Create New App**
2. App 이름 설정 (예: `woncheon-deploy-bot`)
3. 사용할 Slack Workspace 선택

**필요한 권한 (OAuth Scopes)**
- `chat:write` — 메시지 전송
- `commands` — Slash Command 사용
- `incoming-webhook` — Webhook 수신

**Slash Command 등록**
- Command: `/distribute`
- Request URL: AWS Lambda URL (Step 2 완료 후 입력)
- Description: iOS 앱 배포 시작

**Interactivity 설정**
- Interactivity & Shortcuts → Request URL: AWS Lambda URL
- 버튼 클릭, Modal 등 interactive 이벤트 수신용

---

### Step 2. AWS Lambda (Slack Bot 서버) 구성

**초기화**
```bash
mkdir woncheon-deploy-bot && cd woncheon-deploy-bot
pnpm init
pnpm add @slack/bolt
pnpm add -D serverless serverless-esbuild typescript @types/node
```

**핵심 코드 구조**
```typescript
import { App, AwsLambdaReceiver } from '@slack/bolt';

const receiver = new AwsLambdaReceiver({
  signingSecret: process.env.SLACK_SIGNING_SECRET!,
});

const app = new App({
  token: process.env.SLACK_BOT_TOKEN!,
  receiver,
});

// 1. /distribute 커맨드 수신 → 배포 버튼 메시지 전송
app.command('/distribute', async ({ ack, respond }) => {
  await ack();
  await respond({
    blocks: [
      {
        type: 'section',
        text: { type: 'mrkdwn', text: '🚀 *원천청년부 앱 배포*\n배포할 대상을 선택해주세요.' },
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'iOS 배포' },
            action_id: 'deploy_ios',
            style: 'primary',
          },
        ],
      },
    ],
  });
});

// 2. 배포 버튼 클릭 → Modal 표시 (branch, 배포 타입 입력)
app.action('deploy_ios', async ({ ack, body, client }) => {
  await ack();
  await client.views.open({
    trigger_id: (body as any).trigger_id,
    view: {
      type: 'modal',
      callback_id: 'deploy_submit',
      title: { type: 'plain_text', text: 'iOS 배포 설정' },
      submit: { type: 'plain_text', text: '배포 시작' },
      blocks: [
        {
          type: 'input',
          block_id: 'branch',
          label: { type: 'plain_text', text: 'Branch' },
          element: { type: 'plain_text_input', action_id: 'branch_value', placeholder: { type: 'plain_text', text: 'main' } },
        },
        {
          type: 'input',
          block_id: 'deploy_type',
          label: { type: 'plain_text', text: '배포 타입' },
          element: {
            type: 'static_select',
            action_id: 'type_value',
            options: [
              { text: { type: 'plain_text', text: 'TestFlight' }, value: 'testflight' },
              { text: { type: 'plain_text', text: 'App Store' }, value: 'appstore' },
            ],
          },
        },
      ],
    },
  });
});

// 3. Modal 제출 → GitHub Actions workflow_dispatch 트리거
app.view('deploy_submit', async ({ ack, view, client, body }) => {
  await ack();

  const branch = view.state.values.branch.branch_value.value!;
  const deployType = view.state.values.deploy_type.type_value.selected_option!.value;

  // GitHub Actions 트리거
  await fetch(
    `https://api.github.com/repos/{OWNER}/{REPO}/actions/workflows/deploy-ios.yml/dispatches`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
        Accept: 'application/vnd.github+json',
      },
      body: JSON.stringify({
        ref: branch,
        inputs: { deploy_type: deployType },
      }),
    }
  );

  // 트리거 완료 알림
  await client.chat.postMessage({
    channel: process.env.SLACK_DEPLOY_CHANNEL!,
    text: `🚀 iOS ${deployType} 배포 시작!\nbranch: \`${branch}\``,
  });
});

// Lambda handler 내보내기
export const handler = async (event: any, context: any) => {
  const handler = await receiver.start();
  return handler(event, context);
};
```

**Lambda 환경 변수**
```
SLACK_BOT_TOKEN
SLACK_SIGNING_SECRET
GITHUB_TOKEN          # GitHub Personal Access Token (workflow 트리거 권한 필요)
SLACK_DEPLOY_CHANNEL  # 알림 받을 Slack 채널 ID
```

---

### Step 3. GitHub Actions 워크플로우 구성

```yaml
# .github/workflows/deploy-ios.yml

name: iOS Deploy

on:
  workflow_dispatch:
    inputs:
      deploy_type:
        description: '배포 타입 (testflight | appstore)'
        required: true
        default: 'testflight'

jobs:
  deploy:
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Flutter 설치
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: 의존성 설치
        run: flutter pub get

      - name: Fastlane 실행
        run: bundle exec fastlane ${{ github.event.inputs.deploy_type }}
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}

      - name: 배포 완료 Slack 알림
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-type: application/json' \
            -d '{"text":"✅ iOS ${{ github.event.inputs.deploy_type }} 배포 완료!"}'

      - name: 배포 실패 Slack 알림
        if: failure()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-type: application/json' \
            -d '{"text":"❌ iOS 배포 실패. 로그를 확인해주세요."}'
```

---

### Step 4. Fastlane 구성

```ruby
# fastlane/Fastfile

default_platform(:ios)

platform :ios do

  lane :testflight do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  lane :appstore do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_app_store(
      submit_for_review: false,
      automatic_release: false
    )
  end

end
```

**Fastlane 초기화**
```bash
cd ios
bundle init
bundle add fastlane
bundle exec fastlane init
```

---

## 4. GitHub Secrets 목록

| Secret 이름 | 내용 |
|---|---|
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API Key (JSON) |
| `MATCH_PASSWORD` | Fastlane Match 인증서 암호화 비밀번호 |
| `SLACK_WEBHOOK_URL` | 배포 결과 알림용 Slack Incoming Webhook URL |

---

## 5. 민동익님 앱 적용 시 참고사항

- **솔로 개발**이므로 Slack Bot까지 구성하는 건 오버스펙일 수 있습니다. 초반에는 GitHub Actions `workflow_dispatch`를 GitHub 웹에서 직접 수동 트리거하는 것으로 시작하고, 나중에 Slack 연동을 추가하는 순서를 권장합니다.
- **우선순위 추천**:
  1. Fastlane 세팅 (코드 서명 자동화)
  2. GitHub Actions 워크플로우 (수동 트리거)
  3. Slack Bot 연동 (고도화)
- macOS Runner는 GitHub Actions 무료 플랜 기준 월 2,000분 제공. 소규모 앱은 충분합니다.
