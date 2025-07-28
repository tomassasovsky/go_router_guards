import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

/// Utility class for creating guard expressions with a fluent API.
///
/// Provides static methods to create various types of guard expressions
/// and logical combinations.
class Guards {
  const Guards._();

  /// Creates a guard expression from a RouteGuard.
  ///
  /// Example:
  /// ```dart
  /// Guards.guard(AuthenticationGuard())
  /// ```
  static GuardExpression guard(RouteGuard guard) => Guard(guard);

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
  /// ```
  static GuardExpression and(GuardExpression left, GuardExpression right) =>
      And(left, right);

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
  /// ```
  static GuardExpression or(GuardExpression left, GuardExpression right) =>
      Or(left, right);

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
    String redirectPath,
  ) =>
      Xor(left, right, redirectPath);

  /// Creates a NOT expression.
  ///
  /// Inverts the result of the expression.
  ///
  /// Example:
  /// ```dart
  /// Guards.not(Guards.guard(AuthenticationGuard()))
  /// ```
  static GuardExpression not(GuardExpression expression) => Not(expression);

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
  /// ```
  /// {@endtemplate}
  static GuardExpression andAll(List<GuardExpression> expressions) =>
      AndAll(expressions);

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
  /// ```
  /// {@endtemplate}
  static GuardExpression orAll(List<GuardExpression> expressions) =>
      OrAll(expressions);

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
  /// ```
  /// {@endtemplate}
  static GuardExpression xorAll(
    List<GuardExpression> expressions,
    String redirectPath,
  ) =>
      XorAll(expressions, redirectPath);

  /// Creates an expression that always allows access.
  ///
  /// Useful for testing or as a default guard.
  ///
  /// Example:
  /// ```dart
  /// Guards.allow()
  /// ```
  static GuardExpression allow() => const _AllowGuard();

  /// Creates an expression that always denies access.
  ///
  /// Useful for testing or as a default guard.
  ///
  /// Example:
  /// ```dart
  /// Guards.deny('/custom')
  /// ```
  static GuardExpression deny([String redirectPath = '/unauthorized']) =>
      _DenyGuard(redirectPath);
}

/// Guard that always allows access.
class _AllowGuard extends GuardExpression {
  const _AllowGuard();

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) => null;
}

/// Guard that always denies access.
class _DenyGuard extends GuardExpression {
  const _DenyGuard(this.redirectPath);

  final String redirectPath;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) =>
      redirectPath;
}
