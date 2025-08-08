import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/services/preferences_service.dart';
import 'data/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization failed, but app can still run without it
    print('Firebase initialization failed: $e');
  }

  // Initialize SharedPreferences
  await PreferencesService.init();

  // Initialize Hive
  await Hive.initFlutter();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: FinIMoiApp()));

  // Initialiser le router global pour les deep links
  setGlobalRouter(AppRouter.router);
}

class FinIMoiApp extends ConsumerWidget {
  const FinIMoiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialiser le service de deep links
    final deepLinkService = ref.read(deepLinkServiceProvider);
    deepLinkService.initialize();

    return MaterialApp.router(
      title: 'FinIMoi',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Will be managed by provider later
      // Localization
      locale: const Locale('fr', 'FR'),

      // Router
      routerConfig: AppRouter.router,

      // Builder for global error handling
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent text scaling
          ),
          child: child!,
        );
      },
    );
  }
}
