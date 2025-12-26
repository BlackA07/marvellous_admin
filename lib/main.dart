import 'package:flutter/foundation.dart'; // kReleaseMode ke liye
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:marvellous_admin/firebase_options.dart';

// import 'package:device_preview/device_preview.dart';
import 'features/layout/presentation/screens/main_layout_screen.dart';
import 'core/routes/app_router.dart'; // Import AppRouter
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try-Catch to prevent crash if Firebase isn't ready
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Error (Ignored for UI Testing): $e");
  }

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
    // CHANGE: MaterialApp -> GetMaterialApp for Routing
    return GetMaterialApp(
      title: 'Marvellous Admin',
      debugShowCheckedModeBanner: false,

      // 3. Device Preview params commented out
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      theme: AppTheme.darkTheme,

      // ROUTING SETUP
      initialRoute: AppRoutes.home, // Pehli screen
      getPages: AppRoutes.routes, // Saare routes yahan se ayenge
      // home: MainLayoutScreen(), // Iski zaroorat nahi kyunki initialRoute set hai
    );
  }
}
