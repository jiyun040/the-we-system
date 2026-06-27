import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';

class TheWeTextStyle {
  static TextStyle title = defaultTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle pageTitle = defaultTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle subtitle = defaultTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static TextStyle makeApproval = defaultTextStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle section = defaultTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle hintText = defaultTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );

  static TextStyle body = defaultTextStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static TextStyle caption = defaultTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static TextStyle metric = defaultTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );
}

final TextStyle defaultTextStyle = TextStyle(
  color: TheWeColor.black900,
  fontFamily: 'SUIT-Variable',
);
