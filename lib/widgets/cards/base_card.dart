import 'package:flutter/material.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final BoxShape? shape;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final Color? splashColor;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.shape,
    this.border,
    this.onTap,
    this.splashColor,
  });

  factory BaseCard.regular({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return BaseCard(
      key: key,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      backgroundColor: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      splashColor: Colors.grey.withValues(alpha: 0.1),
      child: child,
    );
  }

  factory BaseCard.highlight({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    Color? color,
  }) {
    return BaseCard(
      key: key,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      backgroundColor: color?.withValues(alpha: 0.1) ?? Colors.blue.withValues(alpha: 0.1),
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color ?? Colors.blue),
      onTap: onTap,
      splashColor: color?.withValues(alpha: 0.1) ?? Colors.blue.withValues(alpha: 0.1),
      child: child,
    );
  }

  factory BaseCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double elevation = 4,
  }) {
    return BaseCard(
      key: key,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      backgroundColor: Colors.white,
      elevation: elevation,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      splashColor: Colors.grey.withValues(alpha: 0.1),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        shape: shape ?? BoxShape.rectangle,
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (elevation ?? 2) * 0.05),
            blurRadius: elevation ?? 2,
            offset: Offset(0, elevation == null ? 2 : elevation! / 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          splashColor: splashColor ?? Colors.grey.withValues(alpha: 0.1),
          highlightColor: splashColor?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.05),
          child: card,
        ),
      );
    }

    return card;
  }
}
