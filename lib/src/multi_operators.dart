import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

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
/// ```
/// {@endtemplate}
class All extends GuardExpression {
  /// {@macro go_router_guards.all}
  const All(
    this.expressions, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The expressions to evaluate.
  final List<GuardExpression> expressions;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    if (expressions.isEmpty) {
      throw ArgumentError('All expressions list cannot be empty');
    }

    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        for (final expression in expressions) {
          final result = await expression.execute(context, state);
          if (result != null) return result;
          if (!context.mounted) return null;
        }
        return null;

      case ExecutionOrder.rightToLeft:
        for (var i = expressions.length - 1; i >= 0; i--) {
          final result = await expressions[i].execute(context, state);
          if (result != null) return result;
          if (!context.mounted) return null;
        }
        return null;

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          expressions.map((e) => Future.value(e.execute(context, state))),
        );

        for (final result in results) {
          if (result != null) return result;
        }
        return null;
    }
  }
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
/// ```
/// {@endtemplate}
class AnyOf extends GuardExpression {
  /// {@macro go_router_guards.any_of}
  const AnyOf(
    this.expressions, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The expressions to evaluate.
  final List<GuardExpression> expressions;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    if (expressions.isEmpty) {
      throw ArgumentError('AnyOf expressions list cannot be empty');
    }

    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        String? firstFailure;
        for (final expression in expressions) {
          final result = await expression.execute(context, state);
          if (result == null) return null; // Expression passed
          firstFailure ??= result;
          if (!context.mounted) return null;
        }
        return firstFailure;

      case ExecutionOrder.rightToLeft:
        String? firstFailure;
        for (var i = expressions.length - 1; i >= 0; i--) {
          final result = await expressions[i].execute(context, state);
          if (result == null) return null; // Expression passed
          firstFailure ??= result;
          if (!context.mounted) return null;
        }
        return firstFailure;

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          expressions.map((e) => Future.value(e.execute(context, state))),
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
/// ```
/// {@endtemplate}
class OneOf extends GuardExpression {
  /// {@macro go_router_guards.one_of}
  const OneOf(
    this.expressions,
    this.redirectPath, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The expressions to evaluate.
  final List<GuardExpression> expressions;

  /// The redirect path to use if multiple expressions pass or all fail.
  final String redirectPath;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    if (expressions.isEmpty) {
      throw ArgumentError('OneOf expressions list cannot be empty');
    }

    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        final results = <String?>[];
        var passingCount = 0;

        for (final expression in expressions) {
          final result = await expression.execute(context, state);
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

      case ExecutionOrder.rightToLeft:
        final results = <String?>[];
        var passingCount = 0;

        for (var i = expressions.length - 1; i >= 0; i--) {
          final result = await expressions[i].execute(context, state);
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
          expressions.map((e) => Future.value(e.execute(context, state))),
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
