import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/domain/entities/invoice_model.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/presentation/widgets/common/custom_text_field.dart';
import 'package:finimoi/presentation/widgets/common/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finimoi/data/providers/invoice_provider.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _dueDateController = TextEditingController();
  DateTime? _dueDate;

  final List<InvoiceItem> _items = [InvoiceItem(description: '', quantity: 1, price: 0)];
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(description: '', quantity: 1, price: 0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        _items.removeAt(index);
      }
    });
  }

  void _createInvoice() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(invoiceServiceProvider).createInvoice(
        customerName: _customerNameController.text,
        customerEmail: _customerEmailController.text,
        dueDate: _dueDate!,
        items: _items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facture créée avec succès!')),
        );
        ref.invalidate(merchantInvoicesProvider);
        context.pop();
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Créer une Facture'),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _customerNameController,
                      label: 'Nom du Client',
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _customerEmailController,
                      label: 'Email du Client',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _dueDateController,
                      label: 'Date d\'échéance',
                      readOnly: true,
                      onTap: () => _selectDueDate(context),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Articles', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ..._buildItemFields(),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un article'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: 'Enregistrer le Brouillon',
                onPressed: _createInvoice,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemFields() {
    return List.generate(_items.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: _items[index].description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) => _items[index] = InvoiceItem(description: value, quantity: _items[index].quantity, price: _items[index].price),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: _items[index].quantity.toString(),
                decoration: const InputDecoration(labelText: 'Qté'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _items[index] = InvoiceItem(description: _items[index].description, quantity: int.tryParse(value) ?? 1, price: _items[index].price),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: _items[index].price.toString(),
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                 onChanged: (value) => _items[index] = InvoiceItem(description: _items[index].description, quantity: _items[index].quantity, price: double.tryParse(value) ?? 0.0),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      );
    });
  }
}
