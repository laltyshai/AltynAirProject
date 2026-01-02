import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'staff_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // No more initialization shield. 
    // If not authenticated, go to Login immediately.
    // If background check (init) finds a token later, it will naturally switch to Home.
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Auto-redirect for Staff
    if (auth.isStaff) {
      return const StaffDashboardScreen(); 
    }

    return const HomeScreen();
  }
}
