# Contribution Guidelines - FinIMoi

Merci de votre intérêt pour contribuer à FinIMoi ! Voici les guidelines pour maintenir la qualité du code.

## 🏗️ Architecture

- **Pattern MVVM** avec Riverpod
- **Clean Architecture** (Domain, Data, Presentation)
- **Repository Pattern** pour l'accès aux données
- **Dependency Injection** avec Riverpod

## 📝 Conventions de Code

### Dart/Flutter
- Suivre les [conventions Dart officielles](https://dart.dev/guides/language/effective-dart)
- Utiliser `dart format` avant chaque commit
- Commenter les fonctions publiques
- Utiliser des noms de variables descriptifs

### Structure des Fichiers
```
lib/
├── core/           # Configuration, constantes, utils
├── data/           # Repositories, data sources, models
├── domain/         # Entities, use cases, repositories abstracts
├── presentation/   # Screens, widgets, providers
└── shared/         # Widgets partagés, extensions
```

### Nommage
- **Fichiers**: snake_case (ex: `user_service.dart`)
- **Classes**: PascalCase (ex: `UserService`)
- **Variables/Méthodes**: camelCase (ex: `getUserById`)
- **Constantes**: SCREAMING_SNAKE_CASE (ex: `API_BASE_URL`)

## 🧪 Tests

- Écrire des tests unitaires pour la logique métier
- Écrire des tests d'intégration pour les flows critiques
- Maintenir une couverture de code > 80%

```bash
# Lancer les tests
flutter test

# Couverture de code
flutter test --coverage
```

## 🔄 Workflow Git

1. Fork le repository
2. Créer une branche descriptive (`feature/add-tontine-creation`)
3. Faire des commits atomiques avec des messages clairs
4. Pousser et créer une Pull Request
5. Attendre la review avant merge

## 📋 Pull Request Checklist

- [ ] Le code compile sans erreurs
- [ ] Les tests passent
- [ ] La documentation est à jour
- [ ] Le code respecte les conventions
- [ ] Pas de code commenté ou de TODO
- [ ] Les changements sont testés manuellement

## 🐛 Signaler un Bug

Utilisez le template d'issue GitHub en incluant :
- Description claire du problème
- Étapes pour reproduire
- Comportement attendu vs actuel
- Screenshots si applicable
- Version de l'app et OS

## 💡 Proposer une Fonctionnalité

1. Vérifier si la fonctionnalité n'existe pas déjà
2. Créer une issue avec le label "enhancement"
3. Décrire le besoin et la solution proposée
4. Attendre l'approbation avant développer

## 🔒 Sécurité

- Ne jamais committer de clés API ou secrets
- Utiliser des variables d'environnement
- Chiffrer les données sensibles
- Valider côté serveur

Merci de contribuer à FinIMoi ! 🚀
