import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/presentation/widgets/common/custom_button.dart';
import 'package:finimoi/data/providers/subscription_provider.dart';
import 'package:finimoi/data/providers/gamification_provider.dart';
import 'package:finimoi/data/providers/gift_card_provider.dart';
import 'package:finimoi/data/providers/donation_provider.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _runRecurringPayments() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing...';
    });

    try {
      final count = await ref.read(subscriptionServiceProvider).processRecurringPayments();
      setState(() {
        _statusMessage = '$count payments processed successfully.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Debug Menu'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomButton(
              text: 'Process Recurring Payments',
              onPressed: _runRecurringPayments,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty) Text(_statusMessage),
            const Divider(height: 32),
            CustomButton(
              text: 'Create Sample Quiz Questions',
              onPressed: () async {
                await ref.read(gamificationServiceProvider).createSampleQuestions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample questions created!')),
                );
              },
              variant: ButtonVariant.secondary,
            ),
            const Divider(height: 32),
            CustomButton(
              text: 'Create Sample Partner Stores',
              onPressed: () async {
                await ref.read(giftCardServiceProvider).createSamplePartnerStores();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample stores created!')),
                );
              },
              variant: ButtonVariant.secondary,
            ),
            const Divider(height: 32),
            CustomButton(
              text: 'Create Sample Orphanages',
              onPressed: () async {
                await ref.read(donationServiceProvider).createSampleOrphanages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample orphanages created!')),
                );
              },
              variant: ButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
