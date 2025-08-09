import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/providers/merchant_provider.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantProfileAsync = ref.watch(merchantProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Code QR de Paiement')),
      body: Center(
        child: merchantProfileAsync.when(
          data: (merchant) {
            if (merchant == null || merchant.qrCodeData.isEmpty) {
              return const Text('Impossible de générer le code QR.');
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: merchant.qrCodeData,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
                const SizedBox(height: 24),
                Text(
                  'Scannez pour payer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  merchant.businessName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Erreur: $err'),
        ),
      ),
    );
  }
}
