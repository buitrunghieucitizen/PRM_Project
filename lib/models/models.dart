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
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      id: json['id'],
      userId: json['userId'],
      month: json['month'],
      year: json['year'],
      category: json['category'],
      plannedAmount: (json['plannedAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  final bool isApplied;

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
      id: json['id'],
      userId: json['userId'],
      userQuery: json['userQuery'],
      aiResponse: json['aiResponse'],
      proposedActionsJson: json['proposedActionsJson'],
      isApplied: json['isApplied'],
    );
  }
}
