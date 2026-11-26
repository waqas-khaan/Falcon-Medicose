import 'package:url_launcher/url_launcher.dart';
import '../utils/formatters.dart';

class SmsService {
  static Future<void> sendLoanSms({
    required String phone,
    required String patientName,
    required double amount,
    required double balance,
    String storeName = 'Falcon Medicose',
    String contactPhone = '',
  }) async {
    final contactLine =
        contactPhone.isNotEmpty ? '\nContact: $contactPhone' : '';
    final message = 'Dear $patientName,\n'
        'This is a friendly reminder from $storeName.\n\n'
        'Loan Added: ${Formatters.formatCurrency(amount)}\n'
        'Remaining Balance: ${Formatters.formatCurrency(balance)}\n\n'
        'Please clear your remaining balance at your earliest convenience. Thank you!'
        '$contactLine';

    await _openSmsComposer(phone, message);
  }

  static Future<void> sendPaymentSms({
    required String phone,
    required String patientName,
    required double amount,
    required double balance,
    double? totalPayment,
    String storeName = 'Falcon Medicose',
    String contactPhone = '',
  }) async {
    final totalLine = totalPayment != null
        ? 'Total Payment: ${Formatters.formatCurrency(totalPayment)}\n'
        : '';
    final contactLine =
        contactPhone.isNotEmpty ? '\nContact: $contactPhone' : '';
    final message = 'Dear $patientName,\n'
        'This is a friendly reminder from $storeName.\n\n'
        '$totalLine'
        'Received: ${Formatters.formatCurrency(amount)}\n'
        'Remaining Balance: ${Formatters.formatCurrency(balance)}\n\n'
        'Please clear your remaining balance at your earliest convenience. Thank you!'
        '$contactLine';

    await _openSmsComposer(phone, message);
  }

  static Future<void> _openSmsComposer(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    final opened = await launchUrl(uri);

    if (!opened) {
      throw Exception(
        "Could not open the messaging app. Please make sure a default "
        "SMS app is set on this phone.",
      );
    }
  }
}
