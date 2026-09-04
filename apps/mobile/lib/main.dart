import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/firebase/firebase_options.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'views/main_nav_screen.dart';
import 'views/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Check if user has seen the welcome screen before & restore working backend URL
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
  final savedWorkingUrl = prefs.getString('kurogane_working_api_url');
  if (savedWorkingUrl != null && savedWorkingUrl.isNotEmpty) {
    ApiClient.setWorkingBaseUrl(savedWorkingUrl);
  }

  // Set immersive system overlay style matching Kurogane dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1419),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      child: KuroganeApp(hasSeenWelcome: hasSeenWelcome),
    ),
  );
}

class KuroganeApp extends ConsumerWidget {
  final bool hasSeenWelcome;

  const KuroganeApp({
    super.key,
    required this.hasSeenWelcome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kurogane',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: hasSeenWelcome ? const MainNavScreen() : const WelcomeScreen(),
    );
  }
}
