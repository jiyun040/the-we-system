import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_we_system/common/components/the_we_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('더우리기술 로고가 Flutter 에셋 번들에 포함된다', () async {
    final data = await rootBundle.load(TheWeLogo.assetPath);

    expect(data.lengthInBytes, greaterThan(0));
  });
}
