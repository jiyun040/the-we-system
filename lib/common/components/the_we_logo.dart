import 'package:flutter/material.dart';

class TheWeLogo extends StatelessWidget {
  const TheWeLogo({super.key, this.height = 42});

  static const assetPath = 'assets/images/theWeLogo.png';
  static const aspectRatio = 1090 / 644;

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * aspectRatio,
      height: height,
      child: Image.asset(
        assetPath,
        width: height * aspectRatio,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        semanticLabel: '더우리기술 로고',
        errorBuilder: (context, error, stackTrace) =>
            const SizedBox.expand(),
      ),
    );
  }
}
