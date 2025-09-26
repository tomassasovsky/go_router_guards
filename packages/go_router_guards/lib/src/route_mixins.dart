// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:route_guards/route_guards.dart';

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
  RouteGuard<Object, Object> get guards => const _AllowGuard();

  /// Executes the guards for this route.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuards(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = guards;
    final result = await guard.executeWithResolver(context, state);
    return result.continueNavigation ? null : result.redirectPath;
  }

  /// Redirect method for Go Router integration.
  ///
  /// This method is called by Go Router when the route is accessed.
  /// It executes the guards and returns a redirect path if access is denied.
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return executeGuards(context, state);
  }
}

/// Mixin for Go Router type-safe shell routes to add guard functionality.
///
/// Similar to [GuardedRoute] but for shell routes.
mixin GuardedShellRoute on ShellRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  /// Defaults to allowing all access.
  RouteGuard<Object, Object> get guards => const _AllowGuard();

  /// Executes the guards for this route.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuards(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = guards;
    final result = await guard.executeWithResolver(context, state);
    return result.continueNavigation ? null : result.redirectPath;
  }

  /// Redirect method for Go Router integration.
  ///
  /// This method is called by Go Router when the route is accessed.
  /// It executes the guards and returns a redirect path if access is denied.
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return executeGuards(context, state);
  }
}

/// Mixin for Go Router type-safe routes to explicitly disable router-level
/// guards.
///
/// Use this when you want a route to bypass any global guards that might
/// be configured at the router level.
///
/// Example:
/// ```dart
/// @TypedGoRoute<LoginRoute>(path: '/login')
/// class LoginRoute extends GoRouteData with UnguardedRoute {
///   @override
///   Widget build(context, state) => LoginScreen();
/// }
/// ```
mixin UnguardedRoute on GoRouteData {
  /// Always returns null to bypass any global guards.
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return null;
  }
}

/// Default guard that allows all navigation
class _AllowGuard extends RouteGuard<Object, Object> {
  const _AllowGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver<Object, Object> resolver,
    Object context,
    Object state,
  ) {
    resolver.next();
  }
}
