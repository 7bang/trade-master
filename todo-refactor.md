# 리팩토링 목록 (2026-10-19 코드 점검)

대상: `trade_master/lib` 약 9,600줄 (생성 코드 제외)
진행 순서: **1번 묶음(①③④⑤) → 2번 묶음(②) → 3번 묶음(⑥⑦⑧ + 청소)**

---

## 1순위 — 사용자 체감 문제

### ① 거래내역 탭이 새로고침되지 않음
- [x] 해결 (2026-10-19)
- 위치: `lib/screens/transaction/transaction_list_screen.dart` `allTransactionsProvider`
- 증상: 한 번 불러온 거래내역이 앱 종료 전까지 유지됨. 거래 추가·수정·삭제 시 이 Provider를 갱신하는 코드가 없고, 당겨서 새로고침도 없음 → 새 거래가 목록에 안 보임
- 해결: 데이터 변경 시 함께 갱신(⑤), 당겨서 새로고침 추가

### ② 거래 1,000건 초과 시 조용히 잘림
- [x] 해결 (2026-10-19)
- 위치: `lib/services/supabase_service.dart` `getTransactions()` `.limit(1000)`, `lib/screens/ai/insight_screen.dart`
- 증상: 거래내역 목록에서 오래된 거래가 안내 없이 빠짐, AI 경영 인사이트의 이번 달 매출·매입 합계가 틀려짐
- 시점: 점검 당시 가장 많은 사업장이 **이미 2,170건** (이번 달 468건) → 거래내역 탭에서 1,170건이 빠진 상태였음
- 해결: 목록은 페이지 단위로 나눠 불러오기, 합계는 DB 함수(RPC)에서 계산

### ③ 화면 이동마다 서버 조회 + 네트워크 오류 시 사업장 등록 화면으로 이동
- [x] 해결 (2026-10-19)
- 위치: `lib/main.dart` GoRouter `redirect`
- 증상: 이동할 때마다 `getBusiness()` 서버 호출(느림). 실패 원인을 구분하지 않아 통신 불안정 시 이미 등록한 사용자가 사업장 등록 화면으로 튕김
- 해결: 사업장 조회 결과를 캐시해서 사용, "사업장 없음"(0건)과 "네트워크 오류"를 구분

### ④ 오류 문구에 기술 용어 노출
- [x] 해결 (2026-10-19)
- 위치: 화면 25곳의 `e.toString()`
- 증상: `저장 실패: Exception: 거래처 수정 실패: Could not find the 'balance' column…` 같은 문구가 사용자에게 보임
- 해결: 사용자용 오류 타입(`AppException`)과 문구 변환 함수로 통일

---

## 2순위 — 구조 정리 (재발 방지)

### ⑤ 데이터 새로고침(invalidate) 코드가 화면마다 흩어짐
- [x] 해결 (2026-10-19)
- 위치: 화면 19곳의 `ref.invalidate(...)`
- 문제: 화면마다 갱신할 Provider를 직접 나열 → 하나 빠뜨리면 ①과 같은 문제
- 해결: "거래 변경", "거래처 변경", "품목 변경", "사업장 변경" 갱신 함수로 한 곳에 모음

### ⑥ 저장 시 DB에 없는 칸 제외 로직이 함수마다 흩어짐
- [x] 해결 (2026-10-19)
- 위치: `supabase_service.dart`의 create/update 함수들 (`data.remove(...)` 반복)
- 문제: 2026-10-19 거래처·거래 수정 오류(`balance`, `customer`, `product` 전송)의 근본 원인
- 해결: 모델별로 DB 전송용 변환(`toDbJson`)을 한 곳에 정의하고, 테이블 컬럼과 일치하는지 테스트

### ⑦ 반복 코드
- [x] 알림(SnackBar) 44곳 → 완료/오류 알림 함수로 통일
- [x] 품목 입력 칸 중복 → 거래 입력·다건 거래 입력을 공용 위젯으로 (견적서·납품서는 자유 입력 구조라 별도 유지)

### ⑧ 큰 화면 파일 분리
- [x] `customer_detail_screen.dart` (689줄 → 417줄 + sections 275줄)
- [x] `multi_transaction_form_screen.dart` (628줄 → 253줄)
- [x] `transaction_form_screen.dart` (612줄 → 219줄)

### 기타 구조
- [x] `SupabaseService()`를 Provider 없이 직접 생성하는 곳 정리 (`main.dart` 라우터, 설정 화면 로그아웃)

---

## 3순위 — 청소

- [x] 쓰지 않는 패키지 `screenshot` 삭제 (`pubspec.yaml`)
- [x] 쓰지 않는 함수 `ShareService.shareMultipleWidgets` 삭제
- [x] 분석 경고 23건 정리 → **0건**
  - 18건: freezed 모델의 `@JsonKey` 표기(`invalid_annotation_target`)
  - ~~4건: `await_only_futures`~~ (1번 묶음에서 해결) / 1건: `use_build_context_synchronously`
