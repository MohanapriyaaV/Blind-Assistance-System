import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class MigrateUsersScreen extends StatelessWidget {
  const MigrateUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Create your profile to continue'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final appUser = AppUser(
                    uid: user.uid,
                    email: user.email ?? '',
                    name: user.displayName ?? 'Blind User',
                    role: 'blind',
                  );
                  
                  await FirestoreService().saveUser(appUser);
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Text('Create as Blind User'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final appUser = AppUser(
                    uid: user.uid,
                    email: user.email ?? '',
                    name: user.displayName ?? 'Caretaker',
                    role: 'caretaker',
                    blindUserIds: [],
                  );
                  
                  await FirestoreService().saveUser(appUser);
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Text('Create as Caretaker'),
            ),
          ],
        ),
      ),
    );
  }
}