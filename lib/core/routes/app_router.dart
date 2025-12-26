import 'package:get/get.dart';

// 1. Layout Screen
import '../../features/layout/presentation/screens/main_layout_screen.dart';

// 2. Auth Screens
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';

// 3. Dashboard Screens
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

// 4. Product Screens
import '../../features/products/presentation/screens/products_home_screen.dart';
import '../../features/products/presentation/screens/add_product_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';

class AppRoutes {
  // --- Route Strings ---
  static const String home = '/'; // Main Layout
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';

  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String productDetail = '/products/detail';

  // --- Route Pages Map ---
  static final List<GetPage> routes = [
    // 1. Main Layout (Home)
    GetPage(
      name: home,
      page: () => MainLayoutScreen(),
      transition: Transition.fadeIn,
    ),

    // 2. Auth Routes
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: signup,
      page: () => const SignUpScreen(),
      transition: Transition.rightToLeft,
    ),

    // 3. Dashboard (Standalone if needed)
    GetPage(
      name: dashboard,
      page: () => DashboardScreen(),
      transition: Transition.noTransition,
    ),

    // 4. Products Routes
    GetPage(
      name: products,
      page: () => ProductsHomeScreen(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: addProduct,
      page: () => const AddProductScreen(),
      transition: Transition.rightToLeft, // Slide animation
    ),
    GetPage(
      name: productDetail,
      // Get.arguments se data pass hoga
      page: () => ProductDetailScreen(product: Get.arguments),
      transition: Transition.rightToLeft,
    ),
  ];
}
