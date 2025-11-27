import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../models/customer.dart';
import '../../utils/formatters.dart';
import 'receipt_styles.dart';

/// 거래처 내역서 위젯
class CustomerStatementWidget extends StatelessWidget {
  final Customer customer;
  final List<Transaction> transactions;
  final DateTime startDate;
  final DateTime endDate;
  final String businessName;

  const CustomerStatementWidget({
    super.key,
    required this.customer,
    required this.transactions,
    required this.startDate,
    required this.endDate,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    // 최대 50건 제한
    const maxTransactions = 50;
    final isLimited = transactions.length > maxTransactions;
    final displayTransactions = isLimited
        ? transactions.take(maxTransactions).toList()
        : transactions;

    // 받을 돈 / 줄 돈 합계 계산 (전체 거래 기준)
    double totalReceivable = 0;
    double totalPayable = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.receivable) {
        totalReceivable += transaction.amount;
      } else {
        totalPayable += transaction.amount;
      }
    }

    final currentBalance = totalReceivable - totalPayable;

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
                  '거래 내역서',
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

          // 조회 기간
          ReceiptStyles.buildRow(
            '조회 기간',
            '${Formatters.formatDate(startDate)} ~ ${Formatters.formatDate(endDate)}',
          ),

          const SizedBox(height: ReceiptStyles.paddingMedium),
          ReceiptStyles.divider(thickness: 2),

          // 거래 내역 헤더
          const SizedBox(height: ReceiptStyles.paddingSmall),
          const Text(
            '[거래 내역]',
            style: ReceiptStyles.bodyBoldStyle,
          ),
          const SizedBox(height: ReceiptStyles.paddingSmall),

          // 거래 건수 및 제한 안내
          if (isLimited) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: ReceiptStyles.paddingSmall),
              child: Text(
                '※ 총 ${transactions.length}건 중 최근 $maxTransactions건만 표시',
                style: ReceiptStyles.smallStyle.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // 거래 내역 리스트
          if (displayTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: ReceiptStyles.paddingMedium),
              child: Center(
                child: Text(
                  '거래 내역이 없습니다',
                  style: ReceiptStyles.smallStyle.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...displayTransactions.map((transaction) => _buildTransactionItem(transaction)),

          const SizedBox(height: ReceiptStyles.paddingSmall),
          ReceiptStyles.divider(thickness: 2),

          // 합계
          const SizedBox(height: ReceiptStyles.paddingSmall),
          ReceiptStyles.buildAmountRow(
            '받을 돈 합계:',
            Formatters.formatCurrency(totalReceivable),
            ReceiptStyles.receivableColor,
          ),
          ReceiptStyles.buildAmountRow(
            '줄 돈 합계:',
            Formatters.formatCurrency(totalPayable),
            ReceiptStyles.payableColor,
          ),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          ReceiptStyles.divider(thickness: 2),

          // 현재 잔액 (강조)
          const SizedBox(height: ReceiptStyles.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('현재 잔액:', style: ReceiptStyles.headerStyle),
              Text(
                Formatters.formatCurrency(currentBalance.abs()),
                style: ReceiptStyles.amountStyle.copyWith(
                  color: currentBalance >= 0
                      ? ReceiptStyles.receivableColor
                      : ReceiptStyles.payableColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: ReceiptStyles.lineSpacing),
          Center(
            child: Text(
              currentBalance >= 0 ? '(받을 돈)' : '(줄 돈)',
              style: ReceiptStyles.smallStyle.copyWith(
                color: currentBalance >= 0
                    ? ReceiptStyles.receivableColor
                    : ReceiptStyles.payableColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          ReceiptStyles.divider(thickness: 2),

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
                  '거래의장인',
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

  Widget _buildTransactionItem(Transaction transaction) {
    final isReceivable = transaction.type == TransactionType.receivable;
    final dateStr = Formatters.formatDateShort(transaction.date);

    // 거래 내용 (품목 또는 메모)
    String content = '';
    if (transaction.product != null) {
      content = transaction.product!.name;
      if (transaction.quantity != null) {
        content += ' ${transaction.quantity}${transaction.product?.unit ?? '개'}';
      }
    } else if (transaction.memo != null && transaction.memo!.isNotEmpty) {
      content = transaction.memo!;
      if (content.length > 15) {
        content = '${content.substring(0, 15)}...';
      }
    } else {
      content = isReceivable ? '입금' : '출금';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // 날짜
          SizedBox(
            width: 50,
            child: Text(
              dateStr,
              style: ReceiptStyles.smallStyle,
            ),
          ),
          const SizedBox(width: ReceiptStyles.paddingSmall),

          // 내용
          Expanded(
            child: Text(
              content,
              style: ReceiptStyles.bodyStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ReceiptStyles.paddingSmall),

          // 금액
          Text(
            '${isReceivable ? '+' : '-'}${Formatters.formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontSize: ReceiptStyles.bodyFontSize,
              color: isReceivable
                  ? ReceiptStyles.receivableColor
                  : ReceiptStyles.payableColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
