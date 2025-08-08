# Copilot Instructions pour FinIMoi

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Architecture du Projet

Ce projet est une application financière mobile Flutter inspirée de Revolut, Lydia et Sumeria avec les caractéristiques suivantes :

### Stack Technique
- **Frontend**: Flutter avec Dart
- **Backend**: Firebase (Auth, Firestore, Storage, Functions)
- **State Management**: Riverpod avec code generation
- **Architecture**: MVVM (Model-View-ViewModel)
- **Navigation**: Go Router
- **Theming**: Material 3 avec support dark/light mode

### Structure des Dossiers
```
lib/
├── core/              # Configuration, constantes, utils
├── data/              # Repositories, data sources, models
├── domain/            # Entities, use cases, repositories abstracts
├── presentation/      # Screens, widgets, providers
├── shared/            # Widgets partagés, extensions
└── main.dart          # Point d'entrée
```

### Fonctionnalités Principales
1. **Authentification** : Email, SMS, Google, Facebook, Apple, LinkedIn
2. **Paiements** : Transferts, recharges, cartes virtuelles/physiques
3. **Tontine** : Gestion de tontines avec rappels automatiques
4. **Crédit** : Demandes et gestion de crédits
5. **Épargne** : Comptes d'épargne avec blocage temporel
6. **Messagerie** : Chat intégré avec boutons de paiement
7. **Gamification** : Cashback, badges, défis
8. **Merchant** : Paiements NFC et QR codes

### Guidelines de Développement
- Utiliser Riverpod pour la gestion d'état
- Implémenter le pattern Repository
- Créer des widgets réutilisables
- Respecter les conventions de nommage Dart
- Utiliser des extensions pour les utilitaires
- Implémenter des tests unitaires et d'intégration
- Suivre les principes SOLID
- Gérer les erreurs avec des Either<Failure, Success>
- Utiliser l'injection de dépendances avec Riverpod
- Implémenter la validation des formulaires
- Gérer la persistance locale avec Hive
- Optimiser les performances avec des builders appropriés

### Design System
- Palette de couleurs proche de Revolut/Lydia
- Typography cohérente
- Spacing et sizing standardisés
- Animations fluides et micro-interactions
- Support RTL pour l'internationalisation
- Accessibilité conforme aux standards

### Sécurité
- Authentification biométrique (TouchID/FaceID)
- Chiffrement des données sensibles
- Validation côté serveur
- Gestion sécurisée des tokens
- Audit trails pour les transactions
