import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

/// Mixin for Go Router type-safe routes to add guard functionality.
///
/// Override the `guards` getter to define route protection.
/// The guards will be automatically executed when the route is accessed.
///
/// Example with enhanced guards:
/// ```dart
/// @TypedGoRoute<ProtectedRoute>(path: '/protected')
/// class ProtectedRoute extends GoRouteData with GuardedRoute {
///   const ProtectedRoute();
///
///   @override
///   RouteGuardEnhanced get guards => GuardsEnhanced.simple(
///     (resolver, context, state) async {
///       final isAuth = await checkAuth();
///       if (isAuth) {
///         resolver.next();
///       } else {
///         resolver.redirect('/login');
///       }
///     }
///   );
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const ProtectedScreen();
///   }
/// }
/// ```
///
/// Example with legacy guards (backward compatible):
/// ```dart
/// @override
/// RouteGuard get guards => Guards.all([
///   AuthenticationGuard(),
///   RoleGuard(['admin']),
/// ]);
/// ```
mixin GuardedRoute on GoRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  /// Defaults to allowing all access.
  ///
  /// You can return either a legacy [RouteGuard] or enhanced
  /// [RouteGuardEnhanced].
  RouteGuard get guards => Guards.allow();

  /// Executes the guards for this route using the enhanced guard system.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  /// This method automatically handles both legacy and enhanced guards.
  FutureOr<String?> executeGuards(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = guards;

    // If it's an enhanced guard, use the resolver pattern
    if (guard is RouteGuardEnhanced) {
      final result = await guard.executeWithResolver(context, state);
      return result.redirectPath;
    }

    // Otherwise, use legacy redirect method
    return guard.redirect(context, state);
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
