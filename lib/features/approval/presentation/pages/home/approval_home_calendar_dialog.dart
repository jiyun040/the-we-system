import 'approval_home_dependencies.dart';
import 'approval_home_calendar_models.dart';

class ApprovalCalendarEventDialog extends StatefulWidget {
  const ApprovalCalendarEventDialog({
    super.key,
    required this.date,
    this.initialEvent,
  });

  final DateTime date;
  final ApprovalCalendarEvent? initialEvent;

  @override
  State<ApprovalCalendarEventDialog> createState() =>
      _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<ApprovalCalendarEventDialog> {
  final titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;
    if (initialEvent == null) {
      return;
    }

    titleController.text = initialEvent.title;
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 520;

    return TheWeModalSurface(
      maxWidth: 480,
      width: isPhone ? screen.width - 40 : null,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheWeModalHeader(
              title:
                  '${formatApprovalKoreanDate(widget.date)} 일정 ${widget.initialEvent == null ? '추가' : '수정'}',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: isPhone ? screen.width - 96 : 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarTextField(
                    label: '일정 이름',
                    controller: titleController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            TheWeModalActions(
              primaryLabel: widget.initialEvent == null ? '추가' : '수정',
              secondaryLabel: '취소',
              primaryColor: TheWeColor.blue300,
              onSecondaryPressed: () => Navigator.of(context).pop(),
              onPrimaryPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  ApprovalCalendarEvent(
                    title: title,
                    time: '',
                    place: '',
                    colorKey: 'blue',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTextField extends StatelessWidget {
  const _CalendarTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.body),
        const SizedBox(height: 8),
        CustomTextFormField(controller: controller),
      ],
    );
  }
}

class ApprovalCalendarDetailLine extends StatelessWidget {
  const ApprovalCalendarDetailLine({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TheWeTextStyle.body)),
        ],
      ),
    );
  }
}

class ApprovalCalendarColorDetailLine extends StatelessWidget {
  const ApprovalCalendarColorDetailLine({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '색상',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

String formatApprovalKoreanDate(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}
