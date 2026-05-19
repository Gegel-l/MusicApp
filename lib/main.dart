import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth;
import 'providers/products_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/compare_provider.dart';
import 'utils/local_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalNotificationsService.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF8C00),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFFFF8C00),
              secondary: const Color(0xFFFFA500),
              primaryContainer: const Color(0xFFFFE0B2),
              secondaryContainer: const Color(0xFFFFF3E0),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8F8F8),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              iconTheme: IconThemeData(color: Colors.white),
              actionsIconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF8C00),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFFFFA500),
              secondary: const Color(0xFFFF8C00),
              primaryContainer: const Color(0xFF3A2A1A),
              secondaryContainer: const Color(0xFF2A1A0A),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF1A1A1A),
            cardTheme: CardThemeData(
              color: const Color(0xFF2A2A2A),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              iconTheme: IconThemeData(color: Colors.white),
              actionsIconTheme: IconThemeData(color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1A1A1A),
            ),
          ),
          home: const AnimatedSplashScreen(
            child: _AuthGate(),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _loadedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (user == null) {
          if (_loadedUid != null) {
            _loadedUid = null;
            final cart = context.read<CartProvider>();
            final favs = context.read<FavoritesProvider>();
          final notifications = context.read<NotificationsProvider>();
          final compare = context.read<CompareProvider>();
            Future.microtask(() {
              cart.clearForLogout();
              favs.clearForLogout();
            notifications.clearForLogout();
            compare.clearForLogout();
            });
          }
          return const OnboardingScreen();
        }

        if (_loadedUid != user.uid) {
          _loadedUid = user.uid;
          final cart = context.read<CartProvider>();
          final favs = context.read<FavoritesProvider>();
          final theme = context.read<ThemeProvider>();
          final notifications = context.read<NotificationsProvider>();
          final compare = context.read<CompareProvider>();
          Future.microtask(() {
            cart.loadForUser(user.uid);
            favs.loadForUser(user.uid);
            theme.loadForUser(user.uid);
            notifications.loadForUser(user.uid);
            compare.load();
          });
        }

        return const HomeScreen();
      },
    );
  }
}
