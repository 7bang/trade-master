import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import 'receipt_styles.dart';

/// 견적서 / 납품서 구분
enum TradeDocumentType {
  quote('견적서', '위와 같이 견적합니다.'),
  delivery('납품서', '위와 같이 납품합니다.');

  final String title;
  final String closing;
  const TradeDocumentType(this.title, this.closing);
}

/// 견적서·납품서 품목
class TradeDocumentItem {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;

  const TradeDocumentItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  double get amount => quantity * unitPrice;
}

/// 견적서·납품서 이미지 위젯 (캡처해서 공유)
class TradeDocumentWidget extends StatelessWidget {
  final TradeDocumentType type;
  final String businessName;
  final String? businessPhone;
  final String customerName;
  final DateTime issuedAt;
  final List<TradeDocumentItem> items;
  final String? note;

  const TradeDocumentWidget({
    super.key,
    required this.type,
    required this.businessName,
    this.businessPhone,
    required this.customerName,
    required this.issuedAt,
    required this.items,
    this.note,
  });

  double get total => items.fold(0, (sum, item) => sum + item.amount);

  static String formatQuantity(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
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
          // 제목
          ReceiptStyles.divider(thickness: 2),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          Center(
            child: Text(
              type.title.split('').join(' '),
              style: ReceiptStyles.titleStyle.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          ReceiptStyles.divider(thickness: 2),
          const SizedBox(height: ReceiptStyles.paddingMedium),

          // 수신 / 공급자
          Text('$customerName 귀하', style: ReceiptStyles.headerStyle),
          const SizedBox(height: ReceiptStyles.paddingMedium),
          _infoRow('발행일', Formatters.formatDateKorean(issuedAt)),
          _infoRow('공급자', businessName),
          if (businessPhone != null && businessPhone!.isNotEmpty)
            _infoRow('연락처', Formatters.formatPhoneNumber(businessPhone!)),
          const SizedBox(height: ReceiptStyles.paddingMedium),

          // 합계 (상단 강조)
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: ReceiptStyles.paddingSmall + 4,
              horizontal: ReceiptStyles.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(ReceiptStyles.borderRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('합계 금액', style: ReceiptStyles.bodyBoldStyle),
                Text(
                  Formatters.formatCurrency(total),
                  style: ReceiptStyles.amountStyle.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: ReceiptStyles.paddingMedium),

          // 품목 표
          _tableRow(
            const ['품목', '수량', '단가', '금액'],
            style: ReceiptStyles.smallStyle
                .copyWith(fontWeight: FontWeight.bold),
          ),
          ReceiptStyles.divider(),
          for (final item in items)
            _tableRow([
              item.name,
              '${formatQuantity(item.quantity)}${item.unit}',
              Formatters.formatAmount(item.unitPrice),
              Formatters.formatAmount(item.amount),
            ]),
          ReceiptStyles.divider(),
          _tableRow(
            ['합계', '', '', Formatters.formatAmount(total)],
            style: ReceiptStyles.bodyBoldStyle,
          ),

          if (note != null && note!.trim().isNotEmpty) ...[
            const SizedBox(height: ReceiptStyles.paddingMedium),
            Text('비고', style: ReceiptStyles.smallStyle),
            const SizedBox(height: ReceiptStyles.lineSpacing),
            Text(note!.trim(), style: ReceiptStyles.bodyStyle),
          ],

          const SizedBox(height: ReceiptStyles.paddingLarge),
          Center(child: Text(type.closing, style: ReceiptStyles.bodyStyle)),
          const SizedBox(height: ReceiptStyles.paddingSmall),
          Center(
            child: Text('$businessName 드림',
                style: ReceiptStyles.bodyBoldStyle),
          ),
          const SizedBox(height: ReceiptStyles.paddingMedium),
          ReceiptStyles.dashedDivider(),
          const Center(
            child: Text('AI거래장인으로 작성', style: ReceiptStyles.smallStyle),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReceiptStyles.lineSpacing),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: ReceiptStyles.smallStyle),
          ),
          Expanded(child: Text(value, style: ReceiptStyles.bodyStyle)),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> cells, {TextStyle? style}) {
    final s = style ?? ReceiptStyles.bodyStyle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReceiptStyles.lineSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(cells[0], style: s)),
          Expanded(
            flex: 2,
            child: Text(cells[1], style: s, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text(cells[2], style: s, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text(cells[3], style: s, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
