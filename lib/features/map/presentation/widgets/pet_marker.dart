import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/enums/pet_species.dart';
import '../../../pets/presentation/labels/pet_labels.dart';

/// Marcador de um animal no mapa: um alfinete cuja **ponta** fica exatamente no
/// local do animal (use `Marker(alignment: Alignment.topCenter)`).
///
/// Cão e gato se distinguem pela **forma** (não só pela cor) e o marcador é
/// descrito para leitores de tela. Entra com uma animação curta e, quando
/// [selected], cresce e ganha um halo.
class PetMarker extends StatelessWidget {
  const PetMarker({
    required this.pet,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  /// Área de toque mínima recomendada (48 dp).
  static const double touchSize = 48;

  /// Tamanho do widget inteiro (cabeça + ponta); use no `Marker`.
  static const double width = 52;
  static const double height = 66;

  static const double _badge = 44;
  static const double _tailHeight = 16;

  final Pet pet;
  final VoidCallback onTap;
  final bool selected;

  String get _asset => switch (pet.species) {
        PetSpecies.dog => 'assets/markers/dog.svg',
        PetSpecies.cat => 'assets/markers/cat.svg',
      };

  /// Mesma cor do SVG da espécie, para a ponta emendar com a cabeça.
  Color get _tint => switch (pet.species) {
        PetSpecies.dog => AppColors.caramelo,
        PetSpecies.cat => AppColors.marrom,
      };

  String get _description {
    final name = pet.name?.trim();
    final base = (name != null && name.isNotEmpty)
        ? '${pet.species.label} $name'
        : pet.displayName;
    final reference = pet.location.reference?.trim();
    return (reference != null && reference.isNotEmpty)
        ? '$base, $reference'
        : base;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _description,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Transform.scale(
            scale: t.clamp(0.0, 1.2),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
          child: AnimatedScale(
            scale: selected ? 1.2 : 1,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Sombra no chão, sob a ponta.
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 6,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(20, 6)),
                        color: AppColors.sombra,
                      ),
                    ),
                  ),
                  // Ponta do alfinete.
                  Positioned(
                    top: _badge - 6,
                    child: CustomPaint(
                      size: const Size(16, _tailHeight + 6),
                      painter: _TailPainter(_tint),
                    ),
                  ),
                  // Halo de seleção.
                  Positioned(
                    top: -6,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: _badge + 12,
                        height: _badge + 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.areia.withValues(alpha: 0.55),
                          border: Border.all(color: AppColors.areia, width: 2),
                        ),
                      ),
                    ),
                  ),
                  // Cabeça (distintivo da espécie).
                  Container(
                    width: _badge,
                    height: _badge,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sombra,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child:
                        SvgPicture.asset(_asset, width: _badge, height: _badge),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Triângulo arredondado que liga a cabeça do alfinete ao ponto no mapa.
class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..quadraticBezierTo(
          size.width * 0.62, size.height * 0.55, size.width / 2, size.height)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.55, 0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
