import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo compartido por las pantallas de acceso y registro.
///
/// Por ahora utiliza una composición visual oscura. Cuando agreguemos
/// la fotografía exportada desde Figma, solo habrá que reemplazar
/// esta composición por un Image.asset.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.darkBackground),

        // Elementos visuales provisionales inspirados
        // en el fondo deportivo del prototipo.
        const _TemporarySportsBackground(),

        // Capa oscura que mejora la lectura del formulario.
        ColoredBox(color: Colors.black.withValues(alpha: 0.24)),

        // Degradado inferior semejante al diseño de Figma.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.48),
                AppColors.darkBackground.withValues(alpha: 0.97),
              ],
              stops: const [0, 0.56, 1],
            ),
          ),
        ),

        child,
      ],
    );
  }
}

/// Fondo temporal utilizado hasta agregar la fotografía de Figma.
class _TemporarySportsBackground extends StatelessWidget {
  const _TemporarySportsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -120,
          child: _BackgroundCircle(size: 360, color: const Color(0xFF74251F)),
        ),
        Positioned(
          top: 120,
          right: -150,
          child: _BackgroundCircle(size: 390, color: const Color(0xFF292B2E)),
        ),
        Positioned(
          top: 480,
          right: -80,
          child: _BackgroundCircle(
            size: 270,
            color: AppColors.lime.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          bottom: -180,
          left: -130,
          child: _BackgroundCircle(size: 400, color: const Color(0xFF003A28)),
        ),
      ],
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 85, spreadRadius: 22)],
      ),
    );
  }
}
