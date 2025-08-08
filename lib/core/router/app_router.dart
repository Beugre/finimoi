import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/profile_edit_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/payments/payment_screen.dart';
import '../../presentation/screens/tontine/tontine_screen.dart';
import '../../presentation/screens/tontine/create_tontine_screen.dart';
import '../../presentation/screens/tontine/tontine_detail_screen.dart';
import '../../presentation/screens/transfers/transfer_screen.dart';
import '../../presentation/screens/cards/cards_screen.dart';
import '../../presentation/screens/savings/savings_screen_v2.dart';
import '../../presentation/screens/savings/create_savings_screen.dart';
import '../../presentation/screens/savings/savings_details_screen.dart';
import '../../presentation/screens/credit/credit_screen_v2.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/chat/conversation_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/payments/recharge_screen_cinetpay.dart';
import '../../presentation/screens/payments/payment_return_screen.dart';
import '../../presentation/screens/payments/payment_cancel_screen.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash & Auth
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main App with Bottom Navigation
      GoRoute(path: '/main', builder: (context, state) => const MainScreen()),

      // Individual Screens
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/tontine',
        builder: (context, state) => const TontineScreen(),
      ),
      GoRoute(
        path: '/savings',
        builder: (context, state) => const SavingsScreen(),
      ),
      GoRoute(
        path: '/credit',
        builder: (context, state) => const CreditScreen(),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferScreen(),
      ),
      GoRoute(
        path: '/recharge',
        builder: (context, state) => const RechargeScreenCinetPay(),
      ),
      GoRoute(
        path: '/payment/return',
        builder: (context, state) {
          final transactionId = state.uri.queryParameters['transaction_id'];
          final status = state.uri.queryParameters['status'];
          final message = state.uri.queryParameters['message'];
          return PaymentReturnScreen(
            transactionId: transactionId,
            status: status,
            message: message,
          );
        },
      ),
      GoRoute(
        path: '/payment/cancel',
        builder: (context, state) => const PaymentCancelScreen(),
      ),

      // Tontine routes
      GoRoute(
        path: '/tontine/create',
        builder: (context, state) => const CreateTontineScreen(),
      ),
      GoRoute(
        path: '/tontine/:id',
        builder: (context, state) =>
            TontineDetailScreen(tontineId: state.pathParameters['id']!),
      ), // Savings routes
      GoRoute(
        path: '/savings/create',
        builder: (context, state) => const CreateSavingsScreen(),
      ),
      GoRoute(
        path: '/savings/:id',
        builder: (context, state) =>
            SavingsDetailsScreen(savingsId: state.pathParameters['id']!),
      ),

      // Credit routes
      GoRoute(
        path: '/credit/apply',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Demande de crédit')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),
      GoRoute(
        path: '/credit/:id',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Détails crédit')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),

      // Chat routes
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return ConversationScreen(chatId: chatId);
        },
      ),

      // Cards routes
      GoRoute(path: '/cards', builder: (context, state) => const CardsScreen()),
      GoRoute(
        path: '/cards/:id',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Détails carte')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),

      // Other routes
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),
      GoRoute(
        path: '/merchant',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Marchands')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),
      GoRoute(
        path: '/merchant/dashboard',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Tableau de bord marchand')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Scanner QR')),
          body: const Center(child: Text('Écran en développement')),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'La page demandée n\'existe pas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;
}
