import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/features/auth/controller/signup_controller.dart';
import 'package:marvellous_admin/features/auth/presentation/login_screen.dart';

// Imports check karlena apne project k hisab se
import '../../../../core/theme/pallete.dart';
import '../../../../core/widgets/metallic_button.dart';
import '../../../../core/widgets/metallic_textfield.dart';
import '../../../../core/widgets/trapezoid_button.dart';
// Controller import

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controller ka instance banaya
  final SignUpController _controller = SignUpController();

  @override
  void dispose() {
    _controller.dispose(); // Memory leak na ho
    super.dispose();
  }

  // Error dikhane k liye helper function
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;

    // Background Gradient
    const bgGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white, // Top Highlight
        Color.fromARGB(255, 90, 87, 87),
        Color(0xFF606060),
        Color(0xFF1A1A1A), // Deep Dark Base
      ],
      stops: [0.0, 0.4, 0.75, 1.0],
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // --- FIX 1: Background Color match kiya taake scroll pe white na aaye ---
        backgroundColor: const Color(0xFF1A1A1A),

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Ensure container fills at least the screen height
                    minHeight: constraints.maxHeight,
                  ),
                  child: Container(
                    width: isWeb ? 450 : size.width,
                    margin: isWeb
                        ? EdgeInsets.symmetric(
                            horizontal: (size.width - 450) / 2,
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),

                    // Gradient yahan lagaya he taake poore scroll area pe ho
                    decoration: BoxDecoration(
                      borderRadius: isWeb
                          ? BorderRadius.circular(30)
                          : BorderRadius.zero,
                      gradient: bgGradient,
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // --- 1. LOGO SECTION ---
                        SizedBox(
                          height: 120,
                          width: 120,
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
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.grey,
                                          Colors.transparent,
                                        ],
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

                        Transform.translate(
                          offset: const Offset(0, -10),
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

                        const SizedBox(height: 30),

                        // --- 2. INPUT FIELDS (Using Controller) ---
                        MetallicTextField(
                          hintText: "Full Name",
                          icon: Icons.person_outline,
                          controller: _controller.nameController,
                        ),

                        MetallicTextField(
                          hintText: "Email Address",
                          icon: Icons.email_outlined,
                          controller: _controller.emailController,
                        ),

                        // --- FIX 2: Phone Section with Arrow & Colors ---
                        Row(
                          children: [
                            Container(
                              width: 105, // Thora size barhaya arrow k liye
                              height: 65,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Color(0xFF98A2B3)],
                                ),
                                border: Border.all(
                                  color: Colors.white54,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Country Code Picker
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CountryCodePicker(
                                      onChanged: (code) {
                                        setState(() {
                                          _controller.selectedCountryCode =
                                              code.dialCode ?? "+92";
                                        });
                                      },
                                      initialSelection: 'PK',
                                      favorite: const ['PK', 'US', 'IN'],
                                      showCountryOnly: false,
                                      showOnlyCountryWhenClosed: false,
                                      alignLeft:
                                          true, // Left align taake arrow right pe aaye
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                      ), // Padding adjust
                                      // Display Text Style (Button k upar)
                                      textStyle: GoogleFonts.comicNeue(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),

                                      // --- FIX: Dialog Text Colors (Dropdown k andar) ---
                                      dialogTextStyle: const TextStyle(
                                        color:
                                            Colors.black, // Ab text black hoga
                                        fontWeight: FontWeight.w500,
                                      ),
                                      searchStyle: const TextStyle(
                                        color:
                                            Colors.black, // Search text black
                                      ),
                                      dialogBackgroundColor:
                                          Colors.white, // Dialog bg white

                                      searchDecoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: Colors.grey,
                                        ),
                                        hintText: "Search",
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Down Arrow Icon (Manually added for look)
                                  const Positioned(
                                    right: 8,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.black54,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: MetallicTextField(
                                hintText: "Phone Number",
                                icon: Icons.phone_android,
                                controller: _controller.phoneController,
                              ),
                            ),
                          ],
                        ),

                        MetallicTextField(
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _controller.passController,
                        ),

                        MetallicTextField(
                          hintText: "Confirm Password",
                          icon: Icons.verified_user_outlined,
                          isPassword: true,
                          controller: _controller.confirmPassController,
                        ),

                        const SizedBox(height: 30),

                        // --- 3. MAIN SIGN UP BUTTON ---
                        TrapezoidButton(
                          imagePath: 'assets/images/signupbutton.png',
                          hasGlowingAura: true,
                          height: 90,
                          width: 300,
                          onTap: () {
                            // --- FIX 3: Validation Logic ---
                            String? error = _controller.validateInputs();
                            if (error != null) {
                              _showError(error); // Error dikhao
                            } else {
                              // Sab theek he - Proceed to Signup
                              print("Validation Successful!");
                              print("Code: ${_controller.selectedCountryCode}");
                              // Yahan API call ya next screen logic lagao
                            }
                          },
                        ),

                        const SizedBox(height: 30),

                        // --- 4. DIVIDER ---
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                "OR",
                                style: GoogleFonts.orbitron(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- 5. LOGIN NOW BUTTON (Navigation Fix) ---
                        MetallicButton(
                          text: "LOGIN NOW",
                          hasGlowingAura: false,
                          height: 60,
                          customGradientColors: const [
                            Color.fromRGBO(174, 174, 174, 1),
                            Color.fromARGB(255, 104, 100, 100),
                          ],
                          textColor: Colors.white70,
                          onTap: () {
                            // Login Screen pe wapis jao
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
