import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';

class ApprovalSignupPage extends ConsumerStatefulWidget {
  const ApprovalSignupPage({super.key});

  @override
  ConsumerState<ApprovalSignupPage> createState() => _ApprovalSignupPageState();
}

class _ApprovalSignupPageState extends ConsumerState<ApprovalSignupPage> {
  static const List<String> _departments = [
    '개발팀',
    '교육팀',
    '영업팀',
    '회계팀',
    '세무팀',
    '인사팀',
    '경영관리팀',
  ];

  static const List<String> _employeePositions = [
    '사원',
    '주임',
    '대리',
    '과장',
    '차장',
    '부장',
  ];

  final nameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  String errorMessage = '';
  String selectedDepartment = _departments.first;
  String selectedPosition = _employeePositions.first;

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('회원가입', style: TheWeTextStyle.pageTitle),
                      ),
                      TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                            return;
                          }
                          context.goNamed(AppRouteName.home);
                        },
                        child: Text(
                          '로그인으로 돌아가기',
                          style: TheWeTextStyle.body.copyWith(
                            color: TheWeColor.blue300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _FieldLabel('이름'),
                  CustomTextFormField(controller: nameController),
                  const SizedBox(height: 14),
                  _FieldLabel('아이디'),
                  CustomTextFormField(controller: idController),
                  const SizedBox(height: 14),
                  _FieldLabel('이메일'),
                  CustomTextFormField(controller: emailController),
                  const SizedBox(height: 14),
                  _FieldLabel('부서'),
                  _SelectionDropdown(
                    value: selectedDepartment,
                    items: _departments,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => selectedDepartment = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('직책'),
                  _SelectionDropdown(
                    value: selectedPosition,
                    items: _employeePositions,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => selectedPosition = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('비밀번호'),
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
                  const SizedBox(height: 14),
                  _FieldLabel('비밀번호 확인'),
                  CustomTextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => showConfirmPassword = !showConfirmPassword,
                          );
                        },
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.pink,
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: TheWeColor.black900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '회원가입 완료',
                        style: TheWeTextStyle.subtitle.copyWith(
                          color: Colors.white,
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

  Future<void> _submit() async {
    final name = nameController.text.trim();
    final id = idController.text.trim();
    final email = emailController.text.trim();
    final department = selectedDepartment;
    final position = selectedPosition;
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if ([
      name,
      id,
      email,
      department,
      position,
      password,
      confirmPassword,
    ].any((value) => value.isEmpty)) {
      setState(() => errorMessage = '모든 항목을 입력해 주세요.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => errorMessage = '비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    final error = await ref
        .read(approvalDashboardControllerProvider.notifier)
        .registerAccount(
          id: id,
          password: password,
          name: name,
          department: department,
          position: position,
          email: email,
          isAdmin: false,
        );

    if (error != null) {
      setState(() => errorMessage = error);
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')));
    context.goNamed(AppRouteName.home);
  }
}

class _SelectionDropdown extends StatelessWidget {
  const _SelectionDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        filled: true,
        fillColor: TheWeColor.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: TheWeColor.black900),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: TheWeColor.blue300),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: TheWeTextStyle.hintText,
      dropdownColor: TheWeColor.white,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TheWeTextStyle.body),
    );
  }
}
