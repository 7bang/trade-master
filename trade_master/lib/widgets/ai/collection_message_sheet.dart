import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/customer.dart';
import '../../providers/providers.dart';
import '../../providers/ai_providers.dart';
import '../../utils/formatters.dart';
import '../../config/on_colors.dart';
import '../../utils/app_exception.dart';

void showCollectionMessageSheet(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _CollectionMessageSheet(
      customer: customer,
      ref: ref,
    ),
  );
}

class _CollectionMessageSheet extends StatefulWidget {
  final Customer customer;
  final WidgetRef ref;

  const _CollectionMessageSheet({
    required this.customer,
    required this.ref,
  });

  @override
  State<_CollectionMessageSheet> createState() =>
      _CollectionMessageSheetState();
}

class _CollectionMessageSheetState extends State<_CollectionMessageSheet> {
  String? _message;
  bool _isLoading = true;
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
    });
    try {
      final business =
          await widget.ref.read(currentBusinessProvider.future);
      final ai = widget.ref.read(aiServiceProvider);
      final msg = await ai.generateCollectionMessage(
        widget.customer,
        widget.customer.balance,
        businessName: business?.name ?? '사업장',
        businessPhone: business?.phone,
      );
      if (mounted) {
        setState(() {
          _message = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.customer.balance;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: OnColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 헤더
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: OnColors.ink),
              const SizedBox(width: 8),
              const Text(
                'AI 미수금 독촉 문구',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: balance > 0
                      ? OnColors.receivableBg
                      : OnColors.payableBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  Formatters.formatCurrency(balance.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0
                        ? OnColors.receivable
                        : OnColors.payable,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.customer.name,
            style: TextStyle(color: OnColors.gray),
          ),
          const SizedBox(height: 16),

          // 본문
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('AI가 문구를 생성하고 있습니다...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: OnColors.danger, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: OnColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          else if (_message != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OnColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OnColors.line),
              ),
              child: Text(
                _message!,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _message!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('클립보드에 복사했습니다')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('복사'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(_message!);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('카카오 공유'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _generate,
                  tooltip: '다시 생성',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
