import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/invoice_service.dart';
import 'package:finimoi/domain/entities/invoice_model.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService();
});

final merchantInvoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final invoiceService = ref.watch(invoiceServiceProvider);
  return invoiceService.getInvoicesForMerchant();
});
