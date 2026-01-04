import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictionApi {
  static const String baseUrl =
      'https://urban-pollution-forecasting-explainable.onrender.com';

  /// Fetch pollution prediction for a given location and date.
  static Future<Map<String, dynamic>> fetchPrediction({
    required String location,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'location': location,
        'date': date,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load prediction');
    }
  }
}
