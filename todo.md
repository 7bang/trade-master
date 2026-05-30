# 거래클립(TradeClip) 개선 TODO

> 소상공인용 거래장 관리 Flutter 앱 (Supabase 백엔드) · 현재 앱 버전 **1.1.0+6**
> MVP Phase 1 기능은 구현 완료된 상태이며, 아래는 **품질·안정성·성능 점검 결과**를 우선순위별로 정리한 것이다.
> 각 항목에 영역 태그를 병기했다: `[데이터]` `[성능]` `[UI]` `[설정]` `[보안]` `[테스트]` `[접근성]` `[문서]` `[정리]`

---

## P0 — 긴급 / 안정성 (출시 전 필수)

- [x] **[데이터] 서비스 계층 예외 처리 전무**
  `lib/services/supabase_service.dart` 전 메서드에 `PostgrestException`/`AuthException` try-catch 추가. 한국어 에러 메시지로 래핑.

- [x] **[데이터] 다건 거래 저장 부분 실패**
  `createTransactionsBatch(List<Transaction>)` 신설 — 단일 INSERT로 전체를 저장해 원자성 확보. `multi_transaction_form_screen.dart`의 루프 제거 후 해당 메서드 사용.

- [x] **[데이터] 거래 soft delete 전환**
  마이그레이션 `supabase/migrations/20260529000000_soft_delete_transactions.sql` 추가 (`deleted_at` 컬럼, 부분 인덱스). `deleteTransaction`을 hard DELETE → `deleted_at` 업데이트로 변경. `getTransactions`에 `.isFilter('deleted_at', null)` 추가. `get_customer_balance` RPC에 `deleted_at IS NULL` 조건 추가. `database-schema.sql` 동기화 완료.

---

## P1 — 중요 (성능 · 정확성 · 일관성)

- [x] **[성능] 잔액 조회 N+1 쿼리**
  `get_all_balances(p_business_id)` RPC 신설(마이그레이션 `20260531000000`). `supabase_service.dart`에 `getAllBalances()` 추가. `providers.dart`에서 거래처 목록+잔액 병렬 단일 호출로 교체.

- [x] **[성능] 페이지네이션 — 서비스 limit 추가 (UI 무한스크롤은 Phase 2)**
  `getCustomers`·`getProducts` `.limit(500)`, `getTransactions` `.limit(1000)` 추가해 메모리 위험 방지. UI 무한스크롤은 사용자 규모 증가 시 별도 진행.

- [x] **[데이터] 잔액 조회 실패 시 조용한 stale 반환**
  `customerProvider`의 try-catch 제거 → 잔액 조회 실패 시 에러가 UI `.when(error:)` 핸들러로 전파.

- [x] **[성능] 캐싱 부재**
  전체 FutureProvider / FutureProvider.family에 `ref.keepAlive()` 추가 — 화면 이탈 후에도 데이터 유지, `ref.invalidate()` 호출 시 정상 갱신.

- [x] **[데이터] 스키마 기본값 불일치**
  마이그레이션 `20260531000000`에서 `ALTER TABLE products ALTER COLUMN unit SET DEFAULT '개'` 적용. DB·Dart 모델·스키마 참조 파일 모두 '개'로 통일.

- [x] **[설정] anon key 하드코딩 + dotenv 미사용**
  `supabase_config.dart`를 dotenv getter로 전환. `main.dart`에 `dotenv.load()` 추가. 하드코딩 상수 제거.

---

## P2 — 리팩토링 (코드 품질)

- [ ] **[UI] 대형 화면 파일 분해**
  `customer_detail_screen.dart`(640), `multi_transaction_form_screen.dart`(636), `transaction_form_screen.dart`(598), `transaction_detail_screen.dart`(540), `product_form_screen.dart`(481).
  → 폼 필드/섹션을 하위 위젯으로 추출.

- [ ] **[UI] 중복 UI 컴포넌트 추출**
  `CustomerSelectionDialog`, `BalanceIndicator`(잔액 색/아이콘), `EmptyStateView`, `ErrorView`, `LoadingView`가 여러 화면에 복붙돼 있음.
  → 공통 위젯으로 추출.

- [ ] **[정리] 죽은 코드 삭제**
  `lib/services/share_service.dart.disabled`, `lib/utils/share_utils.dart.disabled`, `lib/widgets/receipt_widget.dart.disabled`(합계 약 847줄). git 히스토리로 대체 가능.
  → 제거.

- [ ] **[UI] 다크테마 정리**
  `lib/config/app_theme.dart`에 다크테마가 정의됐으나 `lib/main.dart:66`에서 `ThemeMode.light` 강제.
  → 완성하거나 미사용 코드 제거.

- [ ] **[UI] 하드코딩 문자열 중앙화**
  전 화면에 한국어 문자열이 인라인.
  → `strings.dart` 또는 `intl`/.arb로 분리(향후 다국어 대비).

- [ ] **[UI] 타이밍 의존 코드 제거**
  `multi_transaction_form_screen.dart`의 `Future.delayed(150ms)`(Form 빌드 대기)는 취약한 타이밍 의존 코드.
  → 명시적 상태/검증으로 대체.

---

## P3 — 품질 / 테스트 / 문서

- [ ] **[테스트] 커버리지 확보**
  `test/widget_test.dart`는 보일러플레이트뿐.
  → `formatters`/`validators` 단위 테스트, `SupabaseService` 모킹 테스트, 핵심 화면(거래 입력 자동계산) 위젯 테스트 추가.

- [ ] **[보안] RPC 권한 강화**
  `get_customer_balance`가 `SECURITY DEFINER`이나 호출자 소유권 미검증(현재 transactions RLS로만 간접 보호).
  → business 소유권 명시 검증.

- [ ] **[데이터] 서비스 경계 입력 검증**
  amount>0, 필수 FK 등 DB 호출 전 검증 추가.

- [ ] **[접근성] a11y 보강**
  잔액 인디케이터 등에 `Semantics` 라벨, 긴 품목명 드롭다운 오버플로우/검색 처리.

- [ ] **[문서] 문서 최신화**
  작업 반영해 `CLAUDE.md`, `trade-master-PRD.md`, `trade-master-tech.md` 갱신(현재 날짜·버전 정합화).

---

## Phase 2 — 신규 기능 로드맵 (PRD 기준, 미착수)

- [ ] **멀티유저 / 직원 관리** — 사업장 단위 다중 사용자 권한.
- [ ] **분석 · 차트 대시보드** — 매출/미수금 추이 시각화.
- [ ] **알림 · 리마인더** — 미수금 회수 등 푸시.
- [ ] **재고 관리** — 품목 수량 추적.
- [ ] **PDF 내보내기** — 거래 50건+ 명세서(현재 이미지 공유만, 50건 제한 안내 존재).
- [ ] **오프라인 모드 / 동기화 큐** — 네트워크 단절 대비.

---

_최종 작성: 2026-05-29 · 코드 변경 없이 점검 결과만 문서화. 실제 수정은 우선순위를 골라 별도 진행._
