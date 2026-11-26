import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupService {
  static Future<String> _dbPath() async {
    return p.join(await getDatabasesPath(), 'clinic.db');
  }

  /// Copies the current database to a temp file and opens the
  /// share sheet so the user can save it to Drive, WhatsApp,
  /// email, Files app, etc.
  static Future<void> backupDatabase() async {
    final dbPath = await _dbPath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception("No data found to backup yet.");
    }

    // Flush everything written so far to disk
    final db = await DatabaseHelper.getDatabase();
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());
    final backupName = 'FalconMedicose_Backup_$dateStr.db';
    final backupPath = p.join(tempDir.path, backupName);

    await dbFile.copy(backupPath);

    await Share.shareXFiles([
      XFile(backupPath),
    ], text: 'Falcon Medicose - Complete Data Backup ($dateStr)');
  }

  /// Replaces the current database with the picked backup file.
  static Future<void> restoreDatabase(String pickedFilePath) async {
    final pickedFile = File(pickedFilePath);

    if (!await pickedFile.exists()) {
      throw Exception("Selected backup file could not be found.");
    }

    final dbPath = await _dbPath();

    // Close the live connection before overwriting
    await DatabaseHelper.closeAndReset();

    await pickedFile.copy(dbPath);

    // Reopen so the rest of the app can use it immediately
    await DatabaseHelper.getDatabase();
  }
}
