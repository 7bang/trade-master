import 'package:flutter/material.dart';
import '../config/on_colors.dart';
import 'app_exception.dart';

/// 화면 하단 알림 (SnackBar) — 화면마다 ScaffoldMessenger 코드를 반복하지 않는다.
extension AppSnackBars on BuildContext {
  /// 저장·삭제 완료 등
  void showSuccess(String message) =>
      _show(message, background: OnColors.success);

  /// 오류 — 예외를 넘기면 사용자용 문구로 바꿔 보여준다
  void showError(Object errorOrMessage) => _show(
        errorOrMessage is String ? errorOrMessage : userMessage(errorOrMessage),
        background: OnColors.danger,
      );

  /// 일반 안내 (테마 기본 색)
  void showInfo(String message) => _show(message);

  void _show(String message, {Color? background}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }
}
