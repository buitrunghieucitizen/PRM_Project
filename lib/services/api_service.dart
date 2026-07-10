import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web/Desktop
  static const String baseUrl = 'http://10.0.2.2:5022/api';
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': 'Đăng nhập thất bại. Kiểm tra lại email/mật khẩu.'};
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    }
    return {'success': false, 'message': 'Đăng ký thất bại. Có thể email đã tồn tại.'};
  }

  static Future<Map<String, dynamic>> getSummary() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/reports/summary'), headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load summary');
  }

  static Future<List<dynamic>> getTransactions() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/transactions'), headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> chatAI(String message) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: headers,
      body: jsonEncode({'message': message}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'role': 'assistant', 'text': 'Xin lỗi, tôi không thể kết nối tới AI lúc này.'};
  }
  // --- Goals ---
  static Future<List<dynamic>> getGoals() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/goals'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/goals'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to create goal');
  }

  static Future<Map<String, dynamic>> updateGoal(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(Uri.parse('$baseUrl/goals/$id'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update goal');
  }

  static Future<void> deleteGoal(int id) async {
    final headers = await _getHeaders();
    await http.delete(Uri.parse('$baseUrl/goals/$id'), headers: headers);
  }

  // --- Transactions ---
  static Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/transactions'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to add transaction');
  }

  static Future<void> deleteTransaction(int id) async {
    final headers = await _getHeaders();
    await http.delete(Uri.parse('$baseUrl/transactions/$id'), headers: headers);
  }

  // --- Budgets / Monthly Plan ---
  static Future<Map<String, dynamic>> getCurrentBudget() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/budgets/current'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to get current budget');
  }

  static Future<Map<String, dynamic>> setBudget(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/budgets'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to set budget');
  }

  // --- AI Suggestion ---
  static Future<String?> suggestBudget(double totalBudget, List<Map<String, dynamic>> lockedCategories, List<String> targetCategories) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/suggest-budget'),
      headers: headers,
      body: jsonEncode({
        'totalBudget': totalBudget,
        'lockedCategories': lockedCategories,
        'targetCategories': targetCategories,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['suggestion'];
    }
    return null;
  }
}
