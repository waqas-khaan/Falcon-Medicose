import 'dart:io';

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../utils/app_theme.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> patients = [];
  List<Patient> filteredPatients = [];
  Map<int, double> patientBalances = {};
  bool loading = true;

  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    loadPatients();
    searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  Future<void> loadPatients() async {
    patients = await DatabaseHelper.getPatients();

    patientBalances.clear();

    for (Patient patient in patients) {
      patientBalances[patient.id!] = await DatabaseHelper.getCurrentBalance(
        patient.id!,
      );
    }

    loading = false;

    _applyFilter();
  }

  void _applyFilter() {
    String query = searchController.text.trim();

    if (query.isEmpty) {
      filteredPatients = patients;
    } else {
      String digitsQuery = query.replaceAll(RegExp(r'[^0-9]'), '');
      String lowerQuery = query.toLowerCase();

      filteredPatients = patients.where((patient) {
        bool nameMatch = patient.name.toLowerCase().contains(lowerQuery);

        String digitsPhone = patient.phone.replaceAll(RegExp(r'[^0-9]'), '');
        bool phoneMatch =
            digitsQuery.isNotEmpty && digitsPhone.contains(digitsQuery);

        return nameMatch || phoneMatch;
      }).toList();
    }

    setState(() {});
  }

  void _startSearch() {
    setState(() => isSearching = true);
    Future.delayed(const Duration(milliseconds: 80), () {
      searchFocus.requestFocus();
    });
  }

  void _stopSearch() {
    searchController.clear();
    setState(() => isSearching = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _stopSearch,
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: isSearching
              ? TextField(
                  key: const ValueKey("search"),
                  controller: searchController,
                  focusNode: searchFocus,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Search by name or phone...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                )
              : const Text(
                  "Patient List",
                  key: ValueKey("title"),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
        actions: [
          if (isSearching && searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => searchController.clear(),
            )
          else if (!isSearching)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
          ? emptyState()
          : filteredPatients.isEmpty
          ? noResultsState()
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                Patient patient = filteredPatients[index];
                double balance = patientBalances[patient.id] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecor.card,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.teal.withOpacity(0.12),
                        backgroundImage:
                            patient.photoPath != null &&
                                File(patient.photoPath!).existsSync()
                            ? FileImage(File(patient.photoPath!))
                            : null,
                        child:
                            patient.photoPath != null &&
                                File(patient.photoPath!).existsSync()
                            ? null
                            : Text(
                                patient.name.isNotEmpty
                                    ? patient.name[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: AppColors.deepTeal,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.call,
                                  size: 13,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  patient.phone,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Rs. ${balance.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.deepTeal.withOpacity(
                            0.08,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: AppColors.deepTeal,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientDetailScreen(patient: patient),
                            ),
                          );
                          loadPatients();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.teal.withOpacity(0.4),
          ),
          const SizedBox(height: 14),
          Text(
            "No Patient Found",
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

  Widget noResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.teal.withOpacity(0.4),
          ),
          const SizedBox(height: 14),
          Text(
            "No matching patient found",
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
