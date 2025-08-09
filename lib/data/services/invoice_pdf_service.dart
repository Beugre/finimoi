import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:finimoi/domain/entities/invoice_model.dart';
import 'package:finimoi/domain/entities/user_model.dart';
import 'package:finimoi/data/services/user_service.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // In a real app, you'd fetch the merchant's full details
    // final UserModel merchant = await UserService.getUserProfile(invoice.merchantId);
    const merchantName = "FinIMoi Marchand";
    const merchantAddress = "123 Rue de la Fintech, Abidjan";

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FACTURE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(merchantName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(merchantAddress),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Facture #: ${invoice.id.substring(0, 6)}'),
                      pw.Text('Date: ${invoice.createdAt.toLocal().toString().split(' ')[0]}'),
                      pw.Text('Échéance: ${invoice.dueDate.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Facturé à:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.customerName),
              pw.Text(invoice.customerEmail),
              pw.SizedBox(height: 20),
              _buildItemsTable(invoice),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total: ${invoice.totalAmount} FCFA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    final headers = ['Description', 'Quantité', 'Prix Unitaire', 'Total'];
    final data = invoice.items.map((item) {
      return [item.description, item.quantity.toString(), item.price.toString(), item.total.toString()];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft},
    );
  }

  static Future<void> saveAndOpenPdf(Invoice invoice) async {
    final bytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}
