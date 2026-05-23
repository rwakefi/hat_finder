import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled image assets do not include reference videos', () {
    final imageDir = Directory('assets/images');
    final videos = imageDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final path = file.path.toLowerCase();
          return path.endsWith('.mp4') ||
              path.endsWith('.mov') ||
              path.endsWith('.m4v');
        })
        .map((file) => file.path)
        .toList();

    expect(videos, isEmpty);
  });
}
