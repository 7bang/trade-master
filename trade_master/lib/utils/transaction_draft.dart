import '../models/product.dart';
import '../models/transaction.dart';
import '../services/ai_service.dart';

/// AI 분석 결과(말·글자)를 저장 가능한 거래 초안으로 정리한다.
/// 규칙은 plan-voice-input.md 3장 — 화면과 분리된 순수 로직이라 테스트로 검증한다.
///
/// - 3.2 금액 맞추기: 수량·단가·총액 중 아는 값으로 나머지를 계산 (말한 총액 우선)
/// - 3.3 품목 고르기: 같은 이름 → 포함된 이름 → 없으면 새 품목
/// - 3.4 단가: 말한 단가 > 품목 기본 단가, 후보가 여럿이면 기본 단가 높은 것 → 최근 등록
class TransactionDraft {
  TransactionType type;
  DateTime date;
  String? memo;

  /// 등록된 품목 (선택됨)
  Product? product;

  /// 등록된 품목이 없을 때 새로 만들 이름 — 저장할 때 품목 생성
  String? newProductName;

  /// 같은 이름으로 걸린 다른 품목들 (결과 카드에서 바꿀 수 있게)
  List<Product> candidates;

  /// 새 품목일 때 쓸 단위 (등록 품목이면 그 품목의 단위)
  String newProductUnit;

  double? quantity;
  double? unitPrice;
  double? amount;

  /// 말한 단가와 총액÷수량이 달라 총액 기준으로 단가를 다시 계산함
  bool priceMismatch;

  TransactionDraft({
    this.type = TransactionType.receivable,
    DateTime? date,
    this.memo,
    this.product,
    this.newProductName,
    this.candidates = const [],
    this.newProductUnit = '개',
    this.quantity,
    this.unitPrice,
    this.amount,
    this.priceMismatch = false,
  }) : date = date ?? DateTime.now();

  // ── 상태 ───────────────────────────────────────────────────────────────

  /// 품목을 쓰는 거래인지 (아니면 총액만 있는 직접 입력 거래)
  bool get usesProduct => product != null || newProductName != null;
  bool get isNewProduct => product == null && newProductName != null;
  String? get productName => product?.name ?? newProductName;
  String get unit => product?.unit ?? newProductUnit;

  /// 등록 품목의 기본 단가 (말한 단가와 비교 표시용)
  double? get defaultUnitPrice => product?.defaultUnitPrice;

  bool get unitPriceDiffersFromDefault =>
      defaultUnitPrice != null &&
      unitPrice != null &&
      (unitPrice! - defaultUnitPrice!).abs() >= 0.5;

  bool get amountMissing => amount == null || amount! <= 0;
  bool get quantityMissing => usesProduct && (quantity == null || quantity! <= 0);
  bool get unitPriceMissing =>
      usesProduct && (unitPrice == null || unitPrice! <= 0);

  /// 저장 가능: 총액이 있고, 품목 거래면 수량·단가도 있음
  bool get canSave => !amountMissing && !quantityMissing && !unitPriceMissing;

  // ── AI 결과 → 초안 ─────────────────────────────────────────────────────

  factory TransactionDraft.fromSpoken(
    SpokenTransaction s,
    List<Product> products,
  ) {
    final draft = TransactionDraft(
      type: s.type == 'payable'
          ? TransactionType.payable
          : TransactionType.receivable,
      date: s.date,
      memo: s.memo,
      newProductUnit: normalizeUnit(s.unit) ?? '개',
    );

    final name = s.productName;
    final hasQuantity = s.quantity != null && s.quantity! > 0;

    // 품목 이름은 들었지만 수량이 없으면 품목 거래로 만들 수 없음 → 총액만, 품목명은 메모로 보존
    if (name != null && !hasQuantity && s.amount != null) {
      draft.amount = s.amount;
      draft.memo = [name, s.memo].whereType<String>().join(' · ');
      return draft;
    }

    if (name != null) {
      final matches = matchProducts(name, products);
      if (matches.isNotEmpty) {
        draft.product = matches.first;
        draft.candidates = matches;
      } else {
        draft.newProductName = name;
      }
    }

    draft.quantity = hasQuantity ? s.quantity : null;
    draft._reconcile(spokenUnitPrice: s.unitPrice, spokenAmount: s.amount);
    return draft;
  }

