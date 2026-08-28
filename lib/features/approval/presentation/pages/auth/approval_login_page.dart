import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class ApprovalLoginPage extends ConsumerStatefulWidget {
  const ApprovalLoginPage({super.key});

  @override
  ConsumerState<ApprovalLoginPage> createState() => _ApprovalLoginPageState();
}

class _ApprovalLoginPageState extends ConsumerState<ApprovalLoginPage> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: TheWeColor.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('로그인', style: TheWeTextStyle.pageTitle),
                  const SizedBox(height: 24),
                  Text('아이디', style: TheWeTextStyle.body),
                  const SizedBox(height: 8),
                  CustomTextFormField(controller: idController),
                  const SizedBox(height: 16),
                  Text('비밀번호', style: TheWeTextStyle.body),
                  const SizedBox(height: 8),
                  CustomTextFormField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => showPassword = !showPassword);
                        },
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state?.loginError ?? '',
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.pink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        final notifier = ref.read(
                          approvalDashboardControllerProvider.notifier,
                        );
                        final id = idController.text.trim();
                        final password = passwordController.text.trim();
                        final success = await notifier.login(id, password);
                        if (!success || !context.mounted) return;
                        context.goNamed(AppRouteName.home);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: TheWeColor.black900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '로그인',
                        style: TheWeTextStyle.subtitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.pushNamed(AppRouteName.signup),
                      child: Text(
                        '회원가입',
                        style: TheWeTextStyle.body.copyWith(
                          color: TheWeColor.blue300,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
