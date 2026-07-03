import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String baseUrl = kIsWeb ? 'http://localhost:5172/api' : 'http://10.0.2.2:5172/api';

  Future<List<Transaction>> getTransactions(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/Transactions/$userId'));
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Transaction>.from(l.map((model) => Transaction.fromJson(model)));
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Transaction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add transaction');
    }
  }

  Future<List<Goal>> getGoals(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/Goals/$userId'));
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Goal>.from(l.map((model) => Goal.fromJson(model)));
    } else {
      throw Exception('Failed to load goals');
    }
  }

  Future<Goal> addGoal(Goal goal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Goals'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(goal.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Goal.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add goal');
    }
  }

  Future<List<MonthlyPlan>> getPlans(int userId, {int? month, int? year}) async {
    String url = '$baseUrl/MonthlyPlans/$userId';
    if (month != null && year != null) {
      url += '?month=$month&year=$year';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<MonthlyPlan>.from(l.map((model) => MonthlyPlan.fromJson(model)));
    } else {
      throw Exception('Failed to load plans');
    }
  }

  Future<MonthlyPlan> addPlan(MonthlyPlan plan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/MonthlyPlans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plan.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return MonthlyPlan.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add plan');
    }
  }

  Future<AIAdvice> consultAI(int userId, String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/AI/consult?userId=$userId'),
        headers: <String, String>{'Content-Type': 'application/json'},
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
    final response = await http.post(Uri.parse('$baseUrl/AI/apply/$adviceId'));
    return response.statusCode == 200;
  }
}
