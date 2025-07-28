import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

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
class AndAll extends GuardExpression {
  /// {@macro go_router_guards.and_all}
  const AndAll(
    this.expressions, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The expressions to evaluate.
  final List<GuardExpression> expressions;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
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
class OrAll extends GuardExpression {
  /// {@macro go_router_guards.or_all}
  const OrAll(
    this.expressions, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The expressions to evaluate.
  final List<GuardExpression> expressions;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
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
        return results.first; // All failed, return first failure
    }
  }
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
/// ```
/// {@endtemplate}
class XorAll extends GuardExpression {
  /// {@macro go_router_guards.xor_all}
  const XorAll(
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
    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        final results = <String?>[];
        for (final expression in expressions) {
          final result = await expression.execute(context, state);
          results.add(result);
        }
        return _evaluateXorResults(results);

      case ExecutionOrder.rightToLeft:
        final results = <String?>[];
        for (var i = expressions.length - 1; i >= 0; i--) {
          final result = await expressions[i].execute(context, state);
          results.add(result);
        }
        return _evaluateXorResults(results);

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          expressions.map((e) => Future.value(e.execute(context, state))),
        );
        return _evaluateXorResults(results);
    }
  }

  String? _evaluateXorResults(List<String?> results) {
    final passingCount = results.where((r) => r == null).length;

    if (passingCount == 1) return null; // Exactly one passed

    // Multiple passed or all failed
    if (passingCount > 1) return redirectPath; // Multiple passed

    // All failed, return first failure
    return results.firstWhere((r) => r != null, orElse: () => redirectPath);
  }
}
