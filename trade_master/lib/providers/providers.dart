import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/share_service.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';

// ========== 서비스 Providers ==========

/// Supabase 서비스 Provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

/// 공유 서비스 Provider
final shareServiceProvider = Provider((ref) => ShareService());

// ========== 인증 Providers ==========

/// 현재 사용자 Provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges.map((state) => state.session?.user);
});

// ========== 사업장 Providers ==========

/// 현재 사업장 Provider
final currentBusinessProvider = FutureProvider<Business?>((ref) async {
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

/// 거래처 목록 Provider
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);

  if (business == null) return [];

  final customers = await service.getCustomers(business.id);

  // 각 거래처의 잔액을 조회하여 추가
  final customersWithBalance = await Future.wait(
    customers.map((customer) async {
      try {
        final balance = await service.getCustomerBalance(customer.id);
        return customer.copyWith(balance: balance);
      } catch (e) {
        return customer;
      }
    }),
  );

  return customersWithBalance;
});

/// 특정 거래처 Provider
final customerProvider = FutureProvider.family<Customer, String>(
  (ref, customerId) async {
    final service = ref.watch(supabaseServiceProvider);
    final customer = await service.getCustomer(customerId);

    // 잔액 조회
    try {
      final balance = await service.getCustomerBalance(customerId);
      return customer.copyWith(balance: balance);
    } catch (e) {
      return customer;
    }
  },
);

// ========== 품목 Providers ==========

/// 품목 목록 Provider
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);

  if (business == null) return [];

  return await service.getProducts(business.id);
});

/// 특정 품목 Provider
final productProvider = FutureProvider.family<Product, String>(
  (ref, productId) async {
    final service = ref.watch(supabaseServiceProvider);
    return await service.getProduct(productId);
  },
);

// ========== 거래 Providers ==========

/// 거래 목록 Provider (거래처별)
final transactionsProvider = FutureProvider.family<List<Transaction>, String>(
  (ref, customerId) async {
    final service = ref.watch(supabaseServiceProvider);
    return await service.getTransactions(customerId: customerId);
  },
);

/// 특정 거래 Provider
final transactionProvider = FutureProvider.family<Transaction, String>(
  (ref, transactionId) async {
    final service = ref.watch(supabaseServiceProvider);
    return await service.getTransaction(transactionId);
  },
);
