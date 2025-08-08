import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/cinetpay_config.dart';
import '../../../data/services/cinetpay_service.dart';

class CinetPayConfigScreen extends ConsumerStatefulWidget {
  const CinetPayConfigScreen({super.key});

  @override
  ConsumerState<CinetPayConfigScreen> createState() =>
      _CinetPayConfigScreenState();
}

class _CinetPayConfigScreenState extends ConsumerState<CinetPayConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _siteIdController = TextEditingController();

  bool _isLoading = false;
  bool _isTestMode = true;
  bool _isProduction = false;
  String _defaultCurrency = 'XOF';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    _siteIdController.dispose();
    super.dispose();
  }

  void _loadCurrentConfig() {
    // Charger la configuration actuelle si elle existe
    _apiKeyController.text = CinetPayConfig.apiKey;
    _siteIdController.text = CinetPayConfig.siteId;
    _isTestMode = !CinetPayConfig.isProduction;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration CinetPay'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Information générale
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration CinetPay',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Configurez vos identifiants CinetPay pour activer les paiements mobiles (Orange Money, Moov Money, Wave) et cartes bancaires.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mode de test
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Environnement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Mode Test'),
                        subtitle: Text(
                          _isTestMode
                              ? 'Utilise l\'environnement de test CinetPay'
                              : 'Utilise l\'environnement de production CinetPay',
                        ),
                        value: _isTestMode,
                        onChanged: (value) {
                          setState(() {
                            _isTestMode = value;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Identifiants CinetPay
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identifiants Merchant',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // API Key
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API Key *',
                          hintText: 'Votre clé API CinetPay',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.key),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'API Key est obligatoire';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Secret Key
                      TextFormField(
                        controller: _secretKeyController,
                        decoration: InputDecoration(
                          labelText: 'Secret Key *',
                          hintText: 'Votre clé secrète CinetPay',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La Secret Key est obligatoire';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Site ID
                      TextFormField(
                        controller: _siteIdController,
                        decoration: InputDecoration(
                          labelText: 'Site ID *',
                          hintText: 'L\'ID de votre site CinetPay',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.web),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le Site ID est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Méthodes de paiement supportées
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Méthodes de paiement supportées',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodChip('Orange Money', Colors.orange),
                      _buildPaymentMethodChip('Moov Money', Colors.blue),
                      _buildPaymentMethodChip('Wave', Colors.blue[800]!),
                      _buildPaymentMethodChip(
                        'Visa/Mastercard',
                        Colors.grey[700]!,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _testConnection,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tester la connexion'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sauvegarder'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Aide
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Besoin d\'aide ? Consultez la documentation CinetPay ou contactez le support.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.check, color: color, size: 16),
        ),
        label: Text(name),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Tester la connexion avec CinetPay en récupérant les méthodes de paiement
      final cinetPayService = ref.read(cinetPayServiceProvider);
      final paymentMethods = await cinetPayService.getPaymentMethods();

      if (paymentMethods.isNotEmpty) {
        if (mounted) {
          _showSuccessDialog(
            'Connexion CinetPay réussie ! ${paymentMethods.length} méthodes disponibles.',
          );
        }
      } else {
        throw Exception('Aucune méthode de paiement disponible');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur de connexion: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Sauvegarder la configuration dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('cinetpay_api_key', _apiKeyController.text);
      await prefs.setString('cinetpay_secret_key', _secretKeyController.text);
      await prefs.setString('cinetpay_site_id', _siteIdController.text);
      await prefs.setBool('cinetpay_is_production', _isProduction);
      await prefs.setString('cinetpay_default_currency', _defaultCurrency);

      if (mounted) {
        _showSuccessDialog('Configuration sauvegardée avec succès !');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur lors de la sauvegarde: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide CinetPay'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pour obtenir vos identifiants CinetPay:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Créez un compte sur https://cinetpay.com'),
              Text('2. Validez votre compte merchant'),
              Text('3. Récupérez vos clés API dans le dashboard'),
              Text('4. Configurez vos URLs de callback'),
              SizedBox(height: 12),
              Text(
                'URLs de callback suggérées:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Return URL: https://yourapp.com/payment/success'),
              Text('• Notify URL: https://yourapp.com/webhook/cinetpay'),
              Text('• Cancel URL: https://yourapp.com/payment/cancel'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
