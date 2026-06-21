import 'package:flutter/material.dart';

class RemoteButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onPressed;
  final double size;

  const RemoteButton({
    super.key,
    this.icon,
    this.label,
    this.onPressed,
    this.size = 52,
  }) : assert(icon != null || label != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: cs.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: icon != null
                ? Icon(icon, color: cs.onSurface, size: size * 0.45)
                : Text(
                    label!,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
