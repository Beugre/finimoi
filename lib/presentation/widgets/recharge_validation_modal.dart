import 'package:flutter/material.dart';
import 'package:finimoi/core/constants/app_colors.dart';

class RechargeValidationModal extends StatelessWidget {
  final double amount;
  final String currency;
  final String paymentMethod;
  final IconData methodIcon;
  final Color methodColor;
  final String phoneNumber;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const RechargeValidationModal({
    super.key,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.methodIcon,
    required this.methodColor,
    required this.phoneNumber,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: AppColors.primaryViolet,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirmer la recharge',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vérifiez les détails de votre recharge :',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Montant
          _buildInfoCard(
            icon: Icons.monetization_on,
            iconColor: AppColors.primaryViolet,
            backgroundColor: AppColors.primaryViolet.withOpacity(0.1),
            title: 'Montant :',
            value: '$amount $currency',
            valueColor: AppColors.primaryViolet,
          ),

          const SizedBox(height: 12),

          // Méthode de paiement
          _buildInfoCard(
            icon: methodIcon,
            iconColor: methodColor,
            backgroundColor: Colors.grey[50]!,
            borderColor: Colors.grey[200]!,
            title: 'Méthode :',
            value: paymentMethod,
          ),

          const SizedBox(height: 12),

          // Numéro de téléphone
          _buildInfoCard(
            icon: Icons.phone,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue[50]!,
            borderColor: Colors.blue[200]!,
            title: 'Téléphone :',
            value: phoneNumber,
          ),

          const SizedBox(height: 20),

          // Information de sécurité
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transaction sécurisée par CinetPay',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Confirmer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    Color? borderColor,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueColor != null ? 18 : 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
