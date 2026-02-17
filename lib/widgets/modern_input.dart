import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/theme/typography.dart';

/// Enhanced text field with floating label animation and modern styling
class ModernTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;

  const ModernTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _labelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Check initial text state
    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      _hasText = true;
      _animationController.forward();
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange(String value) {
    final hadText = _hasText;
    _hasText = value.isNotEmpty;

    if (_hasText != hadText && !_isFocused) {
      if (_hasText) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }

    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
    final effectiveBorderColor = hasError
        ? (widget.errorBorderColor ?? AppColors.accentDanger)
        : _isFocused
            ? (widget.focusedBorderColor ?? AppColors.primary)
            : (widget.borderColor ?? AppColors.borderLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppSpacing.borderRadiusMD,
            border: Border.all(
              color: effectiveBorderColor,
              width: _isFocused ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: effectiveBorderColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            autofocus: widget.autofocus,
            onChanged: _handleTextChange,
            onSubmitted: widget.onSubmitted,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: widget.labelText == null ? widget.hintText : null,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              labelText: widget.labelText,
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: _isFocused ? AppColors.primary : AppColors.textMuted,
              ),
              floatingLabelStyle: AppTypography.labelMedium.copyWith(
                color: hasError ? AppColors.accentDanger : AppColors.primary,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: AppSpacing.iconMD,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 0 : AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          AppSpacing.vGapXS,
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: AppSpacing.iconXS,
                  color: AppColors.accentDanger,
                ),
                AppSpacing.hGapXXS,
                Text(
                  _errorText!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentDanger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Password field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool showStrengthIndicator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const PasswordTextField({
    super.key,
    this.controller,
    this.hintText = 'Password',
    this.labelText = 'Password',
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.showStrengthIndicator = false,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  double _strength = 0;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _calculateStrength(String value) {
    double strength = 0;
    if (value.length >= 8) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    
    setState(() {
      _strength = strength;
    });

    widget.onChanged?.call(value);
  }

  Color _getStrengthColor() {
    if (_strength < 0.25) return AppColors.accentDanger;
    if (_strength < 0.5) return AppColors.accentWarning;
    if (_strength < 0.75) return AppColors.secondary;
    return AppColors.accentSuccess;
  }

  String _getStrengthText() {
    if (_strength < 0.25) return 'Weak';
    if (_strength < 0.5) return 'Fair';
    if (_strength < 0.75) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ModernTextField(
          controller: widget.controller,
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: Iconsax.lock,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          validator: widget.validator,
          onChanged: widget.showStrengthIndicator ? _calculateStrength : widget.onChanged,
          onSubmitted: widget.onSubmitted,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          suffixIcon: IconButton(
            onPressed: _toggleVisibility,
            icon: Icon(
              _obscureText ? Iconsax.eye_slash : Iconsax.eye,
              color: AppColors.textMuted,
              size: AppSpacing.iconMD,
            ),
          ),
        ),
        if (widget.showStrengthIndicator && (widget.controller?.text.isNotEmpty ?? false)) ...[
          AppSpacing.vGapSM,
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusXS,
                  child: LinearProgressIndicator(
                    value: _strength,
                    backgroundColor: AppColors.bgHover,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                    minHeight: 4,
                  ),
                ),
              ),
              AppSpacing.hGapSM,
              Text(
                _getStrengthText(),
                style: AppTypography.caption.copyWith(
                  color: _getStrengthColor(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Search text field with search icon and clear button
class SearchTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Iconsax.search_normal,
            color: AppColors.textMuted,
            size: AppSpacing.iconMD,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: _clearText,
                  icon: const Icon(
                    Iconsax.close_circle,
                    color: AppColors.textMuted,
                    size: AppSpacing.iconMD,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}
