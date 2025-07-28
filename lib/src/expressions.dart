import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

/// Individual guard as an expression.
///
/// Wraps a single RouteGuard as a GuardExpression.
class Guard extends GuardExpression {
  /// Creates a guard expression from a RouteGuard.
  ///
  /// Example:
  /// ```dart
  /// Guards.guard(AuthenticationGuard())
  /// ```
  const Guard(
    this.guard, {
    super.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The guard to execute.
  final RouteGuard guard;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) {
    return guard.redirect(context, state);
  }
}
