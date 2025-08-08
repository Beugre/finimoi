# FinIMoi - Plan de Développement PRODUCTION

## 🎯 FONCTIONNALITÉS PRINCIPALES

### 1. AUTHENTIFICATION ✅
- [x] Email/Password
- [x] Google Sign-in
- [x] Apple Sign-in
- [ ] SMS Verification
- [ ] LinkedIn Sign-in
- [ ] Facebook Sign-in

### 2. PAIEMENTS & TRANSFERTS
- [x] Transfert par email
- [x] Recharge par simulation
- [ ] Paiement par QR Code
- [ ] Paiement NFC
- [ ] CinetPay intégration
- [ ] Mobile Money
- [ ] Carte bancaire

### 3. TONTINES
- [ ] Création de tontine
- [ ] Invitation participants
- [ ] Gestion des contributions
- [ ] Rappels automatiques
- [ ] Historique des tours

### 4. CRÉDIT
- [ ] Demande de crédit
- [ ] Évaluation crédit
- [ ] Remboursement
- [ ] Historique crédits

### 5. ÉPARGNE
- [ ] Objectifs d'épargne
- [ ] Épargne bloquée
- [ ] Intérêts
- [ ] Statistiques

### 6. MESSAGERIE
- [ ] Chat 1-to-1
- [ ] Boutons de paiement
- [ ] Groupes
- [ ] Notifications

### 7. CARTES
- [ ] Carte virtuelle
- [ ] Carte physique
- [ ] Gestion limites
- [ ] Blocage/déblocage

### 8. GAMIFICATION
- [ ] Système de points
- [ ] Badges
- [ ] Défis
- [ ] Cashback

### 9. MERCHANT
- [ ] Profil commerçant
- [ ] Terminal de paiement
- [ ] QR Code dynamique
- [ ] Statistiques ventes

### 10. NOTIFICATIONS
- [ ] Push notifications
- [ ] Notifications in-app
- [ ] Email notifications
- [ ] SMS notifications

## 📱 ÉCRANS À CRÉER

### Auth Screens ✅
- [x] SplashScreen
- [x] OnboardingScreen
- [x] LoginScreen
- [x] RegisterScreen

### Main Screens
- [x] HomeScreen
- [x] TransferScreen
- [x] RechargeScreen
- [ ] TontineScreen
- [ ] SavingsScreen
- [ ] CreditScreen
- [ ] ChatScreen
- [ ] ProfileScreen
- [ ] PaymentScreen

### Detailed Screens
- [ ] TontineDetailsScreen
- [ ] CreateTontineScreen
- [ ] CreditApplicationScreen
- [ ] SavingsGoalScreen
- [ ] CardManagementScreen
- [ ] TransactionHistoryScreen
- [ ] SettingsScreen
- [ ] NotificationScreen
- [ ] MerchantDashboardScreen
- [ ] QRScannerScreen

## 🗄️ COLLECTIONS FIRESTORE

### Users Collection ✅
```
/users/{userId}
- email, firstName, lastName
- balance, createdAt, lastLoginAt
- isEmailVerified, isPhoneVerified
```

### Transactions Collection ✅
```
/transactions/{transactionId}
- userId, type, status, amount
- recipientId, description, createdAt
```

### Nouvelles Collections Nécessaires:

#### Tontines Collection
```
/tontines/{tontineId}
- name, description, amount
- frequency, participants[], currentTurn
- createdBy, status, createdAt
```

#### TontineParticipants SubCollection
```
/tontines/{tontineId}/participants/{userId}
- userId, joinedAt, contributionsPaid
- hasPaidThisTurn, position
```

#### Credits Collection
```
/credits/{creditId}
- userId, amount, interestRate
- duration, status, requestedAt
- approvedAt, dueDate
```

#### Savings Collection
```
/savings/{savingId}
- userId, goalName, targetAmount
- currentAmount, deadline, isLocked
- interestRate, createdAt
```

#### Cards Collection
```
/cards/{cardId}
- userId, cardNumber, expiryDate
- type (virtual/physical), status
- limits{daily, monthly}, isBlocked
```

#### Messages Collection
```
/conversations/{conversationId}
- participants[], lastMessage
- lastMessageAt, type (direct/group)
```

#### Messages SubCollection
```
/conversations/{conversationId}/messages/{messageId}
- senderId, content, timestamp
- type (text/payment), paymentData{}
```

#### Notifications Collection
```
/notifications/{notificationId}
- userId, title, body, type
- isRead, createdAt, actionData{}
```

#### Merchants Collection
```
/merchants/{merchantId}
- userId, businessName, category
- qrCode, isActive, commission
- totalSales, lastSaleAt
```

## 🛣️ ROUTES COMPLÈTES

### Auth Routes ✅
- /splash
- /onboarding
- /auth/login
- /auth/register

### Main Routes
- /main
- /home ✅
- /transfer ✅
- /recharge ✅
- /tontine
- /savings
- /credit
- /chat
- /profile
- /payments

### Detailed Routes
- /tontine/create
- /tontine/{id}
- /savings/create
- /savings/{id}
- /credit/apply
- /credit/{id}
- /cards
- /cards/{id}
- /history
- /settings
- /notifications
- /merchant
- /merchant/dashboard
- /scan-qr

## 🚀 ORDRE DE DÉVELOPPEMENT PRIORITAIRE

1. **TONTINES** (Core feature)
2. **CARTES VIRTUELLES** (Revenue)
3. **ÉPARGNE** (Engagement)
4. **CRÉDIT** (Revenue)
5. **MESSAGERIE** (Social)
6. **MERCHANT** (B2B Revenue)
7. **GAMIFICATION** (Retention)
8. **NOTIFICATIONS** (Engagement)
