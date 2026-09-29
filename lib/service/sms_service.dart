import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static Future<String> sendSms({
    required String number,
    required String message,
  }) async {
    try {
      final uri = Uri(
        scheme: 'sms',
        path: number,
        queryParameters: <String, String>{'body': message},
      );
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? 'OPENED' : 'SMS app not available';
    } catch (e) {
      return 'Error sending SMS: $e';
    }
  }
}
