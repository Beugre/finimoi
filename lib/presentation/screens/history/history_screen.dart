import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/user_provider.dart';
import '../../../domain/entities/transfer_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Historique'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryViolet,
          labelColor: AppColors.primaryViolet,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Transferts'),
            Tab(text: 'Paiements'),
            Tab(text: 'Recharges'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Résumé financier
          _buildFinancialSummary(),

          // Filtres actifs
          if (_searchQuery.isNotEmpty || _selectedDateRange != null)
            _buildActiveFilters(),

          // Liste des transactions
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsList(null),
                _buildTransactionsList(TransferType.internal),
                _buildTransactionsList(TransferType.mobileMoney),
                _buildTransactionsList(TransferType.bankTransfer),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportTransactions,
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.download),
        label: const Text('Exporter'),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryViolet, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé du mois',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Entrées',
                  amount: '+ 250 000 FCFA',
                  icon: Icons.arrow_downward,
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildSummaryItem(
                  title: 'Sorties',
                  amount: '- 180 000 FCFA',
                  icon: Icons.arrow_upward,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_searchQuery.isNotEmpty)
            Chip(
              label: Text('Recherche: $_searchQuery'),
              backgroundColor: AppColors.primaryViolet.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _searchQuery = ''),
            ),
          if (_selectedDateRange != null)
            Chip(
              label: Text('Période: ${_formatDateRange(_selectedDateRange!)}'),
              backgroundColor: AppColors.info.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _selectedDateRange = null),
            ),
        ],
      ),
    );
  }

  List<TransferModel> _getFilteredTransactions(
    List<TransferModel> transactions,
    TransferType? type,
  ) {
    return transactions.where((transaction) {
      if (type != null && transaction.type != type) return false;
      if (_searchQuery.isNotEmpty) {
        return transaction.description
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false;
      }
      if (_selectedDateRange != null) {
        return transaction.createdAt.toDate().isAfter(
              _selectedDateRange!.start,
            ) &&
            transaction.createdAt.toDate().isBefore(
              _selectedDateRange!.end,
            );
      }
      return true;
    }).toList();
  }

  Widget _buildTransactionsList(TransferType? type) {
    final transactionsAsync = ref.watch(userTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final filteredTransactions = _getFilteredTransactions(transactions, type);

        if (filteredTransactions.isEmpty) {
          return _buildEmptyState();
        }

        // Grouper par date
        final groupedTransactions = _groupTransactionsByDate(
          filteredTransactions,
        );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedTransactions.length,
          itemBuilder: (context, index) {
            final date = groupedTransactions.keys.elementAt(index);
            final dayTransactions = groupedTransactions[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de date
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _formatGroupDate(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                // Transactions du jour
                ...dayTransactions.map(
                  (transaction) => _buildTransactionItem(transaction),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Impossible de charger l\'historique des transactions',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userTransactionsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos transactions apparaîtront ici',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransferModel transaction) {
    final isOutgoing =
        transaction.amount <
        0; // Utiliser le signe du montant pour déterminer si c'est sortant

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTransactionColor(transaction.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: _getTransactionColor(transaction.type),
            size: 24,
          ),
        ),
        title: Text(
          transaction.description ?? _getTransactionTitle(transaction.type),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          _formatDateTime(transaction.createdAt.toDate()),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isOutgoing ? '-' : '+'} ${transaction.amount.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isOutgoing ? AppColors.error : AppColors.success,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(transaction.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(transaction.status),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  Map<DateTime, List<TransferModel>> _groupTransactionsByDate(
    List<TransferModel> transactions,
  ) {
    final grouped = <DateTime, List<TransferModel>>{};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.toDate().year,
        transaction.createdAt.toDate().month,
        transaction.createdAt.toDate().day,
      );

      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Aujourd\'hui';
    } else if (date == yesterday) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
  }

  IconData _getTransactionIcon(TransferType type) {
    switch (type) {
      case TransferType.internal:
        return Icons.send;
      case TransferType.mobileMoney:
        return Icons.phone_android;
      case TransferType.bankTransfer:
        return Icons.account_balance;
      case TransferType.qrCode:
        return Icons.qr_code;
    }
  }

  Color _getTransactionColor(TransferType type) {
    switch (type) {
      case TransferType.internal:
        return AppColors.warning;
      case TransferType.mobileMoney:
        return AppColors.info;
      case TransferType.bankTransfer:
        return AppColors.primaryViolet;
      case TransferType.qrCode:
        return AppColors.success;
    }
  }

  String _getTransactionTitle(TransferType type) {
    switch (type) {
      case TransferType.internal:
        return 'Envoi d\'argent';
      case TransferType.mobileMoney:
        return 'Mobile Money';
      case TransferType.bankTransfer:
        return 'Virement bancaire';
      case TransferType.qrCode:
        return 'Code QR';
    }
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return AppColors.warning;
      case TransferStatus.processing:
        return Colors.blue;
      case TransferStatus.completed:
        return AppColors.success;
      case TransferStatus.failed:
        return AppColors.error;
      case TransferStatus.cancelled:
        return Colors.grey;
      case TransferStatus.refunded:
        return Colors.purple;
    }
  }

  String _getStatusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return 'En attente';
      case TransferStatus.processing:
        return 'En cours';
      case TransferStatus.completed:
        return 'Terminé';
      case TransferStatus.failed:
        return 'Échec';
      case TransferStatus.cancelled:
        return 'Annulé';
      case TransferStatus.refunded:
        return 'Remboursé';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Rechercher une transaction...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par période'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Aujourd\'hui'),
              onTap: () => _applyDateFilter(_getTodayRange()),
            ),
            ListTile(
              title: const Text('Cette semaine'),
              onTap: () => _applyDateFilter(_getThisWeekRange()),
            ),
            ListTile(
              title: const Text('Ce mois'),
              onTap: () => _applyDateFilter(_getThisMonthRange()),
            ),
            ListTile(
              title: const Text('Période personnalisée'),
              onTap: () => _showCustomDatePicker(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  DateTimeRange _getTodayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: now);
  }

  DateTimeRange _getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: now,
    );
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return DateTimeRange(start: startOfMonth, end: now);
  }

  void _applyDateFilter(DateTimeRange range) {
    setState(() => _selectedDateRange = range);
    Navigator.pop(context);
  }

  void _showCustomDatePicker() async {
    Navigator.pop(context);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  void _showTransactionDetails(TransferModel transaction) {
    final isOutgoing = transaction.amount < 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTransactionTitle(transaction.type)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Référence', transaction.reference),
              _buildDetailRow(
                isOutgoing ? 'Destinataire' : 'Expéditeur',
                transaction.recipientName ?? 'N/A',
              ),
              _buildDetailRow(
                'Montant',
                '${transaction.amount.abs().toStringAsFixed(0)} FCFA',
              ),
              if (isOutgoing)
                _buildDetailRow(
                  'Frais',
                  '${transaction.fees.toStringAsFixed(0)} FCFA',
                ),
              if (isOutgoing)
                _buildDetailRow(
                  'Total débité',
                  '${transaction.totalAmount.abs().toStringAsFixed(0)} FCFA',
                ),
              _buildDetailRow(
                'Date',
                _formatDateTime(transaction.createdAt.toDate()),
              ),
              _buildDetailRow('Statut', _getStatusText(transaction.status)),
              if (transaction.description != null &&
                  transaction.description!.isNotEmpty)
                _buildDetailRow('Description', transaction.description!),
              if (transaction.status == TransferStatus.failed &&
                  transaction.failureReason != null)
                _buildDetailRow('Raison de l\'échec',
                    transaction.failureReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _exportTransactions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              subtitle: const Text('Document formaté avec détails'),
              onTap: () {
                Navigator.pop(context);
                _generateExport('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel (CSV)'),
              subtitle: const Text('Tableau pour analyse'),
              onTap: () {
                Navigator.pop(context);
                _generateExport('CSV');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.blue),
              title: const Text('JSON'),
              subtitle: const Text('Format brut pour développeurs'),
              onTap: () {
                Navigator.pop(context);
                _generateExport('JSON');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateExport(String format) async {
    final transactions = ref.read(userTransactionsProvider).asData?.value ?? [];
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune transaction à exporter')),
      );
      return;
    }

    final currentTabType = _tabController.index == 0
        ? null
        : TransferType.values[_tabController.index - 1];
    final filteredTransactions =
        _getFilteredTransactions(transactions, currentTabType);

    if (filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune transaction ne correspond à vos filtres'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du PDF en cours...')),
    );

    try {
      final pdfBytes = await _generatePdf(filteredTransactions);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'releve_transactions.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du PDF: $e')),
      );
    }
  }

  Future<Uint8List> _generatePdf(
      List<TransferModel> transactions) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Relevé de Transactions',
                    style: pw.TextStyle(font: boldFont, fontSize: 20)),
                pw.Text(
                  _formatDateRange(
                    _selectedDateRange ??
                        DateTimeRange(
                          start: transactions.last.createdAt.toDate(),
                          end: transactions.first.createdAt.toDate(),
                        ),
                  ),
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ],
            ),
          ),
          pw.Table.fromTextArray(
            headers: ['Date', 'Description', 'Montant', 'Statut'],
            headerStyle: pw.TextStyle(font: boldFont),
            cellStyle: pw.TextStyle(font: font),
            data: transactions.map((tr) {
              final isOutgoing = tr.amount < 0;
              return [
                _formatDateTime(tr.createdAt.toDate()),
                tr.description ?? _getTransactionTitle(tr.type),
                '${isOutgoing ? '-' : '+'} ${tr.amount.abs().toStringAsFixed(0)} FCFA',
                _getStatusText(tr.status),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  void _shareExportFile(String fileName) {
    // This function is no longer needed as Printing.sharePdf handles it.
  }
}
