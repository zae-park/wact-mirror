import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImageImpl(
  Uint8List bytes, {
  int quality = 80,
}) async {
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    quality: quality,
  );

  return Uint8List.fromList(result);
}