  /// 3.2 금액 맞추기 (+ 3.4 말하지 않은 단가는 품목 기본 단가)
  void _reconcile({double? spokenUnitPrice, double? spokenAmount}) {
    final q = quantity;
    if (!usesProduct || q == null) {
      amount = spokenAmount;
      return;
    }
    final price = spokenUnitPrice ?? defaultUnitPrice;

    if (spokenAmount != null) {
      amount = spokenAmount;
      final computed = _round(spokenAmount / q);
      priceMismatch =
          spokenUnitPrice != null && (spokenUnitPrice - computed).abs() >= 0.5;
      unitPrice = computed;
    } else if (price != null) {
      unitPrice = price;
      amount = _round(q * price);
    } else {
      unitPrice = null;
      amount = null;
    }
  }

  // ── 결과 카드에서 고치기 ───────────────────────────────────────────────

  void setQuantity(double? value) {
    quantity = value;
    if (value != null && unitPrice != null) amount = _round(value * unitPrice!);
    priceMismatch = false;
  }

  void setUnitPrice(double? value) {
    unitPrice = value;
    if (value != null && quantity != null) amount = _round(quantity! * value);
    priceMismatch = false;
  }

  /// 총액을 고치면 단가를 다시 계산 (수량이 있을 때)
  void setAmount(double? value) {
    amount = value;
    if (value != null && usesProduct && quantity != null && quantity! > 0) {
      unitPrice = _round(value / quantity!);
    }
    priceMismatch = false;
  }

  /// 등록 품목으로 바꾸기 — 단가가 비어 있으면 기본 단가로 채움
  void selectProduct(Product value) {
    product = value;
    newProductName = null;
    if (unitPrice == null && value.defaultUnitPrice != null) {
      setUnitPrice(value.defaultUnitPrice);
    }
  }

  /// 새 품목으로 바꾸기
  void useNewProduct(String name, {String? unit}) {
    product = null;
    newProductName = name.trim();
    if (unit != null && unit.trim().isNotEmpty) {
      newProductUnit = normalizeUnit(unit) ?? unit.trim();
    }
  }

  /// 품목 없이 총액만 (직접 입력 거래)
  void clearProduct() {
    product = null;
    newProductName = null;
    candidates = const [];
    quantity = null;
    unitPrice = null;
    priceMismatch = false;
  }

  /// 저장할 거래 — 새 품목이면 [productId]에 방금 만든 품목 id를 넘긴다
  Transaction toTransaction({
    required String businessId,
    required String customerId,
    String? productId,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: '',
      businessId: businessId,
      customerId: customerId,
      type: type,
      productId: usesProduct ? (productId ?? product?.id) : null,
      quantity: usesProduct ? quantity : null,
      unitPrice: usesProduct ? unitPrice : null,
      amount: amount ?? 0,
      date: date,
      memo: (memo == null || memo!.trim().isEmpty) ? null : memo!.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}

// ── 규칙 함수 (테스트 대상) ──────────────────────────────────────────────────

String _normalizeName(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[\s()\[\]\-_.·,]'), '');

/// 3.3 품목 고르기 + 3.4 후보 정렬.
/// 같은 이름이 있으면 그것들만, 없으면 이름이 서로 포함되는 품목.
/// 정렬: 기본 단가 높은 순 → 최근 등록 순.
List<Product> matchProducts(String spokenName, List<Product> products) {
  final key = _normalizeName(spokenName);
  if (key.isEmpty) return const [];

  final active = products.where((p) => p.isActive).toList();
  var matches = active.where((p) => _normalizeName(p.name) == key).toList();
  if (matches.isEmpty) {
    matches = active.where((p) {
      final name = _normalizeName(p.name);
      return name.isNotEmpty && (name.contains(key) || key.contains(name));
    }).toList();
  }

  matches.sort((a, b) {
    final byPrice =
        (b.defaultUnitPrice ?? -1).compareTo(a.defaultUnitPrice ?? -1);
    if (byPrice != 0) return byPrice;
    return b.createdAt.compareTo(a.createdAt);
  });
  return matches;
}

/// 말로 한 단위 → 저장 단위. "키로·킬로·키로그램" → kg
String? normalizeUnit(String? unit) {
  if (unit == null) return null;
  final u = unit.trim().toLowerCase();
  if (u.isEmpty) return null;
  const kg = {'kg', '키로', '킬로', '키로그램', '킬로그램', 'kilo', 'kilogram'};
  const g = {'g', '그램', 'gram'};
  if (kg.contains(u)) return 'kg';
  if (g.contains(u)) return 'g';
  return unit.trim();
}
