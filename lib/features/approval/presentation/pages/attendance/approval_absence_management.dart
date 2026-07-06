part of 'approval_absence_page.dart';

class _WorkGroupManagementSection extends StatefulWidget {
  const _WorkGroupManagementSection();

  @override
  State<_WorkGroupManagementSection> createState() =>
      _WorkGroupManagementSectionState();
}

class _WorkGroupManagementSectionState
    extends State<_WorkGroupManagementSection> {
  final List<_ManagementGroupCardData> _cards = const [
    _ManagementGroupCardData(
      badge: '기본',
      title: '기본그룹',
      rows: [
        '근로시간  09:00 ~ 18:00 (8h)',
        '근무요일  월, 화, 수, 목, 금',
        '주휴일  일',
        '근무지  웹 서비스',
        '적용멤버  9명',
      ],
    ),
    _ManagementGroupCardData(
      badge: '고정근로',
      title: '시차출퇴근 그룹',
      rows: [
        '근로시간  08:00 ~ 17:00 (8h)',
        '근무요일  월, 화, 수, 목, 금',
        '주휴일  일',
        '근무지  사내 근무',
        '적용멤버  2명',
      ],
    ),
  ].toList();

  Future<void> _addGroup() async {
    final nameController = TextEditingController(
      text: '신규 근무그룹 ${_cards.length + 1}',
    );
    final timeController = TextEditingController(text: '10:00 ~ 19:00 (8h)');

    final result = await showDialog<_ManagementGroupCardData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('근무그룹 추가'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '근무그룹명'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: '근로시간'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final title = nameController.text.trim().isEmpty
                  ? '신규 근무그룹 ${_cards.length + 1}'
                  : nameController.text.trim();
              final time = timeController.text.trim().isEmpty
                  ? '10:00 ~ 19:00 (8h)'
                  : timeController.text.trim();
              Navigator.of(context).pop(
                _ManagementGroupCardData(
                  badge: '신규',
                  title: title,
                  rows: [
                    '근로시간  $time',
                    '근무요일  월, 화, 수, 목, 금',
                    '주휴일  일',
                    '근무지  웹 서비스',
                    '적용멤버  0명',
                  ],
                ),
              );
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    nameController.dispose();
    timeController.dispose();

    if (result == null) {
      return;
    }

    setState(() => _cards.add(result));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: '근무그룹 관리',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final singleColumn = constraints.maxWidth < 980;
              final widgets = [
                ..._cards.map((card) => _ManagementGroupCard(data: card)),
                _AddManagementCard(title: '근무그룹 추가하기', onTap: _addGroup),
              ];

              if (singleColumn) {
                return Column(
                  children:
                      widgets
                          .expand(
                            (widget) => [widget, const SizedBox(height: 12)],
                          )
                          .toList()
                        ..removeLast(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < widgets.length; index++) ...[
                    Expanded(child: widgets[index]),
                    if (index != widgets.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompensatoryLeaveSection extends StatefulWidget {
  const _CompensatoryLeaveSection();

  @override
  State<_CompensatoryLeaveSection> createState() =>
      _CompensatoryLeaveSectionState();
}

class _CompensatoryLeaveSectionState extends State<_CompensatoryLeaveSection> {
  bool _showGrantTarget = true;

  @override
  Widget build(BuildContext context) {
    final headers = _showGrantTarget
        ? const [
            _TableHeader('사번', flex: 2),
            _TableHeader('사원명', flex: 2),
            _TableHeader('부서명', flex: 2),
            _TableHeader('근무그룹', flex: 2),
            _TableHeader('총 초과근로', flex: 2),
            _TableHeader('부여가능시간', flex: 2),
            _TableHeader('부여시간', flex: 2),
            _TableHeader('수당지급', flex: 2),
          ]
        : const [
            _TableHeader('부여일', flex: 2),
            _TableHeader('사원명', flex: 2),
            _TableHeader('부서명', flex: 2),
            _TableHeader('부여시간', flex: 2),
            _TableHeader('사용기한', flex: 2),
            _TableHeader('상태', flex: 2),
            _TableHeader('처리자', flex: 2),
          ];
    final rows = _showGrantTarget
        ? const [
            ['A-204', '김현정', '교육', '기본그룹', '12h', '8h', '4h', '대기'],
            ['A-318', '이재오', '영업', '시차출퇴근', '7h', '5h', '2h', '완료'],
          ]
        : const [
            ['2026-06-20', '김현정', '교육', '4h', '2026-12-31', '부여완료', '관리자'],
            ['2026-06-18', '이재오', '영업', '2h', '2026-12-31', '수당지급', '관리자'],
          ];

    return _SectionCard(
      title: '보상휴가 관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeatureActionRow(actions: ['보상휴가 부여', '수당지급 취소', '사용기한 변경']),
          const SizedBox(height: 16),
          Row(
            children: [
              _TabPill(
                label: '부여 대상',
                selected: _showGrantTarget,
                onTap: () => setState(() => _showGrantTarget = true),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: '부여 내역',
                selected: !_showGrantTarget,
                onTap: () => setState(() => _showGrantTarget = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '부서, 사번, 이름을 검색하세요.',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('엑셀 다운로드'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GenericTable(headers: headers, rows: rows),
        ],
      ),
    );
  }
}

class _FeatureActionRow extends StatelessWidget {
  const _FeatureActionRow({required this.actions, this.onAction});

  final List<String> actions;
  final ValueChanged<String>? onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: actions
          .map(
            (action) => FilledButton.icon(
              onPressed: () => onAction?.call(action),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: TheWeColor.blue300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
              label: Text(action),
            ),
          )
          .toList(),
    );
  }
}

class _HolidayReplacementSection extends StatefulWidget {
  const _HolidayReplacementSection();

  @override
  State<_HolidayReplacementSection> createState() =>
      _HolidayReplacementSectionState();
}

class _HolidayReplacementSectionState
    extends State<_HolidayReplacementSection> {
  final List<List<String>> _rows = [
    [
      '승인대기',
      '김효민',
      'M-002',
      '회계',
      '기본그룹',
      '2026-06-06',
      '2026-06-08',
      '전사 행사 대응',
    ],
    ['완료', '한지운', 'D-014', '개발', '선택근무', '2026-06-13', '2026-06-15', '시스템 점검'],
  ];

  Future<void> _registerReplacement() async {
    final nameController = TextEditingController(text: '신규직원');
    final holidayController = TextEditingController(text: '2026-06-29');
    final replacementController = TextEditingController(text: '2026-06-30');
    final reasonController = TextEditingController(text: '휴일 근무 대체');

    final row = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴일대체 등록'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '사원명'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holidayController,
                decoration: const InputDecoration(labelText: '선택 휴일'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replacementController,
                decoration: const InputDecoration(labelText: '대체일'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: '신청사유'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop([
              '승인대기',
              nameController.text.trim().isEmpty
                  ? '신규직원'
                  : nameController.text.trim(),
              'NEW',
              '공유',
              '기본그룹',
              holidayController.text.trim().isEmpty
                  ? '2026-06-29'
                  : holidayController.text.trim(),
              replacementController.text.trim().isEmpty
                  ? '2026-06-30'
                  : replacementController.text.trim(),
              reasonController.text.trim().isEmpty
                  ? '휴일 근무 대체'
                  : reasonController.text.trim(),
            ]),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    nameController.dispose();
    holidayController.dispose();
    replacementController.dispose();
    reasonController.dispose();

    if (row == null) {
      return;
    }

    setState(() => _rows.insert(0, row));
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '휴일대체 관리',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureActionRow(
            actions: const ['휴일대체 등록', '휴일대체일 변경', '임직원 신청현황'],
            onAction: (action) {
              if (action == '휴일대체 등록') {
                _registerReplacement();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '부서, 사번, 이름을 검색하세요.',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _registerReplacement,
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: TheWeColor.blue300,
                ),
                label: const Text('휴일대체 등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GenericTable(
            headers: const [
              _TableHeader('상태', flex: 2),
              _TableHeader('사원명', flex: 2),
              _TableHeader('사번', flex: 2),
              _TableHeader('부서', flex: 2),
              _TableHeader('근무그룹명', flex: 2),
              _TableHeader('선택 휴일', flex: 2),
              _TableHeader('대체일', flex: 2),
              _TableHeader('신청사유', flex: 3),
            ],
            rows: _rows,
          ),
        ],
      ),
    );
  }
}