- [x] 테스트 보강 (17 → 45개)
  - [x] 모델 → DB 전송 칸이 테이블 컬럼과 일치하는지 (⑥) — `test/db_columns_test.dart`
  - [x] 오류 문구 변환 (④) — `test/app_exception_test.dart`
  - [ ] 데이터 변경 시 갱신 대상 (⑤) — Supabase 초기화가 필요해 보류
  - [x] 거래 입력 상태 계산·변환 — `test/transaction_entry_test.dart`

---

## 진행 기록

| 날짜 | 묶음 | 내용 |
|---|---|---|
| 2026-10-19 | — | 점검 및 목록 작성 |
| 2026-10-19 | 1번 | ①③④⑤ 완료 — 아래 상세 |
| 2026-10-19 | 2번 | ② 완료 — 아래 상세 |
| 2026-10-19 | 3번 | ⑥⑦⑧ + 청소 완료 — 아래 상세 |

### 1번 묶음 상세 (2026-10-19)

- **⑤ 새로고침 한 곳으로**: `lib/providers/data_refresh.dart` — `ref.refreshTransactions() / refreshCustomers() / refreshProducts() / refreshBusiness() / refreshAll() / pullToRefresh()`. 화면 12곳의 `ref.invalidate` 나열을 교체
  - 덤으로 해결: 다건 거래 입력 후 거래처 목록 잔액이 갱신되지 않던 문제
- **① 거래내역 탭**: `allTransactionsProvider`를 `providers.dart`로 옮기고 거래 변경 시 함께 갱신. 거래처·품목·거래내역 목록에 당겨서 새로고침, "다시 시도"는 전체 다시 불러오기
- **③ 라우터**: `businessByUserProvider`(사용자별 캐시)로 사업장 확인 → 화면 이동마다 서버 호출하지 않음. `getBusiness()`는 사업장 없으면 null, 조회 실패면 오류 → 실패 시 등록 화면으로 보내지 않음
  - `currentBusinessProvider`가 오류를 null로 숨기던 것도 제거 (통신 오류 때 거래처 목록이 빈 화면으로 보이던 문제)
- **④ 오류 문구**: `lib/utils/app_exception.dart` — 서비스 31곳이 `AppException.from(e, '작업 이름')`으로 던지고 화면 31곳은 `userMessage(e)`로 표시. 로그인 오류는 코드별 한국어 문구
- 로그아웃: Provider 경유 + 이전 사용자 캐시 비우기
- 공유(내역서·영수증): 데이터 로딩 중이면 기다린 뒤 공유 (`.value` → `.future`)

### 2번 묶음 상세 (2026-10-19)

- **DB 함수** `get_transaction_summary(p_business_id, p_customer_id, p_start, p_end)` — 받을 돈·줄 돈 합계, 건수, 첫/마지막 거래일. 사업장 소유자 확인 (migration `20261020000000`)
- **목록 50건씩**: `lib/providers/transaction_pages.dart` `transactionPagesProvider(TransactionQuery)` — 거래내역 탭(사업장 전체)과 거래처 상세(거래처별)가 함께 사용, 목록 끝에 닿으면 `LoadMoreFooter`가 다음 페이지 요청
  - 서비스 `getTransactions(limit, offset)` — `limit(1000)` 제거, `id`까지 정렬해 페이지 경계 중복·누락 방지
  - 기존 `transactionsProvider`, `allTransactionsProvider`, `DateFilter` 삭제
- **내역서**: `statementDataProvider` — 최근 50건 + DB 합계. 합계·잔액·조회 기간은 전체 거래 기준 (기존에는 받은 목록을 더해 1,000건 넘으면 틀림)
- **AI 경영 인사이트**: 이번 달 합계를 DB 함수로 계산
  - 덤으로 해결: `isAfter(1일)` 때문에 **매월 1일 거래가 이번 달 합계에서 빠지던 버그**
- 테스트: `test/transaction_summary_test.dart` (6케이스)

### 3번 묶음 상세 (2026-10-19)

- **⑥ 저장 칸 허용 목록**: `lib/models/db_columns.dart` — 테이블별로 보낼 칸만 고르는 `toInsertJson()` / `toUpdateJson()`. 서비스 9곳의 `data.remove(...)` 제거. `test/db_columns_test.dart`가 DB 스키마 스냅샷과 비교
- **⑦ 알림**: `lib/utils/snackbars.dart` — `context.showSuccess / showError / showInfo`, 44곳 교체
- **⑦ 거래 입력 공용 위젯**: `lib/widgets/transaction_entry_fields.dart` (`TransactionEntry` + `TransactionEntryFields`)
  - 함께 맞춘 차이: 다건 입력의 수량 단위가 항상 "개"이던 것 → 품목 단위, 다건 입력이 0·음수를 통과시키던 것 → 0보다 큰 수만
  - 다건 입력: 상단 "전체 저장" 버튼이 흰 글자라 한지색 상단 바에서 안 보이던 문제(리브랜딩 후) 수정, 사업장 로딩 중 저장 실패하던 문제 수정
- **⑧ 큰 화면 분리**: 거래처 상세 → `customer_detail_sections.dart`(상단 잔액 헤더, 거래 목록)
- **청소**: `screenshot` 패키지·`shareMultipleWidgets` 삭제, freezed `@JsonKey` 경고는 `analysis_options.yaml`에서 끔(freezed 공식 안내), `use_build_context_synchronously` 수정 → 분석 경고 0건
