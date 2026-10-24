import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cilgin_kamera/effects.dart';

void main() {
  Uint8List fixture() {
    final photo = img.Image(width: 40, height: 20);
    for (final p in photo) {
      p.setRgb(p.x < 20 ? 200 : 20, 80, p.x < 20 ? 20 : 200);
    }
    return Uint8List.fromList(img.encodePng(photo));
  }

  test('Saved JPEG contains grayscale pixels, not original colors', () {
    final result = img.decodeJpg(
      renderPhoto((fixture(), PhotoEffect.mono, false)),
    )!;
    final p = result.getPixel(5, 5);
    expect((p.r - p.g).abs(), lessThanOrEqualTo(2));
    expect((p.g - p.b).abs(), lessThanOrEqualTo(2));
  });
  test('Mirror moves the right blue patch to the left in the actual JPEG', () {
    final result = img.decodeJpg(
      renderPhoto((fixture(), PhotoEffect.original, true)),
    )!;
    expect(result.getPixel(5, 5).b, greaterThan(180));
    expect(result.getPixel(35, 5).r, greaterThan(180));
    expect(result.width, 40);
    expect(result.height, 20);
  });
  test('Warm and cool transformations persist in exported pixels', () {
    final plain = img
        .decodeJpg(renderPhoto((fixture(), PhotoEffect.original, false)))!
        .getPixel(5, 5);
    final warm = img
        .decodeJpg(renderPhoto((fixture(), PhotoEffect.warm, false)))!
        .getPixel(5, 5);
    final cool = img
        .decodeJpg(renderPhoto((fixture(), PhotoEffect.cool, false)))!
        .getPixel(5, 5);
    expect(warm.r, greaterThan(plain.r));
    expect(cool.b, greaterThan(plain.b));
  });
  test('Malformed camera bytes fail explicitly', () {
    expect(
      () => renderPhoto((Uint8List(0), PhotoEffect.original, false)),
      throwsFormatException,
    );
  });
  test(
    'EXIF rotation is baked into pixels and source metadata is stripped',
    () {
      final source = img.Image(width: 40, height: 20);
      source.exif.imageIfd.orientation = 6;
      source.exif.imageIfd.make = 'Private camera metadata';
      final input = Uint8List.fromList(img.encodeJpg(source));
      expect(img.decodeJpg(input)!.exif.imageIfd.make, isNotNull);
      final output = img.decodeJpg(
        renderPhoto((input, PhotoEffect.original, false)),
      )!;
      expect(output.width, 20);
      expect(output.height, 40);
      expect(output.exif.imageIfd.make, isNull);
      expect(output.exif.imageIfd.orientation, isNull);
    },
  );
  test('Every preview color matrix has the expected 20 entries', () {
    for (final effect in PhotoEffect.values) {
      expect(effect.matrix.length, 20);
    }
  });
}
