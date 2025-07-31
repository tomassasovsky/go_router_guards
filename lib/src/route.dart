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
mixin GuardedRoute on GoRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  /// Defaults to allowing all access.
  RouteGuard get guards => const _AllowGuard();

  /// Executes the guards for this route using the enhanced guard system.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuards(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = guards;
    final result = await guard.executeWithResolver(context, state);
    return result.redirectPath;
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

/// Mixin for Go Router type-safe routes to explicitly disable global guards.
///
/// Use this mixin when you want to opt-out of global guards that are applied
/// via the router's `redirect` parameter. This is useful for routes like
/// login, registration, or public pages that should bypass authentication.
///
/// Example:
/// ```dart
/// @TypedGoRoute<LoginRoute>(path: '/login')
/// class LoginRoute extends GoRouteData with UnguardedRoute {
///   const LoginRoute();
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const LoginScreen();
///   }
/// }
/// ```
///
/// Note: This mixin only affects global guards applied via the router's
/// `redirect` parameter. It does not affect guards applied directly to
/// individual routes.
mixin UnguardedRoute on GoRouteData {
  /// Always allows navigation, effectively bypassing any global guards.
  ///
  /// This method returns null, which tells Go Router to continue with
  /// the navigation without any redirects.
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    // no-op: always allow navigation
    return null;
  }
}

/// Mixin for Go Router type-safe shell routes to add guard functionality.
///
/// Override the `guards` getter to define route protection.
/// The guards will be automatically executed when the route is accessed.
///
/// Example with enhanced guards:
/// ```dart
/// @TypedGoRoute<AuthShell>(path: '/auth')
/// class AuthShell extends ShellRouteData with GuardedShellRoute {
///   const AuthShell();
///
///   @override
///   RouteGuardEnhanced get guards => GuardsEnhanced.all([
///     AuthenticationGuard(),
///   ]);
mixin GuardedShellRoute on ShellRouteData {
  /// The guard to execute when accessing this route.
  ///
  /// Override this getter to define route protection.
  /// Defaults to allowing all access.
  RouteGuard get guards => const _AllowGuard();

  /// Executes the guards for this route using the enhanced guard system.
  ///
  /// Returns a redirect path if access is denied, null if access is granted.
  FutureOr<String?> executeGuards(
    BuildContext context,
    GoRouterState state,
  ) async {
    final guard = guards;
    final result = await guard.executeWithResolver(context, state);
    return result.redirectPath;
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

/// Default guard that allows all navigation
class _AllowGuard extends RouteGuard {
  const _AllowGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.next();
  }
}
