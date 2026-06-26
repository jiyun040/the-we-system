import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';

class TheWeTextStyle {
  static TextStyle title = defaultTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle makeApproval = defaultTextStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle hintText = defaultTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );
}

final TextStyle defaultTextStyle = TextStyle(
  color: TheWeColor.black900,
  fontFamily: 'SUIT-Variable'
);