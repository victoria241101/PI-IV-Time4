import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';
import 'package:pet_care/modelos/dados_banner.dart';

/// Lista horizontal de banners formados somente por imagens.
class CarrosselBanners extends StatelessWidget {
  const CarrosselBanners({super.key, required this.banners});

  final List<DadosBanner> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.pagePadding,
        ),
        child: Center(
          child: Text(
            'Nenhuma novidade no momento.',
            style: TipografiaApp.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.pagePadding,
        ),
        itemCount: banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: EspacamentosApp.md),
        itemBuilder: (context, index) {
          final banner = banners[index];
          return _BannerItem(banner: banner);
        },
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.banner});

  final DadosBanner banner;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = screenWidth - EspacamentosApp.pagePadding * 2;
    final ehImagemDaRede =
        banner.imagem.startsWith('http://') ||
        banner.imagem.startsWith('https://');

    return GestureDetector(
      onTap: banner.aoTocar,
      child: Container(
        width: itemWidth.clamp(260, 420).toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
          boxShadow: EspacamentosApp.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: ehImagemDaRede
            ? Image.network(
                banner.imagem,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImagemIndisponivel(),
              )
            : Image.asset(
                banner.imagem,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImagemIndisponivel(),
              ),
      ),
    );
  }
}

class _ImagemIndisponivel extends StatelessWidget {
  const _ImagemIndisponivel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CoresApp.surface,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: CoresApp.iconDefault,
        ),
      ),
    );
  }
}
