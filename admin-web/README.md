# 폰거래장 온 관리자 페이지

최고관리자가 브라우저에서 로그인해 사용 현황을 보는 **조회 전용** 페이지. 기획: [`../plan-admin-dashboard.md`](../plan-admin-dashboard.md)

```
브라우저 ──HTTPS──▶ Cloudflare Pages (정적 파일만: public/)
   │
   └── 로그인·데이터 ──▶ Supabase (admin_* 함수가 관리자인지 확인 후 결과)
```

| 경로 | 내용 |
|---|---|
| `public/index.html` | 화면 틀·스타일 |
| `public/app.js` | 화면·데이터 로직 (로그인·개요·사업장·상세·AI) |
| `public/config.js` | Supabase URL·anon 키 (공개용). **service role 키 절대 금지** |
| `public/_headers` | 보안 헤더 (CSP·프레임 금지·검색 차단 등) |
| `public/robots.txt` | 검색 엔진 수집 금지 |

> **`public/` 폴더만 올린다.** 이 README는 올리지 않는다.

## 1. DB 준비 (완료)

- 마이그레이션: `20261021000000_admin_dashboard.sql`, `20261021000001_admin_independent_ai_pricing.sql`
- 관리자 등록 (이메일을 git에 남기지 않도록 SQL로 1회):
  ```sql
  insert into public.admins(user_id)
  select id from auth.users where email = '<관리자 이메일>'
  on conflict do nothing;
  ```
- 관리자 해제: `delete from public.admins where user_id = (select id from auth.users where email = '<이메일>');`

## 2. PC에서 미리 보기

```bash
python -m http.server 8766 --bind 127.0.0.1 --directory admin-web/public
# 브라우저: http://127.0.0.1:8766
```

## 3. 무료 호스팅 — Cloudflare Pages

### 방법 A. 대시보드에서 끌어다 놓기 (가장 쉬움)
1. https://dash.cloudflare.com 가입·로그인 (무료)
2. **Workers & Pages → Create → Pages → Upload assets**
3. 프로젝트 이름 예: `phone-ledger-admin` → **`admin-web/public` 폴더**를 끌어다 놓기 → Deploy
4. 주소: `https://phone-ledger-admin.pages.dev` (이름은 프로젝트 이름에 따라 다름)

업데이트: 같은 프로젝트에서 **Create new deployment** → `public` 폴더 다시 올리기

### 방법 B. 명령어 (Node 필요)
```bash
npx wrangler login            # 처음 1회, 브라우저에서 Cloudflare 로그인
npx wrangler pages deploy admin-web/public --project-name phone-ledger-admin
```

### 배포 후 확인
- 주소로 접속 → 로그인 화면 → 앱 계정으로 로그인 → 개요가 보이면 완료
- 관리자가 아닌 계정으로 로그인하면 "관리자 계정이 아닙니다"

## 4. 더 단단하게 (선택) — Cloudflare Access

페이지 자체를 **내 이메일 인증을 통과해야만** 열리게 막는다 (무료 플랜 50명까지).
대시보드 **Zero Trust → Access → Applications → Add → Self-hosted** → 도메인 `phone-ledger-admin.pages.dev` →
정책: Allow, Emails = 관리자 이메일. 이후 페이지 접속 시 이메일로 받은 코드를 먼저 입력해야 한다.

## 보안 메모

- 데이터는 DB 함수 `admin_*`가 `public.admins`에 있는 계정에게만 돌려준다. 페이지 주소가 알려져도 관리자 계정이 아니면 빈손
- 조회 전용 — 데이터를 바꾸는 함수 없음
- 사업장 상세를 열 때마다 `public.admin_access_logs`에 기록 (누가·언제·어느 사업장)
- 사업장명·메모 등 사용자 입력은 화면에 넣을 때 모두 이스케이프 (관리자 세션 탈취 방지)
- `_headers`의 CSP: 스크립트는 이 사이트와 jsDelivr만, 통신은 Supabase만 허용, 인라인 스크립트 금지, 다른 사이트에 끼워넣기 금지
- supabase-js는 버전 고정 + 무결성 확인(SRI). 버전을 올리면 `index.html`의 `integrity` 해시도 새로 계산:
  `curl -sL <URL> | openssl dgst -sha384 -binary | openssl base64 -A`
- 세션 잠금(`navigator.locks`)을 끈 설정은 일부 환경에서 첫 화면이 약 10초 멈추던 문제 때문 (관리자는 탭 하나에서 사용)
- AI 비용 단가·기능 이름: DB 함수 `_ai_price()`, `_ai_task_label()` (관리자 화면 전용). 모델·가격이 바뀌면 새 마이그레이션에서 수정
- 텔레그램 리포트(`stats` 스키마)와는 **독립** — 서로 읽거나 쓰지 않음
