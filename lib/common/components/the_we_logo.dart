import 'dart:typed_data';

import 'package:flutter/material.dart';

class TheWeLogo extends StatelessWidget {
  const TheWeLogo({super.key, this.height = 42, this.bytes});

  static const assetPath = 'assets/images/theWeLogo.png';
  static const aspectRatio = 1090 / 644;

  final double height;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * aspectRatio,
      height: height,
      child: Image(
        image: bytes == null
            ? const AssetImage(assetPath)
            : MemoryImage(bytes!) as ImageProvider,
        width: height * aspectRatio,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        semanticLabel: '더우리기술 로고',
        errorBuilder: (context, error, stackTrace) => Image.asset(
          assetPath,
          fit: BoxFit.contain,
          semanticLabel: '더우리기술 로고',
        ),
      ),
    );
  }
}
