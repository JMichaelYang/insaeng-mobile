import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class TolerantGoldenComparator extends LocalFileComparator {
  new(super.testFile);

  static const int channelTolerance = 8;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await getGoldenBytes(golden);
    final result = await GoldenFileComparator.compareLists(imageBytes, goldenBytes);
    if (result.passed || await _withinTolerance(imageBytes, goldenBytes)) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }

  Future<bool> _withinTolerance(List<int> testBytes, List<int> goldenBytes) async {
    final test = await _decode(testBytes);
    final golden = await _decode(goldenBytes);
    if (test.width != golden.width || test.height != golden.height) {
      return false;
    }
    for (var i = 0; i < test.pixels.length; i++) {
      if ((test.pixels[i] - golden.pixels[i]).abs() > channelTolerance) {
        return false;
      }
    }
    return true;
  }

  Future<({int width, int height, Uint8List pixels})> _decode(List<int> bytes) async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData();
    final decoded = (width: image.width, height: image.height, pixels: data!.buffer.asUint8List());
    image.dispose();
    codec.dispose();
    return decoded;
  }
}
