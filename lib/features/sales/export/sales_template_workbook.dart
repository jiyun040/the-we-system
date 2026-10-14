import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import '../domain/sales_ledger_entry.dart';

const salesExcelMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const _office =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

/// Patches only live input cells in the supplied Excel templates. Original
/// styles, images, merged cells, column widths and print settings remain intact.
class SalesTemplateWorkbook {
  SalesTemplateWorkbook(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      files[file.name] = Uint8List.fromList(file.content);
    }
    sheet = read('xl/worksheets/sheet1.xml');
    styles = read('xl/styles.xml');
  }
  final files = <String, Uint8List>{};
  late XmlDocument sheet;
  late XmlDocument styles;
  final _styleCache = <String, int>{};
  final _fontCache = <String, int>{};
  XmlDocument read(String path) => XmlDocument.parse(utf8.decode(files[path]!));
  void write(String path, XmlDocument xml) =>
      files[path] = Uint8List.fromList(utf8.encode(xml.toXmlString()));
  XmlDocument? _indexedSheet;
  XmlElement? _data;
  final _rows = <int, XmlElement>{};
  XmlElement get data {
    if (!identical(_indexedSheet, sheet)) {
      _indexedSheet = sheet;
      _data = sheet.findAllElements('sheetData').single;
      _rows.clear();
      for (final r in _data!.findElements('row')) {
        _rows[int.parse(r.getAttribute('r')!)] = r;
      }
    }
    return _data!;
  }

  XmlElement row(int number) {
    data;
    return _rows[number]!;
  }

  XmlElement cell(String address) {
    final number = int.parse(address.replaceAll(RegExp('[A-Z]'), ''));
    final r = row(number);
    for (final cell in r.findElements('c')) {
      if (cell.getAttribute('r') == address) return cell;
    }
    final c = XmlElement(XmlName.parts('c'), [
      XmlAttribute(XmlName.parts('r'), address),
    ]);
    r.children.add(c);
    // SpreadsheetML cells must occur in increasing column order.
    final cells = r.findElements('c').toList()
      ..sort(
        (a, b) => columnNumber(
          a.getAttribute('r')!,
        ).compareTo(columnNumber(b.getAttribute('r')!)),
      );
    r.children.clear();
    r.children.addAll(cells);
    return c;
  }

  static int columnNumber(String address) {
    var n = 0;
    for (final c in address.replaceAll(RegExp('[0-9]'), '').codeUnits) {
      n = n * 26 + c - 64;
    }
    return n;
  }

  void set(String address, Object? value, {String? formula}) {
    final c = cell(address);
    c.children.clear();
    c.removeAttribute('t');
    if (formula != null) {
      c.children.add(XmlElement(XmlName.parts('f'), [], [XmlText(formula)]));
    }
    if (value is num) {
      c.children.add(XmlElement(XmlName.parts('v'), [], [XmlText('$value')]));
    } else if (value != null && value.toString().isNotEmpty) {
      c.setAttribute('t', 'inlineStr');
      c.children.add(
        XmlElement(XmlName.parts('is'), [], [
          XmlElement(
            XmlName.parts('t'),
            [XmlAttribute(XmlName.parts('space', prefix: 'xml'), 'preserve')],
            [XmlText(value.toString())],
          ),
        ]),
      );
    }
  }

  int fillStyle(
    int base,
    String color, {
    String? textColor,
  }) => _styleCache.putIfAbsent('$base:$color:$textColor', () {
    final fills = styles.findAllElements('fills').single;
    final fillId = fills.childElements.length;
    fills.children.add(
      XmlDocument.parse(
        '<fill><patternFill patternType="solid"><fgColor rgb="$color"/><bgColor indexed="64"/></patternFill></fill>',
      ).rootElement.copy(),
    );
    fills.setAttribute('count', '${fillId + 1}');
    final xfs = styles.findAllElements('cellXfs').single;
    final style = xfs.childElements.elementAt(base).copy();
    style.setAttribute('fillId', '$fillId');
    style.setAttribute('applyFill', '1');
    if (textColor != null) {
      final fonts = styles.findAllElements('fonts').single;
      final baseFont = int.parse(style.getAttribute('fontId') ?? '0');
      final fontId = _fontCache.putIfAbsent('$baseFont:$textColor', () {
        final font = fonts.childElements.elementAt(baseFont).copy();
        font.children.removeWhere(
          (child) => child is XmlElement && child.name.local == 'color',
        );
        font.children.add(
          XmlElement(XmlName.parts('color'), [
            XmlAttribute(XmlName.parts('rgb'), textColor),
          ]),
        );
        final id = fonts.childElements.length;
        fonts.children.add(font);
        fonts.setAttribute('count', '${id + 1}');
        return id;
      });
      style.setAttribute('fontId', '$fontId');
      style.setAttribute('applyFont', '1');
    }
    final id = xfs.childElements.length;
    xfs.children.add(style);
    xfs.setAttribute('count', '${id + 1}');
    return id;
  });
  void color(String address, String value, {String? textColor}) {
    final c = cell(address);
    c.setAttribute(
      's',
      '${fillStyle(int.parse(c.getAttribute('s') ?? '0'), value, textColor: textColor)}',
    );
  }

  void cloneRow(XmlElement prototype, int number) {
    final copy = prototype.copy();
    copy.setAttribute('r', '$number');
    for (final c in copy.findElements('c')) {
      c.setAttribute(
        'r',
        c.getAttribute('r')!.replaceAll(RegExp('[0-9]'), '$number'),
      );
      c.children.clear();
      c.removeAttribute('t');
    }
    data.children.add(copy);
    _rows[number] = copy;
  }

  void resetOpenPosition(XmlDocument worksheet) {
    for (final view in worksheet.findAllElements('sheetView')) {
      view.setAttribute('topLeftCell', 'A1');
      final pane = view.findElements('pane').firstOrNull;
      final frozenRows = int.tryParse(pane?.getAttribute('ySplit') ?? '') ?? 0;
      final firstVisible = 'A${frozenRows + 1}';
      pane?.setAttribute('topLeftCell', firstVisible);
      for (final selection in view.findElements('selection')) {
        final active = selection.getAttribute('pane') == 'bottomLeft'
            ? firstVisible
            : 'A1';
        selection.setAttribute('activeCell', active);
        selection.setAttribute('sqref', active);
      }
    }
  }

  Uint8List export({
    required List<XmlDocument> sheets,
    required List<String> names,
    required List<String> areas,
  }) {
    write('xl/styles.xml', styles);
    final workbook = read('xl/workbook.xml');
    final list = workbook.findAllElements('sheets').single;
    list.children.clear();
    final defined = workbook.findAllElements('definedNames').single;
    defined.children.clear();
    final relations = read('xl/_rels/workbook.xml.rels');
    final types = read('[Content_Types].xml');
    relations.rootElement.children.removeWhere(
      (e) => e is XmlElement && e.getAttribute('Type') == '$_office/worksheet',
    );
    for (var i = 0; i < sheets.length; i++) {
      final n = i + 1;
      final path = 'xl/worksheets/sheet$n.xml';
      resetOpenPosition(sheets[i]);
      write(path, sheets[i]);
      final sheetRelationships = files['xl/worksheets/_rels/sheet1.xml.rels'];
      if (sheetRelationships != null) {
        files['xl/worksheets/_rels/sheet$n.xml.rels'] = sheetRelationships;
      }
      list.children.add(
        XmlElement(XmlName.parts('sheet'), [
          XmlAttribute(XmlName.parts('name'), names[i]),
          XmlAttribute(XmlName.parts('sheetId'), '$n'),
          XmlAttribute(XmlName.parts('id', prefix: 'r'), 'sheet$n'),
        ]),
      );
      relations.rootElement.children.add(
        XmlElement(XmlName.parts('Relationship'), [
          XmlAttribute(XmlName.parts('Id'), 'sheet$n'),
          XmlAttribute(XmlName.parts('Type'), '$_office/worksheet'),
          XmlAttribute(XmlName.parts('Target'), 'worksheets/sheet$n.xml'),
        ]),
      );
      defined.children.add(
        XmlElement(
          XmlName.parts('definedName'),
          [
            XmlAttribute(XmlName.parts('name'), '_xlnm.Print_Area'),
            XmlAttribute(XmlName.parts('localSheetId'), '$i'),
          ],
          [XmlText("'${names[i]}'!${areas[i]}")],
        ),
      );
      if (i > 0) {
        types.rootElement.children.add(
          XmlElement(XmlName.parts('Override'), [
            XmlAttribute(XmlName.parts('PartName'), '/$path'),
            XmlAttribute(
              XmlName.parts('ContentType'),
              'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml',
            ),
          ]),
        );
      }
    }
    write('xl/workbook.xml', workbook);
    write('xl/_rels/workbook.xml.rels', relations);
    write('[Content_Types].xml', types);
    final archive = Archive();
    for (final entry in files.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}

String salesNote(SalesLedgerEntry item) =>
    item.adjustmentReason.trim().isEmpty ||
        item.note.contains(item.adjustmentReason.trim())
    ? item.note
    : [item.note, item.adjustmentReason].where((s) => s.isNotEmpty).join(' / ');
String salesPeriod(SalesLedgerEntry item) =>
    '${item.startDate == null ? "-" : DateFormat('yy-MM-dd').format(item.startDate!)} ~ ${item.endDate == null ? "사용중" : DateFormat('MM-dd').format(item.endDate!)}';
num? _excelDate(DateTime? d) => d == null
    ? null
    : DateTime.utc(
        d.year,
        d.month,
        d.day,
      ).difference(DateTime.utc(1899, 12, 30)).inDays;

Future<Uint8List> ledgerTemplateXlsx(
  List<SalesLedgerEntry> items,
  DateTime month,
) async {
  final bytes = await rootBundle.load('assets/templates/ledger.xlsx');
  return buildLedgerTemplate(bytes.buffer.asUint8List(), items, month);
}

Uint8List buildLedgerTemplate(
  Uint8List template,
  List<SalesLedgerEntry> items,
  DateTime month,
) {
  final book = SalesTemplateWorkbook(template);
  final prototype = book.row(2).copy();
  final summary = book.row(3).copy();
  book.data.children.removeWhere(
    (e) => e is XmlElement && int.parse(e.getAttribute('r')!) > 1,
  );
  final contractors = <String, List<SalesLedgerEntry>>{};
  final projects = <String, List<SalesLedgerEntry>>{};
  for (final item in items) {
    contractors.putIfAbsent(item.contractor, () => []).add(item);
    projects.putIfAbsent(item.projectName, () => []).add(item);
  }
  final count = [
    items.length + 2,
    contractors.length + 3,
    projects.length + 3,
    3,
  ].reduce((a, b) => a > b ? a : b);
  for (var r = 2; r <= count; r++) {
    book.cloneRow(r == 2 ? prototype : summary, r);
    for (var c = 0; c < 14; c++) {
      book.color(
        '${String.fromCharCode(65 + c)}$r',
        'FFFFFFFF',
        textColor: 'FF000000',
      );
    }
  }
  // Use the source's body formatting consistently, including rows beyond its original capacity.
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final r = i + 2;
    final values = <Object?>[
      i + 1,
      item.projectName,
      item.contractor,
      item.partner,
      item.elevator,
      salesPeriod(item),
      _excelDate(item.billingDate),
      _excelDate(item.invoiceDate),
      _excelDate(item.depositDate),
      item.supplyAmount,
      item.installment,
      item.status,
      salesNote(item),
      item.category,
    ];
    for (var c = 0; c < 14; c++) {
      final address = '${String.fromCharCode(65 + c)}$r';
      book.set(address, values[c]);
    }
    book.color(
      '${item.invoiceIssuerType == '시공사' ? 'C' : 'D'}$r',
      item.invoiceIssuerType == '시공사' ? 'FF2563EB' : 'FF16A34A',
      textColor: 'FFFFFFFF',
    );
    if (item.billingDate != null) {
      book.color('G$r', 'FFFFD43B', textColor: 'FF000000');
    }
    final statusColor = switch (item.status) {
      '신규' => 'FF2563EB',
      '진행' => 'FF16A34A',
      '종료' => 'FFDC2626',
      _ => null,
    };
    if (statusColor != null) {
      book.color('L$r', statusColor, textColor: 'FFFFFFFF');
    }
  }
  book.set('P1', '${month.month}월 시공사별 집계표');
  for (final entry in {
    'P2': '시공사',
    'Q2': '기기수량',
    'R2': '금액',
    'T2': '현장명',
    'U2': '기기수량',
    'V2': '공급가액',
  }.entries) {
    book.set(entry.key, entry.value);
  }
  void group(
    Map<String, List<SalesLedgerEntry>> groups,
    String label,
    String quantity,
    String amount,
  ) {
    var r = 3;
    for (final g in groups.entries) {
      book.set('$label$r', g.key);
      final source = label == 'P' ? 'C' : 'B';
      final end = items.length + 1;
      book.set(
        '$quantity$r',
        g.value.length,
        formula: 'COUNTIF(${source}2:$source$end,$label$r)',
      );
      book.set(
        '$amount$r',
        g.value.fold<int>(0, (s, e) => s + e.supplyAmount),
        formula: 'SUMIF(${source}2:$source$end,$label$r,J2:J$end)',
      );
      r++;
    }
    book.set('$label$r', '합계');
    book.set('$quantity$r', items.length);
    book.set('$amount$r', items.fold<int>(0, (s, e) => s + e.supplyAmount));
  }

  group(contractors, 'P', 'Q', 'R');
  group(projects, 'T', 'U', 'V');
  book.set('B${items.length + 2}', '합계');
  book.set(
    'J${items.length + 2}',
    items.fold<int>(0, (s, e) => s + e.supplyAmount),
    formula: items.isEmpty ? '0' : 'SUM(J2:J${items.length + 1})',
  );
  book.sheet
      .findAllElements('dimension')
      .single
      .setAttribute('ref', 'A1:V$count');
  return book.export(
    sheets: [book.sheet],
    names: ['${month.month}월'],
    areas: ['\$A\$1:\$V\$$count'],
  );
}

