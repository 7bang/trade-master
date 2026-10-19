import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../utils/app_exception.dart';
import 'providers.dart';

/// 거래 목록 조회 조건
/// - [customerId]가 있으면 그 거래처의 거래 (거래처 상세)
/// - 없으면 현재 사업장 전체 거래 (거래내역 탭)
class TransactionQuery {
  final String? customerId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionQuery({this.customerId, this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionQuery &&
          customerId == other.customerId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(customerId, startDate, endDate);
}

/// 지금까지 불러온 거래 + 이어서 불러올 수 있는지
class TransactionPage {
  final List<Transaction> items;
  final bool hasMore;
  final bool isLoadingMore;

  /// 이어서 불러오기 실패 문구 (첫 페이지 실패는 AsyncError로 표시)
  final String? loadMoreError;

  const TransactionPage({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  TransactionPage copyWith({
    List<Transaction>? items,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return TransactionPage(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

/// 거래 목록을 [pageSize]건씩 이어서 불러온다 (거래가 수천 건이어도 잘리지 않음).
class TransactionPagesNotifier
    extends FamilyAsyncNotifier<TransactionPage, TransactionQuery> {
  static const pageSize = 50;

  String? _businessId;

  @override
  Future<TransactionPage> build(TransactionQuery query) async {
    if (query.customerId == null) {
      final business = await ref.watch(currentBusinessProvider.future);
      if (business == null) {
        return const TransactionPage(items: [], hasMore: false);
      }
      _businessId = business.id;
    }
    final items = await _fetch(0);
    return TransactionPage(items: items, hasMore: items.length == pageSize);
  }

  Future<List<Transaction>> _fetch(int offset) {
    return ref.read(supabaseServiceProvider).getTransactions(
          customerId: arg.customerId,
          businessId: arg.customerId == null ? _businessId : null,
          startDate: arg.startDate,
          endDate: arg.endDate,
          limit: pageSize,
          offset: offset,
        );
  }

  /// 다음 페이지 불러오기 (목록 끝에 닿았을 때)
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final more = await _fetch(current.items.length);
      // 그 사이 새로고침됐으면 버린다 (새 목록에 이전 페이지를 붙이지 않음)
      if (!identical(state.valueOrNull?.items, current.items)) return;
      state = AsyncData(TransactionPage(
        items: [...current.items, ...more],
        hasMore: more.length == pageSize,
      ));
    } catch (e) {
      if (!identical(state.valueOrNull?.items, current.items)) return;
      state = AsyncData(current.copyWith(loadMoreError: userMessage(e)));
    }
  }
}

final transactionPagesProvider = AsyncNotifierProvider.family<
    TransactionPagesNotifier, TransactionPage, TransactionQuery>(
  TransactionPagesNotifier.new,
);
