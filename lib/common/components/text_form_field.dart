import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? initialValue;

  final TextStyle? style;

  final InputDecoration? decoration;

  final double labelSpacing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;

  final bool autofocus;
  final bool readOnly;
  final bool obscureText;
  final bool autocorrect;
  final bool expands;
  final bool? showCursor;

  final String obscuringCharacter;

  final List<TextInputFormatter>? inputFormatters;

  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  final double? width;
  final double? height;

  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(PointerDownEvent)? onTapOutside;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;

  bool get hasLabel =>
      decoration != null &&
          (decoration!.label != null || decoration!.labelText != null);

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.focusNode,
    this.initialValue,
    this.style,
    this.decoration = const InputDecoration(),
    this.labelSpacing = 8,
    this.keyboardType,
    this.textInputAction,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.readOnly = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.expands = false,
    this.showCursor,
    this.obscuringCharacter = '*',
    this.inputFormatters,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.height,
    this.width,
    this.onChanged,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TheWeTextStyle.hintText.merge(style);

    InputDecoration inputDecoration = InputDecoration(
      icon: decoration?.icon,
      iconColor: decoration?.iconColor,
      helper: decoration?.helper,
      helperText: decoration?.helperText,
      helperStyle: decoration?.helperStyle,
      helperMaxLines: decoration?.helperMaxLines,
      hintText: decoration?.hintText,
      hintStyle: TheWeTextStyle.hintText.copyWith(
          color: TheWeColor.black500,
          fontSize: 10
      ),
      hintMaxLines: decoration?.hintMaxLines,
      hintTextDirection: decoration?.hintTextDirection,
      error: decoration?.error,
      errorText: decoration?.errorText,
      errorStyle: decoration?.errorStyle,
      errorMaxLines: decoration?.errorMaxLines,
      floatingLabelBehavior: decoration?.floatingLabelBehavior,
      floatingLabelAlignment: decoration?.floatingLabelAlignment,
      isCollapsed: decoration?.isCollapsed ?? false,
      isDense: decoration?.isDense,
      contentPadding: decoration?.contentPadding,
      prefixIcon: decoration?.prefixIcon,
      prefixIconColor: decoration?.prefixIconColor,
      prefixIconConstraints: decoration?.prefixIconConstraints,
      prefix: decoration?.prefix,
      prefixText: decoration?.prefixText,
      prefixStyle: decoration?.prefixStyle,
      suffixIcon: decoration?.suffixIcon,
      suffixIconColor: decoration?.suffixIconColor,
      suffixIconConstraints: decoration?.suffixIconConstraints,
      suffix: decoration?.suffix,
      suffixText: decoration?.suffixText,
      suffixStyle: decoration?.suffixStyle,
      counter: decoration?.counter,
      counterText: decoration?.counterText,
      counterStyle: decoration?.counterStyle,
      filled: decoration?.filled ?? true,
      fillColor: decoration?.fillColor ?? TheWeColor.white,
      focusColor: decoration?.focusColor,
      hoverColor: decoration?.hoverColor,
      disabledBorder: decoration?.disabledBorder,
      enabled: decoration?.enabled ?? true,
      border: decoration?.border,
      semanticCounterText: decoration?.semanticCounterText,
      alignLabelWithHint: decoration?.alignLabelWithHint,
      constraints: decoration?.constraints,

      enabledBorder: decoration?.enabledBorder ?? OutlineInputBorder(
        borderSide: BorderSide(
          color: TheWeColor.black900,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),

      focusedBorder: decoration?.focusedBorder ?? OutlineInputBorder(
        borderSide: BorderSide(
          color: TheWeColor.blue300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),

      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: TheWeColor.pink,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: TheWeColor.pink,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          autocorrect: autocorrect,
          showCursor: showCursor,
          cursorColor: TheWeColor.blue300,
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          decoration: inputDecoration,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: defaultTextStyle,
          textAlign: textAlign,
          autofocus: autofocus,
          readOnly: readOnly,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          expands: expands,
          maxLength: maxLength,
          onChanged: onChanged,
          onTap: onTap,
          onTapOutside: onTapOutside,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: onFieldSubmitted,
          onSaved: onSaved,
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}
