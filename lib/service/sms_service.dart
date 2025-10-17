import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsService {
  static const String _apiKey = "To3EIvwsGFmQMCG1DNRl";
  static const String _senderId = "8809617620392";

  /// Function to send SMS
  /// number: String -> receiver number
  /// message: String -> SMS body
  /// returns: API response as String
  static Future<String> sendSms({
    required String number,
    required String message,
  }) async {
    final String encodedMessage = Uri.encodeComponent(message);
    final String url =
        "http://bulksmsbd.net/api/smsapi?api_key=$_apiKey&type=text&number=$number&senderid=$_senderId&message=$encodedMessage";

    try {
      final response = await http.get(Uri.parse(url));
      return response.body; // 202 = success, others = error codes
    } catch (e) {
      return "Error sending SMS: $e";
    }
  }
}