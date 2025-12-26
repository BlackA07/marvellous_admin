import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod Import
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/core/common/widgets/metallic_button.dart';
import 'package:marvellous_admin/core/common/widgets/metallic_textfield.dart';
import 'package:marvellous_admin/core/common/widgets/trapezoid_button.dart';
import 'package:marvellous_admin/features/auth/presentation/signup_screen.dart';
import '../../../../core/theme/pallete.dart';
import '../controller/auth_controller.dart'; // Controller Import

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Text Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() {
    // Basic Validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Call Auth Controller via Riverpod
    ref
        .read(authControllerProvider)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Watch Loading State
    final isLoading = ref.watch(authLoadingProvider);

    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE0E0E0),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: isWeb ? 450 : size.width,
              height: isWeb ? null : size.height,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: BoxDecoration(
                borderRadius: isWeb
                    ? BorderRadius.circular(30)
                    : BorderRadius.zero,
                border: isWeb
                    ? Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                    : null,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white,
                    Color.fromARGB(255, 90, 87, 87),
                    Color(0xFF606060),
                    Color(0xFF1A1A1A),
                  ],
                  stops: [0.0, 0.4, 0.75, 1.0],
                ),
                boxShadow: isWeb
                    ? [
                        const BoxShadow(
                          color: Colors.black,
                          blurRadius: 40,
                          offset: Offset(0, 20),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- LOGO ---
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned.fill(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.grey, Colors.transparent],
                              stops: [0.0, 0.5],
                            ).createShader(bounds),
                            blendMode: BlendMode.srcATop,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- TITLE ---
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Color.fromARGB(255, 184, 178, 178),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        "Marvellous",
                        style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.9),
                              offset: const Offset(4, 5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- FIELDS ---
                  MetallicTextField(
                    hintText: "Email / Username",
                    icon: Icons.person,
                    controller: _emailController, // Controller attached
                  ),
                  MetallicTextField(
                    hintText: "Password",
                    icon: Icons.lock,
                    isPassword: true,
                    height: 65,
                    width: 700,
                    controller: _passwordController, // Controller attached
                  ),

                  const SizedBox(height: 25),

                  // --- LOGIN BUTTON ---
                  if (isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    TrapezoidButton(
                      hasGlowingAura: true,
                      height: 90,
                      width: 300,
                      onTap: login, // Call login function
                    ),

                  const SizedBox(height: 20),

                  // --- TEXT LINKS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _textBtn("Remember Me"),
                      _textBtn("Forgot Password?"),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Divider(color: Colors.black.withOpacity(0.3), thickness: 1),
                  const SizedBox(height: 20),

                  // --- CREATE ACCOUNT BUTTON ---
                  MetallicButton(
                    text: "CREATE ACCOUNT",
                    hasGlowingAura: false,
                    height: 60,
                    customGradientColors: const [
                      Color.fromRGBO(174, 174, 174, 1),
                      Color.fromARGB(255, 104, 100, 100),
                    ],
                    textColor: Colors.white70,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textBtn(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: Colors.grey.shade300,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        shadows: [
          const Shadow(
            color: Colors.black,
            blurRadius: 3,
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
    );
  }
}
