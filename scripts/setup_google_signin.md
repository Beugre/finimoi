# Configuration Google Sign-In pour FinIMoi

## Étapes pour configurer Google Sign-In :

### 1. Télécharger GoogleService-Info.plist
1. Aller sur https://console.firebase.google.com/project/finimoi
2. Cliquer sur "Paramètres du projet" (icône engrenage)
3. Dans l'onglet "Général", descendre jusqu'à "Vos applications"
4. Cliquer sur l'app iOS "Runner" (Bundle ID: com.finimoi.app.finimoi)
5. Cliquer sur "Télécharger GoogleService-Info.plist"
6. Remplacer le fichier dans `ios/Runner/GoogleService-Info.plist`

### 2. Extraire le REVERSED_CLIENT_ID
Après avoir téléchargé le fichier correct :
1. Ouvrir le fichier GoogleService-Info.plist
2. Copier la valeur de `REVERSED_CLIENT_ID`
3. Mettre à jour `ios/Runner/Info.plist` avec cette valeur dans `CFBundleURLSchemes`

### 3. Commandes pour mettre à jour :
```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
cd ios && pod install
cd ..
flutter build ios
```

### 4. Vérifications :
- [ ] GoogleService-Info.plist contient REVERSED_CLIENT_ID
- [ ] Info.plist contient le bon CFBundleURLSchemes
- [ ] Bundle ID correspond : com.finimoi.app.finimoi
- [ ] OAuth 2.0 Client configuré dans Google Cloud Console

### 5. Test :
```bash
flutter run -d ios
```

## Erreurs communes :
- **"No valid client ID"** : REVERSED_CLIENT_ID manquant ou incorrect
- **"Bundle ID mismatch"** : Bundle ID différent entre Xcode et Firebase
- **"OAuth client not found"** : Client OAuth pas configuré dans Google Cloud Console

## Liens utiles :
- Console Firebase : https://console.firebase.google.com/project/finimoi
- Google Cloud Console : https://console.cloud.google.com/apis/credentials?project=finimoi
