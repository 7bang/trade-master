import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'transaction_pages.dart';

/// 데이터가 바뀐 뒤 다시 불러올 Provider를 한 곳에서 관리한다.
///
/// 화면에서는 `ref.invalidate(...)`를 직접 나열하지 말고 아래 함수만 호출한다.
/// 새 Provider를 추가하면 여기에 함께 등록해야 화면 간 데이터가 어긋나지 않는다.
extension DataRefresh on WidgetRef {
  /// 거래 추가·수정·삭제 후 — 거래 목록, 거래내역 탭, 거래처 잔액
  void refreshTransactions() {
    invalidate(transactionPagesProvider);
    invalidate(transactionProvider);
    invalidate(statementDataProvider);
    invalidate(customersProvider);
    invalidate(customerProvider);
  }

  /// 거래처 추가·수정·삭제 후 — 거래처 목록·상세, 거래처 이름이 붙는 거래 목록
  void refreshCustomers() {
    invalidate(customersProvider);
    invalidate(customerProvider);
    invalidate(transactionPagesProvider);
    invalidate(statementDataProvider);
  }

  /// 품목 추가·수정·삭제 후
  void refreshProducts() {
    invalidate(productsProvider);
    invalidate(productProvider);
  }

  /// 사업장 등록·수정 후 — 사업장에 딸린 데이터도 함께
  void refreshBusiness() {
    invalidate(businessByUserProvider);
    invalidate(currentBusinessProvider);
  }

  /// 전부 다시 불러오기 — 오류 화면의 "다시 시도", 당겨서 새로고침
  void refreshAll() {
    refreshBusiness();
    refreshCustomers();
    refreshProducts();
    refreshTransactions();
  }

  /// 당겨서 새로고침: 전부 다시 불러오고 [screenData]가 끝날 때까지 기다린다.
  /// 실패해도 여기서는 삼키고, 화면의 `.when(error:)`가 오류를 보여준다.
  Future<void> pullToRefresh(ProviderListenable<Future<Object?>> screenData) async {
    refreshAll();
    try {
      await read(screenData);
    } catch (_) {}
  }
}
