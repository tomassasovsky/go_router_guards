import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Base mixin for all route guards.
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
  /// Executes the guard and returns a redirect path if access is denied.
  ///
  /// - Return `null` to allow access to the route
  /// - Return a path (e.g., '/login', '/unauthorized') to redirect
  ///
  /// The guard can perform synchronous or asynchronous operations.
  /// For async operations, use `await` and return a `Future<String?>`.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

/// The order in which guards are executed.
enum ExecutionOrder {
  /// Execute guards in the order they are provided (default).
  sequential,

  /// Execute all guards simultaneously for better performance.
  parallel,
}
