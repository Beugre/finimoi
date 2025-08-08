# Test du Deep Link FinIMoi

## 🚀 Modification apportées :

### 1. Configuration Android (`AndroidManifest.xml`)
- ✅ Ajout de l'intent-filter pour le scheme `finimoi://`

### 2. Configuration iOS (`Info.plist`)
- ✅ Scheme `finimoi` déjà configuré

### 3. Code natif Android (`MainActivity.kt`)
- ✅ Ajout de la gestion des deep links via MethodChannel

### 4. Code natif iOS (`AppDelegate.swift`) 
- ✅ Ajout de la gestion des deep links via MethodChannel

### 5. Code Flutter (`main.dart`)
- ✅ Initialisation du router global
- ✅ Initialisation du service de deep links

## 🧪 Tests à effectuer :

### 1. Test en développement
```bash
cd /Users/yoannbeugre/Documents/DEV/finimoi
flutter run
```

### 2. Test du deep link iOS (Simulateur)
```bash
xcrun simctl openurl booted "finimoi://payment/return?transaction_id=TEST123&status=success"
```

### 3. Test du deep link Android (Emulateur)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "finimoi://payment/return?transaction_id=TEST123&status=success" com.finimoi.app.finimoi
```

### 4. Test du flow complet
1. Lancer l'app
2. Initier un paiement CinetPay
3. Redirection vers le navigateur
4. Site web redirige avec `finimoi://payment/return?transaction_id=XXX`
5. App doit s'ouvrir et naviguer vers PaymentReturnScreen

## 🔍 Debugging

### Logs à surveiller :
- `🔗 Deep link reçu: finimoi://payment/return?transaction_id=XXX`
- `📋 Scheme: finimoi, Path: /payment/return`
- `💳 Transaction ID: XXX, Status: YYY`
- `✅ Navigation via router global vers /payment/return`

### En cas d'erreur "page non trouvée" :
1. Vérifier que le router global est initialisé
2. Vérifier que le service de deep links est démarré
3. Vérifier les logs du MethodChannel
4. Tester manuellement avec les commandes ci-dessus

## 📱 URL de test complet :
`finimoi://payment/return?transaction_id=TESTCINETPAY123&status=success`
