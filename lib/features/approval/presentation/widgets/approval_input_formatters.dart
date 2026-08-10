import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 숫자 8자리를 입력하면 YYYY-MM-DD 모양으로 구분자를 자동 삽입한다.
class ApprovalDateInputFormatter extends TextInputFormatter {
  const ApprovalDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 8));
    final buffer = StringBuffer();
    for (var index = 0; index < limited.length; index++) {
      if (index == 4 || index == 6) buffer.write('-');
      buffer.write(limited[index]);
    }
    final value = buffer.toString();
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

/// 금액을 입력하는 즉시 천 단위 쉼표를 표시한다.
class ApprovalAmountInputFormatter extends TextInputFormatter {
  ApprovalAmountInputFormatter();

  static final NumberFormat _format = NumberFormat.decimalPattern('ko_KR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final value = _format.format(number);
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

/// 수량처럼 쉼표가 필요 없는 숫자 입력에서 숫자 이외의 문자를 제거한다.
class ApprovalDigitsInputFormatter extends TextInputFormatter {
  const ApprovalDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = newValue.text.replaceAll(RegExp(r'\D'), '');
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

String formatApprovalAmount(String value) {
  final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
  return number == null
      ? value
      : ApprovalAmountInputFormatter._format.format(number);
}

/// 수량과 단가가 모두 입력되면 행 합계 금액을 계산한다.
String calculateApprovalLineItemTotal({
  required String quantity,
  required String amount,
}) {
  final quantityDigits = quantity.replaceAll(RegExp(r'[^0-9]'), '');
  final amountDigits = amount.replaceAll(RegExp(r'[^0-9]'), '');
  if (quantityDigits.isEmpty || amountDigits.isEmpty) {
    return '';
  }

  final parsedQuantity = BigInt.tryParse(quantityDigits);
  final parsedAmount = BigInt.tryParse(amountDigits);
  if (parsedQuantity == null || parsedAmount == null) {
    return '';
  }
  return (parsedQuantity * parsedAmount).toString();
}
