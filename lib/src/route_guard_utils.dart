import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

/// A guard that can be applied globally to all routes with inclusion and
/// exclusion capabilities.
///
/// This class wraps another guard and provides functionality to include or
/// exclude specific routes or route patterns from guard execution.
///
/// ## Usage Recommendations
///
/// **Start Simple**: Most use cases need only inclusion OR exclusion, not both.
///
/// **Pure Inclusion** (recommended for targeted protection):
/// ```dart
/// ConditionalGuard(
///   guard: AuthGuard(),
///   includedPatterns: [RegExp(r'^/user/.*')], // Only user routes
/// )
/// ```
///
/// **Pure Exclusion** (recommended for global protection with exceptions):
/// ```dart
/// ConditionalGuard(
///   guard: AuthGuard(),
///   excludedPaths: ['/login', '/register'], // Everywhere except these
/// )
/// ```
///
/// **Mixed Rules** (advanced use cases only):
/// Use when you need to apply guards to a pattern but exclude specific routes
/// within that pattern.
/// ```dart
/// ConditionalGuard(
///   guard: AdminGuard(),
///   includedPatterns: [RegExp(r'^/admin/.*')], // All admin routes
///   excludedPaths: ['/admin/status'], // Except public monitoring
/// )
/// ```
///
/// ## Inclusion vs Exclusion Logic
/// - If `includedPaths` or `includedPatterns` are provided, the guard will
/// ONLY apply to matching routes
/// - If `excludedPaths` or `excludedPatterns` are provided, the guard will
/// apply to all routes EXCEPT matching ones
/// - If both inclusion and exclusion rules are provided, exclusion takes
/// precedence (excluded routes will never have the guard applied)
/// - If no inclusion rules are provided, the guard applies to all routes
/// (global behavior)
///
/// ## Alternative Approaches
///
/// Consider these alternatives before using mixed rules:
/// - **Multiple Guards**: Apply different guards to different route patterns
/// - **Custom Guard Logic**: Write a guard that handles complex logic
/// internally
/// - **Route Restructuring**: Organize routes so simpler patterns work
///
class ConditionalGuard extends RouteGuard {
  /// Creates a conditional guard with the specified inclusion and exclusion
  /// rules.
  ///
  /// [guard] - The underlying guard to execute when conditions are met
  /// [includedPaths] - Exact paths where the guard should apply (if empty,
  /// applies to all paths)
  /// [includedPatterns] - Regular expression patterns for paths where the
  /// guard should apply
  /// [excludedPaths] - Exact paths to exclude from guard execution (takes
  /// precedence over inclusion)
  /// [excludedPatterns] - Regular expression patterns for paths to exclude
  /// (takes precedence over inclusion)
  const ConditionalGuard({
    required this.guard,
    this.includedPaths = const [],
    this.includedPatterns = const [],
    this.excludedPaths = const [],
    this.excludedPatterns = const [],
  });

  /// The underlying guard to execute when the route conditions are met
  final RouteGuard guard;

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

/// Utilities for using route guards with regular (non-type-safe) GoRoute
/// objects.
///
/// This allows you to use the same guard logic whether you're using
/// TypedGoRoute or regular GoRoute definitions.
abstract class RouteGuardUtils {
  /// Creates a redirect function for a guard.
  ///
  /// This can also be used with a complex combination of guards.
  /// You can use [Guards.all], [Guards.anyOf], [Guards.oneOf] to create
  /// a complex guard.
  ///
  /// Example:
  /// ```dart
  /// GoRoute(
  ///   path: '/admin',
  ///   builder: (context, state) => const AdminScreen(),
  ///   redirect: RouteGuardUtils.createGuardRedirect(
  ///     Guards.all([
  ///       AuthenticationGuard(),
  ///       EnhancedRoleGuard(['admin']),
  ///     ]),
  ///   ),
  /// )
  /// ```
  ///
  /// You can also use [Guards.all], [Guards.anyOf], [Guards.oneOf] to create
  /// a complex guard.
  ///
  /// Example:
  /// ```dart
  /// GoRoute(
  ///   path: '/admin',
  ///   builder: (context, state) => const AdminScreen(),
  ///   redirect: RouteGuardUtils.createGuardRedirect(AdminGuard()),
  /// )
  /// ```
  static FutureOr<String?> Function(BuildContext, GoRouterState)
      createGuardRedirect(
    RouteGuard guard,
  ) {
    return (context, state) => _executeGuard(guard, context, state);
  }

  /// Execute a single guard and return redirect path if needed
  static FutureOr<String?> _executeGuard(
    RouteGuard guard,
    BuildContext context,
    GoRouterState state,
  ) async {
    final resolver = NavigationResolver(context, state);

    await guard.onNavigation(resolver, context, state);

    final result = await resolver.future;
    return result.continueNavigation ? null : result.redirectPath;
  }
}
