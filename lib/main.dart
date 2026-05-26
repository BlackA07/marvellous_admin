import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:marvellous_admin/firebase_options.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ FORCE SIGNOUT HATA DIYA: Isse user baar-baar logout ho raha tha
    // aur Controllers "null user" par crash ho rahe thay.

    // ✅ Migration Service ko background mein chalayen taake app start hone mein rukawat na ho
    //MigrationService().migratePackages();
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(const ProviderScope(child: MarvellousAdminApp()));
}

class MarvellousAdminApp extends StatelessWidget {
  const MarvellousAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Marvellous Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Initial route Login rakhain, auth check screen ke andar handle karen
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
    );
  }
}
