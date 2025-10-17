// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/src/core.dart';
import 'package:go_router_guards/src/internal/shared_guards.dart';
import 'package:meta/meta.dart';

/// Mixin for type-safe routes to add guard functionality.
///
/// Override the `guard` getter to define route protection. The guard is
/// executed automatically when the route is accessed.
///
/// Example (single guard):
/// ```dart
/// @TypedGoRoute<ProfileRoute>(path: '/profile')
/// class ProfileRoute extends GoRouteData with GuardedRoute {
///   const ProfileRoute();
///
///   @override
///   RouteGuard get guard => AuthenticationGuard();
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) =>
///       const ProfileScreen();
/// }
/// ```
///
/// Example (multiple guards combined):
/// ```dart
/// @TypedGoRoute<AdminRoute>(path: '/admin')
/// class AdminRoute extends GoRouteData with GuardedRoute {
///   const AdminRoute();
///
///   @override
///   RouteGuard get guard => [
///     AuthenticationGuard(),
///     RoleGuard(['admin']),
///   ].all();
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) =>
///       const AdminScreen();
/// }
/// ```
///
mixin GuardedRoute on GoRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  ///
  /// Defaults to allowing all access.
  RouteGuard get guard => const AllowGuard();

  /// Executes the guards for this route using the enhanced guard system.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = this.guard;
    final result = await guard.executeWithResolver(context, state);
    return result.redirectPath;
  }

  /// Redirect method for backward compatibility.
  ///
  /// This method is called by Go Router when the route is accessed.
  ///
  /// It executes the guards and returns a redirect path if access is denied.
  @override
  @nonVirtual
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      executeGuard(context, state);
}

/// Mixin for type-safe shell routes to add guard functionality.
///
/// Override the `guard` getter to define route protection for the shell.
/// The guard is executed automatically when the shell route is accessed.
///
/// Example:
/// ```dart
/// @TypedGoRoute<AuthShell>(path: '/auth')
/// class AuthShell extends ShellRouteData with GuardedShellRoute {
///   const AuthShell();
///
///   @override
///   RouteGuard get guard => guardAll([
///     AuthenticationGuard(),
///   ]);
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) =>
///       const AuthShellScreen();
/// }
/// ```
///
mixin GuardedShellRoute on ShellRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  /// Defaults to allowing all access.
  RouteGuard get guard => const AllowGuard();

  /// Executes the guards for this route using the enhanced guard system.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = this.guard;
    final result = await guard.executeWithResolver(context, state);
    return result.redirectPath;
  }

  /// This method is called by Go Router when the route is accessed.
  ///
  /// It executes the guard and returns a redirect path if navigation should be
  /// blocked.
  ///
  /// This method is not virtual because it is called by Go Router directly, and
  /// should not be overridden.
  @override
  @nonVirtual
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      executeGuard(context, state);
}
