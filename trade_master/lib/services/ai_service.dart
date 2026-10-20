import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

/// AI 기능 오류 (화면에 그대로 보여줄 수 있는 메시지)
class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => message;
}

class ParsedTransaction {
  final String? customerName;
  final double amount;
  final String type; // 'receivable' | 'payable'
  final String? memo;
  final DateTime date;

  const ParsedTransaction({
    this.customerName,
    required this.amount,
    required this.type,
    this.memo,
    required this.date,
  });

  /// AI 응답 JSON → 거래 정보. 형식이 맞지 않거나 금액을 못 읽었으면 [AiException].
  factory ParsedTransaction.fromAiJson(Object? data, {required String retryHint}) {
    if (data is! Map) {
      throw const AiException('AI 응답 형식이 올바르지 않습니다. 다시 시도해주세요.');
    }
    final amount = data['amount'];
    if (amount is! num || amount <= 0) {
      throw AiException('금액을 인식하지 못했습니다. $retryHint');
    }
    final type = data['type'] == 'payable' ? 'payable' : 'receivable';
    final date = DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();

    String? optional(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;

    return ParsedTransaction(
      customerName: optional(data['customerName']),
      amount: amount.toDouble(),
      type: type,
      memo: optional(data['memo']),
      date: date,
    );
  }
}

/// 말·글자 자연어 분석 결과 (parse_text). 알아듣지 못한 항목은 null.
/// 품목·단가·금액 맞추기는 [TransactionDraft]가 한다.
class SpokenTransaction {
  final String type; // 'receivable' | 'payable'
  final DateTime date;
  final String? productName;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final double? amount;
  final String? memo;

  const SpokenTransaction({
    required this.type,
    required this.date,
    this.productName,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.amount,
    this.memo,
  });

  factory SpokenTransaction.fromAiJson(Object? data) {
    if (data is! Map) {
      throw const AiException('AI 응답 형식이 올바르지 않습니다. 다시 시도해주세요.');
    }
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    double? positive(Object? v) => v is num && v > 0 ? v.toDouble() : null;

    return SpokenTransaction(
      type: data['type'] == 'payable' ? 'payable' : 'receivable',
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      productName: text(data['productName']),
      quantity: positive(data['quantity']),
      unit: text(data['unit']),
      unitPrice: positive(data['unitPrice']),
      amount: positive(data['amount']),
      memo: text(data['memo']),
    );
  }
}

class InsightReport {
  final String summary;
  final List<String> risks;
  final List<String> recommendations;

  const InsightReport({
    required this.summary,
    required this.risks,
    required this.recommendations,
  });
}

/// Claude AI 기능. API 키는 서버(Supabase Edge Function `ai`)에만 있고,
/// 앱은 로그인 토큰으로 서버 함수를 호출한다.
class AiService {
  static const _functionName = 'ai';
  static const _timeout = Duration(seconds: 60);

  Future<Object?> _invoke(String task, Map<String, dynamic> input) async {
    try {
      final response = await Supabase.instance.client.functions
          .invoke(_functionName, body: {'task': task, 'input': input})
          .timeout(_timeout);
      final data = response.data;
      if (data is Map && data.containsKey('result')) return data['result'];
      throw const AiException('AI 응답 형식이 올바르지 않습니다. 다시 시도해주세요.');
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is String) {
        throw AiException(details['error'] as String);
      }
      throw AiException('AI 서버 오류입니다 (${e.status}). 잠시 후 다시 시도해주세요.');
    } on TimeoutException {
      throw const AiException('AI 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException('AI 서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.');
    }
  }

  String _text(Object? result) {
    final text = result is Map ? result['text'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw const AiException('AI가 빈 응답을 보냈습니다. 다시 시도해주세요.');
    }
    return text.trim();
  }

  // ── 1. 자연어 거래 입력 ──────────────────────────────────────────────────

  /// [productNames]: 사업장의 등록 품목 이름 — AI가 "광어 큰거" → "광어(대)"처럼 맞추는 데 쓴다.
  Future<SpokenTransaction> parseNaturalLanguage(
    String text, {
    List<String> productNames = const [],
  }) async {
    final result = await _invoke('parse_text', {
      'text': text,
      'products': productNames.take(100).toList(),
    });
    return SpokenTransaction.fromAiJson(result);
  }

  // ── 2. 영수증/메모 사진 → 거래 입력 ─────────────────────────────────────

  Future<ParsedTransaction> parseReceiptImage(Uint8List imageBytes) async {
    final mediaType = detectImageMediaType(imageBytes);
    if (mediaType == null) {
      throw const AiException(
          '지원하지 않는 이미지 형식입니다. JPG·PNG·GIF·WEBP 사진을 사용해주세요.');
    }
    final result = await _invoke('parse_image', {
      'mediaType': mediaType,
      'imageBase64': base64Encode(imageBytes),
    });
    return ParsedTransaction.fromAiJson(
      result,
      retryHint: '금액이 잘 보이도록 다시 촬영하거나 직접 입력해주세요.',
    );
  }

  // ── 3. AI 경영 인사이트 ──────────────────────────────────────────────────

  Future<InsightReport> getBusinessInsights(Map<String, dynamic> data) async {
    final result = await _invoke('insights', data);
    if (result is! Map ||
        result['summary'] is! String ||
        result['risks'] is! List ||
        result['recommendations'] is! List) {
      throw const AiException('AI 응답 형식이 올바르지 않습니다. 다시 시도해주세요.');
    }
    return InsightReport(
      summary: result['summary'] as String,
      risks: (result['risks'] as List).whereType<String>().toList(),
      recommendations:
          (result['recommendations'] as List).whereType<String>().toList(),
    );
  }

  // ── 4. AI 미수금 독촉 문구 ───────────────────────────────────────────────

  Future<String> generateCollectionMessage(
    Customer customer,
    double balance, {
    required String businessName,
    String? businessPhone,
  }) async {
    final result = await _invoke('collection_message', {
      'customerName': customer.name,
      'balance': balance,
      'businessName': businessName,
      if (businessPhone != null && businessPhone.trim().isNotEmpty)
        'businessPhone': businessPhone.trim(),
    });
    return _text(result);
  }
}

/// 파일 앞부분(매직 바이트)으로 Claude가 지원하는 이미지 형식을 판별한다.
/// 지원하지 않는 형식(HEIC 등)이면 null.
String? detectImageMediaType(Uint8List bytes) {
  bool startsWith(List<int> sig, [int offset = 0]) {
    if (bytes.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (bytes[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (startsWith([0x47, 0x49, 0x46, 0x38])) return 'image/gif'; // GIF8
  if (startsWith([0x52, 0x49, 0x46, 0x46]) && // RIFF....WEBP
      startsWith([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}
