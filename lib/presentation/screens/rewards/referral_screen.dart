import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/providers/user_provider.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Parrainer un ami'),
      body: Center(
        child: userProfileAsync.when(
          data: (user) {
            if (user == null || user.referralCode == null) {
              return const Text("Votre code de parrainage n'est pas encore disponible.");
            }
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Partagez votre code unique et gagnez des récompenses !',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Votre code de parrainage :',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: user.referralCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copié dans le presse-papiers!')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.referralCode!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre ami recevra 50 points en utilisant ce code, et vous aussi !',
                     textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => const Text('Erreur de chargement du profil.'),
        ),
      ),
    );
  }
}
