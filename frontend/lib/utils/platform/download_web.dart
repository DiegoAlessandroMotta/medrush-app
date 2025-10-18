import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

class PlatformDownloadHelper {
  static Future<String> saveBytes(String fileName, Uint8List bytes) async {
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return fileName;
  }
}
