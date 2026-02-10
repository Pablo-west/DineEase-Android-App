import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../root/root_page.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SignInPage();
        }
        // Sync profile into AppState for cross-app use.
        final state = AppScope.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final displayName = user.displayName ?? '';
          final email = user.email ?? '';
          String phone = state.phone;

          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            if (doc.exists) {
              final data = doc.data() ?? {};
              final nameFromDb = (data['name'] ?? '').toString();
              final phoneFromDb = (data['phone'] ?? '').toString();
              final emailFromDb = (data['email'] ?? '').toString();
              final roleFromDb = (data['role'] ?? '').toString();
              final resolvedName =
                  nameFromDb.isNotEmpty ? nameFromDb : displayName;
              final resolvedEmail = emailFromDb.isNotEmpty ? emailFromDb : email;
              final resolvedPhone =
                  phoneFromDb.isNotEmpty ? phoneFromDb : phone;
              if (state.displayName != resolvedName ||
                  state.email != resolvedEmail ||
                  state.phone != resolvedPhone) {
                state.setProfile(
                  displayName: resolvedName,
                  email: resolvedEmail,
                  phone: resolvedPhone,
                );
              }
              state.setRole(roleFromDb);
              return;
            }
          } catch (_) {}

          if (state.displayName != displayName || state.email != email) {
            state.setProfile(
              displayName: displayName,
              email: email,
              phone: phone,
            );
          }
          state.setRole('');
        });
        return const RootPage();
      },
    );
  }
}
