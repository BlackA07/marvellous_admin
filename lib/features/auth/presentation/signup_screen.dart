import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/core/common/widgets/metallic_button.dart';
import 'package:marvellous_admin/core/common/widgets/metallic_textfield.dart';
import 'package:marvellous_admin/core/common/widgets/trapezoid_button.dart';
import 'package:marvellous_admin/features/auth/presentation/login_screen.dart';
import '../controller/auth_controller.dart';
import '../controller/signup_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  String _selectedCountryCode = "+92";

  // SignUp Controller instance
  late final SignUpController _signupController;

  @override
  void initState() {
    super.initState();
    _signupController = SignUpController();
    // Set referral code optional or required
    _signupController.referralCodeOptional =
        true; // Change to false if required
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _referralCodeController.dispose();
    _signupController.dispose();
    super.dispose();
  }

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

  void _signUp() {
    // 1. Basic Validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passController.text.isEmpty) {
      _showError("All fields are required!");
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      _showError("Passwords do not match!");
      return;
    }

    // Validate name length
    if (_nameController.text.trim().length < 3) {
      _showError("Name must be at least 3 characters long");
      return;
    }

    // Validate password length
    if (_passController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    // Check if referral code is required but not provided
    if (!_signupController.referralCodeOptional &&
        _referralCodeController.text.trim().isEmpty) {
      _showError("Referral code is required!");
      return;
    }

    // 2. Call Firebase Auth Controller with all required parameters
    ref
        .read(authControllerProvider)
        .signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          phone: "$_selectedCountryCode${_phoneController.text.trim()}",
          referralCode: _referralCodeController.text.trim(),
          signupController: _signupController,
          context: context,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;

    const bgGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white,
        Color.fromARGB(255, 90, 87, 87),
        Color(0xFF606060),
        Color(0xFF1A1A1A),
      ],
      stops: [0.0, 0.4, 0.75, 1.0],
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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

                        // --- LOGO ---
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

                        // --- TITLE ---
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

                        // --- INPUT FIELDS ---
                        MetallicTextField(
                          hintText: "Full Name",
                          icon: Icons.person_outline,
                          controller: _nameController,
                        ),

                        MetallicTextField(
                          hintText: "Email Address",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),

                        // Phone Row
                        Row(
                          children: [
                            Container(
                              width: 105,
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CountryCodePicker(
                                      onChanged: (code) {
                                        setState(() {
                                          _selectedCountryCode =
                                              code.dialCode ?? "+92";
                                        });
                                      },
                                      initialSelection: 'PK',
                                      favorite: const ['PK', 'US', 'IN'],
                                      showCountryOnly: false,
                                      showOnlyCountryWhenClosed: false,
                                      alignLeft: true,
                                      padding: const EdgeInsets.only(left: 1),
                                      textStyle: GoogleFonts.comicNeue(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      dialogTextStyle: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      searchStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      dialogBackgroundColor: Colors.white,
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
                                controller: _phoneController,
                              ),
                            ),
                          ],
                        ),

                        MetallicTextField(
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passController,
                        ),

                        MetallicTextField(
                          hintText: "Confirm Password",
                          icon: Icons.verified_user_outlined,
                          isPassword: true,
                          controller: _confirmPassController,
                        ),

                        // --- REFERRAL CODE FIELD ---
                        MetallicTextField(
                          hintText: _signupController.referralCodeOptional
                              ? "Referral Code (Optional)"
                              : "Referral Code *",
                          icon: Icons.people_outline,
                          controller: _referralCodeController,
                        ),

                        const SizedBox(height: 30),

                        // --- SIGN UP BUTTON ---
                        if (isLoading)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          TrapezoidButton(
                            imagePath: 'assets/images/signupbutton.png',
                            hasGlowingAura: true,
                            height: 90,
                            width: 300,
                            onTap: _signUp,
                          ),

                        const SizedBox(height: 30),

                        // --- DIVIDER ---
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

                        // --- LOGIN NOW BUTTON ---
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
