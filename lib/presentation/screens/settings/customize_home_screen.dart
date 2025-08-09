import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/providers/user_provider.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';

class CustomizeHomeScreen extends ConsumerStatefulWidget {
  const CustomizeHomeScreen({super.key});

  @override
  ConsumerState<CustomizeHomeScreen> createState() => _CustomizeHomeScreenState();
}

class _CustomizeHomeScreenState extends ConsumerState<CustomizeHomeScreen> {
  late List<String> _layout;
  final Map<String, String> _layoutTitles = {
    'welcome': 'Message de bienvenue',
    'balance': 'Carte de solde',
    'actions': 'Actions rapides',
    'transactions': 'Transactions récentes',
    'promo': 'Bannière promotionnelle',
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider).value;
    _layout = List<String>.from(user?.homeScreenLayout ?? ['welcome', 'balance', 'actions', 'transactions', 'promo']);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _layout.removeAt(oldIndex);
      _layout.insert(newIndex, item);
    });
  }

  void _saveLayout() {
    final userId = ref.read(userProfileProvider).value?.id;
    if (userId != null) {
      ref.read(userServiceProvider).updateUserProfile(userId, {'homeScreenLayout': _layout});
      ref.invalidate(userProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise en page enregistrée!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Personnaliser l\'accueil',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLayout,
          ),
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(8),
        onReorder: _onReorder,
        children: _layout.map((String key) {
          return Card(
            key: Key(key),
            child: ListTile(
              title: Text(_layoutTitles[key] ?? key),
              leading: const Icon(Icons.drag_handle),
            ),
          );
        }).toList(),
      ),
    );
  }
}
