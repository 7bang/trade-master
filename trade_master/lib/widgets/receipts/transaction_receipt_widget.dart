import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../models/customer.dart';
import '../../utils/formatters.dart';
import 'receipt_styles.dart';

/// 개별 거래 영수증 위젯
class TransactionReceiptWidget extends StatelessWidget {
  final Transaction transaction;
  final Customer customer;
  final String businessName;

  const TransactionReceiptWidget({
    super.key,
    required this.transaction,
    required this.customer,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final isReceivable = transaction.type == TransactionType.receivable;

    return Container(
      width: ReceiptStyles.receiptWidth,
      padding: const EdgeInsets.all(ReceiptStyles.paddingLarge),
      decoration: BoxDecoration(
        color: ReceiptStyles.backgroundColor,
        borderRadius: BorderRadius.circular(ReceiptStyles.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더: 제목
          Center(
            child: Column(
              children: [
                ReceiptStyles.divider(thickness: 2),
                const SizedBox(height: ReceiptStyles.paddingSmall),
                const Text(
                  '거래 영수증',
                  style: ReceiptStyles.titleStyle,
                ),
                const SizedBox(height: ReceiptStyles.paddingSmall),
                ReceiptStyles.divider(thickness: 2),
              ],
            ),
          ),

          const SizedBox(height: ReceiptStyles.paddingMedium),

          // 거래처 정보
          Text(
            '거래처: ${customer.name}',
            style: ReceiptStyles.headerStyle,
          ),
          if (customer.phone != null) ...[
            const SizedBox(height: ReceiptStyles.lineSpacing),
            Text(
              '연락처: ${customer.phone}',
              style: ReceiptStyles.bodyStyle,
            ),
          ],

          const SizedBox(height: ReceiptStyles.paddingMedium),

          // 거래 날짜
          ReceiptStyles.buildRow(
            '날짜',
            Formatters.formatDateKorean(transaction.date),
          ),

          const SizedBox(height: ReceiptStyles.paddingSmall),

          // 거래 유형
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('거래 유형', style: ReceiptStyles.bodyStyle),
              Row(
                children: [
                  Text(
                    isReceivable ? '받을 돈' : '줄 돈',
                    style: isReceivable
                        ? ReceiptStyles.receivableStyle
                        : ReceiptStyles.payableStyle,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isReceivable
                        ? ReceiptStyles.receivableColor
                        : ReceiptStyles.payableColor,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: ReceiptStyles.paddingMedium),
          ReceiptStyles.dashedDivider(),
          const SizedBox(height: ReceiptStyles.paddingMedium),

          // 품목 정보 (있는 경우)
          if (transaction.product != null) ...[
            ReceiptStyles.buildRow(
              '품목',
              transaction.product!.name,
              isBold: true,
            ),
            if (transaction.quantity != null)
              ReceiptStyles.buildRow(
                '수량',
                '${transaction.quantity}${transaction.product?.unit ?? '개'}',
              ),
            if (transaction.unitPrice != null)
              ReceiptStyles.buildRow(
                '단가',
                Formatters.formatCurrency(transaction.unitPrice!),
              ),
            const SizedBox(height: ReceiptStyles.paddingSmall),
          ],

          // 금액 (강조)
          ReceiptStyles.divider(thickness: 2),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('금액', style: ReceiptStyles.bodyBoldStyle),
              Text(
                Formatters.formatCurrency(transaction.amount),
                style: ReceiptStyles.amountStyle.copyWith(
                  color: isReceivable
                      ? ReceiptStyles.receivableColor
                      : ReceiptStyles.payableColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          ReceiptStyles.divider(thickness: 2),

          // 메모 (있는 경우)
          if (transaction.memo != null && transaction.memo!.isNotEmpty) ...[
            const SizedBox(height: ReceiptStyles.paddingMedium),
            const Text('메모:', style: ReceiptStyles.bodyBoldStyle),
            const SizedBox(height: ReceiptStyles.lineSpacing),
            Container(
              padding: const EdgeInsets.all(ReceiptStyles.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(ReceiptStyles.borderRadius / 2),
              ),
              child: Text(
                transaction.memo!,
                style: ReceiptStyles.bodyStyle,
              ),
            ),
          ],

          const SizedBox(height: ReceiptStyles.paddingLarge),

          // 푸터: 발행처
          Center(
            child: Column(
              children: [
                ReceiptStyles.dashedDivider(),
                const SizedBox(height: ReceiptStyles.paddingSmall),
                Text(
                  '발행: $businessName',
                  style: ReceiptStyles.smallStyle,
                ),
                const SizedBox(height: ReceiptStyles.lineSpacing),
                const Text(
                  '거래클립',
                  style: ReceiptStyles.smallStyle,
                ),
                const SizedBox(height: ReceiptStyles.paddingSmall),
                ReceiptStyles.dashedDivider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
