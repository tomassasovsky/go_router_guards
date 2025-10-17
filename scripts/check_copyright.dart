#!/usr/bin/env dart
// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print scripts can print to console

import 'dart:io';

const String expectedCopyright = '''
// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.''';

void main(List<String> arguments) {
  final exitCode = checkCopyrightHeaders();
  exit(exitCode);
}

int checkCopyrightHeaders() {
  print('🔍 Checking copyright headers in Dart files...');

  final dartFiles = findDartFiles();
  final filesWithoutCopyright = <String>[];

  for (final file in dartFiles) {
    if (!hasCopyrightHeader(file)) {
      filesWithoutCopyright.add(file);
    }
  }

  if (filesWithoutCopyright.isEmpty) {
    print('✅ All Dart files have proper copyright headers!');
    return 0;
  } else {
    print(
      '❌ Found ${filesWithoutCopyright.length} files without '
      'copyright headers:',
    );
    for (final file in filesWithoutCopyright) {
      print('  - $file');
    }
    print(
      '\n💡 Run `dart scripts/add_copyright.dart` to add copyright '
      'headers to all files.',
    );
    return 1;
  }
}

List<String> findDartFiles() {
  final dartFiles = <String>[];

  final directories = [
    'packages/go_router_guards/lib',
    'packages/go_router_guards/test',
    'packages/route_guards/lib',
    'packages/route_guards/test',
    'example/lib',
    'example/test',
  ];

  for (final dirPath in directories) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // Skip generated files
          if (!entity.path.endsWith('.g.dart') &&
              !entity.path.endsWith('.freezed.dart') &&
              !entity.path.endsWith('.gr.dart')) {
            dartFiles.add(entity.path);
          }
        }
      }
    }
  }

  return dartFiles;
}

bool hasCopyrightHeader(String filePath) {
  final file = File(filePath);
  final content = file.readAsStringSync();

  // Check if file starts with the expected copyright header
  return content.trimLeft().startsWith(expectedCopyright);
}
