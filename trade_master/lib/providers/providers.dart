import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/share_service.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';

// ========== 서비스 Providers ==========

final supabaseServiceProvider = Provider((ref) => SupabaseService());
final shareServiceProvider = Provider((ref) => ShareService());

// ========== 인증 Providers ==========

final currentUserProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges.map((state) => state.session?.user);
});

// ========== 사업장 Providers ==========

final currentBusinessProvider = FutureProvider<Business?>((ref) async {
  ref.keepAlive();
  final service = ref.watch(supabaseServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  try {
    return await service.getBusiness(user.id);
  } catch (e) {
    return null;
  }
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

/// 거래 목록 Provider (거래처별)
final transactionsProvider = FutureProvider.family<List<Transaction>, String>(
  (ref, customerId) async {
    ref.keepAlive();
    final service = ref.watch(supabaseServiceProvider);
    return service.getTransactions(customerId: customerId);
  },
);

/// 특정 거래 Provider
final transactionProvider = FutureProvider.family<Transaction, String>(
  (ref, transactionId) async {
    ref.keepAlive();
    final service = ref.watch(supabaseServiceProvider);
    return service.getTransaction(transactionId);
  },
);
