import 'package:flutter/material.dart';

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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '에러가 발생했습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
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
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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

/// 거래처 잔액 색상 아바타 (양수=초록, 음수=빨강)
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
    return CircleAvatar(
      backgroundColor:
          positive ? Colors.green.shade100 : Colors.red.shade100,
      child: Icon(
        icon,
        color: positive ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }
}

/// 거래 유형 아바타 (receivable=초록 아래화살표, payable=빨강 위화살표)
class TransactionTypeAvatar extends StatelessWidget {
  final bool isReceivable;

  const TransactionTypeAvatar({super.key, required this.isReceivable});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor:
          isReceivable ? Colors.green.shade100 : Colors.red.shade100,
      child: Icon(
        isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
        color: isReceivable ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }
}
