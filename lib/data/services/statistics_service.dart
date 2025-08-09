import '../../domain/entities/transfer_model.dart';

class TransactionStats {
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> spendingByCategory;

  TransactionStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.spendingByCategory,
  });

  double get netFlow => totalIncome - totalExpenses;
}

class StatisticsService {
  static TransactionStats calculateStats(List<TransferModel> transactions) {
    double income = 0;
    double expenses = 0;
    Map<String, double> spendingByCategory = {};

    for (final transaction in transactions) {
      if (transaction.amount > 0) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount.abs();

        // Assuming the transaction type can be used as a category
        final category = _getCategoryFromType(transaction.type);
        spendingByCategory.update(
          category,
          (value) => value + transaction.amount.abs(),
          ifAbsent: () => transaction.amount.abs(),
        );
      }
    }

    return TransactionStats(
      totalIncome: income,
      totalExpenses: expenses,
      spendingByCategory: spendingByCategory,
    );
  }

  static String _getCategoryFromType(TransferType type) {
    switch (type) {
      case TransferType.internal:
        return 'Transferts';
      case TransferType.mobileMoney:
        return 'Mobile Money';
      case TransferType.bankTransfer:
        return 'Virements';
      case TransferType.qrCode:
        return 'Paiements QR';
      default:
        return 'Autre';
    }
  }
}
