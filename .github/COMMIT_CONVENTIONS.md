# Structure des Commits

Utilisez des préfixes pour vos commits :

- `feat:` pour une nouvelle fonctionnalité
- `fix:` pour une correction de bug
- `docs:` pour la documentation
- `style:` pour les changements de style (formatage, etc.)
- `refactor:` pour la refactorisation de code
- `test:` pour l'ajout ou modification de tests
- `chore:` pour les tâches de maintenance

## Exemples

```bash
git commit -m "feat: add tontine creation functionality"
git commit -m "fix: resolve payment validation issue"
git commit -m "docs: update README with new features"
```

## Workflow de Développement

1. Créer une branche pour chaque fonctionnalité
```bash
git checkout -b feature/nouvelle-fonctionnalite
```

2. Faire vos changements et commits

3. Pousser la branche
```bash
git push origin feature/nouvelle-fonctionnalite
```

4. Créer une Pull Request sur GitHub

5. Merger après review

## Branches Importantes

- `main`: Version stable en production
- `develop`: Version de développement
- `feature/*`: Nouvelles fonctionnalités
- `fix/*`: Corrections de bugs
- `release/*`: Préparation des releases
