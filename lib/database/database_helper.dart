import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/customer.dart';
import '../models/customer_payment.dart';
import '../models/customer_return.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/purchase_invoice.dart';
import '../models/report_models.dart';
import '../models/stock_in.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';
import '../models/supplier_payment.dart';
import '../models/supplier_return.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'clinic.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // 1. Legacy tables
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        fatherName TEXT,
        phone TEXT,
        address TEXT,
        email TEXT,
        photoPath TEXT,
        balance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        amount REAL,
        type TEXT,
        date TEXT,
        createdAt TEXT,
        remarks TEXT
      )
    ''');

    // 2. Falcon Medicose Pharmacy Tables
    await _createPharmacyTables(db);

    // 3. Seed Default Settings & Demo Data
    await _seedInitialData(db);
  }

  static Future<void> _createPharmacyTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        companyName TEXT,
        category TEXT,
        unitType TEXT DEFAULT 'STRIP',
        buyingPrice REAL DEFAULT 0,
        retailPrice REAL DEFAULT 0,
        discountPercent REAL DEFAULT 0,
        sellingPrice REAL DEFAULT 0,
        currentStock REAL DEFAULT 0,
        minStockLevel REAL DEFAULT 5,
        nearestExpiryDate TEXT,
        active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        customerType TEXT DEFAULT 'RETAIL',
        companyName TEXT,
        totalAmount REAL DEFAULT 0,
        paidAmount REAL DEFAULT 0,
        remainingAmount REAL DEFAULT 0,
        active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        totalAmount REAL DEFAULT 0,
        paidAmount REAL DEFAULT 0,
        remainingAmount REAL DEFAULT 0,
        active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        customerName TEXT,
        customerPhone TEXT,
        invoiceType TEXT DEFAULT 'RETAIL',
        roomNumber TEXT,
        doctorName TEXT,
        totalAmount REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        paidAmount REAL DEFAULT 0,
        remainingAmount REAL DEFAULT 0,
        invoiceDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        medicineId INTEGER,
        medicineName TEXT NOT NULL,
        companyName TEXT,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        discountPercent REAL DEFAULT 0,
        buyingPrice REAL DEFAULT 0,
        totalPrice REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER,
        supplierNameSnapshot TEXT,
        totalAmount REAL DEFAULT 0,
        paidAmount REAL DEFAULT 0,
        remainingAmount REAL DEFAULT 0,
        purchaseDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_in(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        supplierId INTEGER,
        purchaseInvoiceId INTEGER,
        quantity REAL NOT NULL,
        buyingPrice REAL NOT NULL,
        batchNumber TEXT,
        expiryDate TEXT,
        purchaseDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        invoiceId INTEGER,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER,
        purchaseInvoiceId INTEGER,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_returns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        customerId INTEGER,
        customerNameSnapshot TEXT,
        quantity REAL NOT NULL,
        refundAmount REAL DEFAULT 0,
        buyingPriceSnapshot REAL DEFAULT 0,
        reason TEXT,
        returnDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_returns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        supplierId INTEGER,
        supplierNameSnapshot TEXT,
        quantity REAL NOT NULL,
        creditAmount REAL DEFAULT 0,
        reason TEXT,
        returnDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        expenseDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        id INTEGER PRIMARY KEY,
        storeName TEXT DEFAULT 'Falcon Medicose',
        phone TEXT DEFAULT '',
        address TEXT DEFAULT '',
        currency TEXT DEFAULT 'Rs.',
        lowStockThreshold REAL DEFAULT 5,
        receiptFooter TEXT DEFAULT 'Thank you for choosing Falcon Medicose! Get well soon.'
      )
    ''');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE patients ADD COLUMN photoPath TEXT');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE patients ADD COLUMN balance REAL DEFAULT 0');
      final patients = await db.query('patients');
      for (final patient in patients) {
        final patientId = patient['id'] as int;
        final loanResult = await db.rawQuery(
          'SELECT SUM(amount) as total FROM transactions WHERE patientId = ? AND type = ?',
          [patientId, 'LOAN'],
        );
        final paymentResult = await db.rawQuery(
          'SELECT SUM(amount) as total FROM transactions WHERE patientId = ? AND type = ?',
          [patientId, 'PAYMENT'],
        );
        final loanTotal = (loanResult.first['total'] as num?)?.toDouble() ?? 0;
        final paymentTotal = (paymentResult.first['total'] as num?)?.toDouble() ?? 0;

        await db.update(
          'patients',
          {'balance': loanTotal - paymentTotal},
          where: 'id = ?',
          whereArgs: [patientId],
        );
      }
    }

    if (oldVersion < 4) {
      await _createPharmacyTables(db);
      await _seedInitialData(db);

      // Migrate existing patients into customers so nothing is lost
      final patients = await db.query('patients');
      for (final p in patients) {
        final balance = (p['balance'] as num?)?.toDouble() ?? 0.0;
        await db.insert('customers', {
          'name': p['name'],
          'phone': p['phone'],
          'address': p['address'],
          'customerType': 'RETAIL',
          'totalAmount': balance > 0 ? balance : 0.0,
          'paidAmount': 0.0,
          'remainingAmount': balance > 0 ? balance : 0.0,
          'active': 1,
        });
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE customers ADD COLUMN customerType TEXT DEFAULT 'RETAIL'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE customers ADD COLUMN companyName TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE invoices ADD COLUMN invoiceType TEXT DEFAULT 'RETAIL'");
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute("ALTER TABLE medicines ADD COLUMN retailPrice REAL DEFAULT 0");
        await db.execute("UPDATE medicines SET retailPrice = sellingPrice WHERE retailPrice IS NULL OR retailPrice = 0");
      } catch (_) {}
    }
  }

  static Future<void> _seedInitialData(Database db) async {
    // 1. Settings
    final settingsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM settings')) ?? 0;
    if (settingsCount == 0) {
      await db.insert('settings', {
        'id': 1,
        'storeName': 'Falcon Medicose',
        'phone': '0300-9876543',
        'address': 'Main Market, Healthcare Complex, City',
        'currency': 'Rs.',
        'lowStockThreshold': 5.0,
        'receiptFooter': 'Thank you for visiting Falcon Medicose! Wishing you good health.',
      });
    }

    // 2. Seed starter medicines if empty
    final medCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM medicines')) ?? 0;
    if (medCount == 0) {
      final now = DateTime.now();
      final expiryNextYear = DateTime(now.year + 1, now.month + 3, 15).toIso8601String().substring(0, 10);
      final expirySoon = DateTime(now.year, now.month, now.day + 18).toIso8601String().substring(0, 10);

      final starterMedicines = [
        {
          'name': 'Panadol 500mg',
          'companyName': 'GSK',
          'category': 'Tablets',
          'unitType': 'STRIP',
          'buyingPrice': 25.0,
          'retailPrice': 35.0,
          'discountPercent': 5.0,
          'sellingPrice': 35.0,
          'currentStock': 120.0,
          'minStockLevel': 20.0,
          'nearestExpiryDate': expiryNextYear,
          'active': 1,
        },
        {
          'name': 'Augmentin 625mg',
          'companyName': 'GSK',
          'category': 'Tablets',
          'unitType': 'STRIP',
          'buyingPrice': 180.0,
          'retailPrice': 260.0,
          'discountPercent': 8.0,
          'sellingPrice': 240.0,
          'currentStock': 35.0,
          'minStockLevel': 10.0,
          'nearestExpiryDate': expiryNextYear,
          'active': 1,
        },
        {
          'name': 'Brufen Syrup 120ml',
          'companyName': 'Abbott',
          'category': 'Syrups',
          'unitType': 'BOTTLE',
          'buyingPrice': 85.0,
          'retailPrice': 125.0,
          'discountPercent': 5.0,
          'sellingPrice': 115.0,
          'currentStock': 15.0,
          'minStockLevel': 5.0,
          'nearestExpiryDate': expiryNextYear,
          'active': 1,
        },
        {
          'name': 'Risek 20mg (Omeprazole)',
          'companyName': 'Getz Pharma',
          'category': 'Capsules',
          'unitType': 'STRIP',
          'buyingPrice': 190.0,
          'retailPrice': 280.0,
          'discountPercent': 10.0,
          'sellingPrice': 260.0,
          'currentStock': 4.0, // Low stock demo!
          'minStockLevel': 10.0,
          'nearestExpiryDate': expiryNextYear,
          'active': 1,
        },
        {
          'name': 'Arinac Forte',
          'companyName': 'Abbott',
          'category': 'Tablets',
          'unitType': 'STRIP',
          'buyingPrice': 65.0,
          'retailPrice': 100.0,
          'discountPercent': 5.0,
          'sellingPrice': 90.0,
          'currentStock': 0.0, // Out of stock demo!
          'minStockLevel': 15.0,
          'nearestExpiryDate': expiryNextYear,
          'active': 1,
        },
        {
          'name': 'Cac 1000 Plus Effervescent',
          'companyName': 'GSK',
          'category': 'Tablets',
          'unitType': 'BOTTLE',
          'buyingPrice': 195.0,
          'retailPrice': 275.0,
          'discountPercent': 0.0,
          'sellingPrice': 250.0,
          'currentStock': 22.0,
          'minStockLevel': 5.0,
          'nearestExpiryDate': expirySoon, // Expiring soon demo!
          'active': 1,
        },
      ];

      for (final m in starterMedicines) {
        await db.insert('medicines', m);
      }

      // Starter Supplier
      await db.insert('suppliers', {
        'name': 'Ali Medical Distributors',
        'phone': '0321-4567890',
        'address': 'Pharma Wholesale Market, Shop #12',
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'remainingAmount': 0.0,
        'active': 1,
      });

      // Starter Retail Customer
      await db.insert('customers', {
        'name': 'Muhammad Tariq',
        'phone': '0300-5551234',
        'address': 'Street 4, Sector G',
        'customerType': 'RETAIL',
        'totalAmount': 850.0,
        'paidAmount': 500.0,
        'remainingAmount': 350.0,
        'active': 1,
      });

      // Starter Wholesale Customer
      await db.insert('customers', {
        'name': 'Al-Shifa Community Pharmacy',
        'phone': '0312-7778899',
        'address': 'Hospital Road, Complex Market',
        'customerType': 'WHOLESALE',
        'companyName': 'Al-Shifa Healthcare Ltd',
        'totalAmount': 24500.0,
        'paidAmount': 18000.0,
        'remainingAmount': 6500.0,
        'active': 1,
      });
    }
  }

  // ==========================================
  // 💊 MEDICINES REPOSITORY
  // ==========================================

  static Future<List<Medicine>> getMedicines({String? query, String? category}) async {
    final db = await getDatabase();
    String whereClause = 'active = 1';
    List<dynamic> whereArgs = [];

    if (category != null && category != 'All' && category.isNotEmpty) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (query != null && query.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR companyName LIKE ?)';
      final q = '%${query.trim()}%';
      whereArgs.addAll([q, q]);
    }

    final rows = await db.query(
      'medicines',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return rows.map((e) => Medicine.fromMap(e)).toList();
  }

  static Future<Medicine?> getMedicineById(int id) async {
    final db = await getDatabase();
    final rows = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Medicine.fromMap(rows.first);
  }

  static Future<int> insertMedicine(Medicine medicine) async {
    final db = await getDatabase();
    return await db.insert('medicines', medicine.toMap());
  }

  static Future<int> updateMedicine(Medicine medicine) async {
    final db = await getDatabase();
    return await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  static Future<int> deleteMedicine(int id) async {
    final db = await getDatabase();
    // Soft delete: mark active = 0 to preserve sale and invoice integrity
    return await db.update(
      'medicines',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Medicine>> getLowStockMedicines() async {
    final db = await getDatabase();
    final rows = await db.rawQuery(
      'SELECT * FROM medicines WHERE active = 1 AND currentStock <= minStockLevel AND currentStock > 0 ORDER BY currentStock ASC',
    );
    return rows.map((e) => Medicine.fromMap(e)).toList();
  }

  static Future<List<Medicine>> getOutOfStockMedicines() async {
    final db = await getDatabase();
    final rows = await db.rawQuery(
      'SELECT * FROM medicines WHERE active = 1 AND currentStock <= 0 ORDER BY name ASC',
    );
    return rows.map((e) => Medicine.fromMap(e)).toList();
  }

  static Future<List<Medicine>> getExpiringSoonMedicines([int days = 30]) async {
    final db = await getDatabase();
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final limitStr = now.add(Duration(days: days)).toIso8601String().substring(0, 10);

    final rows = await db.rawQuery(
      'SELECT * FROM medicines WHERE active = 1 AND nearestExpiryDate IS NOT NULL AND nearestExpiryDate != "" AND nearestExpiryDate >= ? AND nearestExpiryDate <= ? ORDER BY nearestExpiryDate ASC',
      [todayStr, limitStr],
    );
    return rows.map((e) => Medicine.fromMap(e)).toList();
  }

  static Future<List<Medicine>> getExpiredMedicines() async {
    final db = await getDatabase();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final rows = await db.rawQuery(
      'SELECT * FROM medicines WHERE active = 1 AND nearestExpiryDate IS NOT NULL AND nearestExpiryDate != "" AND nearestExpiryDate < ? ORDER BY nearestExpiryDate ASC',
      [todayStr],
    );
    return rows.map((e) => Medicine.fromMap(e)).toList();
  }

  // ==========================================
  // 👥 CUSTOMERS REPOSITORY
  // ==========================================

  static Future<List<Customer>> getCustomers({String? query, String? type}) async {
    final db = await getDatabase();
    String whereClause = 'active = 1';
    List<dynamic> whereArgs = [];

    if (type != null && type.isNotEmpty && type != 'ALL') {
      whereClause += ' AND customerType = ?';
      whereArgs.add(type);
    }

    if (query != null && query.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ? OR companyName LIKE ?)';
      final q = '%${query.trim()}%';
      whereArgs.addAll([q, q, q]);
    }

    final rows = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return rows.map((e) => Customer.fromMap(e)).toList();
  }

  static Future<List<Customer>> getRetailCustomers({String? query}) {
    return getCustomers(query: query, type: 'RETAIL');
  }

  static Future<List<Customer>> getWholesaleCustomers({String? query}) {
    return getCustomers(query: query, type: 'WHOLESALE');
  }

  static Future<Customer?> getCustomerById(int id) async {
    final db = await getDatabase();
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  static Future<int> insertCustomer(Customer customer) async {
    final db = await getDatabase();
    return await db.insert('customers', customer.toMap());
  }

  static Future<int> updateCustomer(Customer customer) async {
    final db = await getDatabase();
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  static Future<int> deleteCustomer(int id) async {
    final db = await getDatabase();
    return await db.update(
      'customers',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> receiveCustomerPayment(int customerId, double amount, [int? invoiceId]) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      await txn.insert('customer_payments', {
        'customerId': customerId,
        'invoiceId': invoiceId,
        'amount': amount,
        'paymentDate': DateTime.now().toIso8601String(),
      });

      await txn.rawUpdate(
        'UPDATE customers SET paidAmount = paidAmount + ?, remainingAmount = totalAmount - (paidAmount + ?) WHERE id = ?',
        [amount, amount, customerId],
      );
    });
  }

  static Future<List<CustomerPayment>> getCustomerPayments(int customerId) async {
    final db = await getDatabase();
    final rows = await db.query(
      'customer_payments',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'paymentDate DESC',
    );
    return rows.map((e) => CustomerPayment.fromMap(e)).toList();
  }

  // ==========================================
  // 🚚 SUPPLIERS REPOSITORY
  // ==========================================

  static Future<List<Supplier>> getSuppliers({String? query}) async {
    final db = await getDatabase();
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      final rows = await db.query(
        'suppliers',
        where: 'active = 1 AND (name LIKE ? OR phone LIKE ?)',
        whereArgs: [q, q],
        orderBy: 'name ASC',
      );
      return rows.map((e) => Supplier.fromMap(e)).toList();
    }
    final rows = await db.query('suppliers', where: 'active = 1', orderBy: 'name ASC');
    return rows.map((e) => Supplier.fromMap(e)).toList();
  }

  static Future<Supplier?> getSupplierById(int id) async {
    final db = await getDatabase();
    final rows = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Supplier.fromMap(rows.first);
  }

  static Future<int> insertSupplier(Supplier supplier) async {
    final db = await getDatabase();
    return await db.insert('suppliers', supplier.toMap());
  }

  static Future<int> updateSupplier(Supplier supplier) async {
    final db = await getDatabase();
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  static Future<int> deleteSupplier(int id) async {
    final db = await getDatabase();
    return await db.update(
      'suppliers',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> paySupplier(int supplierId, double amount, [int? purchaseInvoiceId]) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      await txn.insert('supplier_payments', {
        'supplierId': supplierId,
        'purchaseInvoiceId': purchaseInvoiceId,
        'amount': amount,
        'paymentDate': DateTime.now().toIso8601String(),
      });

      await txn.rawUpdate(
        'UPDATE suppliers SET paidAmount = paidAmount + ?, remainingAmount = totalAmount - (paidAmount + ?) WHERE id = ?',
        [amount, amount, supplierId],
      );
    });
  }

  static Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async {
    final db = await getDatabase();
    final rows = await db.query(
      'supplier_payments',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'paymentDate DESC',
    );
    return rows.map((e) => SupplierPayment.fromMap(e)).toList();
  }

  // ==========================================
  // 🛒 INVOICES & POS REPOSITORY
  // ==========================================

  static Future<Invoice> createSaleInvoice(Invoice invoice) async {
    final db = await getDatabase();

    return await db.transaction((txn) async {
      // 1. Insert Invoice Header
      final invoiceId = await txn.insert('invoices', invoice.toMap());

      // 2. Insert Invoice Items and Deduct Medicine Stock
      final createdItems = <InvoiceItem>[];
      for (final item in invoice.items) {
        final itemMap = item.toMap();
        itemMap['invoiceId'] = invoiceId;
        final itemId = await txn.insert('invoice_items', itemMap);
        createdItems.add(item.copyWith(id: itemId, invoiceId: invoiceId));

        if (item.medicineId != null) {
          await txn.rawUpdate(
            'UPDATE medicines SET currentStock = currentStock - ? WHERE id = ?',
            [item.quantity, item.medicineId],
          );
        }
      }

      // 3. Update Customer Ledger if linked
      if (invoice.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET totalAmount = totalAmount + ?, paidAmount = paidAmount + ?, remainingAmount = (totalAmount + ?) - (paidAmount + ?) WHERE id = ?',
          [invoice.totalAmount, invoice.paidAmount, invoice.totalAmount, invoice.paidAmount, invoice.customerId],
        );
      }

      // 4. Record Payment if paid > 0
      if (invoice.paidAmount > 0) {
        await txn.insert('customer_payments', {
          'customerId': invoice.customerId,
          'invoiceId': invoiceId,
          'amount': invoice.paidAmount,
          'paymentDate': invoice.invoiceDate,
        });
      }

      return invoice.copyWith(id: invoiceId, items: createdItems);
    });
  }

  static Future<List<Invoice>> getInvoices({int? customerId, int limit = 50}) async {
    final db = await getDatabase();
    List<Map<String, dynamic>> rows;

    if (customerId != null) {
      rows = await db.query(
        'invoices',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'invoiceDate DESC',
        limit: limit,
      );
    } else {
      rows = await db.query('invoices', orderBy: 'invoiceDate DESC', limit: limit);
    }

    final invoices = <Invoice>[];
    for (final r in rows) {
      final invoiceId = r['id'] as int;
      final itemRows = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
      final items = itemRows.map((e) => InvoiceItem.fromMap(e)).toList();
      invoices.add(Invoice.fromMap(r, items));
    }
    return invoices;
  }

  static Future<Invoice?> getInvoiceById(int id) async {
    final db = await getDatabase();
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final itemRows = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [id]);
    final items = itemRows.map((e) => InvoiceItem.fromMap(e)).toList();
    return Invoice.fromMap(rows.first, items);
  }

  // ==========================================
  // 🛍️ PURCHASES & STOCK-IN REPOSITORY
  // ==========================================

  static Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async {
    final db = await getDatabase();

    return await db.transaction((txn) async {
      // 1. Insert Header
      final invoiceId = await txn.insert('purchase_invoices', invoice.toMap());

      // 2. Insert items, update medicine stock, buying price & nearest expiry
      final savedItems = <StockIn>[];
      for (final item in invoice.items) {
        final itemMap = item.toMap();
        itemMap['purchaseInvoiceId'] = invoiceId;
        final stockInId = await txn.insert('stock_in', itemMap);
        savedItems.add(StockIn.fromMap({...itemMap, 'id': stockInId}));

        // Update medicine stock & latest buying price
        await txn.rawUpdate(
          'UPDATE medicines SET currentStock = currentStock + ?, buyingPrice = ? WHERE id = ?',
          [item.quantity, item.buyingPrice, item.medicineId],
        );

        // Update nearest expiry if this expiry is earlier
        if (item.expiryDate != null && item.expiryDate!.isNotEmpty) {
          final medRow = await txn.query('medicines', columns: ['nearestExpiryDate'], where: 'id = ?', whereArgs: [item.medicineId]);
          if (medRow.isNotEmpty) {
            final currentExpiry = medRow.first['nearestExpiryDate'] as String?;
            if (currentExpiry == null || currentExpiry.isEmpty || item.expiryDate!.compareTo(currentExpiry) < 0) {
              await txn.update(
                'medicines',
                {'nearestExpiryDate': item.expiryDate},
                where: 'id = ?',
                whereArgs: [item.medicineId],
              );
            }
          }
        }
      }

      // 3. Update Supplier Ledger
      if (invoice.supplierId != null) {
        await txn.rawUpdate(
          'UPDATE suppliers SET totalAmount = totalAmount + ?, paidAmount = paidAmount + ?, remainingAmount = (totalAmount + ?) - (paidAmount + ?) WHERE id = ?',
          [invoice.totalAmount, invoice.paidAmount, invoice.totalAmount, invoice.paidAmount, invoice.supplierId],
        );

        if (invoice.paidAmount > 0) {
          await txn.insert('supplier_payments', {
            'supplierId': invoice.supplierId,
            'purchaseInvoiceId': invoiceId,
            'amount': invoice.paidAmount,
            'paymentDate': invoice.purchaseDate,
          });
        }
      }

      return invoice;
    });
  }

  static Future<StockIn> quickStockIn(StockIn stockIn) async {
    final db = await getDatabase();

    return await db.transaction((txn) async {
      final id = await txn.insert('stock_in', stockIn.toMap());

      // Update medicine stock & buying price
      await txn.rawUpdate(
        'UPDATE medicines SET currentStock = currentStock + ?, buyingPrice = ? WHERE id = ?',
        [stockIn.quantity, stockIn.buyingPrice, stockIn.medicineId],
      );

      // Update nearest expiry date
      if (stockIn.expiryDate != null && stockIn.expiryDate!.isNotEmpty) {
        final medRow = await txn.query('medicines', columns: ['nearestExpiryDate'], where: 'id = ?', whereArgs: [stockIn.medicineId]);
        if (medRow.isNotEmpty) {
          final currentExpiry = medRow.first['nearestExpiryDate'] as String?;
          if (currentExpiry == null || currentExpiry.isEmpty || stockIn.expiryDate!.compareTo(currentExpiry) < 0) {
            await txn.update(
              'medicines',
              {'nearestExpiryDate': stockIn.expiryDate},
              where: 'id = ?',
              whereArgs: [stockIn.medicineId],
            );
          }
        }
      }

      return StockIn.fromMap({...stockIn.toMap(), 'id': id});
    });
  }

  static Future<List<PurchaseInvoice>> getPurchaseInvoices({int limit = 50}) async {
    final db = await getDatabase();
    final rows = await db.query('purchase_invoices', orderBy: 'purchaseDate DESC', limit: limit);

    final result = <PurchaseInvoice>[];
    for (final r in rows) {
      final id = r['id'] as int;
      final itemRows = await db.rawQuery('''
        SELECT s.*, m.name as medicineName 
        FROM stock_in s 
        JOIN medicines m ON s.medicineId = m.id 
        WHERE s.purchaseInvoiceId = ?
      ''', [id]);
      final items = itemRows.map((e) => StockIn.fromMap(e, e['medicineName'] as String?)).toList();
      result.add(PurchaseInvoice.fromMap(r, items));
    }
    return result;
  }

  static Future<List<StockIn>> getStockInHistory({int? medicineId, int limit = 50}) async {
    final db = await getDatabase();
    String query = '''
      SELECT s.*, m.name as medicineName, sup.name as supplierName 
      FROM stock_in s 
      JOIN medicines m ON s.medicineId = m.id 
      LEFT JOIN suppliers sup ON s.supplierId = sup.id
    ''';
    List<dynamic> args = [];
    if (medicineId != null) {
      query += ' WHERE s.medicineId = ?';
      args.add(medicineId);
    }
    query += ' ORDER BY s.purchaseDate DESC LIMIT ?';
    args.add(limit);

    final rows = await db.rawQuery(query, args);
    return rows.map((e) => StockIn.fromMap(e, e['medicineName'] as String?, e['supplierName'] as String?)).toList();
  }

  // ==========================================
  // 🔄 RETURNS REPOSITORY
  // ==========================================

  static Future<CustomerReturn> createCustomerReturn(CustomerReturn ret) async {
    final db = await getDatabase();

    return await db.transaction((txn) async {
      final id = await txn.insert('customer_returns', ret.toMap());

      // ➕ Back into sellable stock
      await txn.rawUpdate(
        'UPDATE medicines SET currentStock = currentStock + ? WHERE id = ?',
        [ret.quantity, ret.medicineId],
      );

      // If customer is linked, adjust totalAmount and remainingAmount
      if (ret.customerId != null && ret.refundAmount > 0) {
        await txn.rawUpdate(
          'UPDATE customers SET remainingAmount = remainingAmount - ? WHERE id = ?',
          [ret.refundAmount, ret.customerId],
        );
      }

      return CustomerReturn.fromMap({...ret.toMap(), 'id': id});
    });
  }

  static Future<SupplierReturn> createSupplierReturn(SupplierReturn ret) async {
    final db = await getDatabase();

    return await db.transaction((txn) async {
      // Check stock
      final med = await txn.query('medicines', columns: ['currentStock'], where: 'id = ?', whereArgs: [ret.medicineId]);
      if (med.isEmpty) throw Exception('Medicine not found');
      final currentStock = (med.first['currentStock'] as num).toDouble();
      if (currentStock < ret.quantity) {
        throw Exception('Stock kam hai: Sirf $currentStock available hai');
      }

      final id = await txn.insert('supplier_returns', ret.toMap());

      // ➖ Deduct from inventory
      await txn.rawUpdate(
        'UPDATE medicines SET currentStock = currentStock - ? WHERE id = ?',
        [ret.quantity, ret.medicineId],
      );

      // Adjust supplier payable ledger
      if (ret.supplierId != null && ret.creditAmount > 0) {
        await txn.rawUpdate(
          'UPDATE suppliers SET remainingAmount = remainingAmount - ? WHERE id = ?',
          [ret.creditAmount, ret.supplierId],
        );
      }

      return SupplierReturn.fromMap({...ret.toMap(), 'id': id});
    });
  }

  static Future<List<CustomerReturn>> getCustomerReturns({int limit = 50}) async {
    final db = await getDatabase();
    final rows = await db.rawQuery('''
      SELECT cr.*, m.name as medicineName 
      FROM customer_returns cr 
      JOIN medicines m ON cr.medicineId = m.id 
      ORDER BY cr.returnDate DESC LIMIT ?
    ''', [limit]);
    return rows.map((e) => CustomerReturn.fromMap(e, e['medicineName'] as String?)).toList();
  }

  static Future<List<SupplierReturn>> getSupplierReturns({int limit = 50}) async {
    final db = await getDatabase();
    final rows = await db.rawQuery('''
      SELECT sr.*, m.name as medicineName 
      FROM supplier_returns sr 
      JOIN medicines m ON sr.medicineId = m.id 
      ORDER BY sr.returnDate DESC LIMIT ?
    ''', [limit]);
    return rows.map((e) => SupplierReturn.fromMap(e, e['medicineName'] as String?)).toList();
  }

  // ==========================================
  // 💸 EXPENSES REPOSITORY
  // ==========================================

  static Future<List<Expense>> getExpenses({String? monthFilter, int limit = 100}) async {
    final db = await getDatabase();
    String query = 'SELECT * FROM expenses';
    List<dynamic> args = [];

    if (monthFilter != null && monthFilter.isNotEmpty) {
      query += ' WHERE expenseDate LIKE ?';
      args.add('$monthFilter%');
    }
    query += ' ORDER BY expenseDate DESC LIMIT ?';
    args.add(limit);

    final rows = await db.rawQuery(query, args);
    return rows.map((e) => Expense.fromMap(e)).toList();
  }

  static Future<int> insertExpense(Expense expense) async {
    final db = await getDatabase();
    return await db.insert('expenses', expense.toMap());
  }

  static Future<int> deleteExpense(int id) async {
    final db = await getDatabase();
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // ⚙️ SETTINGS REPOSITORY
  // ==========================================

  static Future<StoreSettings> getSettings() async {
    final db = await getDatabase();
    final rows = await db.query('settings', where: 'id = 1');
    if (rows.isEmpty) {
      final s = StoreSettings();
      await db.insert('settings', s.toMap());
      return s;
    }
    return StoreSettings.fromMap(rows.first);
  }

  static Future<void> updateSettings(StoreSettings settings) async {
    final db = await getDatabase();
    await db.insert('settings', settings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==========================================
  // 📊 REPORTS & ANALYTICS
  // ==========================================

  static Future<ProfitSummary> getProfitSummary([String period = 'today']) async {
    final db = await getDatabase();
    final now = DateTime.now();
    String dateFilter = '';
    List<dynamic> args = [];

    if (period == 'today') {
      final todayStr = now.toIso8601String().substring(0, 10);
      dateFilter = ' WHERE invoiceDate LIKE ?';
      args.add('$todayStr%');
    } else if (period == 'month') {
      final monthStr = now.toIso8601String().substring(0, 7);
      dateFilter = ' WHERE invoiceDate LIKE ?';
      args.add('$monthStr%');
    }

    // Revenue
    final revResult = await db.rawQuery('SELECT SUM(totalAmount) as total FROM invoices$dateFilter', args);
    final totalRev = (revResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Refunds
    String retFilter = dateFilter.replaceAll('invoiceDate', 'returnDate');
    final refResult = await db.rawQuery('SELECT SUM(refundAmount) as total FROM customer_returns$retFilter', args);
    final totalRefunds = (refResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final netRevenue = totalRev - totalRefunds;

    // Cost of Goods Sold
    String itemQuery = '''
      SELECT SUM(ii.quantity * ii.buyingPrice) as cost 
      FROM invoice_items ii 
      JOIN invoices inv ON ii.invoiceId = inv.id 
      $dateFilter
    ''';
    final costResult = await db.rawQuery(itemQuery, args);
    final grossCost = (costResult.first['cost'] as num?)?.toDouble() ?? 0.0;

    // Returned COGS
    final retCostResult = await db.rawQuery(
      'SELECT SUM(quantity * buyingPriceSnapshot) as total FROM customer_returns$retFilter',
      args,
    );
    final returnedCost = (retCostResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final netCost = grossCost - returnedCost;
    final grossProfit = netRevenue - netCost;

    // Expenses
    String expFilter = dateFilter.replaceAll('invoiceDate', 'expenseDate');
    final expResult = await db.rawQuery('SELECT SUM(amount) as total FROM expenses$expFilter', args);
    final totalExpenses = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Retail vs Wholesale Revenue breakdown
    final retailWhere = dateFilter.isEmpty ? " WHERE (invoiceType = 'RETAIL' OR invoiceType IS NULL)" : "$dateFilter AND (invoiceType = 'RETAIL' OR invoiceType IS NULL)";
    final wholesaleWhere = dateFilter.isEmpty ? " WHERE invoiceType = 'WHOLESALE'" : "$dateFilter AND invoiceType = 'WHOLESALE'";

    final retailRevResult = await db.rawQuery('SELECT SUM(totalAmount) as total FROM invoices$retailWhere', args);
    final retailRev = (retailRevResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final wholesaleRevResult = await db.rawQuery('SELECT SUM(totalAmount) as total FROM invoices$wholesaleWhere', args);
    final wholesaleRev = (wholesaleRevResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return ProfitSummary(
      revenue: netRevenue > 0 ? netRevenue : 0.0,
      cost: netCost > 0 ? netCost : 0.0,
      gross: grossProfit,
      expenses: totalExpenses,
      net: grossProfit - totalExpenses,
      retailRevenue: retailRev,
      wholesaleRevenue: wholesaleRev,
    );
  }

  static Future<double> getTodayCashCollected() async {
    final db = await getDatabase();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM customer_payments WHERE paymentDate LIKE ?',
      ['$todayStr%'],
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<double> getInventoryValuation() async {
    final db = await getDatabase();
    final res = await db.rawQuery(
      'SELECT SUM(currentStock * buyingPrice) as costVal, SUM(currentStock * sellingPrice) as retailVal FROM medicines WHERE active = 1',
    );
    return (res.first['costVal'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<Map<String, double>> getFullInventoryValuation() async {
    final db = await getDatabase();
    final res = await db.rawQuery(
      'SELECT SUM(currentStock * buyingPrice) as costVal, '
      'SUM(currentStock * CASE WHEN retailPrice > 0 THEN retailPrice ELSE sellingPrice END) as retailVal, '
      'SUM(currentStock * sellingPrice) as sellingVal '
      'FROM medicines WHERE active = 1',
    );
    final costVal = (res.first['costVal'] as num?)?.toDouble() ?? 0.0;
    final retailVal = (res.first['retailVal'] as num?)?.toDouble() ?? 0.0;
    final sellingVal = (res.first['sellingVal'] as num?)?.toDouble() ?? 0.0;
    return {
      'cost': costVal,
      'retail': retailVal,
      'selling': sellingVal,
      'potentialProfit': (sellingVal > 0 ? sellingVal : retailVal) - costVal,
    };
  }

  static Future<NeedsAttention> getNeedsAttention() async {
    final low = (await getLowStockMedicines()).length;
    final out = (await getOutOfStockMedicines()).length;
    final expiring = (await getExpiringSoonMedicines(30)).length;
    final expired = (await getExpiredMedicines()).length;

    return NeedsAttention(
      lowStock: low,
      outOfStock: out,
      expired: expired,
      expiringSoon: expiring,
    );
  }

  static Future<List<TopSeller>> getTopSellers([int limit = 10]) async {
    final db = await getDatabase();
    final rows = await db.rawQuery('''
      SELECT medicineName, SUM(quantity) as units, SUM(totalPrice) as rev 
      FROM invoice_items 
      GROUP BY medicineName 
      ORDER BY rev DESC 
      LIMIT ?
    ''', [limit]);

    return rows.map((r) {
      return TopSeller(
        medicineName: r['medicineName'] as String? ?? 'Unknown',
        unitsSold: (r['units'] as num?)?.toDouble() ?? 0.0,
        revenue: (r['rev'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  static Future<List<DayRevenue>> getRevenueLastNDays([int days = 7]) async {
    final db = await getDatabase();
    final now = DateTime.now();
    final result = <DayRevenue>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final label = '${date.day}/${date.month}';

      final res = await db.rawQuery(
        'SELECT SUM(totalAmount) as total FROM invoices WHERE invoiceDate LIKE ?',
        ['$dateStr%'],
      );
      final total = (res.first['total'] as num?)?.toDouble() ?? 0.0;
      result.add(DayRevenue(label, total));
    }
    return result;
  }

  static Future<List<CategoryCount>> getStockByCategory() async {
    final db = await getDatabase();
    final rows = await db.rawQuery('''
      SELECT COALESCE(NULLIF(category, ''), 'General') as cat, COUNT(*) as cnt 
      FROM medicines 
      WHERE active = 1 
      GROUP BY cat 
      ORDER BY cnt DESC
    ''');
    return rows.map((r) => CategoryCount(r['cat'] as String, (r['cnt'] as num).toInt())).toList();
  }

  // ==========================================
  // 🏥 LEGACY CLINIC APP PATIENT SUPPORT
  // ==========================================

  static Future<int> insertPatient(Patient patient) async {
    final db = await getDatabase();
    return await db.insert('patients', patient.toMap());
  }

  static Future<List<Patient>> getPatients() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('patients');
    return List.generate(maps.length, (index) => Patient.fromMap(maps[index]));
  }

  static Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await getDatabase();
    return await db.transaction((txn) async {
      final id = await txn.insert('transactions', transaction.toMap());
      final delta = transaction.type == TransactionType.loan ? transaction.amount : -transaction.amount;
      await txn.rawUpdate(
        'UPDATE patients SET balance = balance + ? WHERE id = ?',
        [delta, transaction.patientId],
      );
      return id;
    });
  }

  static Future<int> deleteTransaction(int transactionId) async {
    final db = await getDatabase();
    return await db.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
  }

  static Future<double> getCurrentBalance(int patientId) async {
    final db = await getDatabase();
    final result = await db.query(
      'patients',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [patientId],
    );
    if (result.isEmpty || result.first['balance'] == null) return 0;
    return (result.first['balance'] as num).toDouble();
  }

  static Future<List<TransactionModel>> getTransactionsByPatient(int patientId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (index) => TransactionModel.fromMap(maps[index]));
  }
}
