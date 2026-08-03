import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

Future<DateTime?> showTheWeDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required String title,
  Key? dialogKey,
}) {
  final normalizedFirst = DateUtils.dateOnly(firstDate);
  final normalizedLast = DateUtils.dateOnly(lastDate);
  var selectedDate = DateUtils.dateOnly(initialDate);
  if (selectedDate.isBefore(normalizedFirst)) selectedDate = normalizedFirst;
  if (selectedDate.isAfter(normalizedLast)) selectedDate = normalizedLast;

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final compact = MediaQuery.sizeOf(context).width < 600;
        return Dialog(
          key: dialogKey,
          backgroundColor: TheWeColor.surfaceAlt,
          insetPadding: EdgeInsets.all(compact ? 16 : 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 22,
                compact ? 16 : 20,
                compact ? 14 : 22,
                compact ? 14 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TheWeColor.blueSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: TheWeColor.blue300,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title, style: TheWeTextStyle.subtitle),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TheWeColor.blueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatKoreanDate(selectedDate),
                      textAlign: TextAlign.center,
                      style: TheWeTextStyle.body.copyWith(
                        color: TheWeColor.blue300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: TheWeColor.blue300,
                        onPrimary: Colors.white,
                        surface: TheWeColor.surfaceAlt,
                        onSurface: TheWeColor.black900,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: normalizedFirst,
                      lastDate: normalizedLast,
                      onDateChanged: (date) =>
                          setDialogState(() => selectedDate = date),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('취소'),
                      ),
                      SizedBox(width: compact ? 4 : 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, selectedDate),
                        style: FilledButton.styleFrom(
                          backgroundColor: TheWeColor.black900,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 20 : 24,
                            vertical: 13,
                          ),
                        ),
                        child: const Text('선택'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _formatKoreanDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 '
      '(${weekdays[date.weekday - 1]})';
}
