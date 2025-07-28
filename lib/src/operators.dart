import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

/// {@template go_router_guards.and}
/// AND operator for guard expressions.
///
/// Both expressions must pass (return null) for access to be granted.
/// If the first expression fails, the second is not executed.
///
/// Example:
/// ```dart
/// Guards.and(
///   Guards.guard(AuthenticationGuard()),
///   Guards.guard(RoleGuard(['admin'])),
/// )
/// ```
/// {@endtemplate}
class And extends GuardExpression {
  /// {@macro go_router_guards.and}
  const And(
    this.left,
    this.right, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The left expression.
  final GuardExpression left;

  /// The right expression.
  final GuardExpression right;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        final leftResult = await left.execute(context, state);
        if (leftResult != null) return leftResult;
        if (!context.mounted) return null;
        final rightResult = await right.execute(context, state);
        return rightResult; // Return right result (could be null or failure)

      case ExecutionOrder.rightToLeft:
        final rightResult = await right.execute(context, state);
        if (rightResult != null) return rightResult;
        if (!context.mounted) return null;
        final leftResult = await left.execute(context, state);
        return leftResult; // Return left result (could be null or failure)

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          [
            Future.value(left.execute(context, state)),
            Future.value(right.execute(context, state)),
          ],
        );

        final leftResult = results[0];
        final rightResult = results[1];

        if (leftResult != null) return leftResult;
        return rightResult;
    }
  }
}

/// {@template go_router_guards.or}
/// OR operator for guard expressions.
///
/// At least one expression must pass (return null) for access to be granted.
/// If the first expression passes, the second is not executed.
///
/// Example:
/// ```dart
/// Guards.or(
///   Guards.guard(AuthenticationGuard()),
///   Guards.guard(AdminGuard()),
/// )
/// ```
/// {@endtemplate}
class Or extends GuardExpression {
  /// {@macro go_router_guards.or}
  const Or(
    this.left,
    this.right, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The left expression.
  final GuardExpression left;

  /// The right expression.
  final GuardExpression right;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        final leftResult = await left.execute(context, state);
        if (leftResult == null) return null; // Left passed
        if (!context.mounted) return null;
        final rightResult = await right.execute(context, state);
        if (rightResult == null) return null; // Right passed
        return leftResult; // Both failed, return left result

      case ExecutionOrder.rightToLeft:
        final rightResult = await right.execute(context, state);
        if (rightResult == null) return null; // Right passed
        if (!context.mounted) return null;
        final leftResult = await left.execute(context, state);
        if (leftResult == null) return null; // Left passed
        return rightResult; // Both failed, return right result

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          [
            Future.value(left.execute(context, state)),
            Future.value(right.execute(context, state)),
          ],
        );

        final leftResult = results[0];
        final rightResult = results[1];

        if (leftResult == null) return null; // Left passed
        if (rightResult == null) return null; // Right passed
        return leftResult; // Both failed, return left (first) result
    }
  }
}

/// {@template go_router_guards.xor}
/// XOR operator for guard expressions.
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
/// {@endtemplate}
class Xor extends GuardExpression {
  /// {@macro go_router_guards.xor}
  const Xor(
    this.left,
    this.right,
    this.redirectPath, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The left expression.
  final GuardExpression left;

  /// The right expression.
  final GuardExpression right;

  /// The redirect path to use if both expressions pass or both fail.
  final String redirectPath;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    switch (executionOrder) {
      case ExecutionOrder.leftToRight:
        final leftResult = await left.execute(context, state);
        if (!context.mounted) return null;
        final rightResult = await right.execute(context, state);
        if (!context.mounted) return null;

        final leftPassed = leftResult == null;
        final rightPassed = rightResult == null;

        if (leftPassed && !rightPassed) return null; // Only left passed
        if (!leftPassed && rightPassed) return null; // Only right passed

        // Both passed or both failed
        return leftResult ?? rightResult ?? redirectPath;

      case ExecutionOrder.rightToLeft:
        final rightResult = await right.execute(context, state);
        if (!context.mounted) return null;
        final leftResult = await left.execute(context, state);
        if (!context.mounted) return null;

        final leftPassed = leftResult == null;
        final rightPassed = rightResult == null;

        if (leftPassed && !rightPassed) return null; // Only left passed
        if (!leftPassed && rightPassed) return null; // Only right passed

        // Both passed or both failed
        return leftResult ?? rightResult ?? redirectPath;

      case ExecutionOrder.parallel:
        final results = await Future.wait<String?>(
          [
            Future.value(left.execute(context, state)),
            Future.value(right.execute(context, state)),
          ],
        );

        final leftResult = results[0];
        final rightResult = results[1];

        final leftPassed = leftResult == null;
        final rightPassed = rightResult == null;

        if (leftPassed && !rightPassed) return null; // Only left passed
        if (!leftPassed && rightPassed) return null; // Only right passed

        // Both passed or both failed
        return leftResult ?? rightResult ?? redirectPath;
    }
  }
}
