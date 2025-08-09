import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/invoice_provider.dart';
import 'package:finimoi/domain/entities/invoice_model.dart';
import 'package:finimoi/data/services/invoice_pdf_service.dart';
import 'package:intl/intl.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(merchantInvoicesProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mes Factures'),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return const Center(
              child: Text("Vous n'avez aucune facture."),
            );
          }
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return ListTile(
                title: Text('Facture pour ${invoice.customerName}'),
                subtitle: Text('Total: ${invoice.totalAmount} FCFA - Échéance: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(invoice.status.name),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () => InvoicePdfService.saveAndOpenPdf(invoice),
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: Navigate to invoice details
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/merchant/invoices/create'),
        label: const Text('Créer une Facture'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
