import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class TheWeDataTable extends StatelessWidget {
  const TheWeDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnFlexes,
    this.minWidth = 920,
    this.onRowTaps,
  });

  final List<String> headers;
  final List<List<Widget>> rows;
  final List<double>? columnFlexes;
  final double minWidth;
  final List<VoidCallback?>? onRowTaps;

  @override
  Widget build(BuildContext context) {
    assert(
      rows.every((row) => row.length == headers.length),
      'Every row must have the same number of cells as headers.',
    );
    assert(
      columnFlexes == null || columnFlexes!.length == headers.length,
      'columnFlexes must match the number of headers.',
    );
    assert(
      onRowTaps == null || onRowTaps!.length == rows.length,
      'onRowTaps must match the number of rows.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, minWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: TheWeColor.blue200.withValues(alpha: .58),
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Table(
                  columnWidths: {
                    for (var index = 0; index < headers.length; index++)
                      index: FlexColumnWidth(columnFlexes?[index] ?? 1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: TheWeColor.blueSurface,
                      ),
                      children: [
                        for (var index = 0; index < headers.length; index++)
                          _TableCell(
                            rightBorder: index != headers.length - 1,
                            alignment: Alignment.center,
                            child: Text(
                              headers[index],
                              textAlign: TextAlign.center,
                              style: TheWeTextStyle.body.copyWith(
                                color: TheWeColor.black900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: rowIndex.isEven
                              ? Colors.white
                              : TheWeColor.blueSurface.withValues(alpha: .55),
                        ),
                        children: [
                          for (
                            var columnIndex = 0;
                            columnIndex < rows[rowIndex].length;
                            columnIndex++
                          )
                            _TableCell(
                              rightBorder:
                                  columnIndex != rows[rowIndex].length - 1,
                              bottomBorder: rowIndex != rows.length - 1,
                              onTap: onRowTaps?[rowIndex],
                              child: rows[rowIndex][columnIndex],
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.child,
    this.rightBorder = false,
    this.bottomBorder = false,
    this.alignment = Alignment.center,
    this.onTap,
  });

  final Widget child;
  final bool rightBorder;
  final bool bottomBorder;
  final AlignmentGeometry alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: TheWeColor.blueSurface.withValues(alpha: .7),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              right: rightBorder
                  ? BorderSide(
                      color: TheWeColor.black300.withValues(alpha: .26),
                    )
                  : BorderSide.none,
              bottom: bottomBorder
                  ? BorderSide(
                      color: TheWeColor.black300.withValues(alpha: .26),
                    )
                  : BorderSide.none,
            ),
          ),
          child: DefaultTextStyle(
            style: TheWeTextStyle.body.copyWith(color: TheWeColor.black900),
            textAlign: TextAlign.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
