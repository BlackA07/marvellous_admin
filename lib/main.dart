import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:marvellous_admin/features/auth/presentation/signup_screen.dart';
//import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try-Catch to prevent crash if Firebase isn't ready
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   debugPrint("Firebase Error (Ignored for UI Testing): $e");
  // }

  runApp(const ProviderScope(child: MarvellousAdminApp()));
}

class MarvellousAdminApp extends StatelessWidget {
  const MarvellousAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marvellous Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Hamari Dark Metal Theme
      home: const SignUpScreen(),
    );
  }
}
