import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static Future<void> sendLoanSms({
    required String phone,
    required String patientName,
    required double amount,
    required double balance,
  }) async {
    String message =
        '''
Falcon Medicose

Dear $patientName,

Loan Added

Amount : Rs.${amount.toStringAsFixed(0)}

Current Balance : Rs.${balance.toStringAsFixed(0)}

Thank You
''';

    await _openSmsComposer(phone, message);
  }

  static Future<void> sendPaymentSms({
    required String phone,
    required String patientName,
    required double amount,
    required double balance,
  }) async {
    String message =
        '''
Falcon Medicose

Dear $patientName,

Payment Received

Amount : Rs.${amount.toStringAsFixed(0)}

Remaining Balance : Rs.${balance.toStringAsFixed(0)}

Thank You
''';

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
