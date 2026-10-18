import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../providers/ai_providers.dart';
import '../../services/ai_service.dart';
import '../../utils/formatters.dart';

/// AI 경영 인사이트 화면
class InsightScreen extends ConsumerStatefulWidget {
  const InsightScreen({super.key});

  @override
  ConsumerState<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends ConsumerState<InsightScreen> {
  InsightReport? _report;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _report = null;
    });

    try {
      // 데이터 수집
      final business = await ref.read(currentBusinessProvider.future);
      final customers = await ref.read(customersProvider.future);

      if (business == null) {
        throw Exception('사업장 정보를 불러올 수 없습니다');
      }

      final service = ref.read(supabaseServiceProvider);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final allTx = await service.getTransactions(businessId: business.id);
      final monthlyTx = allTx.where((t) => t.date.isAfter(monthStart)).toList();

      final monthlyReceivable = monthlyTx
          .where((t) => t.type == TransactionType.receivable)
          .fold<double>(0, (s, t) => s + t.amount);

      final monthlyPayable = monthlyTx
          .where((t) => t.type == TransactionType.payable)
          .fold<double>(0, (s, t) => s + t.amount);

      // 잔액 기준 상위 5 거래처
      final sorted = [...customers]
        ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
      final topCustomers = sorted
          .take(5)
          .map((c) =>
              '${c.name}: ${Formatters.formatBalance(c.balance)}')
          .join(', ');

      final totalReceivable =
          customers.where((c) => c.balance > 0).fold<double>(0, (s, c) => s + c.balance);
      final totalPayable =
          customers.where((c) => c.balance < 0).fold<double>(0, (s, c) => s + c.balance.abs());

      final ai = ref.read(aiServiceProvider);
      final report = await ai.getBusinessInsights({
        'customerCount': customers.length,
        'monthlyReceivable': monthlyReceivable,
        'monthlyPayable': monthlyPayable,
        'totalReceivable': totalReceivable,
        'totalPayable': totalPayable,
        'topCustomers': topCustomers,
      });

      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 경영 인사이트'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '다시 분석',
              onPressed: _generate,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI가 거래 데이터를 분석하고 있습니다...'),
            SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_report == null) return const SizedBox.shrink();

    final report = _report!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 헤더
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(
              'AI 분석 결과',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              DateFormat('MM/dd HH:mm').format(DateTime.now()),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 종합 요약
        _Section(
          icon: Icons.summarize,
          color: Colors.blue,
          title: '종합 요약',
          child: Text(
            report.summary,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
        const SizedBox(height: 12),

        // 위험 요소
        if (report.risks.isNotEmpty)
          _Section(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            title: '주의 사항',
            child: Column(
              children: report.risks
                  .map((r) => _BulletItem(text: r, color: Colors.orange))
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),

        // 권고사항
        if (report.recommendations.isNotEmpty)
          _Section(
            icon: Icons.lightbulb_outline,
            color: Colors.green,
            title: '개선 권고사항',
            child: Column(
              children: report.recommendations
                  .map((r) => _BulletItem(text: r, color: Colors.green))
                  .toList(),
            ),
          ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'AI 분석은 참고용이며 실제 경영 판단은 직접 확인하세요',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
