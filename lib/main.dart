import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseUrl.contains('YOUR_SUPABASE_URL_HERE') ||
      supabaseAnonKey == null || supabaseAnonKey.isEmpty || supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY_HERE')) {
    // Missing keys, show a placeholder error screen
    runApp(MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Lütfen .env dosyasındaki SUPABASE_URL ve SUPABASE_ANON_KEY değerlerini doldurun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.redAccent),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Latin Nation Turkey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/lntadmin': (context) => const LoginScreen(),
      },
    );
  }
}
