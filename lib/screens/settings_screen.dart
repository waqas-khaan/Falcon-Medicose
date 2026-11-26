import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _thresholdCtrl;
  late TextEditingController _footerCtrl;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final s = await DatabaseHelper.getSettings();

    _nameCtrl = TextEditingController(text: s.storeName);
    _phoneCtrl = TextEditingController(text: s.phone);
    _addrCtrl = TextEditingController(text: s.address);
    _currencyCtrl = TextEditingController(text: s.currency);
    _thresholdCtrl =
        TextEditingController(text: s.lowStockThreshold.toStringAsFixed(0));
    _footerCtrl = TextEditingController(text: s.receiptFooter);

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _currencyCtrl.dispose();
    _thresholdCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final s = StoreSettings(
        storeName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addrCtrl.text.trim(),
        currency: _currencyCtrl.text.trim().isNotEmpty
            ? _currencyCtrl.text.trim()
            : 'Rs.',
        lowStockThreshold:
            double.tryParse(_thresholdCtrl.text.trim()) ?? 5.0,
        receiptFooter: _footerCtrl.text.trim(),
      );

      await DatabaseHelper.updateSettings(s);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving settings: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Store & Receipt Settings'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            onPressed: _isSaving ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy Information
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storefront_rounded,
                                      color: AppColors.primaryLight, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pharmacy Information',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: _inputDecor(
                                    'Store / Clinic Name *',
                                    Icons.badge_outlined),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter store name'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecor(
                                    'Phone Number', Icons.phone_outlined),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addrCtrl,
                                decoration: _inputDecor('Address / Location',
                                    Icons.location_on_outlined),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Receipt & Operational Preferences
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.receipt_long_rounded,
                                      color: AppColors.primaryLight, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Receipt & System Preferences',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _currencyCtrl,
                                      decoration: _inputDecor(
                                          'Currency Symbol',
                                          Icons.currency_exchange_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _thresholdCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecor(
                                          'Low Stock Alert Level',
                                          Icons.warning_amber_rounded),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _footerCtrl,
                                decoration: _inputDecor(
                                    'Receipt Footer Message',
                                    Icons.message_outlined,
                                    hint:
                                        'e.g. Thank you for your visit! Goods once sold cannot be returned.'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        ModernButton(
                          label: 'Save Settings',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveSettings,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}
