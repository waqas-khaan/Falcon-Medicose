import 'dart:io';

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../utils/app_theme.dart';
import 'add_loan_screen.dart';
import 'receive_payment_screen.dart';
import 'history_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  double balance = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  Future<void> loadBalance() async {
    balance = await DatabaseHelper.getCurrentBalance(widget.patient.id!);
    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppDecor.appBar("Patient Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDecor.card,
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.deepTeal, AppColors.teal],
                      ),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.7),
                        width: 2,
                      ),
                      image:
                          widget.patient.photoPath != null &&
                              File(widget.patient.photoPath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(
                                File(widget.patient.photoPath!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        widget.patient.photoPath != null &&
                            File(widget.patient.photoPath!).existsSync()
                        ? null
                        : const Icon(
                            Icons.person,
                            size: 38,
                            color: Colors.white,
                          ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.patient.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Divider(height: 1),

                  const SizedBox(height: 16),

                  buildRow(
                    Icons.family_restroom,
                    "Father Name",
                    widget.patient.fatherName,
                  ),
                  buildRow(Icons.call, "Phone", widget.patient.phone),
                  buildRow(
                    Icons.location_on_outlined,
                    "Address",
                    widget.patient.address,
                  ),
                  buildRow(
                    Icons.mail_outline,
                    "Email",
                    widget.patient.email.isEmpty
                        ? "Not Available"
                        : widget.patient.email,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.deepTeal, AppColors.teal],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepTeal.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Current Balance",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  loading
                      ? const SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Rs. ${balance.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            actionButton(
              icon: Icons.add_card_outlined,
              label: "Add Loan",
              color: AppColors.danger,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLoanScreen(patient: widget.patient),
                  ),
                );
                if (result == true) loadBalance();
              },
            ),

            const SizedBox(height: 12),

            actionButton(
              icon: Icons.payments_outlined,
              label: "Receive Payment",
              color: AppColors.success,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReceivePaymentScreen(patient: widget.patient),
                  ),
                );
                if (result == true) loadBalance();
              },
            ),

            const SizedBox(height: 12),

            actionButton(
              icon: Icons.history,
              label: "History",
              color: AppColors.deepTeal,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(patient: widget.patient),
                  ),
                );
                if (result == true) loadBalance();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.teal),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
