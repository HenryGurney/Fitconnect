import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';
import 'services/subscription_service.dart';
import 'services/notification_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tezarjmgnvsgfkfjwqmu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlemFyam1nbnZzZ2ZrZmp3cW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNDIyNDMsImV4cCI6MjA5MzkxODI0M30.Zy5UrueA2kxw2450LtqqMHCicGzL91rbr0KnVXke7sk',
  );

  final currentUser = Supabase.instance.client.auth.currentUser;
  await SubscriptionService().init(userId: currentUser?.id);
  NotificationService().init(messengerKey: rootScaffoldMessengerKey);

  runApp(const FitConnectApp());
}

class FitConnectApp extends StatelessWidget {
  const FitConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitConnect',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39FF14),
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}