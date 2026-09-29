import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session_provider.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.state.isLoading || session.state.isIdle) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
