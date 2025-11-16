import 'dart:typed_data';

import 'image_compression_io.dart'
    if (dart.library.html) 'image_compression_stub.dart';

Future<Uint8List> compressImage(
  Uint8List bytes, {
  int quality = 80,
}) {
  return compressImageImpl(
    bytes,
    quality: quality,
  );
}
