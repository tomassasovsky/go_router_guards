import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:meta/meta.dart';

/// ALL operator for multiple guards.
///
/// All guards must pass (return null) for access to be granted.
/// Guards are executed in order, and execution stops on first failure.
///
/// Example:
/// ```dart
/// Guards.all([
///   AuthenticationGuard(),
///   RoleGuard(['admin']),
///   SubscriptionGuard(),
///   PaymentGuard(),
/// ])
/// ```
@internal
class All implements RouteGuard {
  /// Creates an ALL operator for multiple guards.
  All(
    this.guards, {
    this.executionOrder = ExecutionOrder.sequential,
  });

  /// The guards to evaluate.
  final List<RouteGuard> guards;

  /// The execution order for the guards.
  final ExecutionOrder executionOrder;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    if (guards.isEmpty) {
      throw ArgumentError('All guards list cannot be empty');
    }

    switch (executionOrder) {
      case ExecutionOrder.sequential:
        for (final guard in guards) {
          final result = await guard.redirect(context, state);
          if (result != null) return result;
          if (!context.mounted) return null;
        }
        return null;

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          guards.map((g) => Future.value(g.redirect(context, state))),
        );

        for (final result in results) {
          if (result != null) return result;
        }
        return null;
    }
  }
}

/// ANY OF operator for multiple guards.
///
/// At least one guard must pass (return null) for access to be granted.
/// Guards are executed in order, and execution stops on first success.
///
/// Example:
/// ```dart
/// Guards.anyOf([
///   AuthenticationGuard(),
///   AdminGuard(),
///   SuperAdminGuard(),
/// ])
/// ```
@internal
class AnyOf implements RouteGuard {
  /// Creates an ANY OF operator for multiple guards.
  AnyOf(
    this.guards, {
    this.executionOrder = ExecutionOrder.sequential,
  });

  /// The guards to evaluate.
  final List<RouteGuard> guards;

  /// The execution order for the guards.
  final ExecutionOrder executionOrder;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    if (guards.isEmpty) {
      throw ArgumentError('AnyOf guards list cannot be empty');
    }

    switch (executionOrder) {
      case ExecutionOrder.sequential:
        String? firstFailure;
        for (final guard in guards) {
          final result = await guard.redirect(context, state);
          if (result == null) return null; // Guard passed
          firstFailure ??= result;
          if (!context.mounted) return null;
        }
        return firstFailure;

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          guards.map((g) => Future.value(g.redirect(context, state))),
        );

        for (final result in results) {
          if (result == null) return null; // At least one passed
        }
        return results.isNotEmpty
            ? results.first
            : null; // All failed, return first failure
    }
  }
}

/// ONE OF operator for multiple guards.
///
/// Exactly one guard must pass (return null) for access to be granted.
///
/// Example:
/// ```dart
/// Guards.oneOf([
///   AuthenticationGuard(),
///   AdminGuard(),
///   SuperAdminGuard(),
/// ], '/unauthorized')
/// ```
@internal
class OneOf implements RouteGuard {
  /// Creates a ONE OF operator for multiple guards.
  OneOf(
    this.guards,
    this.redirectPath, {
    this.executionOrder = ExecutionOrder.sequential,
  });

  /// The guards to evaluate.
  final List<RouteGuard> guards;

  /// The redirect path to use if multiple guards pass or all fail.
  final String redirectPath;

  /// The execution order for the guards.
  final ExecutionOrder executionOrder;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    if (guards.isEmpty) {
      throw ArgumentError('OneOf guards list cannot be empty');
    }

    switch (executionOrder) {
      case ExecutionOrder.sequential:
        final results = <String?>[];
        var passingCount = 0;

        for (final guard in guards) {
          final result = await guard.redirect(context, state);
          results.add(result);

          if (result == null) {
            passingCount++;
            // If we already have more than one passing, we can short-circuit
            if (passingCount > 1) {
              return redirectPath;
            }
          }

          if (!context.mounted) return null;
        }
        return _evaluateOneOfResults(results);

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          guards.map((g) => Future.value(g.redirect(context, state))),
        );
        return _evaluateOneOfResults(results);
    }
  }

  String? _evaluateOneOfResults(List<String?> results) {
    final passingCount = results.where((r) => r == null).length;

    if (passingCount == 1) return null; // Exactly one passed

    // Multiple passed or all failed
    if (passingCount > 1) return redirectPath; // Multiple passed

    // All failed, return first failure
    return results.firstWhere((r) => r != null, orElse: () => redirectPath);
  }
}
