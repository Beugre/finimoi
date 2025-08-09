import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finimoi/data/services/ocr_service.dart';
import 'package:finimoi/domain/entities/bill_splitting_model.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/user_provider.dart';
import 'package:finimoi/domain/entities/user_model.dart';

class BillSplitScreen extends ConsumerStatefulWidget {
  const BillSplitScreen({super.key});

  @override
  ConsumerState<BillSplitScreen> createState() => _BillSplitScreenState();
}

class _BillSplitScreenState extends ConsumerState<BillSplitScreen> {
  final OcrService _ocrService = OcrService();
  XFile? _imageFile;
  List<BillItem> _billItems = [];
  List<BillParticipant> _participants = [];
  bool _isProcessing = false;

  Future<void> _pickAndProcessImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) return;

    // Add the current user as the first participant
    final currentUser = ref.read(userProfileProvider).value;
    if (currentUser != null && _participants.isEmpty) {
        _participants.add(BillParticipant(userId: currentUser.id, name: "Moi"));
    }

    setState(() {
      _imageFile = imageFile;
      _isProcessing = true;
    });

    final text = await _ocrService.getTextFromImage(imageFile);
    final parsedItems = _ocrService.parseBillText(text);

    setState(() {
      _billItems = parsedItems.map((item) => BillItem(description: item['description'], price: item['price'])).toList();
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Diviser une Facture'),
      body: Column(
        children: [
          if (_imageFile == null)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Sélectionner une facture'),
                onPressed: _pickAndProcessImage,
              ),
            ),
          if (_imageFile != null)
            SizedBox(
              height: 200,
              child: Image.file(File(_imageFile!.path)),
            ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
          if (_billItems.isNotEmpty)
            _buildParticipantsSection(),
          Expanded(
            child: ListView.builder(
              itemCount: _billItems.length,
              itemBuilder: (context, index) {
                final item = _billItems[index];
                return ListTile(
                  title: Text(item.description),
                  subtitle: Text(item.assignedParticipantIds.isEmpty ? 'Non assigné' : 'Assigné à: ${item.assignedParticipantIds.map((id) => _participants.firstWhere((p) => p.userId == id).name).join(', ')}'),
                  trailing: Text('${item.price.toStringAsFixed(2)} FCFA'),
                  onTap: () => _showAssignItemDialog(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Participants', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8.0,
            children: _participants.map((p) => Chip(label: Text(p.name))).toList()..add(
              ActionChip(
                label: const Text('Ajouter'),
                onPressed: _addParticipant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addParticipant() {
    // In a real app, this would open a user search dialog.
    // For this demo, we'll add a mock user.
    final mockId = 'user_${_participants.length + 1}';
    setState(() {
      _participants.add(BillParticipant(userId: mockId, name: 'Ami ${_participants.length}'));
    });
  }

  void _showAssignItemDialog(BillItem item) {
    showDialog(
      context: context,
      builder: (context) {
        // Using a StatefulBuilder to manage the dialog's own state
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assigner: ${item.description}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final participant = _participants[index];
                    final isAssigned = item.assignedParticipantIds.contains(participant.userId);
                    return CheckboxListTile(
                      title: Text(participant.name),
                      value: isAssigned,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            item.assignedParticipantIds.add(participant.userId);
                          } else {
                            item.assignedParticipantIds.remove(participant.userId);
                          }
                        });
                        // Also update the main screen state when dialog is closed
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
