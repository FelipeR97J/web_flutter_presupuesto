import 'package:flutter/material.dart';

// ============================================
// MODELO: Dashboard Summary
// ============================================
class DashboardSummary {
  final Period period;
  final Summary summary;

  DashboardSummary({
    required this.period,
    required this.summary,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      period: Period.fromJson(json['period']),
      summary: Summary.fromJson(json['summary']),
    );
  }
}

class Period {
  final int month;
  final int year;

  Period({required this.month, required this.year});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      month: json['month'],
      year: json['year'],
    );
  }
}

class Summary {
  final MetricData income;
  final MetricData expense;
  final DebtData debt;
  final BalanceData balance;

  Summary({
    required this.income,
    required this.expense,
    required this.debt,
    required this.balance,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      income: MetricData.fromJson(json['income']),
      expense: MetricData.fromJson(json['expense']),
      debt: DebtData.fromJson(json['debt']),
      balance: BalanceData.fromJson(json['balance']),
    );
  }
}

class MetricData {
  final double total;
  final double previousMonth;
  final double variationPercentage;
  final String trend; // "up" | "down" | "equal"

  MetricData({
    required this.total,
    required this.previousMonth,
    required this.variationPercentage,
    required this.trend,
  });

  factory MetricData.fromJson(Map<String, dynamic> json) {
    return MetricData(
      total: (json['total'] ?? 0).toDouble(),
      previousMonth: (json['previousMonth'] ?? 0).toDouble(),
      variationPercentage: (json['variationPercentage'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'equal',
    );
  }

  IconData get trendIcon {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color get trendColor {
    switch (trend) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class DebtData {
  final double totalPayment;
  final int pendingCount;

  DebtData({
    required this.totalPayment,
    required this.pendingCount,
  });

  factory DebtData.fromJson(Map<String, dynamic> json) {
    return DebtData(
      totalPayment: (json['totalPayment'] ?? 0).toDouble(),
      pendingCount: json['pendingCount'] ?? 0,
    );
  }
}

class BalanceData {
  final double total;
  final String status; // "positive" | "negative"

  BalanceData({
    required this.total,
    required this.status,
  });

  factory BalanceData.fromJson(Map<String, dynamic> json) {
    return BalanceData(
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'positive',
    );
  }

  Color get statusColor {
    return status == 'positive' ? Colors.green : Colors.red;
  }
}

// ============================================
// MODELO: Category Distribution
// ============================================
class CategoryDistribution {
  final double total;
  final List<CategoryData> categories;

  CategoryDistribution({
    required this.total,
    required this.categories,
  });

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) {
    final categoriesList = (json['categories'] as List<dynamic>?) ?? [];
    
    return CategoryDistribution(
      total: (json['total'] ?? 0).toDouble(),
      categories: categoriesList
          .asMap()
          .entries
          .map((entry) => CategoryData.fromJson(entry.value, index: entry.key))
          .toList(),
    );
  }
}

class CategoryData {
  final int? id;
  final String name;
  final double total;
  final double percentage;
  final String color;

  CategoryData({
    this.id,
    required this.name,
    required this.total,
    required this.percentage,
    required this.color,
  });

  // Lista de colores predefinidos para categorías
  static const List<String> predefinedColors = [
    '#FF6B6B', // Rojo coral
    '#4ECDC4', // Turquesa
    '#45B7D1', // Azul cielo
    '#FFA07A', // Salmón
    '#98D8C8', // Verde menta
    '#F7DC6F', // Amarillo
    '#BB8FCE', // Púrpura claro
    '#85C1E2', // Azul claro
    '#F8B88B', // Naranja claro
    '#ABEBC6', // Verde claro
    '#F1948A', // Rosa
    '#AED6F1', // Azul pastel
  ];

  // Método estático para obtener color por índice
  static String getColorByIndex(int index) {
    return predefinedColors[index % predefinedColors.length];
  }

  factory CategoryData.fromJson(Map<String, dynamic> json, {int index = 0}) {
    // Si la API no envía color o envía el color por defecto (#3357FF), usar uno predefinido
    String apiColor = json['color'] ?? '';
    
    // Ignorar el color de la API si es el color por defecto azul que usa para todas las categorías
    bool useApiColor = apiColor.isNotEmpty && 
                       apiColor.startsWith('#') && 
                       apiColor.toUpperCase() != '#3357FF'; // Ignorar el color por defecto
    
    String finalColor = useApiColor ? apiColor : getColorByIndex(index);
    
    debugPrint('🎨 CategoryData - Index: $index, Name: ${json['name']}, API Color: "$apiColor", Final Color: $finalColor');
    
    return CategoryData(
      id: json['id'],
      name: json['name'] ?? 'Desconocido',
      total: (json['total'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      color: finalColor,
    );
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Si falla el parsing, usar un color basado en el hash del nombre
      return Color(0xFF000000 + (name.hashCode % 0xFFFFFF));
    }
  }
}

// ============================================
// MODELO: Dashboard History
// ============================================
class DashboardHistory {
  final List<HistoryData> history;

  DashboardHistory({required this.history});

  factory DashboardHistory.fromJson(Map<String, dynamic> json) {
    return DashboardHistory(
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class HistoryData {
  final int month;
  final int year;
  final double income;
  final double expense;
  final double debt;

  HistoryData({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.debt,
  });

  factory HistoryData.fromJson(Map<String, dynamic> json) {
    return HistoryData(
      month: json['month'],
      year: json['year'],
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      debt: (json['debt'] ?? 0).toDouble(),
    );
  }

  String get monthLabel {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[month - 1];
  }
}
