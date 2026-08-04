import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/constants.dart';

/// Primary action button with gradient, loading state, and optional icon.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient? gradient;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? AppColors.primaryGradient;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onPressed == null ? 0.5 : 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: (grad.colors.first).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textOnPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: AppColors.textOnPrimary, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textOnPrimary,
                              letterSpacing: 0.3,
                            ),
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
}
