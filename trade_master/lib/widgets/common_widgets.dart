import 'package:flutter/material.dart';
import '../config/on_colors.dart';

/// 로딩 인디케이터
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// 에러 표시 — 선택적 재시도 버튼 포함
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: OnColors.danger),
            const SizedBox(height: 16),
            Text(
              '에러가 발생했습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: OnColors.gray),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 빈 목록 상태 표시 — 선택적 액션 버튼 포함
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: OnColors.grayLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, color: OnColors.gray),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: OnColors.gray),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 거래처 잔액 아바타 (받을 돈=황토, 줄 돈=남색 · 테두리 + 아이콘색)
class BalanceAvatar extends StatelessWidget {
  final double balance;
  final IconData icon;

  const BalanceAvatar({
    super.key,
    required this.balance,
    this.icon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final positive = balance >= 0;
    final label = positive ? '받을 돈 있음' : '줄 돈 있음';
    return Semantics(
      label: label,
      child: _StatusCircle(
        color: positive ? OnColors.receivable : OnColors.payable,
        child: Icon(icon),
      ),
    );
  }
}

/// 거래 유형 아바타 (받을 돈=황토 아래화살표, 줄 돈=남색 위화살표)
class TransactionTypeAvatar extends StatelessWidget {
  final bool isReceivable;

  const TransactionTypeAvatar({super.key, required this.isReceivable});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isReceivable ? '받을 돈' : '줄 돈',
      child: _StatusCircle(
        color: isReceivable ? OnColors.receivable : OnColors.payable,
        child: Icon(isReceivable ? Icons.arrow_downward : Icons.arrow_upward),
      ),
    );
  }
}

/// 상태 원형 표시 — 배경 채움 대신 테두리 + 아이콘색 (BRAND_GUIDE 4.3, 햇빛 아래 가독성)
class _StatusCircle extends StatelessWidget {
  final Color color;
  final Widget child;

  const _StatusCircle({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: 22),
        child: Center(child: child),
      ),
    );
  }
}
