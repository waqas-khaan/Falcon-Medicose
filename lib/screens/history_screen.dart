import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final Patient patient;

  const HistoryScreen({super.key, required this.patient});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> transactions = [];

  bool loading = true;
  bool balanceChanged = false;

  bool selectionMode = false;
  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    transactions = await DatabaseHelper.getTransactionsByPatient(
      widget.patient.id!,
    );

    loading = false;

    setState(() {});
  }

  void _enterSelectionMode(int firstSelectedId) {
    setState(() {
      selectionMode = true;
      selectedIds = {firstSelectedId};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      selectionMode = false;
      selectedIds.clear();
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectedIds.length == transactions.length) {
        selectedIds.clear();
      } else {
        selectedIds = transactions.map((t) => t.id!).toSet();
      }
    });
  }

  Future<bool> _confirmDelete({required int count, required double total}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(count == 1 ? "Delete Entry?" : "Delete $count Entries?"),
        content: Text(
          count == 1
              ? "This entry will be permanently removed from the history "
                "log. The patient's current balance will NOT change. "
                "This cannot be undone."
              : "These $count entries (totaling Rs.${total.toStringAsFixed(0)}) "
                "will be permanently removed from the history log. The "
                "patient's current balance will NOT change. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _deleteSingle(TransactionModel transaction) async {
    bool confirmed = await _confirmDelete(
      count: 1,
      total: transaction.amount,
    );
    if (!confirmed) return;

    await DatabaseHelper.deleteTransaction(transaction.id!);

    setState(() {
      transactions.removeWhere((t) => t.id == transaction.id);
      balanceChanged = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Entry Deleted")));
  }

  Future<void> _deleteSelected() async {
    List<TransactionModel> toDelete = transactions
        .where((t) => selectedIds.contains(t.id))
        .toList();

    double total = toDelete.fold(0, (sum, t) => sum + t.amount);

    bool confirmed = await _confirmDelete(
      count: toDelete.length,
      total: total,
    );
    if (!confirmed) return;

    for (final t in toDelete) {
      await DatabaseHelper.deleteTransaction(t.id!);
    }

    setState(() {
      transactions.removeWhere((t) => selectedIds.contains(t.id));
      balanceChanged = true;
      selectionMode = false;
      selectedIds.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${toDelete.length} Entries Deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allSelected =
        transactions.isNotEmpty && selectedIds.length == transactions.length;

    return PopScope(
      canPop: !selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectionMode) {
          _exitSelectionMode();
        } else {
          Navigator.pop(context, balanceChanged);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.deepTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(selectionMode ? Icons.close : Icons.arrow_back),
            onPressed: () {
              if (selectionMode) {
                _exitSelectionMode();
              } else {
                Navigator.pop(context, balanceChanged);
              }
            },
          ),
          title: Text(
            selectionMode
                ? "${selectedIds.length} Selected"
                : "${widget.patient.name}'s History",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (transactions.isNotEmpty && !selectionMode)
              IconButton(
                icon: const Icon(Icons.checklist_rounded),
                tooltip: "Select entries",
                onPressed: () => _enterSelectionMode(transactions.first.id!),
              ),
            if (selectionMode)
              IconButton(
                icon: Icon(
                  allSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
                tooltip: allSelected ? "Deselect All" : "Select All",
                onPressed: _toggleSelectAll,
              ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : transactions.isEmpty
            ? emptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  TransactionModel transaction = transactions[index];
                  bool isLoan = transaction.type == TransactionType.loan;
                  Color color = isLoan
                      ? AppColors.danger
                      : AppColors.success;
                  bool isSelected = selectedIds.contains(transaction.id);

                  Widget card = Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: isSelected
                          ? Border.all(color: AppColors.deepTeal, width: 1.6)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepTeal.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectionMode) ...[
                          Checkbox(
                            value: isSelected,
                            activeColor: AppColors.deepTeal,
                            onChanged: (_) => _toggleSelect(transaction.id!),
                          ),
                          const SizedBox(width: 4),
                        ] else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isLoan
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: color,
                            ),
                          ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isLoan
                                        ? "Loan Added"
                                        : "Payment Received",
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "Rs.${transaction.amount.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                transaction.date,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                ),
                              ),

                              if (transaction.remarks.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  transaction.remarks,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.ink.withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (!selectionMode)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.ink.withOpacity(0.35),
                              size: 22,
                            ),
                            onPressed: () => _deleteSingle(transaction),
                          ),
                      ],
                    ),
                  );

                  if (selectionMode) {
                    return GestureDetector(
                      onTap: () => _toggleSelect(transaction.id!),
                      child: card,
                    );
                  }

                  return GestureDetector(
                    onLongPress: () =>
                        _enterSelectionMode(transaction.id!),
                    child: Dismissible(
                      key: ValueKey(transaction.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(
                        count: 1,
                        total: transaction.amount,
                      ),
                      onDismissed: (_) {
                        DatabaseHelper.deleteTransaction(transaction.id!);
                        setState(() {
                          transactions.removeWhere(
                            (t) => t.id == transaction.id,
                          );
                          balanceChanged = true;
                        });
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      child: card,
                    ),
                  );
                },
              ),
        bottomNavigationBar: selectionMode && selectedIds.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _deleteSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        "Delete Selected (${selectedIds.length})",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.teal.withOpacity(0.4),
          ),
          const SizedBox(height: 14),
          Text(
            "No History Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
