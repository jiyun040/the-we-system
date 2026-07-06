part of 'approval_absence_page.dart';

class _OvertimeRequestDialog extends StatefulWidget {
  const _OvertimeRequestDialog();

  @override
  State<_OvertimeRequestDialog> createState() => _OvertimeRequestDialogState();
}

class _OvertimeRequestDialogState extends State<_OvertimeRequestDialog> {
  final reasonController = TextEditingController();
  final String checkDate = _formatDate(DateTime.now());
  final String startDate = _formatDate(DateTime.now());
  final String endDate = _formatDate(DateTime.now());
  int startHour = 18;
  int startMinute = 0;
  int endHour = 21;
  int endMinute = 0;

  DateTime get _startDateTime => DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    startHour,
    startMinute,
  );

  DateTime get _endDateTime => DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    endHour,
    endMinute,
  );

  bool get _invalidTime => !_endDateTime.isAfter(_startDateTime);

  String get _durationLabel {
    if (_invalidTime) {
      return '0h 0m';
    }
    final duration = _endDateTime.difference(_startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 520;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 18 : 40,
        vertical: 24,
      ),
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(28, 24, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      title: Row(
        children: [
          Text('초과근로 신청', style: TheWeTextStyle.title),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: isPhone ? screen.width - 72 : 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogField(
                label: '출근체크일',
                child: _InlineBox(text: checkDate),
              ),
              _DialogField(
                label: '초과근로신청',
                child: Column(
                  children: [
                    _OvertimeDateTimeRow(
                      label: '초과근로발생시작일',
                      date: startDate,
                      hour: startHour,
                      minute: startMinute,
                      onHourChanged: (value) =>
                          setState(() => startHour = value ?? startHour),
                      onMinuteChanged: (value) =>
                          setState(() => startMinute = value ?? startMinute),
                    ),
                    const SizedBox(height: 12),
                    _OvertimeDateTimeRow(
                      label: '초과근로발생종료일',
                      date: endDate,
                      hour: endHour,
                      minute: endMinute,
                      onHourChanged: (value) =>
                          setState(() => endHour = value ?? endHour),
                      onMinuteChanged: (value) =>
                          setState(() => endMinute = value ?? endMinute),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _SmallStat(label: '초과근로시간', value: _durationLabel),
                  const _SmallStat(label: '잔여 초과근로시간', value: '12h 0m'),
                  _SmallStat(label: '신청 후 초과근로시간', value: _durationLabel),
                ],
              ),
              if (_invalidTime) ...[
                const SizedBox(height: 14),
                Text(
                  '신청 시간이 잘못되었습니다.',
                  style: TheWeTextStyle.body.copyWith(color: TheWeColor.pink),
                ),
              ],
              const SizedBox(height: 18),
              _DialogField(
                label: '신청사유',
                child: CustomTextFormField(
                  controller: reasonController,
                  minLines: 4,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: '신청 사유를 입력하세요.'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _invalidTime
              ? null
              : () => Navigator.of(context).pop(
                  AttendanceRequestRecord(
                    type: '초과근로 신청서',
                    date: checkDate,
                    timeRange:
                        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} ~ ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
                    status: '결재대기',
                    reason: reasonController.text.trim().isEmpty
                        ? '초과근무 사유 미입력'
                        : reasonController.text.trim(),
                  ),
                ),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('전자결재 상신'),
        ),
      ],
    );
  }
}

class _WorkTimeCorrectionDialog extends StatefulWidget {
  const _WorkTimeCorrectionDialog();

  @override
  State<_WorkTimeCorrectionDialog> createState() =>
      _WorkTimeCorrectionDialogState();
}

class _WorkTimeCorrectionDialogState extends State<_WorkTimeCorrectionDialog> {
  final reasonController = TextEditingController();
  final String selectedDate = _formatDate(DateTime.now());
  final List<String> corrections = [];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correctedHours = corrections.length * 2;
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 520;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 18 : 40,
        vertical: 24,
      ),
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(28, 24, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      title: Row(
        children: [
          Text('근무시간수정 신청', style: TheWeTextStyle.title),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: isPhone ? screen.width - 72 : 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogField(
                label: '수정 신청일',
                child: _InlineBox(text: selectedDate),
              ),
              _DialogField(
                label: '근무시간 수정',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(
                            () => corrections.add(
                              '$selectedDate 09:00 ~ 11:00 근무시간 추가',
                            ),
                          ),
                          child: const Text('추가'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: corrections.isEmpty
                              ? null
                              : () => setState(() => corrections.removeLast()),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: corrections.isEmpty
                          ? Text(
                              '타임라인 내역이 없습니다.',
                              style: TheWeTextStyle.body.copyWith(
                                color: TheWeColor.black500,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: corrections
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        item,
                                        style: TheWeTextStyle.body,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  const _SmallStat(label: '신청일 근로시간', value: '0h'),
                  _SmallStat(label: '수정 후 근로시간', value: '${correctedHours}h'),
                  _SmallStat(label: '주간 총 근로시간', value: '${correctedHours}h'),
                ],
              ),
              const SizedBox(height: 18),
              _DialogField(
                label: '신청사유',
                child: CustomTextFormField(
                  controller: reasonController,
                  minLines: 4,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: '신청 사유를 입력하세요.'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            AttendanceRequestRecord(
              type: '근무시간 수정 신청서',
              date: selectedDate,
              timeRange: corrections.isEmpty
                  ? '타임라인 없음'
                  : '${corrections.length}건 수정',
              status: '결재대기',
              reason: reasonController.text.trim().isEmpty
                  ? '근무시간 수정 사유 미입력'
                  : reasonController.text.trim(),
            ),
          ),
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: const Text('전자결재 상신'),
        ),
      ],
    );
  }
}
