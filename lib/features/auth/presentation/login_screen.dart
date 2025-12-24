import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/pallete.dart';
import '../../../../core/widgets/metallic_button.dart';
import '../../../../core/widgets/metallic_textfield.dart';
import '../../../../core/widgets/trapezoid_button.dart'; // <--- Import Zaroori he

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
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/background.jpeg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.darken,
              ),
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: isWeb ? 450 : size.width * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0E0E0),
                      Color(0xFFB0B0B0),
                      Color(0xFF606060),
                      Color(0xFF202020),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 40,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
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
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Color.fromARGB(255, 146, 140, 140),
                            // Color(0xFF404040),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          "MARVELLOUS",
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

                    // --- LOGIN BUTTON (Special Trapezoid) ---
                    TrapezoidButton(
                      hasGlowingAura: true,
                      height: 60, // Sleek height
                      width: 230, // Thori width kam rakhi style ke liye
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

                    // --- CREATE ACCOUNT BUTTON (Normal Metallic but Dark) ---
                    MetallicButton(
                      text: "CREATE ACCOUNT",
                      hasGlowingAura: false,
                      height: 60,
                      // Custom Colors: Dark Grey Gradient
                      customGradientColors: const [
                        Color.fromRGBO(174, 174, 174, 1),
                        Color.fromARGB(255, 104, 100, 100),
                        // Color(0xFF101010),
                      ],
                      textColor: Colors.white70, // Thora dim white text
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
