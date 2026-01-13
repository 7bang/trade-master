import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';

/// Supabase 서비스
///
/// 모든 백엔드 작업을 담당합니다.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // 싱글톤 패턴
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ========== 인증 ==========

  /// 회원가입
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// 로그인
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 현재 사용자 가져오기
  User? get currentUser => _client.auth.currentUser;

  /// 인증 상태 변경 스트림
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ========== 사업장 ==========

  /// 사업장 정보 조회
  Future<Business> getBusiness(String userId) async {
    final response = await _client
        .from('businesses')
        .select()
        .eq('user_id', userId)
        .single();

    return Business.fromJson(response);
  }

  /// 사업장 정보 생성
  Future<Business> createBusiness(Business business) async {
    // id, created_at, updated_at은 DB에서 자동 생성되므로 제외
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
  }

  /// 사업장 정보 수정
  Future<void> updateBusiness(Business business) async {
    await _client
        .from('businesses')
        .update(business.toJson())
        .eq('id', business.id);
  }

  // ========== 거래처 ==========

  /// 거래처 목록 조회
  Future<List<Customer>> getCustomers(String businessId) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((json) => Customer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 거래처 단일 조회
  Future<Customer> getCustomer(String customerId) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('id', customerId)
        .single();

    return Customer.fromJson(response);
  }

  /// 거래처 생성
  Future<Customer> createCustomer(Customer customer) async {
    // id, created_at, updated_at은 DB에서 자동 생성되므로 제외
    final data = customer.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('balance'); // 조회 전용 필드

    final response = await _client
        .from('customers')
        .insert(data)
        .select()
        .single();

    return Customer.fromJson(response);
  }

  /// 거래처 수정
  Future<void> updateCustomer(Customer customer) async {
    await _client
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id);
  }

  /// 거래처 삭제 (비활성화)
  Future<void> deleteCustomer(String customerId) async {
    await _client
        .from('customers')
        .update({'is_active': false})
        .eq('id', customerId);
  }

  // ========== 품목 ==========

  /// 품목 목록 조회
  Future<List<Product>> getProducts(String businessId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 품목 단일 조회
  Future<Product> getProduct(String productId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .single();

    return Product.fromJson(response);
  }

  /// 품목 생성
  Future<Product> createProduct(Product product) async {
    // id, created_at, updated_at은 DB에서 자동 생성되므로 제외
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
  }

  /// 품목 수정
  Future<void> updateProduct(Product product) async {
    await _client
        .from('products')
        .update(product.toJson())
        .eq('id', product.id);
  }

  /// 품목 삭제 (비활성화)
  Future<void> deleteProduct(String productId) async {
    await _client
        .from('products')
        .update({'is_active': false})
        .eq('id', productId);
  }

  // ========== 거래 ==========

  /// 거래 목록 조회
  Future<List<Transaction>> getTransactions({
    String? customerId,
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('transactions')
        .select('*, customer:customers(*), product:products(*)');

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    } else if (businessId != null) {
      query = query.eq('business_id', businessId);
    }

    // 날짜 필터링
    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    // 정렬: 1) 날짜 내림차순(최신순), 2) 생성시간 내림차순(같은 날짜 내에서 최근 생성순)
    final response = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 거래 단일 조회
  Future<Transaction> getTransaction(String transactionId) async {
    final response = await _client
        .from('transactions')
        .select('*, customer:customers(*), product:products(*)')
        .eq('id', transactionId)
        .single();

    return Transaction.fromJson(response);
  }

  /// 거래 생성
  Future<Transaction> createTransaction(Transaction transaction) async {
    // id, created_at, updated_at은 DB에서 자동 생성되므로 제외
    final data = transaction.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('customer'); // JOIN 데이터 (조회 전용)
    data.remove('product'); // JOIN 데이터 (조회 전용)

    final response = await _client
        .from('transactions')
        .insert(data)
        .select()
        .single();

    return Transaction.fromJson(response);
  }

  /// 거래 수정
  Future<void> updateTransaction(Transaction transaction) async {
    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }

  /// 거래 삭제
  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId);
  }

  // ========== 잔액 ==========

  /// 거래처별 잔액 조회
  Future<double> getCustomerBalance(String customerId) async {
    final response = await _client.rpc(
      'get_customer_balance',
      params: {'p_customer_id': customerId},
    );

    return (response as num).toDouble();
  }
}
