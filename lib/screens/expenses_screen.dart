import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final list = await DatabaseHelper.getExpenses();

    if (mounted) {
      setState(() {
        _settings = settings;
        _expenses = list;
        _isLoading = false;
      });
    }
  }

  double get _totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);

  void _openAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCat = AppConstants.expenseCategories.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: Color(0xFFEA580C), size: 22),
                SizedBox(width: 8),
                Text('Add Daily Expense',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: _dialogInput(
                        'Expense Title *', Icons.title_rounded,
                        hint: 'e.g. Shop Rent, Electricity Bill'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration:
                        _dialogInput('Category', Icons.category_rounded),
                    items: AppConstants.expenseCategories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCat = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _dialogInput(
                        'Amount *', Icons.payments_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    decoration: _dialogInput(
                        'Notes (Optional)', Icons.notes_rounded),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ModernButton(
                label: 'Save Expense',
                icon: Icons.check_rounded,
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (title.isEmpty || amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Please enter title and valid amount')));
                    return;
                  }

                  final exp = Expense(
                    title: title,
                    category: selectedCat,
                    amount: amt,
                    notes: notesCtrl.text.trim().isNotEmpty
                        ? notesCtrl.text.trim()
                        : null,
                    expenseDate:
                        DateTime.now().toIso8601String().substring(0, 10),
                  );

                  await DatabaseHelper.insertExpense(exp);
                  Navigator.pop(ctx);
                  _loadExpenses();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteExpense(Expense exp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${exp.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && exp.id != null) {
      await DatabaseHelper.deleteExpense(exp.id!);
      _loadExpenses();
    }
  }

  static InputDecoration _dialogInput(String label, IconData icon,
      {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Store Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Expenses',
            onPressed: _loadExpenses,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseDialog,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          // Total Expense Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFFEA580C)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Recorded Expenses',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                        Text(
                          Formatters.formatCurrency(
                              _totalExpenses, _settings.currency),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_expenses.length} entries',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight))
                : _expenses.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No expenses recorded',
                        subtitle:
                            'Tap the button below to log rent, electricity, salaries, etc.',
                        actionLabel: 'Add Expense',
                        onAction: _openAddExpenseDialog,
                      )
                    : isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 100,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _expenses.length,
                            itemBuilder: (context, i) =>
                                _buildExpenseCard(_expenses[i]),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _expenses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildExpenseCard(_expenses[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense exp) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: Color(0xFFEA580C), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(exp.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  '${exp.category} • ${Formatters.formatShortDate(exp.expenseDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
                if (exp.notes != null && exp.notes!.isNotEmpty)
                  Text(
                    exp.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(exp.amount, _settings.currency),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFFEA580C)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.textMuted),
            onPressed: () => _deleteExpense(exp),
          ),
        ],
      ),
    );
  }
}
