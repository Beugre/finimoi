import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/school_provider.dart';
import 'package:finimoi/domain/entities/school_models.dart';

class SchoolFeesScreen extends ConsumerWidget {
  const SchoolFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myStudentsAsync = ref.watch(myStudentsProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Frais de Scolarité'),
      body: myStudentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('Aucun enfant trouvé.'));
          }
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    _buildFeesList(ref, student.id),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildFeesList(WidgetRef ref, String studentId) {
    final feesAsync = ref.watch(studentFeesProvider(studentId));
    return feesAsync.when(
      data: (fees) {
        if (fees.isEmpty) {
          return const ListTile(title: Text('Aucun frais impayé.'));
        }
        return Column(
          children: fees.map((fee) {
            return ListTile(
              title: Text(fee.description),
              subtitle: Text('Montant: ${fee.amount} FCFA'),
              trailing: ElevatedButton(
                child: const Text('Payer'),
                onPressed: () {
                  ref.read(schoolServiceProvider).payFee(fee.id);
                },
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
    );
  }
}
