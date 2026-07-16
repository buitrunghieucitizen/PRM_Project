class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? jobTitle;
  final double? monthlySalary;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.jobTitle,
    this.monthlySalary,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      jobTitle: json['jobTitle'],
      monthlySalary: json['monthlySalary'] != null ? (json['monthlySalary'] as num).toDouble() : null,
    );
  }
}

class Transaction {
  final int id;
  final int userId;
  final double amount;
  final String category;
  final String type;
  final DateTime transactionDate;
  final String? note;
  final int? goalId;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.transactionDate,
    this.note,
    this.goalId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 1,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      transactionDate: DateTime.parse(json['transactionDate']),
      note: json['note'],
      goalId: json['goalId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'type': type,
      'transactionDate': transactionDate.toIso8601String(),
      'note': note,
      'goalId': goalId,
    };
  }
}

class Goal {
  final int id;
  final int userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final bool isCompleted;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.isCompleted,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 1,
      title: json['title'] ?? '',
      targetAmount: json['targetAmount'] != null ? (json['targetAmount'] as num).toDouble() : 0.0,
      currentAmount: json['currentAmount'] != null ? (json['currentAmount'] as num).toDouble() : 0.0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

class MonthlyPlan {
  final int id;
  final int userId;
  final int month;
  final int year;
  final String category;
  final double plannedAmount;

  MonthlyPlan({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.category,
    required this.plannedAmount,
  });

  factory MonthlyPlan.fromJson(Map<String, dynamic> json) {
    return MonthlyPlan(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 1,
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      category: json['category'] ?? '',
      plannedAmount: json['plannedAmount'] != null ? (json['plannedAmount'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'month': month,
      'year': year,
      'category': category,
      'plannedAmount': plannedAmount,
    };
  }
}

class AIAdvice {
  final int id;
  final int userId;
  final String userQuery;
  final String aiResponse;
  final String? proposedActionsJson;
  bool isApplied;

  AIAdvice({
    required this.id,
    required this.userId,
    required this.userQuery,
    required this.aiResponse,
    this.proposedActionsJson,
    required this.isApplied,
  });

  factory AIAdvice.fromJson(Map<String, dynamic> json) {
    return AIAdvice(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 1,
      userQuery: json['userQuery'] ?? '',
      aiResponse: json['aiResponse'] ?? '',
      proposedActionsJson: json['proposedActionsJson'],
      isApplied: json['isApplied'] ?? false,
    );
  }
}
