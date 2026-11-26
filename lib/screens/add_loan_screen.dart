import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import '../services/sms_service.dart';

class AddLoanScreen extends StatefulWidget {
  final Patient patient;

  const AddLoanScreen({super.key, required this.patient});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loanSaved = false;
  bool isSending = false;

  double? savedAmount;
  double? savedBalance;

  @override
  void dispose() {
    amountController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> saveLoan() async {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter Loan Amount")));
      return;
    }

    TransactionModel transaction = TransactionModel(
      patientId: widget.patient.id!,
      amount: double.parse(amountController.text),
      type: TransactionType.loan,
      date: DateFormat("dd-MM-yyyy").format(DateTime.now()),
      createdAt: DateTime.now().toIso8601String(),
      remarks: remarksController.text,
    );

    await DatabaseHelper.insertTransaction(transaction);

    double currentBalance = await DatabaseHelper.getCurrentBalance(
      widget.patient.id!,
    );

    if (!mounted) return;

    setState(() {
      loanSaved = true;
      savedAmount = transaction.amount;
      savedBalance = currentBalance;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Loan Added Successfully")));
  }

  Future<void> sendSms() async {
    if (savedAmount == null || savedBalance == null) return;

    if (widget.patient.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient phone number is not set")),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      await SmsService.sendLoanSms(
        phone: widget.patient.phone,
        patientName: widget.patient.name,
        amount: savedAmount!,
        balance: savedBalance!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("SMS Sent Successfully")));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("SMS Failed: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, loanSaved);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppDecor.appBar("Add Loan"),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.deepTeal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: AppColors.deepTeal,
                      size: 30,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.patient.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppDecor.card,
                child: Column(
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      enabled: !loanSaved,
                      decoration: AppDecor.input(
                        "Loan Amount",
                        icon: Icons.currency_rupee_rounded,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: remarksController,
                      maxLines: 2,
                      enabled: !loanSaved,
                      decoration: AppDecor.input(
                        "Remarks (Optional)",
                        icon: Icons.notes_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: loanSaved ? null : saveLoan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text(
                          "Save Loan",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (loanSaved && !isSending) ? sendSms : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          disabledBackgroundColor: AppColors.success
                              .withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sms_outlined),
                        label: const Text(
                          "Send SMS",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (loanSaved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, loanSaved),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
