// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:route_guards/route_guards.dart';

/// A specialized path matcher that handles inclusion and exclusion rules
/// for route filtering.
@immutable
class _PathMatcher {
  const _PathMatcher({
    required this.includedPaths,
    required this.includedPatterns,
    required this.excludedPaths,
    required this.excludedPatterns,
  });

  final Set<String> includedPaths;
  final List<RegExp> includedPatterns;
  final Set<String> excludedPaths;
  final List<RegExp> excludedPatterns;

  /// Checks if the given path should be excluded from guard execution
  bool isExcluded(String path) {
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
  bool isIncluded(String path) {
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
  bool shouldApplyGuard(String path) {
    // First check if the path is excluded (exclusion takes precedence)
    if (isExcluded(path)) {
      return false;
    }

    // Then check if the path is included
    return isIncluded(path);
  }
}

/// A guard that can be applied globally to all routes with inclusion and
/// exclusion capabilities.
///
/// This class wraps another guard and provides functionality to include or
/// exclude specific routes or route patterns from guard execution.
///
/// ## Usage Patterns
///
/// **Pure Inclusion** (targeted protection):
/// ```dart
/// ConditionalGuard(
///   guard: AuthGuard(),
///   includedPatterns: [RegExp(r'^/user/.*')], // Only user routes
/// )
/// ```
///
/// **Pure Exclusion** (global protection with exceptions):
/// ```dart
/// ConditionalGuard(
///   guard: AuthGuard(),
///   excludedPaths: ['/login', '/register'], // Everywhere except these
/// )
/// ```
///
/// **Mixed Rules** (inclusion with exceptions):
/// ```dart
/// ConditionalGuard(
///   guard: ApiKeyGuard(),
///   includedPatterns: [RegExp(r'^/api/.*')], // All API routes
///   excludedPaths: ['/api/health'], // Except health endpoints
/// )
/// ```
///
/// ## Rule Precedence
///
/// When both inclusion and exclusion rules are specified:
/// 1. **Exclusion takes precedence** - excluded paths are never guarded
/// 2. **Inclusion defines scope** - only included paths are considered
/// 3. **Result**: Guard applies to (included paths - excluded paths)
@immutable
class ConditionalGuard extends RouteGuard<Object, Object> {
  /// Creates a conditional guard with the specified inclusion and exclusion
  /// rules.
  ConditionalGuard({
    required this.guard,
    this.includedPaths = const [],
    this.includedPatterns = const [],
    this.excludedPaths = const [],
    this.excludedPatterns = const [],
  }) : _pathMatcher = _PathMatcher(
          includedPaths: includedPaths.toSet(),
          includedPatterns: includedPatterns,
          excludedPaths: excludedPaths.toSet(),
          excludedPatterns: excludedPatterns,
        );

  /// The underlying guard to execute when the route conditions are met
  final RouteGuard<Object, Object> guard;

  /// List of exact paths where the guard should apply
  /// If empty, guard applies to all paths (unless excluded)
  final List<String> includedPaths;

  /// List of regular expression patterns for paths where the guard should apply
  /// If empty, guard applies to all paths (unless excluded)
  final List<RegExp> includedPatterns;

  /// List of exact paths that should be excluded from guard execution
  /// Takes precedence over inclusion rules
  final List<String> excludedPaths;

  /// List of regular expression patterns for paths to exclude
  /// Takes precedence over inclusion rules
  final List<RegExp> excludedPatterns;

  /// Path matcher for efficient pattern matching
  final _PathMatcher _pathMatcher;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver<Object, Object> resolver,
    Object context,
    Object state,
  ) async {
    try {
      final goRouterState = state as GoRouterState;
      final path = goRouterState.uri.path;

      // If this path should not have the guard applied, allow navigation
      if (!_pathMatcher.shouldApplyGuard(path)) {
        resolver.next();
        return;
      }

      // Otherwise, execute the wrapped guard
      await guard.onNavigation(resolver, context, state);
    } on Exception catch (error, stackTrace) {
      // Log error for debugging purposes in development mode
      if (kDebugMode) {
        debugPrint('ConditionalGuard error: $error');
        debugPrint('Stack trace: $stackTrace');
      }

      // Block navigation on error to fail safely
      resolver.block();
    }
  }
}

/// Utilities for using route guards with regular (non-type-safe) GoRoute
/// objects.
///
/// This allows you to use the same guard logic whether you're using
/// TypedGoRoute or regular GoRoute definitions.
abstract class RouteGuardUtils {
  /// Creates a redirect function for a guard.
  ///
  /// This can be used with individual guards or complex combinations using
  /// [Guards.all], [Guards.anyOf], [Guards.oneOf].
  ///
  /// Example:
  /// ```dart
  /// GoRoute(
  ///   path: '/admin',
  ///   builder: (context, state) => const AdminScreen(),
  ///   redirect: RouteGuardUtils.createGuardRedirect(
  ///     Guards.all([
  ///       AuthenticationGuard(),
  ///       RoleGuard(['admin']),
  ///     ]),
  ///   ),
  /// )
  /// ```
  static FutureOr<String?> Function(BuildContext, GoRouterState)
      createGuardRedirect(
    RouteGuard<Object, Object> guard,
  ) {
    return (context, state) => _executeGuard(guard, context, state);
  }

  /// Execute a single guard and return redirect path if needed
  static FutureOr<String?> _executeGuard(
    RouteGuard<Object, Object> guard,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final result = await guard.executeWithResolver(context, state);
      return result.continueNavigation ? null : result.redirectPath;
    } on Exception catch (error, stackTrace) {
      // Log error for debugging purposes in development mode
      if (kDebugMode) {
        debugPrint('RouteGuardUtils guard execution error: $error');
        debugPrint('Stack trace: $stackTrace');
      }

      // Return null to allow navigation to continue in case of error
      // This provides a fail-safe behavior for guard execution failures
      return null;
    }
  }
}
