import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 폰거래장 온 로고 (BRAND_GUIDE.md 2.3)
///
/// - 가로형: 폭 120px 이상 (웹 헤더, 앱 상단)
/// - 세로형: 폭 96px 이상 (첫 화면, 스티커)
/// - 심볼: 폭 120px 미만일 때 단독 사용
class BrandLogo extends StatelessWidget {
  final String _asset;
  final double height;

  const BrandLogo.horizontal({super.key, this.height = 36})
      : _asset = 'assets/logo/on-logo-horizontal.svg';

  const BrandLogo.vertical({super.key, this.height = 140})
      : _asset = 'assets/logo/on-logo-vertical.svg';

  const BrandLogo.symbol({super.key, this.height = 40})
      : _asset = 'assets/symbol/on-symbol.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      height: height,
      semanticsLabel: '폰거래장 온',
    );
  }
}
