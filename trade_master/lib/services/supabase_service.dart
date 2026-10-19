import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_summary.dart';
import '../utils/app_exception.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ========== 인증 ==========

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } catch (e) {
      throw AppException.from(e, '회원가입');
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _client.auth
          .signInWithPassword(email: email, password: password);
    } catch (e) {
      throw AppException.from(e, '로그인');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AppException.from(e, '로그아웃');
    }
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ========== 사업장 ==========

  /// 사업장이 아직 없으면 null, 조회 자체가 실패하면(네트워크 등) [AppException]
  Future<Business?> getBusiness(String userId) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response == null ? null : Business.fromJson(response);
    } catch (e) {
      throw AppException.from(e, '사업장 조회');
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
    } catch (e) {
      throw AppException.from(e, '사업장 등록');
    }
  }

  Future<void> updateBusiness(Business business) async {
    try {
      await _client
          .from('businesses')
          .update(business.toJson())
          .eq('id', business.id);
    } catch (e) {
      throw AppException.from(e, '사업장 수정');
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
          .order('name')
          .limit(500);
      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException.from(e, '거래처 조회');
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
    } catch (e) {
      throw AppException.from(e, '거래처 조회');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    if (customer.name.trim().isEmpty) {
      throw AppException('거래처명을 입력해주세요');
    }
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
    } catch (e) {
      throw AppException.from(e, '거래처 등록');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.name.trim().isEmpty) {
      throw AppException('거래처명을 입력해주세요');
    }
    try {
      // DB에 없는 칸(balance: 조회용 잔액)과 바꾸면 안 되는 값은 제외
      final data = customer.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('balance');

      await _client
          .from('customers')
          .update(data)
          .eq('id', customer.id);
    } catch (e) {
      throw AppException.from(e, '거래처 수정');
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _client
          .from('customers')
          .update({'is_active': false})
          .eq('id', customerId);
    } catch (e) {
      throw AppException.from(e, '거래처 삭제');
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
          .order('name')
          .limit(500);
      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException.from(e, '품목 조회');
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
    } catch (e) {
      throw AppException.from(e, '품목 조회');
    }
  }

  Future<Product> createProduct(Product product) async {
    if (product.name.trim().isEmpty) {
      throw AppException('품목명을 입력해주세요');
    }
    if (product.unit.trim().isEmpty) {
      throw AppException('단위를 입력해주세요');
    }
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
    } catch (e) {
      throw AppException.from(e, '품목 등록');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id);
    } catch (e) {
      throw AppException.from(e, '품목 수정');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .update({'is_active': false})
          .eq('id', productId);
    } catch (e) {
      throw AppException.from(e, '품목 삭제');
    }
  }

  // ========== 거래 ==========

  /// 거래 목록 한 페이지 ([offset]부터 [limit]건, 최신순).
  /// 전체 합계가 필요하면 목록을 더하지 말고 [getTransactionSummary]를 쓴다.
  Future<List<Transaction>> getTransactions({
    String? customerId,
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
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

      // id까지 정렬해야 같은 날짜·시각 거래가 페이지 사이에서 겹치거나 빠지지 않는다
      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException.from(e, '거래 조회');
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
    } catch (e) {
      throw AppException.from(e, '거래 조회');
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    if (transaction.amount <= 0) {
      throw AppException('금액은 0보다 커야 합니다');
    }
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
    } catch (e) {
      throw AppException.from(e, '거래 저장');
    }
  }

  /// 여러 거래를 단일 INSERT로 저장 — 일부 실패 시 전체 롤백 보장
  Future<List<Transaction>> createTransactionsBatch(
      List<Transaction> transactions) async {
    if (transactions.isEmpty) {
      throw AppException('저장할 거래 내역이 없습니다');
    }
    for (final t in transactions) {
      if (t.amount <= 0) {
        throw AppException('모든 거래의 금액은 0보다 커야 합니다');
      }
    }
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
    } catch (e) {
      throw AppException.from(e, '거래 일괄 저장');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // DB에 없는 칸(customer, product: 조회 시 붙는 연관 정보)과 바꾸면 안 되는 값은 제외
      final data = transaction.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('customer');
      data.remove('product');

      await _client
          .from('transactions')
          .update(data)
          .eq('id', transaction.id);
    } catch (e) {
      throw AppException.from(e, '거래 수정');
    }
  }

  /// 거래 삭제 (soft delete — deleted_at 기록)
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _client
          .from('transactions')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', transactionId);
    } catch (e) {
      throw AppException.from(e, '거래 삭제');
    }
  }

  // ========== 잔액 ==========

  /// 사업장 전체 거래처 잔액을 단일 쿼리로 조회 — N+1 방지
  Future<Map<String, double>> getAllBalances(String businessId) async {
    try {
      final response = await _client.rpc(
        'get_all_balances',
        params: {'p_business_id': businessId},
      );

      final result = <String, double>{};
      for (final row in response as List) {
        result[row['customer_id'] as String] =
            (row['balance'] as num).toDouble();
      }
      return result;
    } catch (e) {
      throw AppException.from(e, '잔액 일괄 조회');
    }
  }

  Future<double> getCustomerBalance(String customerId) async {
    try {
      final response = await _client.rpc(
        'get_customer_balance',
        params: {'p_customer_id': customerId},
      );
      return (response as num).toDouble();
    } catch (e) {
      throw AppException.from(e, '잔액 조회');
    }
  }

  /// 거래 합계·건수·기간 (DB에서 계산 — 거래 수와 관계없이 정확)
  Future<TransactionSummary> getTransactionSummary({
    required String businessId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? day(DateTime? d) => d?.toIso8601String().split('T')[0];
    try {
      final response = await _client.rpc(
        'get_transaction_summary',
        params: {
          'p_business_id': businessId,
          'p_customer_id': customerId,
          'p_start': day(startDate),
          'p_end': day(endDate),
        },
      );
      return TransactionSummary.fromJson(
          (response as List).first as Map<String, dynamic>);
    } catch (e) {
      throw AppException.from(e, '거래 합계 조회');
    }
  }
}
