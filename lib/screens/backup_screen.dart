import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_widgets.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool isBackingUp = false;
  bool isRestoring = false;

  Future<void> _backupNow() async {
    setState(() => isBackingUp = true);

    try {
      await BackupService.backupDatabase();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup ready — choose where to save it")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Backup Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => isBackingUp = false);
    }
  }

  Future<void> _restoreNow() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.single.path == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Restore Data?"),
        content: const Text(
          "This will replace current catalog, transactions, and ledgers with "
          "the data from the selected backup file. This cannot be undone.\n\n"
          "Do you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Restore",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isRestoring = true);

    try {
      await BackupService.restoreDatabase(result.files.single.path!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data Restored Successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Restore Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Backup & Restore")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Backup card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryActionGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              "Backup Your Data",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Export a complete copy of all medicines, sales invoices, stock-in history, customer ledgers, and suppliers. "
                        "You can save it to Google Drive, WhatsApp, or local storage for safekeeping.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernButton(
                        label: isBackingUp ? "Creating Backup..." : "Create Backup Now",
                        icon: Icons.download_rounded,
                        isLoading: isBackingUp,
                        onPressed: isBackingUp ? null : _backupNow,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Restore card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.settings_backup_restore_rounded,
                              color: AppColors.warning,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              "Restore from File",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Select a previously saved backup file (.db) to restore your system data.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernButton(
                        label: isRestoring ? "Restoring Data..." : "Choose Backup File",
                        icon: Icons.folder_open_rounded,
                        variant: ModernButtonVariant.secondary,
                        isLoading: isRestoring,
                        onPressed: isRestoring ? null : _restoreNow,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Info banner
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "System active as of $today",
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
