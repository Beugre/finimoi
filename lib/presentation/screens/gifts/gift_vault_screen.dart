import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/gift_card_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GiftVaultScreen extends ConsumerWidget {
  const GiftVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftCardsAsync = ref.watch(myGiftCardsProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Mon Coffre à Cadeaux'),
      body: giftCardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('Votre coffre à cadeaux est vide.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    // backgroundImage: NetworkImage(card.storeLogoUrl),
                  ),
                  title: Text(card.storeName),
                  subtitle: Text('Solde: ${card.remainingBalance} / ${card.initialAmount} FCFA'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          QrImageView(
                            data: card.code,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                          const SizedBox(height: 8),
                          Text('Code: ${card.code}'),
                          Text('Expire le: ${card.expiryDate.toLocal().toString().split(' ')[0]}'),
                        ],
                      ),
                    ),
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
}
