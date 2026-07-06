import 'package:flutter/material.dart';

abstract final class TheWeSpacing {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 20.0;
  static const page = 24.0;
  static const section = 28.0;
}

abstract final class TheWeRadius {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const card = 20.0;
  static const dialog = 24.0;
  static const pill = 999.0;
}

abstract final class TheWeInsets {
  static const card = EdgeInsets.all(TheWeSpacing.xl);
  static const panel = EdgeInsets.all(TheWeSpacing.xxl);
  static const page = EdgeInsets.all(TheWeSpacing.page);
  static const horizontalPage = EdgeInsets.symmetric(
    horizontal: TheWeSpacing.page,
  );
}

abstract final class TheWeGaps {
  static const verticalXs = SizedBox(height: TheWeSpacing.xs);
  static const verticalSm = SizedBox(height: TheWeSpacing.sm);
  static const verticalMd = SizedBox(height: TheWeSpacing.md);
  static const verticalLg = SizedBox(height: TheWeSpacing.lg);
  static const verticalXl = SizedBox(height: TheWeSpacing.xl);
  static const verticalXxl = SizedBox(height: TheWeSpacing.xxl);
  static const verticalSection = SizedBox(height: TheWeSpacing.section);
  static const horizontalSm = SizedBox(width: TheWeSpacing.sm);
  static const horizontalMd = SizedBox(width: TheWeSpacing.md);
  static const horizontalLg = SizedBox(width: TheWeSpacing.lg);
  static const horizontalXl = SizedBox(width: TheWeSpacing.xl);
}
