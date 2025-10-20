// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

/// {@template conditional_guard}
/// Applies a `RouteGuard` conditionally using include and exclude rules.
/// {@endtemplate}
///
/// Behavior:
/// - Inclusion rules (`includedPaths`/`includedPatterns`) restrict where the guard runs.
/// - Exclusion rules (`excludedPaths`/`excludedPatterns`) always skip the guard.
/// - With no inclusion rules, the guard applies globally (except excluded).
///
/// Quick start:
/// ```dart
/// // Include only specific routes
/// ConditionalGuard.including(
///   guard: AuthGuard(),
///   paths: [RegExp(r'^/user/.*')],
/// );
///
/// // Exclude a few routes from a global guard
/// ConditionalGuard.excluding(
///   guard: AuthGuard(),
///   paths: ['/login', '/register'],
/// );
/// ```
///
/// Tip: Prefer using only include or only exclude in most cases.
///
class ConditionalGuard extends RouteGuard {
  /// {@macro conditional_guard}
  const ConditionalGuard({
    required this.guard,
    this.includedPaths = const [],
    this.includedPatterns = const [],
    this.excludedPaths = const [],
    this.excludedPatterns = const [],
  });

  /// Creates a [ConditionalGuard] that applies the guard only to specified
  /// paths.
  ///
  /// The guard will only execute for paths matching the provided [paths]
  /// patterns. Paths can be exact strings, glob patterns (with `*` or `?`),
  /// or [RegExp].
  factory ConditionalGuard.including({
    required RouteGuard guard,
    List<Pattern> paths = const [],
  }) {
    final tuples = _splitPatterns(paths);
    return ConditionalGuard(
      guard: guard,
      includedPaths: tuples.$1,
      includedPatterns: tuples.$2,
    );
  }

  /// Creates a [ConditionalGuard] that applies the guard to all paths except
  /// those specified.
  ///
  /// The guard will execute for all paths except those matching the provided
  /// [paths] patterns. Paths can be exact strings, glob patterns (with `*` or
  /// `?`), or [RegExp].
  factory ConditionalGuard.excluding({
    required RouteGuard guard,
    List<Pattern> paths = const [],
  }) {
    final tuples = _splitPatterns(paths);
    return ConditionalGuard(
      guard: guard,
      excludedPaths: tuples.$1,
      excludedPatterns: tuples.$2,
    );
  }

  /// The guard to execute when conditions are met.
  final RouteGuard guard;

  /// List of exact paths where the guard should apply.
  ///
  /// If empty, guard applies to all paths (unless excluded).
  final List<String> includedPaths;

  /// List of regular expression patterns for paths where the guard should
  /// apply.
  ///
  /// If empty, guard applies to all paths (unless excluded).
  final List<RegExp> includedPatterns;

  /// List of exact paths that should be excluded from guard execution.
  ///
  /// Takes precedence over inclusion rules.
  final List<String> excludedPaths;

  /// List of regular expression patterns for paths to exclude.
  ///
  /// Takes precedence over inclusion rules.
  final List<RegExp> excludedPatterns;

  /// Splits provided patterns into exact string paths and regex patterns.
  static (List<String>, List<RegExp>) _splitPatterns(List<Pattern> patterns) {
    final exact = <String>[];
    final regexes = <RegExp>[];
    for (final p in patterns) {
      if (p is RegExp) {
        regexes.add(p);
      } else if (p is String) {
        // Treat wildcard strings as glob-like and convert to RegExp
        if (p.contains('*') || p.contains('?')) {
          regexes.add(_globToRegExp(p));
        } else {
          exact.add(p);
        }
      }
    }
    return (exact, regexes);
  }

  /// Converts a simple glob pattern to a `RegExp`.
  ///
  /// Supported:
  /// - `*` matches any sequence except '/'
  /// - `**` matches any sequence including '/'
  /// - `?` matches a single character except '/'
  ///
  static RegExp _globToRegExp(String pattern) {
    final buffer = StringBuffer('^');
    var i = 0;

    // Regex meta characters to escape when used literally
    const metaChars = {
      '.',
      '^',
      r'$',
      '+',
      '{',
      '}',
      '(',
      ')',
      '|',
      '[',
      ']',
      r'\',
    };

    while (i < pattern.length) {
      final c = pattern[i];

      if (c == '*') {
        final isDouble = i + 1 < pattern.length && pattern[i + 1] == '*';
        if (isDouble) {
          buffer.write('.*');
          i += 2;
        } else {
          buffer.write('[^/]*');
          i += 1;
        }
        continue;
      }

      if (c == '?') {
        buffer.write('[^/]');
        i += 1;
        continue;
      }

      if (metaChars.contains(c)) buffer.write(r'\');
      buffer.write(c);
      i += 1;
    }

    buffer.write(r'$');
    return RegExp(buffer.toString());
  }

  /// Checks if the given path should be excluded from guard execution
  bool _isExcluded(String path) {
    // Check exact path exclusions
    if (excludedPaths.contains(path)) {
      return true;
    }

    // Check pattern exclusions
    for (final pattern in excludedPatterns) {
      if (pattern.hasMatch(path)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if the given path should be included for guard execution
  bool _isIncluded(String path) {
    // If no inclusion rules are specified, include all paths by default
    if (includedPaths.isEmpty && includedPatterns.isEmpty) {
      return true;
    }

    // Check exact path inclusions
    if (includedPaths.contains(path)) {
      return true;
    }

    // Check pattern inclusions
    for (final pattern in includedPatterns) {
      if (pattern.hasMatch(path)) {
        return true;
      }
    }

    return false;
  }

  /// Determines if the guard should be applied to the given path
  bool _shouldApplyGuard(String path) {
    // First check if the path is excluded (exclusion takes precedence)
    if (_isExcluded(path)) {
      return false;
    }

    // Then check if the path is included
    return _isIncluded(path);
  }

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;

    // If this path should not have the guard applied, allow navigation
    if (!_shouldApplyGuard(path)) {
      resolver.next();
      return;
    }

    // Otherwise, execute the wrapped guard
    await guard.onNavigation(resolver, context, state);
  }
}
