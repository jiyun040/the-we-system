import 'approval_admin_dependencies.dart';
import 'approval_admin_direct_leave.dart';

class AdminAnnualLeavePolicyEditor extends ConsumerStatefulWidget {
  const AdminAnnualLeavePolicyEditor({
    super.key,
    required this.policy,
    required this.monthlyLeavePerMonth,
  });

  final Map<int, int> policy;
  final int monthlyLeavePerMonth;

  @override
  ConsumerState<AdminAnnualLeavePolicyEditor> createState() =>
      _AnnualLeavePolicyEditorState();
}

class _AnnualLeavePolicyEditorState
    extends ConsumerState<AdminAnnualLeavePolicyEditor> {
  late final Map<int, TextEditingController> controllers;
  late final TextEditingController monthlyLeaveController;
  bool dirty = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    controllers = {
      for (final entry in widget.policy.entries)
        entry.key: TextEditingController(text: entry.value.toString()),
    };
    monthlyLeaveController = TextEditingController(
      text: widget.monthlyLeavePerMonth.toString(),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    monthlyLeaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(mobile ? 15 : 22),
      decoration: adminSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Text(
              '근속연수에 따라 지급할 연차 일수를 입력해 주세요.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: dirty ? _save : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('연차 설정 저장'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '근속연수에 따라 지급할 연차 일수를 입력한 뒤 저장해 주세요.',
                    style: TheWeTextStyle.body.copyWith(
                      color: TheWeColor.black500,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: dirty ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('연차 설정 저장'),
                ),
              ],
            ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('monthly-leave-per-month'),
            controller: monthlyLeaveController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {
              dirty = true;
              error = '';
            }),
            decoration: const InputDecoration(
              labelText: '1년 미만 월차 (매월 지급)',
              suffixText: '일',
              helperText: '입사 후 완료된 근속월마다 설정한 일수가 발생합니다.',
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const ValueKey('annual-leave-add-year'),
              onPressed: _addPolicyYear,
              icon: const Icon(Icons.add_rounded),
              label: const Text('연차 구간 추가'),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 600
                  ? (constraints.maxWidth - 8) / 2
                  : 150.0;
              final years = controllers.keys.toList()..sort();
              return Wrap(
                spacing: mobile ? 8 : 12,
                runSpacing: mobile ? 8 : 12,
                children: years
                    .map(
                      (year) => SizedBox(
                        width: itemWidth,
                        child: TextField(
                          key: ValueKey('annual-leave-$year'),
                          controller: controllers[year],
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {
                            dirty = true;
                            error = '';
                          }),
                          decoration: InputDecoration(
                            labelText: '$year년',
                            suffixText: '일',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TheWeTextStyle.caption.copyWith(color: TheWeColor.danger),
            ),
          ],
        ],
      ),
    );
  }

  void _save() {
    final monthlyDays = int.tryParse(monthlyLeaveController.text.trim());
    if (monthlyDays == null || monthlyDays < 1 || monthlyDays > 31) {
      setState(() => error = '1년 미만 직원의 월차 지급 일수를 확인해 주세요.');
      return;
    }
    final policy = <int, int>{};
    for (final entry in controllers.entries) {
      final days = int.tryParse(entry.value.text.trim());
      if (days == null || days < 1 || days > 365) {
        setState(() => error = '${entry.key}년 연차 일수를 확인해 주세요.');
        return;
      }
      policy[entry.key] = days;
    }
    final message = ref
        .read(approvalDashboardControllerProvider.notifier)
        .updateAnnualLeavePolicies(policy, monthlyLeavePerMonth: monthlyDays);
    if (message != null) {
      setState(() => error = message);
      return;
    }
    setState(() {
      dirty = false;
      error = '';
    });
    showTheWeSnackBar(context, message: '연차 설정이 저장되었습니다.');
  }

  void _addPolicyYear() {
    final years = controllers.keys.toList()..sort();
    var year = 1;
    if (years.isNotEmpty) {
      year = years.first;
      while (controllers.containsKey(year)) {
        year++;
      }
      if (year > 99) {
        setState(() => error = '99년까지 추가할 수 있습니다.');
        return;
      }
    }
    final previousYears = years.where((item) => item < year);
    final previousDays = previousYears.isEmpty
        ? 15
        : int.tryParse(controllers[previousYears.last]!.text.trim()) ?? 15;
    setState(() {
      controllers[year] = TextEditingController(text: '$previousDays');
      dirty = true;
      error = '';
    });
  }
}
