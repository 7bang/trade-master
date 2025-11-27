import 'package:flutter/material.dart';

/// 영수증 및 내역서 공통 스타일
class ReceiptStyles {
  // 색상
  static const Color backgroundColor = Colors.white;
  static const Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color dividerColor = Colors.black26;
  static final Color receivableColor = Colors.green.shade700;
  static final Color payableColor = Colors.red.shade700;

  // 폰트 크기
  static const double titleFontSize = 20.0;
  static const double headerFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double amountFontSize = 24.0;
  static const double smallFontSize = 12.0;

  // 간격
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double lineSpacing = 4.0;

  // 레이아웃
  static const double receiptWidth = 400.0;
  static const double borderRadius = 8.0;

  // 구분선
  static Widget divider({double thickness = 1.0}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: paddingSmall),
      height: thickness,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: dividerColor,
            width: thickness,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  // 점선 구분선
  static Widget dashedDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: paddingSmall),
      child: Row(
        children: List.generate(
          50,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven ? dividerColor : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
  );

  static const TextStyle headerStyle = TextStyle(
    fontSize: headerFontSize,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: bodyFontSize,
    color: primaryTextColor,
  );

  static const TextStyle bodyBoldStyle = TextStyle(
    fontSize: bodyFontSize,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
  );

  static const TextStyle amountStyle = TextStyle(
    fontSize: amountFontSize,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
  );

  static const TextStyle smallStyle = TextStyle(
    fontSize: smallFontSize,
    color: secondaryTextColor,
  );

  static TextStyle receivableStyle = TextStyle(
    fontSize: bodyFontSize,
    fontWeight: FontWeight.bold,
    color: receivableColor,
  );

  static TextStyle payableStyle = TextStyle(
    fontSize: bodyFontSize,
    fontWeight: FontWeight.bold,
    color: payableColor,
  );

  // 행 위젯
  static Widget buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: lineSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyStyle),
          Text(
            value,
            style: isBold ? bodyBoldStyle : bodyStyle,
          ),
        ],
      ),
    );
  }

  // 금액 행 위젯
  static Widget buildAmountRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: lineSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyBoldStyle),
          Text(
            amount,
            style: TextStyle(
              fontSize: bodyFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
