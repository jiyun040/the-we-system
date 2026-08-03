part of 'approval_dialogs.dart';

class _ApprovalLineSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: _TreePanel(
            searchHint: '이름/아이디/부서/직위/직책/...',
            nodes: [
              '다우오피스',
              '  김윤덕 사장',
              '  웍스 매니저',
              '사업본부',
              '  김경영 상무',
              '  이재오 차장',
              '  관리자 과장',
              '교육관리팀',
              '  교육관리자 부장',
              '  교육강사 부장',
            ],
            selectedIndex: 5,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _SelectedPeopleTable(
                rows: const [
                  ('신청', '기안', '교육강사', '교육관리팀', '기안'),
                  ('승인', '결재', '이재오', '교육관리팀', '대결 승인 대기'),
                  ('승인', '결재', '김경영', '경영관리팀', '결재 예정'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => showSaveApprovalLineDialog(context),
                    child: const Text('개인 결재선으로 저장'),
                  ),
                  const SizedBox(width: 18),
                  Text('합의방식 :', style: TheWeTextStyle.body),
                  const SizedBox(width: 8),
                  const _AgreementOption(label: '순차합의', selected: true),
                  const SizedBox(width: 12),
                  const _AgreementOption(label: '병렬합의'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgreementOption extends StatelessWidget {
  const _AgreementOption({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? TheWeColor.blue300 : TheWeColor.black300,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(label, style: TheWeTextStyle.body),
      ],
    );
  }
}

class _PeopleSetup extends StatelessWidget {
  const _PeopleSetup({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: _TreePanel(
            searchHint: '이름/아이디/부서/직위/직책/...',
            nodes: ['교육관리팀', '  교육관리자 부장', '  교육강사 부장', '기획팀', '  김사원'],
            selectedIndex: 2,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: _SelectedPeopleTable(
            caption: caption,
            rows: const [
              ('추가', '사용자', '교육관리자', '교육관리팀', '저장 전'),
              ('추가', '부서', '기획팀', '기획팀', '저장 전'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicReceiverSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: _TreePanel(
            searchHint: '이름, 이메일',
            nodes: [
              '공용 주소록',
              '  교육강사 (teacher@study.com)',
              '  김다우 (vipark@daou.co.kr)',
            ],
            selectedIndex: 2,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _SelectedPeopleTable(
                rows: const [('신규 발송', '공문', '김다우', '다우기술', '발신 명의 선택 필요')],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('발신 명의 : ', style: TheWeTextStyle.body),
                  TheWeDropdown<String>(
                    value: '(주)대한민국',
                    width: 160,
                    items: const ['(주)대한민국', '경영지원부문장', '다우기술'],
                    labelBuilder: (value) => value,
                    onChanged: (_) {},
                  ),
                  const SizedBox(width: 12),
                  Text('직인 : ', style: TheWeTextStyle.body),
                  TheWeDropdown<String>(
                    value: '선택',
                    width: 130,
                    items: const ['선택', '대표', '부문장'],
                    labelBuilder: (value) => value,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedPeopleTable extends StatelessWidget {
  const _SelectedPeopleTable({required this.rows, this.caption});

  final List<(String, String, String, String, String)> rows;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black300)),
      child: Column(
        children: [
          Container(
            height: 38,
            color: TheWeColor.black300.withValues(alpha: 0.14),
            child: Row(
              children: ['타입', '구분', '이름', '부서', '상태', '삭제']
                  .map(
                    (header) => Expanded(
                      child: Center(
                        child: Text(
                          header,
                          style: TheWeTextStyle.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...rows.map(
            (row) => SizedBox(
              height: 54,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(row.$1, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$2, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$3, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$4, style: TheWeTextStyle.body),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$5, style: TheWeTextStyle.caption),
                    ),
                  ),
                  const Expanded(child: Icon(Icons.delete_outline, size: 18)),
                ],
              ),
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  caption!,
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.black500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: TheWeTextStyle.body)),
        Expanded(child: Text(value, style: TheWeTextStyle.body)),
      ],
    );
  }
}
