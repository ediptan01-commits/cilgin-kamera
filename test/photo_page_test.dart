import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cilgin_kamera/main.dart';

void main() {
  testWidgets('Review exposes Turkish save and share actions', (tester) async {
    final dir = Directory.systemTemp.createTempSync('cilgin_test');
    final file = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 20, height: 20)));
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(MaterialApp(home: PhotoPage(file: file)));
    await tester.pumpAndSettle();
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
