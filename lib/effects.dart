import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum PhotoEffect {
  original('Doğal', [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  mono('Siyah beyaz', [
    .299,
    .587,
    .114,
    0,
    0,
    .299,
    .587,
    .114,
    0,
    0,
    .299,
    .587,
    .114,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  warm('Gün batımı', [
    1,
    0,
    0,
    0,
    22,
    0,
    1,
    0,
    0,
    6,
    0,
    0,
    1,
    0,
    -18,
    0,
    0,
    0,
    1,
    0,
  ]),
  cool('Buz gibi', [
    1,
    0,
    0,
    0,
    -12,
    0,
    1,
    0,
    0,
    6,
    0,
    0,
    1,
    0,
    24,
    0,
    0,
    0,
    1,
    0,
  ]);

  const PhotoEffect(this.label, this.matrix);
  final String label;
  final List<double> matrix;
}

// The same matrix drives Flutter's preview and the exported pixels.
Uint8List renderPhoto((Uint8List, PhotoEffect, bool) request) {
  final (bytes, effect, mirror) = request;
  if (bytes.length < 4) throw const FormatException('Fotoğraf okunamadı.');
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Fotoğraf okunamadı.');
  var photo = img.bakeOrientation(decoded);
  // Bound memory and processing time on budget Android phones.
  if (photo.width > 2048 || photo.height > 2048) {
    photo = img.copyResize(
      photo,
      width: photo.width >= photo.height ? 2048 : null,
      height: photo.height > photo.width ? 2048 : null,
    );
  }
  if (mirror) photo = img.flipHorizontal(photo);
  final m = effect.matrix;
  for (final p in photo) {
    final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
    p
      ..r = (r * m[0] + g * m[1] + b * m[2] + m[4]).round().clamp(0, 255)
      ..g = (r * m[5] + g * m[6] + b * m[7] + m[9]).round().clamp(0, 255)
      ..b = (r * m[10] + g * m[11] + b * m[12] + m[14]).round().clamp(0, 255);
  }
  return Uint8List.fromList(img.encodeJpg(photo, quality: 92));
}
