import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class PlatformDownloadHelper {
  static Future<String> saveBytes(String fileName, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
