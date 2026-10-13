import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Converts the sales document's table and heading layout to an OOXML workbook.
/// Strings are inline strings (never formulas); amounts remain numeric cells.
Uint8List salesXlsx(String document, {required String sheetName}) {
  final source = XmlDocument.parse(
    document
        .replaceAll('<meta charset="utf-8">', '<meta charset="utf-8"/>')
        .replaceAll('<br>', '\n'),
  );
  String escape(String text) => const HtmlEscape().convert(text);
  final rows = <String>[];
  final merges = <String>[];
  final body = source.findAllElements('body').single;
  final tables = body.findAllElements('table').toList();
  final columns = tables.isEmpty
      ? 8
      : tables.first
            .findElements('tr')
            .first
            .children
            .whereType<XmlElement>()
            .length;
  String column(int index) {
    var value = index + 1;
    var name = '';
    while (value > 0) {
      value--;
      name = String.fromCharCode(65 + value % 26) + name;
      value ~/= 26;
    }
    return name;
  }

  void row(List<XmlElement> cells, {bool merged = false}) {
    final number = rows.length + 1;
    final height = merged ? (cells.first.innerText.split('\n').length * 18 + 18) : 36;
    final output = StringBuffer('<row r="$number" ht="$height" customHeight="1">');
    for (var i = 0; i < cells.length; i++) {
      final element = cells[i];
      final text = element.innerText;
      final fill = element.getAttribute('class');
      final numeric = !merged && RegExp(r'^-?\d+(,\d{3})*$').hasMatch(text);
      final style = element.name.local == 'th'
          ? 1
          : fill == 'contractor'
          ? 2
          : fill == 'partner'
          ? 3
          : numeric
          ? 4
          : 0;
      final address = '${column(i)}$number';
      output.write(
        numeric
            ? '<c r="$address" s="$style"><v>${text.replaceAll(',', '')}</v></c>'
            : '<c r="$address" s="$style" t="inlineStr"><is><t xml:space="preserve">${escape(text)}</t></is></c>',
      );
    }
    output.write('</row>');
    rows.add(output.toString());
    if (merged) {
      merges.add('<mergeCell ref="A$number:${column(columns - 1)}$number"/>');
    }
  }

  for (final element in body.childElements) {
    if (element.name.local == 'table') {
      for (final tr in element.findElements('tr')) {
        row(tr.childElements.toList());
      }
    } else {
      row([element], merged: true);
    }
  }
  final archive = Archive();
  void add(String path, String xml) {
    final bytes = utf8.encode(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>$xml',
    );
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    '[Content_Types].xml',
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
  );
  add(
    '_rels/.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
  );
  add(
    'xl/workbook.xml',
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="${escape(sheetName)}" sheetId="1" r:id="rId1"/></sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
  );
  final fills = ['FFD9EFFB', 'FFE7EFFF', 'FFE8F5E9'];
  add(
    'xl/styles.xml',
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="1"><font><sz val="11"/><name val="맑은 고딕"/></font></fonts><fills count="5"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>${fills.map((c) => '<fill><patternFill patternType="solid"><fgColor rgb="$c"/><bgColor indexed="64"/></patternFill></fill>').join()}</fills><borders count="1"><border><left style="thin"/><right style="thin"/><top style="thin"/><bottom style="thin"/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="5">${[0, 2, 3, 4, 0].asMap().entries.map((e) => '<xf numFmtId="${e.key == 4 ? 3 : 0}" fontId="0" fillId="${e.value}" borderId="0" xfId="0" applyFill="1" applyNumberFormat="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>').join()}</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
  );
  add(
    'xl/worksheets/sheet1.xml',
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0"/></sheetViews><cols><col min="1" max="$columns" width="22" customWidth="1"/></cols><sheetData>${rows.join()}</sheetData>${merges.isEmpty ? '' : '<mergeCells count="${merges.length}">${merges.join()}</mergeCells>'}<pageMargins left="0.3" right="0.3" top="0.5" bottom="0.5" header="0.2" footer="0.2"/><pageSetup paperSize="9" orientation="landscape" fitToWidth="1" fitToHeight="0"/></worksheet>',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
