import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'xfile_image_io.dart' if (dart.library.html) 'xfile_image_web.dart';

Widget buildLocalImage(
  XFile file, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return buildLocalImageImpl(
    file,
    fit: fit,
    width: width,
    height: height,
  );
}
