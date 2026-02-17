import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/models/login_request.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  
  bool _obscurePassword = true;
  bool _isEmailValid = true;
  bool _isLoading = false;
  double _passwordStrength = 0;

  // Animation controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = _isValidEmail(value);
    });
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email);
  }

  void _calculatePasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    
    setState(() {
      _passwordStrength = strength;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.25) return AppColors.accentDanger;
    if (_passwordStrength < 0.5) return AppColors.accentWarning;
    if (_passwordStrength < 0.75) return AppColors.secondary;
    return AppColors.accentSuccess;
  }

  String _getStrengthText() {
    if (_passwordStrength < 0.25) return 'Weak';
    if (_passwordStrength < 0.5) return 'Fair';
    if (_passwordStrength < 0.75) return 'Good';
    return 'Strong';
  }

  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.textWhite, size: 20),
            AppSpacing.hGapSM,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.accentDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMD),
        margin: AppSpacing.screenPadding,
      ),
    );
  }

  void _handleLogin() {
    HapticFeedback.lightImpact();
    
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError('Please enter email');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _triggerShakeAnimation();
      _showError('Please enter a valid email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Please enter password');
      return;
    }

    if (_phoneNumberController.text.isEmpty) {
      _showError('Please enter phone number');
      return;
    }

    _validateUser(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
  }

  void _validateUser(String name, String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.login(
        LoginRequest(name: name, email: email, password: password),
      );

      if (response.success) {
        final data = response.data;
        
        if (data == null) {
          if (mounted) _showError('Invalid response from server');
          return;
        }

        final userId = data['userId'] is int 
            ? data['userId'] as int 
            : int.parse(data['userId'].toString());
        final isExistingUser = data['isExistingUser'] is bool
            ? data['isExistingUser'] as bool
            : data['isExistingUser'].toString().toLowerCase() == 'true';
        final token = data['token'] as String?;
        
        if (token == null || token.isEmpty) {
          if (mounted) _showError('Invalid token received from server');
          return;
        }

        HapticFeedback.mediumImpact();
        
        if (!isExistingUser) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/onboarding',
              arguments: {'userId': userId, 'token': token, 'name': name, 'phoneNumber': _phoneNumberController.text},
            );
          }
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userid', userId);
          await prefs.setString('token', token);
          DioClient.setToken(token);
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home', arguments: userId);
          }
        }
      } else {
        if (mounted) _showError(response.message ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Error: ${e.message}';
        
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check your connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please try again later.';
        } else if (e.response != null) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }
        _showError(errorMessage);
      }
    } catch (e) {
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppSpacing.vGapXXL,
                  
                  // Logo with animation
                  _buildLogo()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: -0.2, end: 0, duration: 600.ms),
                  
                  AppSpacing.vGapXL,
                  
                  // Welcome text
                  _buildWelcomeText()
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms),
                  
                  AppSpacing.vGapXXXL,
                  
                  // Login form in glass card
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value * 
                            (_shakeController.status == AnimationStatus.forward ? 1 : -1), 0),
                        child: child,
                      );
                    },
                    child: _buildLoginForm()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.1, end: 0, duration: 600.ms),
                  ),
                  
                  AppSpacing.vGapXXL,
                  
                  // Footer
                  _buildFooter()
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return BreathingAnimation(
      scaleAmount: 0.03,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPrimary,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'GX',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome to',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.vGapXS,
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryLightGradient.createShader(bounds),
          child: Text(
            'GrievX',
            style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        AppSpacing.vGapSM,
        SizedBox(
          height: 24,
          child: DefaultTextStyle(
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            child: AnimatedTextKit(
              repeatForever: true,
              pause: const Duration(milliseconds: 2000),
              animatedTexts: [
                TypewriterAnimatedText('Your Safety Companion', speed: const Duration(milliseconds: 80)),
                TypewriterAnimatedText('Track journeys safely', speed: const Duration(milliseconds: 80)),
                TypewriterAnimatedText('One tap emergency alerts', speed: const Duration(milliseconds: 80)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return GlassCard(
      padding: AppSpacing.cardPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign In', style: AppTypography.titleLarge),
          AppSpacing.vGapXS,
          Text('Enter your credentials to continue', style: AppTypography.bodySmall),
          AppSpacing.vGapXL,
          
          // Name field
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            hintText: 'Full Name',
            icon: Iconsax.user,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          AppSpacing.vGapMD,
          
          // Email field
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            hintText: 'Email Address',
            icon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: _validateEmail,
            hasError: !_isEmailValid,
            errorText: !_isEmailValid ? 'Invalid email format' : null,
            onSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          AppSpacing.vGapMD,

          // Phone number field
          _buildTextField(
            controller: _phoneNumberController,
            focusNode: _phoneFocus,
            hintText: 'Phone Number',
            icon: Iconsax.call,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          AppSpacing.vGapMD,
          
          // Password field
          _buildPasswordField(),
          
          // Password strength indicator
          if (_passwordController.text.isNotEmpty) ...[
            AppSpacing.vGapSM,
            _buildPasswordStrengthIndicator()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.2, end: 0),
          ],
          
          AppSpacing.vGapXL,
          
          // Login button
          GradientButton.primary(
            text: 'Sign In',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
            icon: const Icon(Iconsax.login, color: AppColors.textWhite, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool hasError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppSpacing.borderRadiusMD,
            border: Border.all(
              color: hasError ? AppColors.accentDanger : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              prefixIcon: Icon(icon, color: hasError ? AppColors.accentDanger : AppColors.textMuted, size: AppSpacing.iconMD),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          AppSpacing.vGapXS,
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, size: AppSpacing.iconXS, color: AppColors.accentDanger),
                AppSpacing.hGapXXS,
                Text(errorText, style: AppTypography.caption.copyWith(color: AppColors.accentDanger)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onChanged: _calculatePasswordStrength,
        onSubmitted: (_) => _handleLogin(),
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(Iconsax.lock, color: AppColors.textMuted, size: AppSpacing.iconMD),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
              color: AppColors.textMuted,
              size: AppSpacing.iconMD,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppSpacing.borderRadiusXS,
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: AppColors.bgHover,
              valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
              minHeight: 4,
            ),
          ),
        ),
        AppSpacing.hGapSM,
        Text(
          _getStrengthText(),
          style: AppTypography.caption.copyWith(color: _getStrengthColor(), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 40, height: 1, color: AppColors.borderLight),
            AppSpacing.hGapMD,
            Text('Secured by GrievX', style: AppTypography.caption),
            AppSpacing.hGapMD,
            Container(width: 40, height: 1, color: AppColors.borderLight),
          ],
        ),
        AppSpacing.vGapMD,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.shield_tick, size: AppSpacing.iconSM, color: AppColors.accentSuccess),
            AppSpacing.hGapXS,
            Text('Your data is encrypted and secure', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}
