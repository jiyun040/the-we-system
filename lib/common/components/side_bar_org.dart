import 'side_bar_dependencies.dart';

class SideBarOrgButton extends ConsumerWidget {
  const SideBarOrgButton({super.key, required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: isCompact
          ? IconButton(
              onPressed: () => _showOrganizationDialog(context),
              icon: const Icon(Icons.account_tree_outlined),
              tooltip: '조직도',
            )
          : OutlinedButton.icon(
              onPressed: () => _showOrganizationDialog(context),
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('조직도'),
            ),
    );
  }

  void _showOrganizationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _OrganizationDialog(),
    );
  }
}

class _OrganizationDialog extends ConsumerWidget {
  const _OrganizationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalDashboardControllerProvider).asData?.value;
    final departments = state?.departments ?? const [];
    final members = state?.selectedDepartmentMembers ?? const [];
    final selectedMember = state?.selectedOrgMember;

    return Dialog(
      backgroundColor: TheWeColor.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TheWeRadius.xl),
      ),
      child: SizedBox(
        width: 880,
        height: 620,
        child: Padding(
          padding: TheWeInsets.page,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('조직도', style: TheWeTextStyle.title),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    TheWeGaps.verticalXl,
                    Expanded(
                      child: departments.isEmpty
                          ? Center(
                              child: Text(
                                '등록된 부서가 없습니다.',
                                style: TheWeTextStyle.body.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: departments.length,
                              separatorBuilder: (context, index) =>
                                  TheWeGaps.verticalSm,
                              itemBuilder: (context, index) {
                                final department = departments[index];
                                final selected =
                                    department == state?.selectedOrgDepartment;
                                return InkWell(
                                  onTap: () => ref
                                      .read(
                                        approvalDashboardControllerProvider
                                            .notifier,
                                      )
                                      .setDepartment(department),
                                  borderRadius: BorderRadius.circular(
                                    TheWeRadius.lg,
                                  ),
                                  child: Container(
                                    padding: TheWeInsets.card,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? TheWeColor.blue100.withValues(
                                              alpha: 0.4,
                                            )
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(
                                        TheWeRadius.lg,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.apartment_outlined,
                                          size: 18,
                                        ),
                                        TheWeGaps.horizontalMd,
                                        Expanded(
                                          child: Text(
                                            department,
                                            style: TheWeTextStyle.body.copyWith(
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              TheWeGaps.horizontalXl,
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('구성원', style: TheWeTextStyle.subtitle),
                    TheWeGaps.verticalLg,
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(
                                  TheWeRadius.xl,
                                ),
                              ),
                              child: ListView.builder(
                                padding: TheWeInsets.card,
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final selected =
                                      member.id == selectedMember?.id;
                                  return ListTile(
                                    onTap: () => ref
                                        .read(
                                          approvalDashboardControllerProvider
                                              .notifier,
                                        )
                                        .setOrgMember(member.id),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        TheWeRadius.md,
                                      ),
                                    ),
                                    selected: selected,
                                    selectedTileColor: TheWeColor.blue100
                                        .withValues(alpha: 0.45),
                                    title: Text(
                                      member.name,
                                      style: TheWeTextStyle.body,
                                    ),
                                    subtitle: Text(
                                      '${member.position}  |  ${member.id}',
                                      style: TheWeTextStyle.caption,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          TheWeGaps.horizontalXl,
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: TheWeInsets.panel,
                              decoration: BoxDecoration(
                                color: TheWeColor.white,
                                borderRadius: BorderRadius.circular(
                                  TheWeRadius.xl,
                                ),
                                border: Border.all(
                                  color: TheWeColor.black300.withValues(
                                    alpha: 0.22,
                                  ),
                                ),
                              ),
                              child: selectedMember == null
                                  ? Center(
                                      child: Text(
                                        '구성원을 선택해 주세요.',
                                        style: TheWeTextStyle.body,
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: TheWeColor.blue100,
                                          child: Text(
                                            selectedMember
                                                .name
                                                .characters
                                                .first,
                                            style: TheWeTextStyle.title,
                                          ),
                                        ),
                                        TheWeGaps.verticalXxl,
                                        Text(
                                          '${selectedMember.name} ${selectedMember.position}',
                                          style: TheWeTextStyle.title,
                                        ),
                                        TheWeGaps.verticalLg,
                                        _ProfileLine(
                                          label: '부서',
                                          value: selectedMember.department,
                                        ),
                                        _ProfileLine(
                                          label: '아이디',
                                          value: selectedMember.id,
                                        ),
                                        _ProfileLine(
                                          label: '이메일',
                                          value: selectedMember.email,
                                        ),
                                        _ProfileLine(
                                          label: '권한',
                                          value: selectedMember.isAdmin
                                              ? '관리자'
                                              : '일반 직원',
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TheWeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          const SizedBox(height: 4),
          Text(value, style: TheWeTextStyle.body),
        ],
      ),
    );
  }
}
