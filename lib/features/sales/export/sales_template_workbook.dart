import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import '../domain/sales_ledger_entry.dart';
import '../domain/sales_ledger_order.dart';
import '../domain/sales_statement_notes.dart';

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

  void setAutoFilter(String range) {
    final children = sheet.rootElement.children;
    children.removeWhere(
      (node) => node is XmlElement && node.name.local == 'autoFilter',
    );
    children.insert(
      children.indexOf(data) + 1,
      XmlElement(XmlName.parts('autoFilter'), [
        XmlAttribute(XmlName.parts('ref'), range),
      ]),
    );
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

  void wrapText(String address, {double fontSize = 9, String? textColor}) {
    final c = cell(address);
    final xfs = styles.findAllElements('cellXfs').single;
    final style = xfs.childElements
        .elementAt(int.parse(c.getAttribute('s') ?? '0'))
        .copy();
    final fonts = styles.findAllElements('fonts').single;
    final font = fonts.childElements
        .elementAt(int.parse(style.getAttribute('fontId') ?? '0'))
        .copy();
    font.findElements('sz').first.setAttribute('val', '$fontSize');
    if (textColor != null) {
      font.children.removeWhere(
        (child) => child is XmlElement && child.name.local == 'color',
      );
      font.children.add(
        XmlElement(XmlName.parts('color'), [
          XmlAttribute(XmlName.parts('rgb'), textColor),
        ]),
      );
    }
    final fontId = fonts.childElements.length;
    fonts.children.add(font);
    fonts.setAttribute('count', '${fontId + 1}');
    style.setAttribute('fontId', '$fontId');
    style.setAttribute('applyFont', '1');
    style.setAttribute('applyAlignment', '1');
    final alignment = style.findElements('alignment').firstOrNull;
    if (alignment == null) {
      style.children.add(
        XmlElement(XmlName.parts('alignment'), [
          XmlAttribute(XmlName.parts('wrapText'), '1'),
          XmlAttribute(XmlName.parts('vertical'), 'center'),
        ]),
      );
    } else {
      alignment.setAttribute('wrapText', '1');
    }
    final styleId = xfs.childElements.length;
    xfs.children.add(style);
    xfs.setAttribute('count', '${styleId + 1}');
    c.setAttribute('s', '$styleId');
  }

  void enlargeStatementFonts() {
    final fonts = styles.findAllElements('fonts').single;
    for (final font in fonts.childElements) {
      final size = font.findElements('sz').firstOrNull;
      final value = double.tryParse(size?.getAttribute('val') ?? '');
      if (size != null && value != null && value <= 8) {
        size.setAttribute('val', '${value + 1}');
      }
    }
  }

  void useLedgerTypography() {
    final fonts = styles.findAllElements('fonts').single;
    for (final font in fonts.childElements) {
      final name = font.findElements('name').firstOrNull;
      if (name != null) {
        name.setAttribute('val', 'Arial');
      } else {
        font.children.add(
          XmlElement(XmlName.parts('name'), [
            XmlAttribute(XmlName.parts('val'), 'Arial'),
          ]),
        );
      }
    }
  }

  void widenLedgerDates() {
    final columns = sheet.findAllElements('cols').single;
    for (final column in columns.findElements('col')) {
      final min = column.getAttribute('min');
      if (min == '6') {
        column.setAttribute('width', '20');
        column.setAttribute('customWidth', '1');
      } else if (min == '7' && column.getAttribute('max') == '8') {
        column.setAttribute('width', '10');
        column.setAttribute('customWidth', '1');
      }
    }
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

/// Creates one workbook with a separate worksheet for each month.
Future<Uint8List> annualLedgerTemplateXlsx(
  Map<int, List<SalesLedgerEntry>> monthlyItems,
  int year,
) async {
  final template = (await rootBundle.load('assets/templates/ledger.xlsx'))
      .buffer
      .asUint8List();
  final base = SalesTemplateWorkbook(template);
  final sheets = <XmlDocument>[];
  final combined = <SalesLedgerEntry>[
    for (var month = 1; month <= 12; month++)
      ...(monthlyItems[month] ?? const <SalesLedgerEntry>[]),
  ];
  final combinedBytes = buildLedgerTemplate(template, combined, DateTime(year, 12));
  final combinedArchive = ZipDecoder().decodeBytes(combinedBytes);
  sheets.add(XmlDocument.parse(utf8.decode(
    combinedArchive.findFile('xl/worksheets/sheet1.xml')!.content,
  )));
  for (var month = 1; month <= 12; month++) {
    final bytes = buildLedgerTemplate(
      template,
      monthlyItems[month] ?? const [],
      DateTime(year, month),
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final sheet = archive.findFile('xl/worksheets/sheet1.xml');
    sheets.add(XmlDocument.parse(utf8.decode(sheet!.content)));
  }
  return base.export(
    sheets: sheets,
    names: ['통합', for (var month = 1; month <= 12; month++) '$month월'],
    areas: List.filled(13, '\$A\$1:\$V\$2000'),
  );
}

Uint8List buildLedgerTemplate(
  Uint8List template,
  List<SalesLedgerEntry> items,
  DateTime month,
) {
  items = [...items]..sort(compareSalesLedgerEntries);
  final book = SalesTemplateWorkbook(template);
  book.useLedgerTypography();
  book.widenLedgerDates();
  final prototype = book.row(2).copy();
  final summary = book.row(3).copy();
  book.data.children.removeWhere(
    (e) => e is XmlElement && int.parse(e.getAttribute('r')!) > 1,
  );
  final contractors = <String, List<SalesLedgerEntry>>{};
  final partners = <String, List<SalesLedgerEntry>>{};
  final projects = <String, List<SalesLedgerEntry>>{};
  for (final item in items) {
    contractors.putIfAbsent(item.contractor, () => []).add(item);
    partners.putIfAbsent(item.partner, () => []).add(item);
    projects.putIfAbsent(item.projectName, () => []).add(item);
  }
  final mainTotal = items.length + 2;
  final contractorTotal = 3 + contractors.length;
  final partnerTitle = contractorTotal + 2;
  final partnerTotal = partnerTitle + 2 + partners.length;
  final categoryTitle = partnerTotal + 2;
  final categoryTotal = categoryTitle + 4;
  final headquartersTitle = categoryTotal + 2;
  final headquartersTotal = headquartersTitle + 4;
  final franchiseTitle = headquartersTotal + 2;
  final franchiseTotal = franchiseTitle + 4;
  final siteTitle = franchiseTotal + 2;
  final siteTotal = siteTitle + 5;
  final projectTotal = 3 + projects.length;
  final sectionGaps = {
    contractorTotal + 1,
    partnerTotal + 1,
    categoryTotal + 1,
    headquartersTotal + 1,
    franchiseTotal + 1,
  };
  final count = [
    mainTotal,
    siteTotal,
    projectTotal,
  ].reduce((a, b) => a > b ? a : b);
  for (var r = 2; r <= count; r++) {
    book.cloneRow(r == 2 ? prototype : summary, r);
    book.row(r).children.removeWhere((node) {
      if (node is! XmlElement || node.name.local != 'c') return false;
      final column = SalesTemplateWorkbook.columnNumber(
        node.getAttribute('r')!,
      );
      return (r > mainTotal && column <= 14) ||
          (column >= 16 &&
              column <= 18 &&
              (sectionGaps.contains(r) || r > siteTotal)) ||
          (column >= 20 && column <= 22 && r > projectTotal);
    });
    if (r > mainTotal) {
      continue;
    }
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
    if (item.category == '가맹') {
      book.color('B$r', 'FFF4B544', textColor: 'FF5C3A00');
      book.color('N$r', 'FFF4B544', textColor: 'FF5C3A00');
    }
    // 계산서 발행처에 해당하는 시공사 또는 협력사 칸만 같은 초록색으로 표시한다.
    final issuerColumn = item.invoiceIssuerType == '시공사' ? 'C' :
        (item.invoiceIssuerType == '협력사' ? 'D' : null);
    if (issuerColumn != null) {
      book.color('${issuerColumn}$r', 'FFDEF0E4', textColor: 'FF245B39');
    }
    if (item.billingDate != null) {
      book.color('G$r', 'FFF9E7AD', textColor: 'FF6D5010');
    }
    final statusColor = switch (item.status) {
      '신규' => 'FFBBD6F6',
      '진행' => 'FFA8DBB9',
      '종료' => 'FFF3BABA',
      _ => null,
    };
    if (statusColor != null) {
      final statusText = switch (item.status) {
        '진행' => 'FF14532D',
        '종료' => 'FF842020',
        _ => 'FF174A7E',
      };
      book.color('L$r', statusColor, textColor: statusText);
    }
  }
  final end = items.length + 1;
  final totalSupply = items.fold<int>(0, (s, e) => s + e.supplyAmount);
  void styleLike(String target, String source) =>
      book.cell(target).setAttribute('s', book.cell(source).getAttribute('s')!);
  void merge(String range) {
    final merges = book.sheet.findAllElements('mergeCells').single;
    merges.children.add(
      XmlElement(XmlName.parts('mergeCell'), [
        XmlAttribute(XmlName.parts('ref'), range),
      ]),
    );
    merges.setAttribute('count', '${merges.childElements.length}');
  }

  void title(int row, String value) {
    for (final column in ['P', 'Q', 'R']) {
      styleLike('$column$row', '${column}1');
    }
    book.set('P$row', value);
    if (row != 1) merge('P$row:R$row');
  }

  void header(int row, String first, String second, String third) {
    for (final column in ['P', 'Q', 'R']) {
      styleLike('$column$row', '${column}2');
    }
    book.set('P$row', first);
    book.set('Q$row', second);
    book.set('R$row', third);
  }

  void total(int row, int quantity, int amount) {
    book.set('P$row', '합계');
    book.set('Q$row', quantity);
    book.set('R$row', amount);
    for (final column in ['P', 'Q', 'R']) {
      book.color('$column$row', 'FFE5E7EB', textColor: 'FF111827');
    }
  }

  void groupedTable(
    int titleRow,
    String heading,
    String firstHeader,
    String sourceColumn,
    Map<String, List<SalesLedgerEntry>> groups,
  ) {
    title(titleRow, heading);
    header(titleRow + 1, firstHeader, '기기수량', '금액');
    var row = titleRow + 2;
    for (final group in groups.entries) {
      book.set('P$row', group.key);
      book.set(
        'Q$row',
        group.value.length,
        formula: items.isEmpty
            ? null
            : 'COUNTIF(${sourceColumn}2:$sourceColumn$end,P$row)',
      );
      book.set(
        'R$row',
        group.value.fold<int>(0, (sum, item) => sum + item.supplyAmount),
        formula: items.isEmpty
            ? null
            : 'SUMIF(${sourceColumn}2:$sourceColumn$end,P$row,J2:J$end)',
      );
      row++;
    }
    total(row, items.length, totalSupply);
  }

  groupedTable(1, '${month.month}월 시공사별 집계표', '시공사', 'C', contractors);
  groupedTable(partnerTitle, '${month.month}월 협력사별 집계표', '협력사', 'D', partners);

  title(categoryTitle, '${month.month}월 본부, 가맹점 집계표');
  header(categoryTitle + 1, '가맹점상호', '기기', '금액');
  for (final (offset, category, label) in [(2, '본사', '본부'), (3, '가맹', '가맹점')]) {
    final row = categoryTitle + offset;
    final selected = items.where((item) => item.category == category).toList();
    book.set('P$row', label);
    book.set(
      'Q$row',
      selected.length,
      formula: items.isEmpty ? null : 'COUNTIF(N2:N$end,"$category")',
    );
    book.set(
      'R$row',
      selected.fold<int>(0, (sum, item) => sum + item.supplyAmount),
      formula: items.isEmpty ? null : 'SUMIF(N2:N$end,"$category",J2:J$end)',
    );
  }
  final categorized = items
      .where((item) => item.category == '본사' || item.category == '가맹')
      .toList();
  total(
    categoryTotal,
    categorized.length,
    categorized.fold<int>(0, (sum, item) => sum + item.supplyAmount),
  );

  const statuses = ['진행', '신규', '종료'];
  void statusColor(String address, String status) {
    final (fill, text) = switch (status) {
      '진행' => ('FFA8DBB9', 'FF14532D'),
      '신규' => ('FFBBD6F6', 'FF174A7E'),
      _ => ('FFF3BABA', 'FF842020'),
    };
    book.color(address, fill, textColor: text);
  }

  void progressTable(int titleRow, String category, String label) {
    title(titleRow, '${month.month}월 $label 진행상황');
    for (var i = 0; i < statuses.length; i++) {
      final row = titleRow + 1 + i;
      final status = statuses[i];
      book.set('P$row', label);
      book.set('Q$row', status);
      book.set(
        'R$row',
        items
            .where((item) => item.category == category && item.status == status)
            .length,
        formula: items.isEmpty
            ? null
            : 'COUNTIFS(N2:N$end,"$category",L2:L$end,Q$row)',
      );
      statusColor('Q$row', status);
    }
    final totalRow = titleRow + 4;
    book.set('P$totalRow', '합계');
    book.set(
      'R$totalRow',
      items.where((item) => item.category == category).length,
      formula: 'SUM(R${titleRow + 1}:R${titleRow + 3})',
    );
    for (final column in ['P', 'Q', 'R']) {
      book.color('$column$totalRow', 'FFE5E7EB', textColor: 'FF111827');
    }
    merge('P$totalRow:Q$totalRow');
  }

  progressTable(headquartersTitle, '본사', '본부');
  progressTable(franchiseTitle, '가맹', '가맹점');

  title(siteTitle, '${month.month}월 현장상황');
  header(siteTitle + 1, '구분', '상황', '수량');
  for (var i = 0; i < statuses.length; i++) {
    final row = siteTitle + 2 + i;
    final status = statuses[i];
    book.set('P$row', '전체');
    book.set('Q$row', status);
    book.set(
      'R$row',
      items.where((item) => item.status == status).length,
      formula: items.isEmpty ? null : 'COUNTIF(L2:L$end,Q$row)',
    );
    statusColor('Q$row', status);
  }
  book.set('P$siteTotal', '합계');
  book.set(
    'R$siteTotal',
    items.length,
    formula: 'SUM(R${siteTitle + 2}:R${siteTitle + 4})',
  );
  for (final column in ['P', 'Q', 'R']) {
    book.color('$column$siteTotal', 'FFE5E7EB', textColor: 'FF111827');
  }
  merge('P$siteTotal:Q$siteTotal');

  book.set('T1', '현장별 집계표');
  for (final entry in {'T2': '현장명', 'U2': '기기수량', 'V2': '공급가액'}.entries) {
    book.set(entry.key, entry.value);
  }
  var projectRow = 3;
  for (final group in projects.entries) {
    book.set('T$projectRow', group.key);
    book.set(
      'U$projectRow',
      group.value.length,
      formula: 'COUNTIF(B2:B$end,T$projectRow)',
    );
    book.set(
      'V$projectRow',
      group.value.fold<int>(0, (sum, item) => sum + item.supplyAmount),
      formula: 'SUMIF(B2:B$end,T$projectRow,J2:J$end)',
    );
    projectRow++;
  }
  book.set('T$projectRow', '합계');
  book.set('U$projectRow', items.length);
  book.set('V$projectRow', totalSupply);
  book.set('B${items.length + 2}', '합계');
  book.set(
    'J${items.length + 2}',
    totalSupply,
    formula: items.isEmpty ? '0' : 'SUM(J2:J${items.length + 1})',
  );
  book.sheet
      .findAllElements('dimension')
      .single
      .setAttribute('ref', 'A1:V$count');
  book.setAutoFilter('A1:N${items.length + 1}');
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
  book.enlargeStatementFonts();
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
        statementItemNote(item),
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
    final pageItems = statement.items.skip(page * 17).take(17);
    final footerNotes = statementFooterNotes(pageItems);
    if (footerNotes.isNotEmpty) {
      book.set('A31', footerNotes.join('\n'));
      for (final column in const ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
        book.color('${column}31', 'FFEAF0DF');
      }
      book.wrapText('A31', fontSize: 10, textColor: 'FFCC0000');
      book.row(31).setAttribute('ht', '48');
      book.row(31).setAttribute('customHeight', '1');
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
