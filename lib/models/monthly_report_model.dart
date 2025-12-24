import 'package:flutter/material.dart';

class MonthlyReport {
  final ReportDate date;
  final ReportSummary summary;
  final DebtReportStatus debtStatus;
  final List<ReportInsight> insights;
  final List<CategoryComparison> comparisons; // Replaces categoryInsights
  final List<CategoryBreakdown> expenseBreakdown;
  final List<CategoryBreakdown> incomeBreakdown;

  MonthlyReport({
    required this.date,
    required this.summary,
    required this.debtStatus,
    required this.insights,
    required this.comparisons,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
  });
}

class CategoryComparison {
  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double difference;
  final double percentage; // Store as double (e.g., 25.0 for 25%)

  CategoryComparison({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.difference,
    required this.percentage,
  });
}

class ReportDate {
  final int year;
  final int month;
  
  ReportDate({required this.year, required this.month});
}

class ReportSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double previousMonthExpense;
  final double expenseVariation; // Difference vs previous month

  ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.previousMonthExpense,
    required this.expenseVariation,
  });
}

class DebtReportStatus {
  final int activeCount;
  final int finishedCount;
  final List<DebtReportItem> activeList;
  final List<DebtReportItem> finishedList;
  final double totalDebtPayment; // Total paid in installments this month

  DebtReportStatus({
    required this.activeCount,
    required this.finishedCount,
    required this.activeList,
    required this.finishedList,
    required this.totalDebtPayment,
  });
}

class DebtReportItem {
  final String description;
  final double amount;
  final String progress; // "1/6"
  final bool isFinished;

  DebtReportItem({
    required this.description,
    required this.amount,
    required this.progress,
    required this.isFinished,
  });
}

enum InsightType { positive, negative, neutral, alert }

class ReportInsight {
  final String message;
  final InsightType type;
  final IconData icon;

  ReportInsight({
    required this.message,
    required this.type,
    required this.icon,
  });
}

class CategoryBreakdown {
  final String categoryName;
  final double total;
  final double percentage;
  final String? colorHex; // Optional hex color

  CategoryBreakdown({
    required this.categoryName,
    required this.total,
    required this.percentage,
    this.colorHex,
  });
}
