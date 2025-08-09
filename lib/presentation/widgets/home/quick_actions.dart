import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.group,
                title: 'Tontine',
                subtitle: 'Organiser une tontine',
                color: AppColors.success,
                onTap: () {
                  context.push('/tontine');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.savings,
                title: 'Épargne',
                subtitle: 'Créer un objectif',
                color: AppColors.info,
                onTap: () {
                  context.push('/savings');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.add_circle,
                title: 'Recharger',
                subtitle: 'Ajouter des fonds',
                color: AppColors.primaryViolet,
                onTap: () {
                  context.push('/recharge');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.credit_card,
                title: 'Crédit',
                subtitle: 'Demander un crédit',
                color: AppColors.warning,
                onTap: () {
                  context.push('/credit');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.chat,
                title: 'Messages',
                subtitle: 'Envoyer un message',
                color: AppColors.accent,
                onTap: () {
                  context.push('/chat');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.send,
                title: 'Transfert',
                subtitle: 'Envoyer de l\'argent',
                color: AppColors.secondary,
                onTap: () {
                  context.push('/transfer');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.money_off,
                title: 'Retrait',
                subtitle: 'Retirer des fonds',
                color: AppColors.error,
                onTap: () {
                  context.push('/withdraw');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.link,
                title: 'Lien de paiement',
                subtitle: 'Recevoir de l\'argent',
                color: AppColors.info,
                onTap: () {
                  context.push('/payments/link');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.receipt_long,
                title: 'Diviser une facture',
                subtitle: 'Utiliser l\'OCR pour partager',
                color: Colors.teal,
                onTap: () {
                  context.push('/split-bill');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.store,
                title: 'Nos Partenaires',
                subtitle: 'Découvrez nos partenaires',
                color: Colors.purple,
                onTap: () {
                  context.push('/partners');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.favorite,
                title: 'Faire un Don',
                subtitle: 'Soutenir une cause',
                color: Colors.redAccent,
                onTap: () {
                  context.push('/donations');
                },
              ),
            ),
             const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.school,
                title: 'Frais Scolaires',
                subtitle: 'Payer les frais de scolarité',
                color: Colors.brown,
                onTap: () {
                  context.push('/school-fees');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionItem(
                icon: Icons.casino,
                title: 'Loterie',
                subtitle: 'Tentez votre chance',
                color: Colors.deepOrange,
                onTap: () {
                  context.push('/lottery');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionItem(
                icon: Icons.home_work,
                title: 'Logement',
                subtitle: 'Payer votre loyer',
                color: Colors.lightGreen,
                onTap: () {
                  context.push('/housing');
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
