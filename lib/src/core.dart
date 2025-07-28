import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mixin for route guards.
///
/// Implement this interface to create custom guards that can check
/// authentication, permissions, app state, or any other conditions
/// before allowing access to a route.
///
/// Example:
/// ```dart
/// class AuthenticationGuard implements RouteGuard {
///   @override
///   FutureOr<String?> redirect(
///     BuildContext context,
///     GoRouterState state,
///   ) async {
///     final authState = context.read<AuthCubit>().state;
///     if (!authState.isAuthenticated) {
///       return '/login';
///     }
///     return null;
///   }
/// }
/// ```
mixin RouteGuard {
  /// Returns a redirect path if the guard fails, null if it passes.
  ///
  /// - Return `null` to allow access to the route
  /// - Return a path (e.g., '/login', '/unauthorized') to redirect
  ///
  /// The guard can perform synchronous or asynchronous operations.
  /// For async operations, use `await` and return a `Future<String?>`.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

/// The order in which the guard expressions are executed.
enum ExecutionOrder {
  /// Execute the guard expressions in the order they are added.
  leftToRight,

  /// Execute the guard expressions in the reverse order they are added.
  rightToLeft,

  /// Execute the guard expressions in parallel.
  parallel,
}

/// Base class for all guard expressions.
///
/// Guard expressions can be combined using logical operators to create
/// complex guard logic like (a & b) || c.
abstract class GuardExpression {
  /// Creates a guard expression.
  const GuardExpression({
    this.executionOrder = ExecutionOrder.leftToRight,
  });

  /// The order in which the guard expressions are executed.
  final ExecutionOrder executionOrder;

  /// Executes the guard expression and returns a redirect path if access
  /// is denied.
  ///
  /// - Return `null` to allow access
  /// - Return a path to redirect (e.g., '/login', '/unauthorized')
  FutureOr<String?> execute(BuildContext context, GoRouterState state);
}
