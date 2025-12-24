import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/pallete.dart';
import '../../../../core/widgets/metallic_button.dart';
import '../../../../core/widgets/metallic_textfield.dart';
import '../../../../core/widgets/trapezoid_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
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
              // Web: 450 width, Mobile: Full Width
              width: isWeb ? 450 : size.width,
              // Web: Auto height, Mobile: Full Height
              height: isWeb ? null : size.height,

              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),

              decoration: BoxDecoration(
                borderRadius: isWeb
                    ? BorderRadius.circular(30)
                    : BorderRadius.zero,
                border: isWeb
                    ? Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                    : null,

                // --- UPDATED GRADIENT ---
                gradient: const LinearGradient(
                  begin: Alignment.topRight, // Top Right se shuru (White)
                  end: Alignment.bottomLeft, // Bottom Left pe khatam (Dark)
                  colors: [
                    Colors.white, // Top Right: Full White
                    Color.fromARGB(
                      255,
                      90,
                      87,
                      87,
                    ), // Thora sa left aake: Light Grey
                    Color(0xFF606060), // Neeche aate hue: Dark Grey
                    Color(0xFF1A1A1A), // Bilkul neeche: Deep Dark
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
                  const MetallicTextField(
                    hintText: "Email / Username",
                    icon: Icons.person,
                  ),
                  const MetallicTextField(
                    hintText: "Password",
                    icon: Icons.lock,
                    isPassword: true,
                  ),

                  const SizedBox(height: 25),

                  // --- LOGIN BUTTON ---
                  TrapezoidButton(
                    hasGlowingAura: true,
                    height: 90,
                    width: 300,
                    onTap: () {
                      print("Login Pressed");
                      FocusScope.of(context).unfocus();
                    },
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
                      print("Create Account Pressed");
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
