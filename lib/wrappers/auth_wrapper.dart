import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/splash/opening_screen.dart';
import '../screens/caretaker/caretaker_dashboard.dart';
import '../screens/blind/blind_dashboard.dart';
import '../screens/admin/migrate_users.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const OpeningScreen();
        }

        final uid = snapshot.data!.uid;

        return FutureBuilder(
          future: FirestoreService().getUser(uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnap.hasError) {
              print('Firestore error: ${userSnap.error}');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Error loading user data'),
                      ElevatedButton(
                        onPressed: () => AuthService().logout(),
                        child: const Text('Logout and try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!userSnap.hasData || userSnap.data == null) {
              return const MigrateUsersScreen();
            }

            final user = userSnap.data!;
            if (user.role == 'caretaker') {
              return const CaretakerDashboard();
            } else {
              return const BlindDashboard();
            }
          },
        );
      },
    );
  }
}
