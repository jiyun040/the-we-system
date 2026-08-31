import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/models/signup_employee_profile.dart';

class ApprovalSignupPage extends ConsumerStatefulWidget {
  const ApprovalSignupPage({super.key});

  @override
  ConsumerState<ApprovalSignupPage> createState() => _ApprovalSignupPageState();
}

class _ApprovalSignupPageState extends ConsumerState<ApprovalSignupPage> {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final positionController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? selectedDepartment;
  bool showPassword = false;
  bool showConfirmPassword = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    positionController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    _syncPosition();
    if (errorMessage.isNotEmpty) setState(() => errorMessage = '');
  }

  void _selectDepartment(String? department) {
    setState(() {
      selectedDepartment = department;
      errorMessage = '';
    });
    _syncPosition();
  }

  void _syncPosition() {
    final department = selectedDepartment;
    final position = department == null
        ? ''
        : signupPositionFor(department: department, name: nameController.text);
    if (positionController.text != position) {
      positionController.text = position;
    }
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
                  CustomTextFormField(
                    key: const Key('signup-name-field'),
                    controller: nameController,
                    style: TheWeTextStyle.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('아이디'),
                  CustomTextFormField(
                    key: const Key('signup-id-field'),
                    controller: idController,
                    style: TheWeTextStyle.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('부서'),
                  TheWeDropdown<String>(
                    key: const Key('signup-department-dropdown'),
                    value: selectedDepartment,
                    items: signupDepartments,
                    labelBuilder: (department) => department,
                    hintText: '부서를 선택해 주세요.',
                    onChanged: _selectDepartment,
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('직책'),
                  CustomTextFormField(
                    key: const Key('signup-position-field'),
                    controller: positionController,
                    readOnly: true,
                    style: TheWeTextStyle.body.copyWith(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '이름과 부서에 따라 자동으로 입력됩니다.',
                      suffixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('비밀번호'),
                  CustomTextFormField(
                    key: const Key('signup-password-field'),
                    controller: passwordController,
                    style: TheWeTextStyle.body.copyWith(fontSize: 16),
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
                    key: const Key('signup-confirm-password-field'),
                    controller: confirmPasswordController,
                    style: TheWeTextStyle.body.copyWith(fontSize: 16),
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
    final department = selectedDepartment ?? '';
    final position = department.isEmpty
        ? ''
        : signupPositionFor(department: department, name: name);
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (positionController.text != position) {
      positionController.text = position;
    }

    if ([
      name,
      id,
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

    final employeeError = validateSignupEmployee(
      name: name,
      department: department,
      position: position,
    );
    if (employeeError != null) {
      setState(() => errorMessage = employeeError);
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
        );

    if (error != null) {
      setState(() => errorMessage = error);
      return;
    }

    if (!mounted) {
      return;
    }

    showTheWeSnackBar(context, message: '회원가입이 완료되었습니다. 로그인해 주세요.');
    context.goNamed(AppRouteName.home);
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
