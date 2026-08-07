import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class TheWeDropdown<T> extends StatelessWidget {
  const TheWeDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.width,
  });

  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DropdownMenu<T>(
      key: ValueKey(value),
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      requestFocusOnTap: false,
      enableFilter: false,
      enableSearch: false,
      menuHeight: 340,
      textStyle: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w600),
      trailingIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: TheWeColor.black900,
      ),
      selectedTrailingIcon: const Icon(
        Icons.keyboard_arrow_up_rounded,
        color: TheWeColor.black900,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TheWeColor.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: TheWeColor.blue200.withValues(alpha: .8),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: TheWeColor.blue300, width: 1.4),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(TheWeColor.white),
        surfaceTintColor: const WidgetStatePropertyAll(TheWeColor.white),
        elevation: const WidgetStatePropertyAll(12),
        shadowColor: WidgetStatePropertyAll(
          TheWeColor.black900.withValues(alpha: .18),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: TheWeColor.blue200.withValues(alpha: .7)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      dropdownMenuEntries: items
          .map(
            (item) => DropdownMenuEntry<T>(
              value: item,
              label: labelBuilder(item),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  item == value ? TheWeColor.blueSurface : Colors.transparent,
                ),
                foregroundColor: const WidgetStatePropertyAll(
                  TheWeColor.black900,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          )
          .toList(),
      onSelected: onChanged,
    ),
  );
}
