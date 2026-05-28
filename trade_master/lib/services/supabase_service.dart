import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ========== 인증 ==========

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception('회원가입 실패: ${e.message}');
    } catch (_) {
      throw Exception('회원가입 중 오류가 발생했습니다');
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _client.auth
          .signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception('로그인 실패: ${e.message}');
    } catch (_) {
      throw Exception('로그인 중 오류가 발생했습니다');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw Exception('로그아웃 중 오류가 발생했습니다');
    }
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ========== 사업장 ==========

  Future<Business> getBusiness(String userId) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .single();
      return Business.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('사업장 정보를 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('사업장 조회 중 오류가 발생했습니다');
    }
  }

  Future<Business> createBusiness(Business business) async {
    try {
      final data = business.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('businesses')
          .insert(data)
          .select()
          .single();
      return Business.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('사업장 등록 실패: ${e.message}');
    } catch (_) {
      throw Exception('사업장 등록 중 오류가 발생했습니다');
    }
  }

  Future<void> updateBusiness(Business business) async {
    try {
      await _client
          .from('businesses')
          .update(business.toJson())
          .eq('id', business.id);
    } on PostgrestException catch (e) {
      throw Exception('사업장 수정 실패: ${e.message}');
    } catch (_) {
      throw Exception('사업장 수정 중 오류가 발생했습니다');
    }
  }

  // ========== 거래처 ==========

  Future<List<Customer>> getCustomers(String businessId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .order('name');
      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('거래처 목록을 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('거래처 조회 중 오류가 발생했습니다');
    }
  }

  Future<Customer> getCustomer(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();
      return Customer.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('거래처 정보를 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('거래처 조회 중 오류가 발생했습니다');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final data = customer.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('balance');

      final response = await _client
          .from('customers')
          .insert(data)
          .select()
          .single();
      return Customer.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('거래처 등록 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래처 등록 중 오류가 발생했습니다');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _client
          .from('customers')
          .update(customer.toJson())
          .eq('id', customer.id);
    } on PostgrestException catch (e) {
      throw Exception('거래처 수정 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래처 수정 중 오류가 발생했습니다');
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _client
          .from('customers')
          .update({'is_active': false})
          .eq('id', customerId);
    } on PostgrestException catch (e) {
      throw Exception('거래처 삭제 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래처 삭제 중 오류가 발생했습니다');
    }
  }

  // ========== 품목 ==========

  Future<List<Product>> getProducts(String businessId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .order('name');
      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('품목 목록을 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('품목 조회 중 오류가 발생했습니다');
    }
  }

  Future<Product> getProduct(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .single();
      return Product.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('품목 정보를 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('품목 조회 중 오류가 발생했습니다');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final data = product.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('products')
          .insert(data)
          .select()
          .single();
      return Product.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('품목 등록 실패: ${e.message}');
    } catch (_) {
      throw Exception('품목 등록 중 오류가 발생했습니다');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id);
    } on PostgrestException catch (e) {
      throw Exception('품목 수정 실패: ${e.message}');
    } catch (_) {
      throw Exception('품목 수정 중 오류가 발생했습니다');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .update({'is_active': false})
          .eq('id', productId);
    } on PostgrestException catch (e) {
      throw Exception('품목 삭제 실패: ${e.message}');
    } catch (_) {
      throw Exception('품목 삭제 중 오류가 발생했습니다');
    }
  }

  // ========== 거래 ==========

  Future<List<Transaction>> getTransactions({
    String? customerId,
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('*, customer:customers(*), product:products(*)');

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      } else if (businessId != null) {
        query = query.eq('business_id', businessId);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      // 삭제된 거래 제외
      query = query.isFilter('deleted_at', null);

      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('거래 목록을 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('거래 조회 중 오류가 발생했습니다');
    }
  }

  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response = await _client
          .from('transactions')
          .select('*, customer:customers(*), product:products(*)')
          .eq('id', transactionId)
          .single();
      return Transaction.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('거래 정보를 불러올 수 없습니다: ${e.message}');
    } catch (_) {
      throw Exception('거래 조회 중 오류가 발생했습니다');
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final data = transaction.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('customer');
      data.remove('product');

      final response = await _client
          .from('transactions')
          .insert(data)
          .select()
          .single();
      return Transaction.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('거래 저장 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래 저장 중 오류가 발생했습니다');
    }
  }

  /// 여러 거래를 단일 INSERT로 저장 — 일부 실패 시 전체 롤백 보장
  Future<List<Transaction>> createTransactionsBatch(
      List<Transaction> transactions) async {
    try {
      final dataList = transactions.map((transaction) {
        final data = transaction.toJson();
        data.remove('id');
        data.remove('created_at');
        data.remove('updated_at');
        data.remove('customer');
        data.remove('product');
        return data;
      }).toList();

      final response = await _client
          .from('transactions')
          .insert(dataList)
          .select();

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('거래 일괄 저장 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래 저장 중 오류가 발생했습니다');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _client
          .from('transactions')
          .update(transaction.toJson())
          .eq('id', transaction.id);
    } on PostgrestException catch (e) {
      throw Exception('거래 수정 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래 수정 중 오류가 발생했습니다');
    }
  }

  /// 거래 삭제 (soft delete — deleted_at 기록)
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _client
          .from('transactions')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', transactionId);
    } on PostgrestException catch (e) {
      throw Exception('거래 삭제 실패: ${e.message}');
    } catch (_) {
      throw Exception('거래 삭제 중 오류가 발생했습니다');
    }
  }

  // ========== 잔액 ==========

  Future<double> getCustomerBalance(String customerId) async {
    try {
      final response = await _client.rpc(
        'get_customer_balance',
        params: {'p_customer_id': customerId},
      );
      return (response as num).toDouble();
    } on PostgrestException catch (e) {
      throw Exception('잔액 조회 실패: ${e.message}');
    } catch (_) {
      throw Exception('잔액 조회 중 오류가 발생했습니다');
    }
  }
}
