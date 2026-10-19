import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/share_service.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_summary.dart';

// ========== 서비스 Providers ==========

final supabaseServiceProvider = Provider((ref) => SupabaseService());
final shareServiceProvider = Provider((ref) => ShareService());

// ========== 인증 Providers ==========

final currentUserProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges.map((state) => state.session?.user);
});

// ========== 사업장 Providers ==========

/// 사용자별 사업장 (라우터와 화면이 같은 캐시를 사용)
/// - null: 아직 사업장을 등록하지 않음 → 사업장 등록 화면
/// - 오류: 네트워크 등 조회 실패 → 등록 화면으로 보내지 않고 오류 표시
final businessByUserProvider = FutureProvider.family<Business?, String>(
  (ref, userId) => ref.watch(supabaseServiceProvider).getBusiness(userId),
);

final currentBusinessProvider = FutureProvider<Business?>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  // 앱 시작 직후 인증 스트림이 아직 값을 내기 전에는 현재 세션으로 보완
  final userId =
      ref.watch(currentUserProvider).value?.id ?? service.currentUser?.id;
  if (userId == null) return null;
  return ref.watch(businessByUserProvider(userId).future);
});

// ========== 거래처 Providers ==========

/// 거래처 목록 + 잔액을 단일 쿼리로 조회 (N+1 제거)
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return [];

  // 거래처 목록과 전체 잔액을 병렬 조회
  final customersFuture = service.getCustomers(business.id);
  final balancesFuture = service.getAllBalances(business.id);

  final customers = await customersFuture;
  final balances = await balancesFuture;

  return customers
      .map((c) => c.copyWith(balance: balances[c.id] ?? 0))
      .toList();
});

/// 특정 거래처 Provider — 잔액 조회 실패 시 에러 전파 (stale 반환 제거)
final customerProvider = FutureProvider.family<Customer, String>(
  (ref, customerId) async {
    ref.keepAlive();
    final service = ref.watch(supabaseServiceProvider);
    final customer = await service.getCustomer(customerId);
    final balance = await service.getCustomerBalance(customerId);
    return customer.copyWith(balance: balance);
  },
);

// ========== 품목 Providers ==========

final productsProvider = FutureProvider<List<Product>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);
  if (business == null) return [];
  return service.getProducts(business.id);
});

final productProvider = FutureProvider.family<Product, String>(
  (ref, productId) async {
    ref.keepAlive();
    final service = ref.watch(supabaseServiceProvider);
    return service.getProduct(productId);
  },
);

// ========== 거래 Providers ==========
// 거래 목록(페이지 단위)은 transaction_pages.dart 의 transactionPagesProvider

/// 특정 거래 Provider
final transactionProvider = FutureProvider.family<Transaction, String>(
  (ref, transactionId) async {
    ref.keepAlive();
    final service = ref.watch(supabaseServiceProvider);
    return service.getTransaction(transactionId);
  },
);

/// 거래처 내역서 데이터: 최근 거래 [statementMaxRows]건 + 전체 합계(DB 계산)
class StatementData {
  static const statementMaxRows = 50;

  final List<Transaction> recent;
  final TransactionSummary summary;

  const StatementData({required this.recent, required this.summary});

  bool get isLimited => summary.count > recent.length;
}

final statementDataProvider = FutureProvider.family<StatementData, String>(
  (ref, customerId) async {
    final service = ref.watch(supabaseServiceProvider);
    final customer = await ref.watch(customerProvider(customerId).future);
    final results = await Future.wait([
      service.getTransactions(
        customerId: customerId,
        limit: StatementData.statementMaxRows,
      ),
      service.getTransactionSummary(
        businessId: customer.businessId,
        customerId: customerId,
      ),
    ]);
    return StatementData(
      recent: results[0] as List<Transaction>,
      summary: results[1] as TransactionSummary,
    );
  },
);
