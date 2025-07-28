import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

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
  /// Private constructor to prevent instantiation
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

  /// Creates an AND expression.
  ///
  /// Both expressions must pass (return null) for access to be granted.
  ///
  /// Example:
  /// ```dart
  /// Guards.and(
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(RoleGuard(['admin'])),
  /// )
  ///
  /// // With custom execution order
  /// Guards.and(
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(RoleGuard(['admin'])),
  ///   executionOrder: ExecutionOrder.parallel,
  /// )
  /// ```
  static GuardExpression and(
    GuardExpression left,
    GuardExpression right, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) =>
      And(left, right, executionOrder: executionOrder);

  /// Creates an OR expression.
  ///
  /// At least one expression must pass (return null) for access to be granted.
  ///
  /// Example:
  /// ```dart
  /// Guards.or(
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  /// )
  ///
  /// // With custom execution order
  /// Guards.or(
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   executionOrder: ExecutionOrder.rightToLeft,
  /// )
  /// ```
  static GuardExpression or(
    GuardExpression left,
    GuardExpression right, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) =>
      Or(left, right, executionOrder: executionOrder);

  /// Creates an XOR expression.
  ///
  /// Exactly one expression must pass (return null) for access to be granted.
  ///
  /// Example:
  /// ```dart
  /// Guards.xor(
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   '/unauthorized',
  /// )
  /// ```
  static GuardExpression xor(
    GuardExpression left,
    GuardExpression right,
    String redirectPath, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) {
    if (redirectPath.isEmpty) {
      throw ArgumentError('redirectPath cannot be empty');
    }
    return Xor(left, right, redirectPath, executionOrder: executionOrder);
  }

  /// {@template go_router_guards.and_all}
  /// AND operator for multiple guard expressions.
  ///
  /// All expressions must pass (return null) for access to be granted.
  /// Expressions are executed in order, and execution stops on first failure.
  ///
  /// Example:
  /// ```dart
  /// Guards.andAll([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(RoleGuard(['admin'])),
  ///   Guards.guard(SubscriptionGuard()),
  ///   Guards.guard(PaymentGuard()),
  /// ])
  ///
  /// // With custom execution order
  /// Guards.andAll([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(RoleGuard(['admin'])),
  ///   Guards.guard(SubscriptionGuard()),
  ///   Guards.guard(PaymentGuard()),
  /// ], executionOrder: ExecutionOrder.parallel)
  /// ```
  /// {@endtemplate}
  static GuardExpression andAll(
    List<GuardExpression> expressions, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) {
    if (expressions.isEmpty) {
      throw ArgumentError('expressions list cannot be empty');
    }
    return AndAll(expressions, executionOrder: executionOrder);
  }

  /// {@template go_router_guards.or_all}
  /// OR operator for multiple guard expressions.
  ///
  /// At least one expression must pass (return null) for access to be granted.
  /// Expressions are executed in order, and execution stops on first success.
  ///
  /// Example:
  /// ```dart
  /// Guards.orAll([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ])
  ///
  /// // With custom execution order
  /// Guards.orAll([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ], executionOrder: ExecutionOrder.rightToLeft)
  /// ```
  /// {@endtemplate}
  static GuardExpression orAll(
    List<GuardExpression> expressions, {
    ExecutionOrder executionOrder = ExecutionOrder.leftToRight,
  }) {
    if (expressions.isEmpty) {
      throw ArgumentError('expressions list cannot be empty');
    }
    return OrAll(expressions, executionOrder: executionOrder);
  }

  /// {@template go_router_guards.xor_all}
  /// XOR operator for multiple guard expressions.
  ///
  /// Exactly one expression must pass (return null) for access to be granted.
  ///
  /// Example:
  /// ```dart
  /// Guards.xorAll([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ], '/unauthorized')
  ///
  /// // With custom execution order
  /// Guards.xorAll([
  ///   Guards.guard(AuthenticationGuard()),
  ///   Guards.guard(AdminGuard()),
  ///   Guards.guard(SuperAdminGuard()),
  /// ], '/unauthorized', executionOrder: ExecutionOrder.parallel)
  /// ```
  /// {@endtemplate}
  static GuardExpression xorAll(
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
    return XorAll(expressions, redirectPath, executionOrder: executionOrder);
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
