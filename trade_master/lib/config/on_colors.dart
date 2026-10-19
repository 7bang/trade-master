import 'package:flutter/material.dart';

/// 폰거래장 온 브랜드 색상 (BRAND_GUIDE.md 3·4장)
///
/// 비율 한지 60 : 먹남 30 : 인주 10.
/// 인주색은 행동·확정의 순간(저장 버튼, 확정 표시, 심볼)에만 쓴다.
class OnColors {
  // brand
  static const ink = Color(0xFF1F2A36); // 먹남: 본문, 금액
  static const paper = Color(0xFFF6F2EA); // 한지: 화면 배경
  static const vermilion = Color(0xFFC4321E); // 인주: 주요 버튼, 선택
  static const vermilionDeep = Color(0xFFA82A18); // 눌림, 작은 강조 글자
  static const vermilionLight = Color(0xFFEF6A4A); // 어두운 배경 전용
  static const gray = Color(0xFF5A6370); // 장부 먹회색: 날짜, 설명
  static const grayLight = Color(0xFF9AA3AE); // 빈 화면 아이콘 등 흐린 표시
  static const line = Color(0xFFE2DCCF); // 장부선: 구분선, 테두리
  static const night = Color(0xFF151C24);

  // status (light)
  static const success = Color(0xFF2E7D4F); // 입금완료, 저장 완료 알림
  static const warning = Color(0xFF9A6212); // 미수, 확인 필요
  static const info = Color(0xFF2F5D8A); // 공유됨, 안내
  static const danger = vermilion; // 삭제·오류 (아이콘·문구 필수)

  // 연한 배경 (안내 박스 등)
  static const successBg = Color(0xFFE6F1EA);
  static const warningBg = Color(0xFFF6EDDF);
  static const infoBg = Color(0xFFE7EEF5);
  static const dangerBg = Color(0xFFF8E6E2);

  // 거래 방향 (4.3: 미수는 빨강이 아닌 warning)
  static const receivable = warning; // 받을 돈 (미수)
  static const payable = info; // 줄 돈
  static const receivableBg = warningBg;
  static const payableBg = infoBg;
  // 먹남(ink) 배경 위
  static const receivableOnDark = Color(0xFFE0A33E);
  static const payableOnDark = Color(0xFF7FA9D6);
}
