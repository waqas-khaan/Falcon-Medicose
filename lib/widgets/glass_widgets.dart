import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Responsive helper breakpoint utilities
class ResponsiveBreakpoints {
  static const double mobileMax = 768;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1280;
}

/// A premium Glassmorphism Card with soft background blur,
/// subtle border highlight, and refined shadow depth.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.blur = 12,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Colors.white.withValues(alpha: 0.88);
    final effectiveBorder = widget.border ??
        Border.all(
          color: _isHovered
              ? AppColors.primaryLight.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.8),
          width: 1.2,
        );

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveColor,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: effectiveBorder,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F243A)
                .withValues(alpha: _isHovered ? 0.08 : 0.04),
            blurRadius: _isHovered ? 24 : 16,
            offset: Offset(0, _isHovered ? 8 : 4),
          ),
          if (_isHovered)
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: widget.child,
    );

    // Apply blur on mobile and web
    content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: content,
      ),
    );

    if (widget.margin != null) {
      content = Padding(padding: widget.margin!, child: content);
    }

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A Glassmorphism Button with primary gradient, secondary glass, or outline styles
enum ModernButtonVariant { primary, secondary, outline, danger, success }

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ModernButtonVariant variant;
  final bool isLoading;
  final double? width;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const ModernButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ModernButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Gradient? gradient;
    Border? border;

    switch (variant) {
      case ModernButtonVariant.primary:
        bg = AppColors.primaryLight;
        fg = Colors.white;
        gradient = AppColors.primaryActionGradient;
        break;
      case ModernButtonVariant.secondary:
        bg = Colors.white.withValues(alpha: 0.85);
        fg = AppColors.textPrimary;
        border = Border.all(color: AppColors.border, width: 1);
        break;
      case ModernButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primaryLight;
        border = Border.all(color: AppColors.primaryLight, width: 1.4);
        break;
      case ModernButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        gradient = const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case ModernButtonVariant.success:
        bg = AppColors.success;
        fg = Colors.white;
        gradient = AppColors.emeraldGradient;
        break;
    }

    final effectiveWidth = isFullWidth ? double.infinity : width;

    return SizedBox(
      width: effectiveWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: bg,
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              border: border,
              boxShadow: variant == ModernButtonVariant.primary ||
                      variant == ModernButtonVariant.danger ||
                      variant == ModernButtonVariant.success
                  ? [
                      BoxShadow(
                        color: (variant == ModernButtonVariant.danger
                                ? AppColors.danger
                                : variant == ModernButtonVariant.success
                                    ? AppColors.success
                                    : AppColors.primaryLight)
                            .withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize:
                  effectiveWidth != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: fg,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern Glass Status Badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sleek Glassmorphism Input Field
class ModernTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const ModernTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primaryLight, size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.8), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
    );
  }
}

/// Modern Search Bar with glass backdrop
class ModernSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const ModernSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F243A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primaryLight, size: 21),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    controller.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Glass Dialog for modern alerts and forms
class ModernDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;
  final double maxWidth;

  const ModernDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    this.iconColor,
    this.maxWidth = 520,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? icon,
    Color? iconColor,
    double maxWidth = 520,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => ModernDialog(
        title: title,
        content: content,
        actions: actions,
        icon: icon,
        iconColor: iconColor,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(24),
          color: Colors.white.withValues(alpha: 0.94),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.primaryLight)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon,
                          color: iconColor ?? AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: content)),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