Future<Uint8List> statementTemplateXlsx(SalesStatement statement) async {
  final bytes = await rootBundle.load('assets/templates/statement.xlsx');
  return buildStatementTemplate(
    bytes.buffer.asUint8List(),
    statement,
    DateTime.now(),
  );
}

Uint8List buildStatementTemplate(
  Uint8List template,
  SalesStatement statement,
  DateTime issued,
) {
  final book = SalesTemplateWorkbook(template);
  final original = book.sheet.copy();
  final pages = <XmlDocument>[];
  final pageCount = statement.items.isEmpty
      ? 1
      : (statement.items.length / 17).ceil();
  final overall = statement.items.fold<int>(
    0,
    (s, e) => s + e.supplyAmount + (e.supplyAmount * .1).round(),
  );
  for (var page = 0; page < pageCount; page++) {
    book.sheet = original.copy();
    final first = statement.items.firstOrNull;
    book.set(
      'B4',
      first == null
          ? ''
          : first.invoiceIssuerType == '시공사'
          ? first.contractor
          : first.partner,
    );
    book.set('B6', statement.projectName);
    book.set('E9', _excelDate(issued));
    book.set(
      'C10',
      overall,
      formula: pageCount == 1
          ? 'G29'
          : 'SUM(${List.generate(pageCount, (i) => "'내역서 ${i + 1}'!G29").join(',')})',
    );
    if (pageCount > 1) book.set('A2', '내 역 서 (${page + 1}/$pageCount)');
    var supply = 0, tax = 0, quantity = 0;
    for (var i = 0; i < 17; i++) {
      final index = page * 17 + i;
      final r = 12 + i;
      for (var c = 0; c < 8; c++) {
        final col = String.fromCharCode(65 + c);
        book
            .cell('$col$r')
            .setAttribute('s', book.cell('${col}12').getAttribute('s')!);
      }
      if (index >= statement.items.length) {
        continue;
      }
      final item = statement.items[index];
      final vat = (item.supplyAmount * .1).round();
      supply += item.supplyAmount;
      tax += vat;
      quantity++;
      final values = <Object?>[
        '${index + 1}. PDAM시스템 공급',
        '${item.elevator} ${item.installment}회 : ${salesPeriod(item)}',
        'SET',
        1,
        item.supplyAmount,
        vat,
        item.supplyAmount + vat,
        salesNote(item),
      ];
      for (var c = 0; c < 8; c++) {
        book.set(
          '${String.fromCharCode(65 + c)}$r',
          values[c],
          formula: c == 5
              ? 'ROUND(E$r*0.1,0)'
              : c == 6
              ? 'E$r+F$r'
              : null,
        );
      }
    }
    for (final e in {
      'D': quantity,
      'E': supply,
      'F': tax,
      'G': supply + tax,
    }.entries) {
      book.set('${e.key}29', e.value, formula: 'SUM(${e.key}12:${e.key}28)');
    }
    pages.add(book.sheet);
  }
  return book.export(
    sheets: pages,
    names: [
      for (var i = 0; i < pageCount; i++)
        pageCount == 1 ? '내역서' : '내역서 ${i + 1}',
    ],
    areas: List.filled(pageCount, '\$A\$1:\$H\$31'),
  );
}
