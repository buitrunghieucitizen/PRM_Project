import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String baseUrl = kIsWeb ? 'http://localhost:5172/api' : 'http://10.0.2.2:5172/api';
  
  static String? _token;
  static int? _userId;
  
  static final Map<String, dynamic> _apiCache = {};

  static void clearCache() {
    _apiCache.clear();
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userId = prefs.getInt('user_id');
  }

  static Future<void> saveAuth(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setInt('user_id', userId);
    _token = token;
    _userId = userId;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    _token = null;
    _userId = null;
  }

  static bool get isLoggedIn => _token != null && _userId != null;
  static int get currentUserId => _userId ?? 0;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth Methods
  Future<bool> updateUser(int userId, String fullName, String? phoneNumber, String? jobTitle, double? monthlySalary) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'jobTitle': jobTitle,
        'monthlySalary': monthlySalary,
      }),
    );
    if (response.statusCode == 200) {
      clearCache();
      return true;
    }
    return false;
  }

  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/change-password'),
      headers: _headers,
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> register(String email, String password) async { final response = await http.post(Uri.parse('$baseUrl/Users/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'passwordHash': password, 'username': email.split('@')[0], 'isProfileComplete': false})); if (response.statusCode == 200) { return jsonDecode(response.body); } throw Exception(response.body); }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'passwordHash': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Login failed: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Users/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Google Login failed: ${response.statusCode} - ${response.body}');
  }

  Future<void> onboardUser({
    required String fullName,
    required String phoneNumber,
    required String jobTitle,
    required double monthlySalary,
    required double? incomeGoal,
    required String expensesDescription,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Users/onboard'),
      headers: _headers,
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'jobTitle': jobTitle,
        'monthlySalary': monthlySalary,
        'incomeGoal': incomeGoal,
        'expensesDescription': expensesDescription,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Onboard failed: ${response.body}');
    }
  }

  Future<User> getUser(int userId) async {
    String url = '$baseUrl/Users/$userId';
    if (_apiCache.containsKey(url)) return _apiCache[url] as User;

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      var user = User.fromJson(jsonDecode(response.body));
      _apiCache[url] = user;
      return user;
    } else {
      throw Exception('Failed to load user');
    }
  }

  // Data Methods
  Future<List<Transaction>> getTransactions(int userId, {int? limit, int? offset, DateTime? startDate, DateTime? endDate}) async {
    String url = '$baseUrl/Transactions/$userId?';
    if (limit != null) url += 'limit=$limit&';
    if (offset != null) url += 'offset=$offset&';
    if (startDate != null) url += 'startDate=${startDate.toIso8601String()}&';
    if (endDate != null) url += 'endDate=${endDate.toIso8601String()}&';

    if (_apiCache.containsKey(url)) return _apiCache[url] as List<Transaction>;

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      var result = List<Transaction>.from(l.map((model) => Transaction.fromJson(model)));
      _apiCache[url] = result;
      return result;
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Transactions'),
      headers: _headers,
      body: jsonEncode(transaction.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCache();
      return Transaction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add transaction');
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Transactions/${transaction.id}'),
      headers: _headers,
      body: jsonEncode(transaction.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      clearCache();
      return transaction; // usually API returns updated object or we just return passed object
    } else {
      throw Exception('Failed to update transaction');
    }
  }

  Future<List<Goal>> getGoals(int userId) async {
    String url = '$baseUrl/Goals/$userId';
    if (_apiCache.containsKey(url)) return _apiCache[url] as List<Goal>;

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      var result = List<Goal>.from(l.map((model) => Goal.fromJson(model)));
      _apiCache[url] = result;
      return result;
    } else {
      throw Exception('Failed to load goals');
    }
  }

  Future<Goal> addGoal(Goal goal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Goals'),
      headers: _headers,
      body: jsonEncode(goal.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCache();
      return Goal.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add goal');
    }
  }

  Future<Goal> updateGoal(Goal goal) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Goals/${goal.id}'),
      headers: _headers,
      body: jsonEncode(goal.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      clearCache();
      return goal;
    } else {
      throw Exception('Failed to update goal');
    }
  }

  Future<List<MonthlyPlan>> getPlans(int userId, {int? month, int? year}) async {
    String url = '$baseUrl/MonthlyPlans/$userId';
    if (month != null && year != null) {
      url += '?month=$month&year=$year';
    }
    if (_apiCache.containsKey(url)) return _apiCache[url] as List<MonthlyPlan>;

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      var result = List<MonthlyPlan>.from(l.map((model) => MonthlyPlan.fromJson(model)));
      _apiCache[url] = result;
      return result;
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<MonthlyPlan> addPlan(MonthlyPlan plan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/MonthlyPlans'),
      headers: _headers,
      body: jsonEncode(plan.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCache();
      return MonthlyPlan.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add plan');
    }
  }

  Future<MonthlyPlan> updatePlan(MonthlyPlan plan) async {
    final response = await http.put(
      Uri.parse('$baseUrl/MonthlyPlans/${plan.id}'),
      headers: _headers,
      body: jsonEncode(plan.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      clearCache();
      return plan;
    } else {
      throw Exception('Failed to update plan');
    }
  }

  Future<AIAdvice> consultAI(int userId, String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/AI/consult?userId=$userId'),
        headers: _headers,
        body: jsonEncode(query),
      );
      if (response.statusCode == 200) {
        return AIAdvice.fromJson(json.decode(response.body));
      } else {
        throw Exception('Server Error (Mã lỗi ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<bool> applyAIAdvice(int adviceId) async {
    final response = await http.post(Uri.parse('$baseUrl/AI/apply/$adviceId'), headers: _headers);
    if (response.statusCode == 200) {
      clearCache();
      return true;
    }
    return false;
  }

  Future<bool> deleteTransaction(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/Transactions/$id'), headers: _headers);
    bool ok = response.statusCode == 204 || response.statusCode == 200;
    if (ok) clearCache();
    return ok;
  }

  Future<bool> deleteGoal(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/Goals/$id'), headers: _headers);
    bool ok = response.statusCode == 204 || response.statusCode == 200;
    if (ok) clearCache();
    return ok;
  }

  Future<bool> deletePlan(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/MonthlyPlans/$id'), headers: _headers);
    bool ok = response.statusCode == 204 || response.statusCode == 200;
    if (ok) clearCache();
    return ok;
  }
}

