import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/restaurant_list_screen.dart';
import 'screens/restaurant_owner_screen.dart';
import 'screens/pending_activation_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Quitar estas importaciones si no se usan:
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'models/app_user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicialización de WebView solo si es necesario en iOS/macOS:
  if (Platform.isIOS || Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }
  // En Android, el plugin por defecto ya lo gestiona, no hace falta AndroidWebView()

  runApp(const EasyMenuApp());
}

class EasyMenuApp extends StatelessWidget {
  const EasyMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyMenu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
        ),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) {
          final user = snap.data!;
          return StreamBuilder<DocumentSnapshot<AppUser>>(
            stream: AppUser.doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final data = userSnap.data?.data();
              if (data == null) {
                return const RestaurantListScreen();
              }

              if (data.role == AppUser.roleRestaurant) {
                if (!data.isActive) {
                  return PendingActivationScreen(email: data.email);
                }

                if (data.restaurantId == null || data.restaurantId!.isEmpty) {
                  return PendingActivationScreen(
                    email: data.email,
                    message:
                        'Tu cuenta de restaurante no tiene un restaurante asociado todavía. Contacta con el administrador.',
                  );
                }

                return RestaurantOwnerScreen(
                  restaurantId: data.restaurantId!,
                  ownerName: data.name ?? data.email,
                );
              }

              return const RestaurantListScreen();
            },
          );
        }
        return const AuthScreen();
      },
    );
  }
}