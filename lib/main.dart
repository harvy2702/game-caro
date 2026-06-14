import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'caro_game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://wffssmjnczlmvisqrnpp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmZnNzbWpuY3psbXZpc3FybnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MjUyNzksImV4cCI6MjA5NjMwMTI3OX0.hTq1-YEWMQ2P2xvQWk7WxDs3owsx_6SkX7RRtH_HXkI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Premium',
      debugShowCheckedModeBanner: false, // Ẩn banner Debug ở góc màn hình
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF00E5FF),
          secondary: const Color(0xFFFF4081),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        } else {
          return const CaroGameScreen();
        }
      },
    );
  }
}

