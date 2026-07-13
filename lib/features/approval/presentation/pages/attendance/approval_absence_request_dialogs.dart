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

    return TheWeModalSurface(
      maxWidth: 820,
      width: isPhone ? screen.width - 36 : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title: '초과근로 신청',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          Flexible(
            child: SizedBox(
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
                            onMinuteChanged: (value) => setState(
                              () => startMinute = value ?? startMinute,
                            ),
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
                        style: TheWeTextStyle.body.copyWith(
                          color: TheWeColor.pink,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _DialogField(
                      label: '신청사유',
                      child: CustomTextFormField(
                        controller: reasonController,
                        minLines: 4,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '신청 사유를 입력하세요.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            primaryLabel: '전자결재 상신',
            secondaryLabel: '취소',
            primaryColor: TheWeColor.green,
            onSecondaryPressed: () => Navigator.of(context).pop(),
            onPrimaryPressed: _invalidTime
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
          ),
        ],
      ),
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
  final List<_WorkTimeCorrectionEntry> corrections = [];
  int startHour = 9;
  int startMinute = 0;
  int endHour = 11;
  int endMinute = 0;
  int? selectedCorrectionIndex;

  int get _selectedDurationMinutes {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return math.max(0, end - start);
  }

  int get _correctedMinutes =>
      corrections.fold(0, (total, entry) => total + entry.durationMinutes);

  String _durationText(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes.remainder(60);
    return remainingMinutes == 0
        ? '${hours}h'
        : '${hours}h ${remainingMinutes}m';
  }

  void _addCorrection() {
    if (_selectedDurationMinutes <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다.')));
      return;
    }

    setState(() {
      corrections.add(
        _WorkTimeCorrectionEntry(
          date: selectedDate,
          startHour: startHour,
          startMinute: startMinute,
          endHour: endHour,
          endMinute: endMinute,
        ),
      );
      selectedCorrectionIndex = corrections.length - 1;
    });
  }

  void _deleteSelectedCorrection() {
    final index = selectedCorrectionIndex;
    if (index == null) {
      return;
    }

    setState(() {
      corrections.removeAt(index);
      selectedCorrectionIndex = null;
    });
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

    return TheWeModalSurface(
      maxWidth: 820,
      width: isPhone ? screen.width - 36 : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TheWeModalHeader(
            title: '근무시간수정 신청',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          Flexible(
            child: SizedBox(
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
                          _OvertimeDateTimeRow(
                            label: '수정 시작 시간',
                            date: selectedDate,
                            hour: startHour,
                            minute: startMinute,
                            onHourChanged: (value) =>
                                setState(() => startHour = value ?? startHour),
                            onMinuteChanged: (value) => setState(
                              () => startMinute = value ?? startMinute,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _OvertimeDateTimeRow(
                            label: '수정 종료 시간',
                            date: selectedDate,
                            hour: endHour,
                            minute: endMinute,
                            onHourChanged: (value) =>
                                setState(() => endHour = value ?? endHour),
                            onMinuteChanged: (value) =>
                                setState(() => endMinute = value ?? endMinute),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: _addCorrection,
                                child: const Text('추가'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: selectedCorrectionIndex == null
                                    ? null
                                    : _deleteSelectedCorrection,
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: TheWeColor.surfaceAlt,
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
                                    children: List.generate(corrections.length, (
                                      index,
                                    ) {
                                      final item = corrections[index];
                                      final selected =
                                          selectedCorrectionIndex == index;
                                      return InkWell(
                                        onTap: () => setState(
                                          () => selectedCorrectionIndex = index,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 7,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                selected
                                                    ? Icons.radio_button_checked
                                                    : Icons.radio_button_off,
                                                color: selected
                                                    ? TheWeColor.blue300
                                                    : TheWeColor.black300,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.label,
                                                  style: TheWeTextStyle.body,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
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
                        _SmallStat(
                          label: '수정 후 근로시간',
                          value: _durationText(_correctedMinutes),
                        ),
                        _SmallStat(
                          label: '주간 총 근로시간',
                          value: _durationText(_correctedMinutes),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _DialogField(
                      label: '신청사유',
                      child: CustomTextFormField(
                        controller: reasonController,
                        minLines: 4,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '신청 사유를 입력하세요.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          TheWeModalActions(
            primaryLabel: '전자결재 상신',
            secondaryLabel: '취소',
            primaryColor: TheWeColor.green,
            onSecondaryPressed: () => Navigator.of(context).pop(),
            onPrimaryPressed: () => Navigator.of(context).pop(
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
          ),
        ],
      ),
    );
  }
}

class _WorkTimeCorrectionEntry {
  const _WorkTimeCorrectionEntry({
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final String date;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  int get durationMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  String get label =>
      '$date ${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} ~ '
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} 근무시간 추가';
}
