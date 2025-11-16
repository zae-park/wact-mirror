import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Widget buildLocalImageImpl(
  XFile file, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return Image.network(
    file.path,
    fit: fit,
    width: width,
    height: height,
  );
}
