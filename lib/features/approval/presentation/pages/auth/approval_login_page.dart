import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final passwordFocusNode = FocusNode();
  bool showPassword = false;
  bool isLoggingIn = false;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (isLoggingIn) return;

    final notifier = ref.read(approvalDashboardControllerProvider.notifier);
    final id = idController.text.trim();
    final password = passwordController.text.trim();
    if (id.isEmpty || password.isEmpty) {
      notifier.setLoginError('아이디와 비밀번호를 모두 입력해 주세요.');
      return;
    }

    setState(() => isLoggingIn = true);
    final success = await notifier.login(id, password);

    if (!mounted) return;
    setState(() => isLoggingIn = false);
    if (success) {
      TextInput.finishAutofillContext(shouldSave: true);
      context.goNamed(AppRouteName.home);
    }
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
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('로그인', style: TheWeTextStyle.pageTitle),
                    const SizedBox(height: 24),
                    Text('아이디', style: TheWeTextStyle.body),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: idController,
                      autofillHints: const [AutofillHints.username],
                      keyboardType: TextInputType.text,
                      style: TheWeTextStyle.body.copyWith(fontSize: 16),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (_) => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .clearLoginError(),
                      onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    Text('비밀번호', style: TheWeTextStyle.body),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      autofillHints: const [AutofillHints.password],
                      keyboardType: TextInputType.visiblePassword,
                      style: TheWeTextStyle.body.copyWith(fontSize: 16),
                      obscureText: !showPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                      onChanged: (_) => ref
                          .read(approvalDashboardControllerProvider.notifier)
                          .clearLoginError(),
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 10),
                    if (state?.loginError.isNotEmpty ?? false)
                      Container(
                        key: const Key('login-error-message'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: TheWeColor.dangerSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: TheWeColor.danger.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: TheWeColor.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state!.loginError,
                                style: TheWeTextStyle.body.copyWith(
                                  color: TheWeColor.danger,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: isLoggingIn ? null : _login,
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
      ),
    );
  }
}
