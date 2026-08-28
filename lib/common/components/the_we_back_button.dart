import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/core/router/app_router.dart';

class TheWeBackButton extends StatelessWidget {
  const TheWeBackButton({
    super.key,
    this.fallbackRouteName = AppRouteName.home,
  });

  final String fallbackRouteName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '뒤로가기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (context.canPop()) {
            context.pop();
            return;
          }

          context.goNamed(fallbackRouteName);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: TheWeColor.black900,
          ),
        ),
      ),
    );
  }
}
