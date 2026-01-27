import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sc/presentation/screens/home_page.dart';
import 'package:sc/presentation/screens/login_page.dart';
import 'package:sc/presentation/screens/register_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'application/auth_provider.dart';
import 'application/receipt_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'service/firebase_auth_service.dart';
import 'application/staff_provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    print("✅ DotEnv loaded successfully");
  } catch (e) {
    print("❌ Error loading .env file: $e");
  }
  await Firebase.initializeApp();
  await FirebaseAuth.instance.authStateChanges().first;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final authRepository = AuthRepository(authService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider<ReceiptProvider>(
          create: (_) => ReceiptProvider(),
        ),
        ChangeNotifierProvider<StaffProvider>(
          create: (_) => StaffProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Receipt Scanner',
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Auth Error: ${snapshot.error}'),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const HomePage();
            }
            return const LoginPage();
          },
        ),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.black,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            secondary: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}