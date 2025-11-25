import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

/// 공유 서비스
///
/// 거래 내역을 이미지로 생성하여 공유합니다.
class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  /// 거래 내역을 이미지로 공유
  Future<void> shareTransactionReceipt({
    required String businessName,
    required String businessPhone,
    required String customerName,
    required List<Transaction> transactions,
    required double balance,
  }) async {
    try {
      // 1. 영수증 위젯 생성
      final receiptWidget = _buildReceiptWidget(
        businessName: businessName,
        businessPhone: businessPhone,
        customerName: customerName,
        transactions: transactions,
        balance: balance,
      );

      // 2. 위젯을 이미지로 캡처
      final imageBytes = await _screenshotController.captureFromWidget(
        receiptWidget,
        pixelRatio: 3.0,
        context: null,
      );

      // 3. 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/receipt_$timestamp.png');
      await file.writeAsBytes(imageBytes);

      // 4. 공유 시트 열기
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '[$businessName] 거래 명세서\n거래처: $customerName',
        subject: '거래 명세서',
      );
    } catch (e) {
      print('공유 실패: $e');
      rethrow;
    }
  }

  /// 영수증 위젯 생성
  Widget _buildReceiptWidget({
    required String businessName,
    required String businessPhone,
    required String customerName,
    required List<Transaction> transactions,
    required double balance,
  }) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          const Text(
            '💼 거래 명세서',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // 사업장 정보
          Text(
            businessName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '📞 $businessPhone',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // 거래처 정보
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '거래처:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 날짜
          Text(
            '📅 ${Formatters.formatYearMonth(DateTime.now())}',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // 구분선
          const Divider(thickness: 2, color: Colors.black54),

          // 거래 내역
          ...transactions.map((tx) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.formatDateShort(tx.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              tx.type == TransactionType.receivable
                                  ? '💰 받을 돈'
                                  : '💸 준 돈',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (tx.product != null) ...{
                              const SizedBox(width: 8),
                              Text(
                                '(${tx.product!.name})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            },
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${tx.type == TransactionType.receivable ? '+' : '-'}'
                      '${Formatters.formatAmount(tx.amount)}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tx.type == TransactionType.receivable
                            ? const Color(0xFF388E3C)
                            : const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              )),

          // 구분선
          const Divider(thickness: 2, color: Colors.black54),
          const SizedBox(height: 8),

          // 잔액
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balance >= 0
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: balance >= 0
                    ? const Color(0xFFA5D6A7)
                    : const Color(0xFFEF9A9A),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '📊 현재 잔액',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.formatAmount(balance.abs())}원',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0
                        ? const Color(0xFF388E3C)
                        : const Color(0xFFD32F2F),
                  ),
                ),
                Text(
                  balance >= 0 ? '(받을 돈)' : '(줄 돈)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 푸터
          Text(
            '${Formatters.formatDate(DateTime.now())} 발행',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
