import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/phone_auth_screen.dart';
import '../../presentation/screens/auth/otp_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/profile_edit_screen.dart';
import '../../presentation/screens/profile/manage_subscriptions_screen.dart';
import '../../presentation/screens/profile/junior_dashboard_screen.dart';
import '../../presentation/screens/profile/create_junior_account_screen.dart';
import '../../presentation/screens/gifts/gift_vault_screen.dart';
import '../../presentation/screens/gifts/gift_card_store_screen.dart';
import '../../presentation/screens/splitting/bill_split_screen.dart';
import '../../presentation/screens/partners/partner_hub_screen.dart';
import '../../presentation/screens/donations/donation_hub_screen.dart';
import '../../presentation/screens/donations/donation_screen.dart';
import '../../presentation/screens/school/school_fees_screen.dart';
import '../../presentation/screens/lottery/lottery_screen.dart';
import '../../presentation/screens/housing/my_housing_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/debug_screen.dart';
import '../../presentation/screens/settings/customize_home_screen.dart';
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
import '../../presentation/screens/notifications/notification_center_screen.dart';
import '../../presentation/screens/merchant/merchant_onboarding_screen.dart';
import '../../presentation/screens/merchant/merchant_dashboard_screen.dart';
import '../../presentation/screens/merchant/qr_code_screen.dart';
import '../../presentation/screens/merchant/merchant_payment_screen.dart';
import '../../presentation/screens/merchant/subscription_plans_screen.dart';
import '../../presentation/screens/merchant/create_subscription_plan_screen.dart';
import '../../presentation/screens/merchant/invoices_screen.dart';
import '../../presentation/screens/merchant/create_invoice_screen.dart';
import '../../presentation/screens/scanner/qr_scanner_screen.dart';
import '../../presentation/screens/rewards/rewards_screen.dart';
import '../../presentation/screens/rewards/leaderboard_screen.dart';
import '../../presentation/screens/rewards/referral_screen.dart';
import '../../presentation/screens/rewards/quiz_screen.dart';
import '../../presentation/screens/statistics/statistics_screen.dart';
import '../../presentation/screens/payments/request_money_screen.dart';
import '../../presentation/screens/cards/physical_card_form_screen.dart';
import '../../presentation/screens/credit/repayment_schedule_screen.dart';
import '../../domain/entities/credit_model.dart';
import '../../presentation/screens/payments/withdrawal_screen.dart';
import '../../presentation/screens/payments/payment_link_screen.dart';
import '../../presentation/screens/payments/subscription_approval_screen.dart';

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
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final verificationId = state.extra as String;
          return OtpScreen(verificationId: verificationId);
        },
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
        path: '/profile/subscriptions',
        builder: (context, state) => const ManageSubscriptionsScreen(),
      ),
      GoRoute(
        path: '/profile/junior',
        builder: (context, state) => const JuniorDashboardScreen(),
      ),
      GoRoute(
        path: '/profile/junior/create',
        builder: (context, state) => const CreateJuniorAccountScreen(),
      ),
      GoRoute(
        path: '/profile/gift-vault',
        builder: (context, state) => const GiftVaultScreen(),
      ),
      GoRoute(
        path: '/gifts/store',
        builder: (context, state) => const GiftCardStoreScreen(),
      ),
      GoRoute(
        path: '/split-bill',
        builder: (context, state) => const BillSplitScreen(),
      ),
      GoRoute(
        path: '/partners',
        builder: (context, state) => const PartnerHubScreen(),
      ),
      GoRoute(
        path: '/school-fees',
        builder: (context, state) => const SchoolFeesScreen(),
      ),
      GoRoute(
        path: '/lottery',
        builder: (context, state) => const LotteryScreen(),
      ),
      GoRoute(
        path: '/housing',
        builder: (context, state) => const MyHousingScreen(),
      ),
      GoRoute(
        path: '/donations',
        builder: (context, state) => const DonationHubScreen(),
      ),
      GoRoute(
        path: '/donations/:id',
        builder: (context, state) {
          final orphanage = state.extra as PartnerOrphanage;
          return DonationScreen(
            orphanageId: state.pathParameters['id']!,
            orphanageName: orphanage.name,
          );
        },
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
      GoRoute(
        path: '/payments/request',
        builder: (context, state) => const RequestMoneyScreen(),
      ),
      GoRoute(
        path: '/withdraw',
        builder: (context, state) => const WithdrawalScreen(),
      ),
      GoRoute(
        path: '/payments/link',
        builder: (context, state) => const PaymentLinkScreen(),
      ),
      GoRoute(
        path: '/subscribe/:planId',
        builder: (context, state) {
          final planId = state.pathParameters['planId'];
          if (planId == null) {
            return const Scaffold(body: Center(child: Text('ID de plan manquant.')));
          }
          return SubscriptionApprovalScreen(planId: planId);
        },
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
        path: '/credit/:id/schedule',
        builder: (context, state) {
          final credit = state.extra as CreditModel;
          return RepaymentScheduleScreen(credit: credit);
        },
      ),
      GoRoute(
        path: '/merchant/onboarding',
        builder: (context, state) => const MerchantOnboardingScreen(),
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
        path: '/cards/physical-request',
        builder: (context, state) => const PhysicalCardFormScreen(),
      ),
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
        path: '/settings/debug',
        builder: (context, state) => const DebugScreen(),
      ),
      GoRoute(
        path: '/settings/customize-home',
        builder: (context, state) => const CustomizeHomeScreen(),
      ),
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/rewards/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/rewards/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/rewards/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
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
        builder: (context, state) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: '/merchant/subscriptions',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/merchant/subscriptions/create',
        builder: (context, state) => const CreateSubscriptionPlanScreen(),
      ),
      GoRoute(
        path: '/merchant/invoices',
        builder: (context, state) => const InvoicesScreen(),
      ),
      GoRoute(
        path: '/merchant/invoices/create',
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      GoRoute(
        path: '/merchant/qr',
        builder: (context, state) => const QrCodeScreen(),
      ),
      GoRoute(
        path: '/merchant/pay',
        builder: (context, state) {
          final merchantId = state.extra as String;
          return MerchantPaymentScreen(merchantId: merchantId);
        },
      ),
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => const QRScannerScreen(),
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
