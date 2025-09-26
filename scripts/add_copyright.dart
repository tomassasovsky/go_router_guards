#!/usr/bin/env dart
// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print scripts can print to console

import 'dart:io';

const String copyrightHeader = '''
// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

''';

void main(List<String> arguments) {
  addCopyrightHeaders();
}

void addCopyrightHeaders() {
  print('📝 Adding copyright headers to Dart files...');

  final dartFiles = findDartFiles();
  var addedCount = 0;
  var skippedCount = 0;

  for (final filePath in dartFiles) {
    if (addCopyrightToFile(filePath)) {
      addedCount++;
      print('✅ Added copyright header to: $filePath');
    } else {
      skippedCount++;
      print('⏭️  Skipped (already has header): $filePath');
    }
  }

  print('\n🎉 Complete!');
  print('  - Added copyright headers to $addedCount files');
  print('  - Skipped $skippedCount files (already had headers)');
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

bool addCopyrightToFile(String filePath) {
  final file = File(filePath);
  final content = file.readAsStringSync();

  if (content.trimLeft().startsWith('// Copyright 2025 Tomás Sasovsky')) {
    return false;
  }

  String newContent;

  // If file starts with a shebang, preserve it
  if (content.startsWith('#!')) {
    final lines = content.split('\n');
    final shebangLine = lines.first;
    final restOfFile = lines.skip(1).join('\n');

    // Remove leading empty lines after shebang
    final trimmedRest = restOfFile.trimLeft();

    newContent = '$shebangLine\n\n$copyrightHeader$trimmedRest';
  } else {
    // Remove leading whitespace and add copyright header
    final trimmedContent = content.trimLeft();
    newContent = '$copyrightHeader$trimmedContent';
  }

  file.writeAsStringSync(newContent);
  return true;
}
