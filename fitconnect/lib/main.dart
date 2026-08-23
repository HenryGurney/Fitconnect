import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart'; // 1. IMPORT YOUR SPLASH SCREEN
import 'services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tezarjmgnvsgfkfjwqmu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlemFyam1nbnZzZ2ZrZmp3cW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNDIyNDMsImV4cCI6MjA5MzkxODI0M30.Zy5UrueA2kxw2450LtqqMHCicGzL91rbr0KnVXke7sk',
  );

  final currentUser = Supabase.instance.client.auth.currentUser;
  await SubscriptionService().init(userId: currentUser?.id);

  runApp(const FitConnectApp());
}

class FitConnectApp extends StatelessWidget {
  const FitConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39FF14),
          brightness: Brightness.dark,
        ),
      ),
      // 2. CHANGE THIS FROM LoginScreen TO SplashScreen
      home: const SplashScreen(), 
    );
  }
}