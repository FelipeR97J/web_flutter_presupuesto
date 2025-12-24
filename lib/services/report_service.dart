import 'package:flutter/material.dart';
import '../models/monthly_report_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import 'expense_service.dart';
import 'income_service.dart';
import 'debt_service.dart';
import 'expense_category_service.dart';
import 'income_category_service.dart';
import 'package:intl/intl.dart';

class ReportService {
  final _expenseService = ExpenseService();
  final _incomeService = IncomeService();
  final _debtService = DebtService();
  final _expenseCategoryService = ExpenseCategoryService();
  final _incomeCategoryService = IncomeCategoryService();

  Future<MonthlyReport> getMonthlyReport(String token, int year, int month) async {
    try {
      // 1. Obtener datos del mes actual (M)
      final currentExpensesFuture = _expenseService.getExpenses(
        token, 
        year: year, 
        month: month, 
        limit: 2000 // Asegurar traer todos
      );
      
      final currentIncomesFuture = _incomeService.getIncomes(token); // Filtrar por fecha despues
      
      // 2. Obtener datos del mes anterior (M-1)
      final prevDate = DateTime(year, month - 1);
      // Ajuste por si month es 1 (Enero -> mes anterior es Dic del año anterior)
      final prevYear = month == 1 ? year - 1 : year;
      final prevMonth = month == 1 ? 12 : month - 1;

      final prevExpensesFuture = _expenseService.getExpenses(
        token, 
        year: prevYear, 
        month: prevMonth,
        limit: 2000
      );

      // 3. Obtener Categorías para resolver nombres
      final expenseCategoriesFuture = _expenseCategoryService.getCategories();
      final incomeCategoriesFuture = _incomeCategoryService.getCategories();

      // 4. Obtener Deudas (para cruzar info si es necesario)
      final debtsFuture = _debtService.getDebts(token);

      final results = await Future.wait([
        currentExpensesFuture,
        currentIncomesFuture,
        prevExpensesFuture,
        expenseCategoriesFuture,
        incomeCategoriesFuture,
        debtsFuture,
      ]);

      final currentExpenses = results[0] as List<Expense>;
      final allIncomes = results[1] as List<Income>;
      final prevExpenses = results[2] as List<Expense>;
      final expenseCategories = results[3] as dynamic; 
      final incomeCategories = results[4] as dynamic;
      final debtsResponse = results[5] as dynamic; // PaginationResponse<Debt>
      // ignore: unused_local_variable
      final allDebts = debtsResponse.data as List<dynamic>;

      // Crear mapas de categorías ID -> Nombre
      final expenseCatMap = <int, String>{};
      if (expenseCategories.data != null) {
         for (var c in expenseCategories.data) {
             expenseCatMap[c.id] = c.name;
         }
      }
      
      final incomeCatMap = <int, String>{};
      if (incomeCategories.data != null) {
         for (var c in incomeCategories.data) {
             incomeCatMap[c.id] = c.name;
         }
      }

      // Filtrar ingresos del mes seleccionado
      final currentIncomes = allIncomes.where((i) {
        return i.date.year == year && i.date.month == month;
      }).toList();

      // --- CÁLCULOS ---

      // 1. Resumen
      final totalIncome = _calculateTotal(currentIncomes);
      final totalExpense = _expenseService.calculateTotal(currentExpenses);
      final prevTotalExpense = _expenseService.calculateTotal(prevExpenses);
      final balance = totalIncome - totalExpense;
      final expenseVariation = totalExpense - prevTotalExpense;

      final summary = ReportSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        previousMonthExpense: prevTotalExpense,
        expenseVariation: expenseVariation,
      );

      // 2. Estado de Deudas
      final debtExpenses = currentExpenses.where((e) => e.debtId != null).toList();
      final totalDebtPayment = _expenseService.calculateInstallmentsTotal(currentExpenses);
      
      final activeDebtItems = debtExpenses.map((e) {
        String progress = "?";
        if (e.description.contains("Cuota")) {
          final parts = e.description.split("Cuota");
          if (parts.length > 1) {
            progress = parts[1].trim(); 
          }
        }
        
        return DebtReportItem(
          description: e.description,
          amount: e.amount,
          progress: progress,
          isFinished: false, // Logica simple por ahora
        );
      }).toList();

      final finishedDebtItems = <DebtReportItem>[]; 

      final debtStatus = DebtReportStatus(
        activeCount: activeDebtItems.length,
        finishedCount: finishedDebtItems.length,
        activeList: activeDebtItems,
        finishedList: finishedDebtItems,
        totalDebtPayment: totalDebtPayment,
      );

      // 3. Income & Expense Breakdown (con mapas de nombres)
      final expenseBreakdown = _generateBreakdown(currentExpenses, expenseCatMap);
      final incomeBreakdown = _generateIncomeBreakdown(currentIncomes, incomeCatMap);

      // 4. Generar Insights
      final mainInsights = _generateMainInsights(
        totalExpense, 
        prevTotalExpense, 
        currentExpenses, 
        balance
      );

      final comparisons = _generateComparisons(
        currentExpenses, 
        prevExpenses,
        expenseCatMap
      );

      return MonthlyReport(
        date: ReportDate(year: year, month: month),
        summary: summary,
        debtStatus: debtStatus,
        insights: mainInsights,
        comparisons: comparisons,
        expenseBreakdown: expenseBreakdown,
        incomeBreakdown: incomeBreakdown,
      );

    } catch (e) {
      debugPrint('Error generating report: $e');
      throw Exception('No se pudo generar el reporte: $e');
    }
  }

  double _calculateTotal(List<dynamic> items) {
    return items.fold(0.0, (sum, item) => sum + (item.amount as double));
  }

  List<ReportInsight> _generateMainInsights(
    double currentTotal, 
    double prevTotal, 
    List<Expense> current, 
    double balance
  ) {
    final insights = <ReportInsight>[];
    final formatter = NumberFormat('#,##0', 'es_ES');

    // Insight de Balance
    if (balance > 0) {
      insights.add(ReportInsight(
        message: "💰 Balance positivo: Ahorraste \$${formatter.format(balance.toInt())}",
        type: InsightType.positive,
        icon: Icons.savings,
      ));
    } else if (balance < 0) {
      insights.add(ReportInsight(
        message: "⚠️ Gastaste \$${formatter.format(balance.abs().toInt())} más de lo que ganaste.",
        type: InsightType.alert,
        icon: Icons.warning_amber,
      ));
    }

    // Insight de Tendencia General
    final diff = currentTotal - prevTotal;
    if (diff > 0) {
       insights.add(ReportInsight(
        message: "📈 Gastaste \$${formatter.format(diff.toInt())} más que el mes anterior.",
        type: InsightType.negative,
        icon: Icons.trending_up,
      ));
    } else if (diff < 0 && prevTotal > 0) {
       insights.add(ReportInsight(
        message: "📉 Redujiste tus gastos en \$${formatter.format(diff.abs().toInt())} vs el mes pasado.",
        type: InsightType.positive,
        icon: Icons.trending_down,
      ));
    }

    return insights;
  }

  List<CategoryComparison> _generateComparisons(
    List<Expense> current, 
    List<Expense> prev,
    Map<int, String> catMap
  ) {
    final comparisons = <CategoryComparison>[];

    // 1. Agrupar gastos actuales por nombre de categoría (usando el breakdown existente)
    final currentBreakdown = _generateBreakdown(current, catMap);
    
    // 2. Agrupar gastos anteriores
    Map<String, double> prevCatMap = {};
    if (prev.isNotEmpty) {
       for (var e in prev) { 
          final catName = catMap[e.categoryId] ?? 'Otros';
          prevCatMap[catName] = (prevCatMap[catName] ?? 0) + e.amount;
       }
    }

    // 3. Crear comparaciones para categorías actuales
    for (var cat in currentBreakdown) {
       final prevAmount = prevCatMap[cat.categoryName] ?? 0;
       final diff = cat.total - prevAmount;
       double percentage = 0.0;
       if (prevAmount > 0) {
          percentage = ((cat.total - prevAmount) / prevAmount) * 100;
       } else if (cat.total > 0) {
          percentage = 100.0; // Nuevo gasto (infinity técnicamente, pero 100% o N/A para la UI)
       }

       comparisons.add(CategoryComparison(
         categoryName: cat.categoryName,
         currentAmount: cat.total,
         previousAmount: prevAmount,
         difference: diff,
         percentage: percentage,
       ));
       
       // Remover del mapa anterior para detectar las que ya no existen este mes (opcional)
       prevCatMap.remove(cat.categoryName);
    }
    
    // (Opcional) Agregar categorías que existían antes y ahora son 0? 
    // Por simplicidad, nos enfocamos en lo que gastaste este mes vs antes.

    // Ordenar por magnitud de la diferencia (lo más impactante primero)
    comparisons.sort((a, b) => b.difference.abs().compareTo(a.difference.abs()));

    return comparisons;
  }

  List<CategoryBreakdown> _generateBreakdown(List<Expense> expenses, Map<int, String> catMap) {
    final map = <String, double>{};
    double total = 0;

    for (var e in expenses) {
      final catName = catMap[e.categoryId] ?? 'Otros';
      map[catName] = (map[catName] ?? 0) + e.amount;
      total += e.amount;
    }

    final list = map.entries.map((e) {
      return CategoryBreakdown(
        categoryName: e.key,
        total: e.value,
        percentage: total == 0 ? 0 : (e.value / total) * 100,
      );
    }).toList();

    list.sort((a, b) => b.total.compareTo(a.total));
    
    return list;
  }

  List<CategoryBreakdown> _generateIncomeBreakdown(List<Income> incomes, Map<int, String> catMap) {
     final map = <String, double>{};
    double total = 0;

    for (var i in incomes) {
      final catName = catMap[i.categoryId] ?? 'Otros';
      map[catName] = (map[catName] ?? 0) + i.amount;
      total += i.amount;
    }

    final list = map.entries.map((e) {
      return CategoryBreakdown(
        categoryName: e.key,
        total: e.value,
        percentage: total == 0 ? 0 : (e.value / total) * 100,
      );
    }).toList();

     list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }
}
