import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:the_we_system/common/components/the_we_snack_bar.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/features/approval/domain/entities/document/approval_document.dart';

const materialPhotoBeforeKey = 'materialPhotoBefore';
const materialPhotoAfterKey = 'materialPhotoAfter';

bool isMaterialPurchaseDocument(ApprovalDocument document) =>
    document.form == '자재구매신청서';

List<int>? materialPhotoBytes(String? dataUri) {
  if (dataUri == null || !dataUri.startsWith('data:image/')) return null;
  final separator = dataUri.indexOf(';base64,');
  if (separator < 0) return null;
  try {
    return base64Decode(dataUri.substring(separator + 8));
  } on FormatException {
    return null;
  }
}

class ApprovalMaterialPhotoSection extends StatelessWidget {
  const ApprovalMaterialPhotoSection({
    super.key,
    required this.document,
    this.onChanged,
  });

  final ApprovalDocument document;
  final void Function(String key, String value)? onChanged;

  Future<void> _pick(BuildContext context, String key) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: '사진', extensions: ['jpg', 'jpeg', 'png', 'webp']),
      ],
    );
    if (file == null) return;
    final source = await file.readAsBytes();
    if (source.lengthInBytes > 10 * 1024 * 1024) {
      if (context.mounted) {
        showTheWeSnackBar(
          context,
          message: '원본 사진은 10MB 이하만 등록할 수 있습니다.',
          type: TheWeSnackBarType.error,
        );
      }
      return;
    }
    final bytes = await compute(normalizeMaterialPhoto, source);
    if (bytes == null) {
      if (context.mounted) {
        showTheWeSnackBar(
          context,
          message: '사진을 읽거나 최적화하지 못했습니다. 다른 사진을 선택해 주세요.',
          type: TheWeSnackBarType.error,
        );
      }
      return;
    }
    onChanged?.call(key, 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final photos = [
      (materialPhotoBeforeKey, '자재 반입 전'),
      (materialPhotoAfterKey, '자재 반입 후'),
    ];
    final cards = photos.map((photo) {
      final bytes = materialPhotoBytes(document.formFields[photo.$1]);
      return Container(
        key: ValueKey('material-photo-${photo.$1}'),
        decoration: BoxDecoration(
          border: Border.all(color: TheWeColor.black900),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: bytes == null
                  ? Center(child: Text('사진 없음', style: TheWeTextStyle.body))
                  : Image.memory(
                      Uint8List.fromList(bytes),
                      fit: BoxFit.contain,
                    ),
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: TheWeColor.black900)),
              ),
              child: Text(photo.$2, style: TheWeTextStyle.body),
            ),
            if (onChanged != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pick(context, photo.$1),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(bytes == null ? '사진 선택' : '사진 변경'),
                    ),
                    if (bytes != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: '사진 삭제',
                        onPressed: () => onChanged?.call(photo.$1, ''),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text('2. 반입 및 비치 대지 (사진 대지)', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        if (narrow)
          Column(children: [cards[0], const SizedBox(height: 12), cards[1]])
        else
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
      ],
    );
  }
}

Uint8List? normalizeMaterialPhoto(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) return null;
  final longestSide = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = longestSide > 1600
      ? img.copyResize(
          decoded,
          width: (decoded.width * 1600 / longestSide).round(),
          height: (decoded.height * 1600 / longestSide).round(),
        )
      : decoded;
  for (final quality in [80, 65, 50]) {
    final encoded = img.encodeJpg(resized, quality: quality);
    if (encoded.lengthInBytes <= 1500000) return encoded;
  }
  return null;
}
