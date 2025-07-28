import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

/// Mixin for Go Router type-safe routes to add guard functionality.
///
/// Override the `guards` getter to define route protection.
/// The guards will be automatically executed when the route is accessed.
///
/// Example:
/// ```dart
/// @TypedGoRoute<ProtectedRoute>(path: '/protected')
/// class ProtectedRoute extends GoRouteData with GuardedRoute {
///   const ProtectedRoute();
///
///   @override
///   RouteGuard get guards => Guards.all([
///     AuthenticationGuard(),
///     RoleGuard(['admin']),
///   ]);
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const ProtectedScreen();
///   }
/// }
/// ```
mixin GuardedRoute on GoRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  /// Defaults to allowing all access.
  RouteGuard get guards => Guards.allow();

  /// Executes the guards for this route.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuards(BuildContext context, GoRouterState state) {
    return guards.redirect(context, state);
  }

  /// Redirect method for backward compatibility.
  ///
  /// This method is called by Go Router when the route is accessed.
  /// It executes the guards and returns a redirect path if access is denied.
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return executeGuards(context, state);
  }
}
