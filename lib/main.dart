import 'package:flutter/foundation.dart'; // kReleaseMode ke liye
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:device_preview/device_preview.dart'; // 1. Import Commented Out
import 'package:marvellous_admin/features/layout/presentation/screens/main_layout_screen.dart';

import 'features/auth/presentation/signup_screen.dart';
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

  runApp(
    // 2. ProviderScope abhi bhi chahiye state management ke liye
    const ProviderScope(
      // DevicePreview ko comment out kar diya aur direct App laga di
      child: MarvellousAdminApp(),

      /* child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const MarvellousAdminApp(),
      ),
      */
    ),
  );
}

class MarvellousAdminApp extends StatelessWidget {
  const MarvellousAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marvellous Admin',
      debugShowCheckedModeBanner: false,

      // 3. Device Preview params commented out
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      theme: AppTheme.darkTheme,
      home: MainLayoutScreen(),
    );
  }
}
