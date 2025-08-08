import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/currency_service.dart';

class CurrencySelectionWidget extends ConsumerWidget {
  final Function(String)? onCurrencyChanged;
  final bool showToggleButton;

  const CurrencySelectionWidget({
    super.key,
    this.onCurrencyChanged,
    this.showToggleButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(currencyPreferencesProvider);
    final converter = ref.watch(currencyConverterProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Devise d\'affichage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (showToggleButton)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      ref
                          .read(currencyPreferencesProvider.notifier)
                          .toggleCurrencyDisplay();
                      if (onCurrencyChanged != null) {
                        onCurrencyChanged!(preferences.displayCurrency);
                      }
                    },
                    tooltip: 'Changer l\'affichage',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Options de devise
            Column(
              children: [
                _buildCurrencyOption(
                  context,
                  ref,
                  'XOF',
                  'Franc CFA uniquement',
                  'Afficher seulement les montants en XOF',
                  Icons.monetization_on,
                  Colors.orange,
                  preferences.displayCurrency == 'XOF',
                ),

                const SizedBox(height: 8),

                _buildCurrencyOption(
                  context,
                  ref,
                  'EUR',
                  'Euro uniquement',
                  'Afficher seulement les montants en EUR',
                  Icons.euro,
                  Colors.blue,
                  preferences.displayCurrency == 'EUR',
                ),

                const SizedBox(height: 8),

                _buildCurrencyOption(
                  context,
                  ref,
                  'BOTH',
                  'Affichage dual',
                  'Afficher XOF et EUR simultanément',
                  Icons.compare_arrows,
                  Colors.green,
                  preferences.displayCurrency == 'BOTH',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Taux de change actuel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taux de change actuel',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 EUR = ${converter.getExchangeRate('EUR', 'XOF').toStringAsFixed(2)} XOF',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '1 XOF = ${converter.getExchangeRate('XOF', 'EUR').toStringAsFixed(4)} EUR',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Exemple d'affichage
            if (preferences.displayCurrency == 'BOTH') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exemple d\'affichage',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      converter.formatWithPreferences(10000, preferences),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context,
    WidgetRef ref,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref
            .read(currencyPreferencesProvider.notifier)
            .setDisplayCurrency(value);
        if (onCurrencyChanged != null) {
          onCurrencyChanged!(value);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher un montant selon les préférences
class CurrencyAmountDisplay extends ConsumerWidget {
  final double amountXof;
  final TextStyle? style;
  final bool showIcon;

  const CurrencyAmountDisplay({
    super.key,
    required this.amountXof,
    this.style,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(currencyPreferencesProvider);
    final converter = ref.watch(currencyConverterProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
          const SizedBox(width: 4),
        ],
        Text(
          converter.formatWithPreferences(amountXof, preferences),
          style: style,
        ),
      ],
    );
  }
}

// Widget pour la conversion rapide
class QuickCurrencyConverter extends ConsumerStatefulWidget {
  const QuickCurrencyConverter({super.key});

  @override
  ConsumerState<QuickCurrencyConverter> createState() =>
      _QuickCurrencyConverterState();
}

class _QuickCurrencyConverterState
    extends ConsumerState<QuickCurrencyConverter> {
  final _amountController = TextEditingController();
  String _fromCurrency = 'XOF';
  String _toCurrency = 'EUR';
  double? _convertedAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _convertAmount() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    final converter = ref.read(currencyConverterProvider);
    setState(() {
      _convertedAmount = converter.getAmountInCurrency(
        amount,
        _fromCurrency,
        _toCurrency,
      );
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convertAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final converter = ref.watch(currencyConverterProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convertisseur rapide',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: _fromCurrency,
                    ),
                    onChanged: (_) => _convertAmount(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _swapCurrencies,
                  icon: const Icon(Icons.swap_horiz),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[50],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résultat',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          _convertedAmount != null
                              ? converter.formatAmount(
                                  _convertedAmount!,
                                  _toCurrency,
                                )
                              : '0.00 $_toCurrency',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
