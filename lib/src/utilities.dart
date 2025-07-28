import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:meta/meta.dart';

/// Utility class for creating guard combinations with a fluent API.
///
/// Provides static methods to create various types of guard combinations
/// and logical operators. All methods support an optional `executionOrder`
/// parameter to control the order in which guards are evaluated:
///
/// - `ExecutionOrder.sequential`: Execute guards in the order they
///   are provided (default)
/// - `ExecutionOrder.parallel`: Execute all guards simultaneously
class Guards {
  /// Internal constructor to prevent instantiation.
  @internal
  const Guards();

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
  ///
  /// // With parallel execution
  /// Guards.all([
  ///   AuthenticationGuard(),
  ///   RoleGuard(['admin']),
  ///   SubscriptionGuard(),
  ///   PaymentGuard(),
  /// ], executionOrder: ExecutionOrder.parallel)
  /// ```
  static RouteGuard all(
    List<RouteGuard> guards, {
    ExecutionOrder executionOrder = ExecutionOrder.sequential,
  }) {
    if (guards.isEmpty) {
      throw ArgumentError('guards list cannot be empty');
    }
    return All(guards, executionOrder: executionOrder);
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
  ///
  /// // With parallel execution
  /// Guards.anyOf([
  ///   AuthenticationGuard(),
  ///   AdminGuard(),
  ///   SuperAdminGuard(),
  /// ], executionOrder: ExecutionOrder.parallel)
  /// ```
  static RouteGuard anyOf(
    List<RouteGuard> guards, {
    ExecutionOrder executionOrder = ExecutionOrder.sequential,
  }) {
    if (guards.isEmpty) {
      throw ArgumentError('guards list cannot be empty');
    }
    return AnyOf(guards, executionOrder: executionOrder);
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
  ///
  /// // With parallel execution
  /// Guards.oneOf([
  ///   AuthenticationGuard(),
  ///   AdminGuard(),
  ///   SuperAdminGuard(),
  /// ], '/unauthorized', executionOrder: ExecutionOrder.parallel)
  /// ```
  static RouteGuard oneOf(
    List<RouteGuard> guards,
    String redirectPath, {
    ExecutionOrder executionOrder = ExecutionOrder.sequential,
  }) {
    if (guards.isEmpty) {
      throw ArgumentError('guards list cannot be empty');
    }
    if (redirectPath.isEmpty) {
      throw ArgumentError('redirectPath cannot be empty');
    }
    return OneOf(guards, redirectPath, executionOrder: executionOrder);
  }

  /// Creates a guard that always allows access.
  ///
  /// Useful for testing or as a default guard.
  ///
  /// Example:
  /// ```dart
  /// Guards.allow()
  /// ```
  static RouteGuard allow() => const _AllowGuard();
}

/// Guard that always allows access.
class _AllowGuard implements RouteGuard {
  const _AllowGuard();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) => null;
}
