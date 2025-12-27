// import 'package:flutter/foundation.dart'; // kReleaseMode ke liye
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
// import 'package:get/get.dart'; // Import GetX
// import 'package:marvellous_admin/firebase_options.dart';

// import 'package:device_preview/device_preview.dart'; // Uncommented
// import 'core/routes/app_router.dart'; // Import AppRouter
// import 'core/theme/app_theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Try-Catch to prevent crash if Firebase isn't ready
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//   } catch (e) {
//     debugPrint("Firebase Error (Ignored for UI Testing): $e");
//   }

//   // --- CHECK LOGIN STATUS ---
//   // Agar user pehle se logged in hai (null nahi hai), to Home par bhejo
//   User? currentUser = FirebaseAuth.instance.currentUser;
//   String startRoute = (currentUser != null) ? AppRoutes.home : AppRoutes.login;

//   runApp(
//     // 2. ProviderScope abhi bhi chahiye state management ke liye
//     ProviderScope(
//       // DevicePreview ko uncomment kar diya hai aur working bana diya hai
//       child: DevicePreview(
//         // Release mode (Play Store build) men ye disable rahega
//         enabled: !kReleaseMode,
//         builder: (context) => MarvellousAdminApp(initialRoute: startRoute),
//       ),
//     ),
//   );
// }

// class MarvellousAdminApp extends StatelessWidget {
//   final String initialRoute;

//   // Constructor updated to accept initialRoute
//   const MarvellousAdminApp({super.key, required this.initialRoute});

//   @override
//   Widget build(BuildContext context) {
//     // CHANGE: MaterialApp -> GetMaterialApp for Routing
//     return GetMaterialApp(
//       title: 'Marvellous Admin',
//       debugShowCheckedModeBanner: false,

//       // 3. Device Preview params uncommented
//       useInheritedMediaQuery:
//           true, // Ye zaroori hai taake UI size sahi detect ho
//       locale: DevicePreview.locale(context),
//       builder: DevicePreview.appBuilder,

//       theme: AppTheme.darkTheme,

//       // ROUTING SETUP
//       initialRoute: initialRoute, // Dynamic Route (Login or Home)
//       getPages: AppRoutes.routes, // Saare routes yahan se ayenge
//     );
//   }
// }

import 'package:flutter/foundation.dart'; // kReleaseMode ke liye
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:get/get.dart'; // Import GetX
import 'package:marvellous_admin/firebase_options.dart';

// import 'package:device_preview/device_preview.dart';
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

  // --- CHECK LOGIN STATUS ---
  // Agar user pehle se logged in hai (null nahi hai), to Home par bhejo
  User? currentUser = FirebaseAuth.instance.currentUser;
  String startRoute = (currentUser != null) ? AppRoutes.home : AppRoutes.login;
  runApp(
    // 2. ProviderScope abhi bhi chahiye state management ke liye
    ProviderScope(
      // DevicePreview ko comment out kar diya aur direct App laga di
      // startRoute pass kar rahe hain
      child: MarvellousAdminApp(initialRoute: startRoute),

      /* child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const MarvellousAdminApp(initialRoute: AppRoutes.login),
      ),
      */
    ),
  );
}

class MarvellousAdminApp extends StatelessWidget {
  final String initialRoute;

  // Constructor updated to accept initialRoute
  const MarvellousAdminApp({super.key, required this.initialRoute});

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
      initialRoute: initialRoute, // Dynamic Route (Login or Home)
      getPages: AppRoutes.routes, // Saare routes yahan se ayenge
    );
  }
}
