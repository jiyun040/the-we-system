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
  final idController = TextEditingController(text: 'edu_manager');
  final passwordController = TextEditingController(text: '1234');
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TheWeColor.blueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state?.adminOtpEnabled == false
                          ? '관리자 계정은 아이디·비밀번호 확인 후 관리자 화면으로 이동합니다.'
                          : '관리자 계정은 아이디·비밀번호 확인 후 OTP 인증을 진행합니다.',
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.black500,
                      ),
                    ),
                  ),
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
                        final isAdminLogin = notifier.hasValidAdminCredentials(
                          id,
                          password,
                        );
                        String? verifiedOtp;
                        if (isAdminLogin && (state?.adminOtpEnabled ?? true)) {
                          verifiedOtp = await _requestAdminLoginOtp(
                            context,
                            notifier,
                          );
                          if (verifiedOtp == null || !context.mounted) return;
                        }
                        final success = await notifier.login(id, password);
                        if (!success || !context.mounted) return;
                        if (isAdminLogin) {
                          notifier.enterAdminMode(verifiedOtp ?? '');
                        }
                        context.goNamed(
                          isAdminLogin ? AppRouteName.admin : AppRouteName.home,
                        );
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

Future<String?> _requestAdminLoginOtp(
  BuildContext context,
  ApprovalDashboardController notifier,
) {
  final controller = TextEditingController();
  var error = '';
  final mobile = MediaQuery.sizeOf(context).width < 600;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: mobile ? 22 : 40,
          vertical: 24,
        ),
        backgroundColor: TheWeColor.surfaceAlt,
        title: const Text('관리자 OTP 인증'),
        content: SizedBox(
          width: mobile ? double.maxFinite : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('관리자 OTP 앱에 표시된 6자리 번호를 입력하세요.'),
              const SizedBox(height: 6),
              Text(
                '프로토타입 인증번호: 123456',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.blue300,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP 인증번호',
                  errorText: error.isEmpty ? null : error,
                ),
                onSubmitted: (_) {
                  if (notifier.verifyAdminOtp(controller.text)) {
                    Navigator.pop(context, controller.text);
                  } else {
                    setDialogState(() => error = 'OTP 번호가 올바르지 않습니다.');
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (notifier.verifyAdminOtp(controller.text)) {
                Navigator.pop(context, controller.text);
              } else {
                setDialogState(() => error = 'OTP 번호가 올바르지 않습니다.');
              }
            },
            child: const Text('인증'),
          ),
        ],
      ),
    ),
  );
}
