import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/credit_model.dart';
import '../../../data/services/real_credit_service.dart';
import 'package:intl/intl.dart';

class RepaymentScheduleScreen extends ConsumerWidget {
  final CreditModel credit;

  const RepaymentScheduleScreen({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.read(realCreditServiceProvider).generateRepaymentSchedule(credit);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier de Remboursement')),
      body: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final item = schedule[index];
          return ListTile(
            leading: Text(item.month.toString()),
            title: Text('Échéance: ${DateFormat.yMd().format(item.dueDate)}'),
            subtitle: Text(
                'Principal: ${item.principal.toStringAsFixed(2)} | Intérêts: ${item.interest.toStringAsFixed(2)}'),
            trailing: Text(
              '${item.totalPayment.toStringAsFixed(2)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
