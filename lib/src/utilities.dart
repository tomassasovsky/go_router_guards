import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:meta/meta.dart';

/// Utility class for creating guard expressions with a fluent API.
///
/// Provides static methods to create various types of guard expressions
/// and logical combinations. All methods support an optional `executionOrder`
/// parameter to control the order in which guard expressions are evaluated:
///
/// - `ExecutionOrder.leftToRight`: Execute expressions in the order they
///   are provided (default)
/// - `ExecutionOrder.rightToLeft`: Execute expressions in reverse order
/// - `ExecutionOrder.parallel`: Execute all expressions simultaneously
class Guards {
  /// Internal constructor to prevent instantiation.
  @internal
  const Guards();

  /// Creates a guard expression from a RouteGuard.
  ///
  /// Example:
  /// ```dart
  /// Guards.guard(AuthenticationGuard())
  /// ```
  static GuardExpression guard(
    RouteGuard guard, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) =>
      Guard(guard, executionOrder: executionOrder);

  /// {@template go_router_guards.all}
  /// ALL operator for multiple guard expressions.
  ///
  /// All expressions must pass (return null) for access to be granted.
  /// Expressions are executed in order, and execution stops on first failure.
  ///
  /// Example:
  /// ```dart
  /// Guards.all([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(RoleGuard(['admin'])),
  ///   Guards.guard(SubscriptionGuard()),
  ///   Guards.guard(PaymentGuard()),
  /// ])
  ///
  /// // With custom execution order
  /// Guards.all([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(RoleGuard(['admin'])),
  ///   Guards.guard(SubscriptionGuard()),
  ///   Guards.guard(PaymentGuard()),
  /// ], executionOrder: ExecutionOrder.parallel)
  /// ```
  /// {@endtemplate}
  static GuardExpression all(
    List<GuardExpression> expressions, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) {
    if (expressions.isEmpty) {
      throw ArgumentError('expressions list cannot be empty');
    }
    return All(expressions, executionOrder: executionOrder);
  }

  /// {@template go_router_guards.any_of}
  /// ANY OF operator for multiple guard expressions.
  ///
  /// At least one expression must pass (return null) for access to be granted.
  /// Expressions are executed in order, and execution stops on first success.
  ///
  /// Example:
  /// ```dart
  /// Guards.anyOf([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ])
  ///
  /// // With custom execution order
  /// Guards.anyOf([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ], executionOrder: ExecutionOrder.rightToLeft)
  /// ```
  /// {@endtemplate}
  static GuardExpression anyOf(
    List<GuardExpression> expressions, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) {
    if (expressions.isEmpty) {
      throw ArgumentError('expressions list cannot be empty');
    }
    return AnyOf(expressions, executionOrder: executionOrder);
  }

  /// {@template go_router_guards.one_of}
  /// ONE OF operator for multiple guard expressions.
  ///
  /// Exactly one expression must pass (return null) for access to be granted.
  ///
  /// Example:
  /// ```dart
  /// Guards.oneOf([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ], '/unauthorized')
  ///
  /// // With custom execution order
  /// Guards.oneOf([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ], '/unauthorized', executionOrder: ExecutionOrder.parallel)
  /// ```
  /// {@endtemplate}
  static GuardExpression oneOf(
    List<GuardExpression> expressions,
    String redirectPath, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) {
    if (expressions.isEmpty) {
      throw ArgumentError('expressions list cannot be empty');
    }
    if (redirectPath.isEmpty) {
      throw ArgumentError('redirectPath cannot be empty');
    }
    return OneOf(expressions, redirectPath, executionOrder: executionOrder);
  }

  /// Creates an expression that always allows access.
  ///
  /// Useful for testing or as a default guard.
  ///
  /// Example:
  /// ```dart
  /// Guards.allow()
  /// ```
  static GuardExpression allow() => const _AllowGuard();
}

/// Guard that always allows access.
class _AllowGuard extends GuardExpression {
  const _AllowGuard();

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) => null;
}
