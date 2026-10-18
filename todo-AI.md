# AI 통합 + 앱 이름 변경 (거래클립 → AI거래장인)

## Context

거래클립 앱에 Claude AI 기능 5가지를 추가하고, 앱 이름을 "AI거래장인"으로 변경한다.
Claude API 키가 앱에 포함되지 않도록 **Supabase Edge Function(`ai`)이 Claude를 대신 호출**하고,
앱은 로그인 토큰으로 이 함수만 호출한다.

---

## AI 기능 5가지

- [x] 1. **자연어 거래 입력** — "오늘 사과 30개 5만원 받을 돈" → 거래 폼 자동 채움
- [x] 2. **AI 경영 인사이트** — 거래 데이터 분석 → 매출 추이·위험 거래처 리포트
- [x] 3. **영수증·메모 사진 → 거래 자동 입력** — 카메라/갤러리 이미지 → Claude Vision → 거래 폼
- [x] 4. **AI 미수금 독촉 문구 생성** — 거래처 잔액 → 카카오 발송용 메시지
- [x] 5. **견적서/납품서 자동 생성** — 품목·수량·금액 입력 → 포맷된 문서 텍스트

---

## 구조

```
앱 (AiService) ──functions.invoke('ai', {task, input})──▶ Edge Function `ai` ──▶ Claude API
                  로그인 JWT                                CLAUDE_API_KEY (secret)
```

| 파일 | 역할 |
|------|------|
| `supabase/functions/ai/index.ts` | 사용자 인증 확인, 입력 검증, 프롬프트 생성, Claude 호출, 오류 → 한국어 메시지 |
| `supabase/functions/.env` | `CLAUDE_API_KEY` (gitignore, `supabase secrets set`용) |
| `lib/services/ai_service.dart` | Edge Function 호출, 응답 검증, `AiException`, 이미지 형식 감지 |
| `lib/providers/ai_providers.dart` | Riverpod Provider |
| `lib/screens/ai/ai_transaction_input_screen.dart` | 자연어/사진 입력 화면 |
| `lib/screens/ai/insight_screen.dart` | AI 경영 인사이트 화면 |
| `lib/screens/ai/document_generator_screen.dart` | 견적서/납품서 생성 화면 |
| `lib/widgets/ai/collection_message_sheet.dart` | 미수금 독촉 문구 BottomSheet |

Edge Function task: `parse_text`, `parse_image`, `insights`, `collection_message`, `document`

### 모델
- 텍스트: `claude-haiku-5-5` (effort `low`)
- 사진: `claude-sonnet-5-5` (effort `low`, 거절 시 서버측 fallback 사용)
- JSON이 필요한 작업(거래 파싱, 인사이트)은 structured outputs(`output_config.format`)로 형식 보장

### 진입점
- 거래처 상세 AppBar ✨ 메뉴 → 미수금 독촉 문구 / 견적서·납품서
- 거래처 상세 거래 추가 시트 → AI 자동 입력
- 거래 내역 AppBar ✨ → AI 경영 인사이트
- `TransactionFormScreen(initialData:)` — AI 파싱 결과 프리필

---

## 앱 이름 변경

- [x] `lib/main.dart`, 로그인/회원가입, 거래처 목록, 설정(AboutListTile)
- [x] `android/app/src/main/AndroidManifest.xml` — `android:label`
- [x] `ios/Runner/Info.plist` — `CFBundleDisplayName`

---

## 보안·품질 보강 (2026-10-18)

- [x] API 키를 앱 번들(`.env` asset)에서 제거 → Edge Function secret으로 이동
- [x] Edge Function에서 실제 로그인 사용자 확인 (anon 키만으로 호출 불가)
- [x] 프롬프트를 서버에서 생성, 입력 길이·품목 수·이미지 크기 제한
- [x] iOS `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` 추가
- [x] 이미지 매직 바이트로 media type 감지 (JPEG/PNG/GIF/WEBP, 그 외 안내)
- [x] 금액 0/미인식 시 폼 진입 차단, 오류 메시지 한국어화
- [x] 모델을 Claude 5.5 계열로 변경

---

## 남은 작업

- [ ] Edge Function 배포
  ```bash
  supabase secrets set --env-file supabase/functions/.env
  supabase functions deploy ai
  ```
- [ ] 실기기에서 AI 기능 5가지 호출 테스트
  - [ ] 자연어 입력 → 거래 폼 프리필
  - [ ] 사진(카메라·갤러리) → 거래 폼 프리필
  - [ ] 미수금 독촉 문구 생성 → 공유
  - [ ] 견적서/납품서 생성
  - [ ] 경영 인사이트
- [ ] Android/iOS 설치 후 홈화면 아이콘 레이블 확인
- [ ] (선택) 사용자별 일일 AI 호출 횟수 제한 — 비용 보호
