import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/money_transaction.dart';
import '../state/money_controller.dart';
import '../utils/money_utils.dart';
import '../widgets/finance_widgets.dart';

class TransactionEditor extends StatefulWidget {
  const TransactionEditor({super.key, this.initial});
  final MoneyTransaction? initial;

  @override
  State<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends State<TransactionEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late MoneyType _type;
  late String _category;
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _type = item?.type ?? MoneyType.expense;
    _category = item?.category ?? expenseCategories.first;
    _date = item?.date ?? DateTime.now();
    _amountController = TextEditingController(
        text: item == null ? '' : formatAmountForField(item.amountCents));
    _noteController = TextEditingController(text: item?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context,
      initialDate: _date, firstDate: DateTime(2010), lastDate: DateTime(2100));
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseAmount(_amountController.text);
    if (amount == null) return;
    setState(() => _busy = true);
    try {
      await context.read<MoneyController>().saveTransaction(MoneyTransaction(
        id: widget.initial?.id,
        amountCents: amount,
        type: _type,
        category: _category,
        date: _date,
        note: _noteController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      showFinanceError(context, error);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final item = widget.initial;
    if (item?.id == null) return;
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: redColor))),
        ],
      ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<MoneyController>().removeTransaction(item!.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      showFinanceError(context, error);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == MoneyType.expense ? expenseCategories : incomeCategories;
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Add transaction' : 'Edit transaction'),
        actions: [
          if (widget.initial != null)
            IconButton(tooltip: 'Delete transaction', onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline, color: redColor)),
        ]),
      body: SafeArea(child: Form(key: _formKey,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 28), children: [
          const Text('Transaction type', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: SegmentedButton<MoneyType>(
            segments: const [
              ButtonSegment(value: MoneyType.expense, label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: MoneyType.income, label: Text('Income'),
                  icon: Icon(Icons.arrow_downward)),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() {
              _type = value.first;
              _category = _type == MoneyType.expense
                  ? expenseCategories.first : incomeCategories.first;
            }),
          )),
          const SizedBox(height: 26),
          const Text('Amount (LKR)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            autofocus: widget.initial == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(hintText: 'e.g. 1500.00', prefixText: 'Rs.  ',
              prefixIcon: Icon(Icons.payments_outlined)),
            validator: (value) => parseAmount(value ?? '') == null
                ? 'Enter an amount greater than zero (max 2 decimal places)' : null,
          ),
          const SizedBox(height: 22),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_type),
            value: _category,
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
            items: categories.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Row(children: [Icon(categoryIcon(item), color: categoryColor(item), size: 19),
                const SizedBox(width: 12), Text(item)]),
            )).toList(),
            onChanged: (value) { if (value != null) setState(() => _category = value); },
          ),
          const SizedBox(height: 22),
          const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FinanceCard(padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined, color: brandBlue),
              title: Text(readableDate(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 22),
          const Text('Note (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(controller: _noteController,
            maxLength: 120, maxLines: 2,
            decoration: const InputDecoration(hintText: 'What was this for?',
                prefixIcon: Icon(Icons.edit_note_outlined))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy ? const SizedBox(width: 17, height: 17,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text(widget.initial == null ? 'Save transaction' : 'Save changes'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ]),
      )),
    );
  }
}

