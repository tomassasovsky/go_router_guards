import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Abstract base class for route guards.
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

/// Chainable guard system that executes multiple guards in sequence.
///
/// Guards are executed in the order they are added. The first guard
/// that returns a redirect path stops the execution and returns that path.
///
/// Example:
/// ```dart
/// GuardChain()
///   ..add(AuthenticationGuard())
///   ..add(RoleBasedGuard(['admin']))
///   ..add(SubscriptionGuard())
/// ```
class GuardChain {
  /// Creates an empty guard chain.
  GuardChain();

  final List<RouteGuard> _guards = [];

  /// Adds a guard to the chain.
  ///
  /// Example:
  /// ```dart
  /// GuardChain()
  ///   ..add(AuthenticationGuard())
  ///   ..add(RoleBasedGuard(['admin']))
  /// ```
  void add(RouteGuard guard) {
    _guards.add(guard);
  }

  /// Adds multiple guards to the chain.
  ///
  /// Example:
  /// ```dart
  /// GuardChain()
  ///   ..addAll([
  ///   AuthenticationGuard(),
  ///   AppInitializationGuard(),
  ///   RoleBasedGuard(['admin']),
  /// ])
  /// ```
  void addAll(List<RouteGuard> guards) {
    _guards.addAll(guards);
  }

  /// Executes all guards in the chain.
  ///
  /// Returns the first redirect path encountered, or null if all guards pass.
  /// Guards are executed in the order they were added to the chain.
  ///
  /// Example:
  /// ```dart
  /// final result = await chain.execute(context, state);
  /// if (result != null) {
  ///   // Redirect to result path
  /// }
  /// ```
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    for (final guard in _guards) {
      final result = await guard.redirect(context, state);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Clears all guards from the chain.
  void clear() {
    _guards.clear();
  }

  /// Returns the number of guards in the chain.
  int get length => _guards.length;

  /// Returns true if the chain is empty.
  bool get isEmpty => _guards.isEmpty;

  /// Returns true if the chain is not empty.
  bool get isNotEmpty => _guards.isNotEmpty;
}

/// Mixin for applying guards to GoRouteData classes.
///
/// Use this mixin to add guard functionality to your route classes.
/// Override the `guards` getter to define which guards should be applied.
///
/// Example:
/// ```dart
/// @TypedGoRoute<ProtectedRoute>(path: '/protected')
/// class ProtectedRoute extends GoRouteData with GuardedRoute {
///   const ProtectedRoute();
///
///   @override
///   GuardChain get guards => GuardChain()
///     ..add(AuthenticationGuard())
///     ..add(RoleBasedGuard(['admin']));
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const ProtectedScreen();
///   }
/// }
/// ```
mixin GuardedRoute on GoRouteData {
  /// Override this getter to define guards for the route.
  ///
  /// Return a `GuardChain` with the guards you want to apply.
  /// If no guards are needed, return an empty `GuardChain()`.
  GuardChain get guards => GuardChain();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    return await guards.execute(context, state);
  }
}
