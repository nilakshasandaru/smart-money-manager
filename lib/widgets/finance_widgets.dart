import 'package:flutter/material.dart';

import '../models/money_transaction.dart';
import '../utils/money_utils.dart';

class FinanceCard extends StatelessWidget {
  const FinanceCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEF7)),
          boxShadow: const [BoxShadow(
            blurRadius: 24, color: Color(0x090B4A98), offset: Offset(0, 8),
          )],
        ),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF182B45),
          ))),
          if (trailing != null) trailing!,
        ],
      );
}

class MoneyStat extends StatelessWidget {
  const MoneyStat({
    super.key, required this.label, required this.amount, required this.icon,
    required this.color,
  });
  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => FinanceCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 19)),
            const SizedBox(width: 7),
            Expanded(child: Text(label, style: const TextStyle(
              color: Color(0xFF75839A), fontSize: 12, fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 12),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(formatMoney(amount, compact: true), style: const TextStyle(
                color: Color(0xFF182B45), fontSize: 19, fontWeight: FontWeight.w800,
              ))),
        ]),
      );
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});
  final MoneyTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == MoneyType.income;
    final color = income ? greenColor : categoryColor(transaction.category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13)),
              child: Icon(categoryIcon(transaction.category), color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.category,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(transaction.note.trim().isEmpty
                        ? readableDate(transaction.date)
                        : '${transaction.note} · ${readableDate(transaction.date)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8190A6))),
                ])),
            const SizedBox(width: 8),
            Text('${income ? '+' : '-'}${formatMoney(transaction.amountCents, compact: true)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: income ? greenColor : const Color(0xFF23354D))),
            if (onTap != null) const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(Icons.chevron_right, size: 15, color: Color(0xFF9FAFC2)),
            ),
          ]),
        ),
      ),
    );
  }
}

class EmptyFinanceState extends StatelessWidget {
  const EmptyFinanceState({super.key, required this.title, required this.subtitle,
    this.icon = Icons.account_balance_wallet_outlined});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(
          color: paleBlue, shape: BoxShape.circle,
        ), child: Icon(icon, size: 32, color: brandBlue)),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7B8AA2), fontSize: 12)),
      ]));
}

class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({super.key, required this.label, required this.onPrevious,
    required this.onNext, this.canGoNext = true});
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(tooltip: 'Previous period', onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: brandBlue)),
          Flexible(child: Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          IconButton(tooltip: 'Next period', onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right, color: brandBlue)),
        ]);
}

class SpendingProgress extends StatelessWidget {
  const SpendingProgress({super.key, required this.spent, required this.limit, this.goalMode = false});
  final int spent;
  final int limit;
  final bool goalMode;

  @override
  Widget build(BuildContext context) {
    final ratio = limit <= 0 ? 0.0 : spent / limit;
    final over = ratio > 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(value: ratio.clamp(0.0, 1.0),
          minHeight: 8, backgroundColor: const Color(0xFFE8EFF9),
          valueColor: AlwaysStoppedAnimation<Color>(goalMode ? greenColor : (over ? redColor : brandBlue)))),
      const SizedBox(height: 5),
      Text('${(ratio * 100).toStringAsFixed(0)}% ${goalMode ? 'of goal reached' : 'used'}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: !goalMode && over ? redColor : const Color(0xFF7B8AA2))),
    ]);
  }
}

void showFinanceError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Something went wrong: $error'), backgroundColor: redColor,
  ));
}
