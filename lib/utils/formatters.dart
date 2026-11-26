import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFmt = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _intCurrencyFmt = NumberFormat('#,##0', 'en_US');
  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFmt = DateFormat('dd/MM/yy');
  static final DateFormat _dbDateFmt = DateFormat('yyyy-MM-dd');

  static String formatCurrency(num amount, [String symbol = 'Rs.']) {
    // If it's a whole number, format without .00 for cleaner display
    if (amount % 1 == 0) {
      return '$symbol ${_intCurrencyFmt.format(amount)}';
    }
    return '$symbol ${_currencyFmt.format(amount)}';
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return _dateFmt.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return _dateTimeFmt.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatShortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return _shortDateFmt.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String toDbDate(DateTime dt) {
    return _dbDateFmt.format(dt);
  }
}

