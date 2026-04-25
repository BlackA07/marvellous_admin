import 'package:flutter/foundation.dart'; // kReleaseMode ke liye
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:get/get.dart'; // Import GetX
import 'package:marvellous_admin/firebase_options.dart';

import 'core/routes/app_router.dart'; // Import AppRouter
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try-Catch to prevent crash if Firebase isn't ready
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // --- FORCE LOGOUT ON EVERY START ---
    // Yeh line ensure karegi ke jab bhi app dubara khule,
    // to Firebase ka pichla session automatically khatam ho jaye.
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint("Firebase Error: $e");
  }

  runApp(
    // ProviderScope abhi bhi chahiye state management ke liye
    ProviderScope(child: MarvellousAdminApp()),
  );
}

class MarvellousAdminApp extends StatelessWidget {
  const MarvellousAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp -> GetMaterialApp for Routing
    return GetMaterialApp(
      title: 'Marvellous Admin',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.darkTheme,

      // ROUTING SETUP
      // Hamesha login screen se start hoga
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
    );
  }
}
