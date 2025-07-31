import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/src/core.dart';
import 'package:go_router_guards/src/navigation_resolver.dart';

/// {@template enhanced_guard}
/// Enhanced route guard that supports middleware-style navigation control
///
/// Guards can either implement the new [onNavigation] method for
/// middleware-style control, or the legacy [redirect] method for simple
/// redirect-based guards.
///
/// Example of middleware-style guard:
/// ```dart
/// class AuthGuard extends RouteGuardEnhanced {
///   @override
///   void onNavigation(
///     NavigationResolver resolver,
///     BuildContext context,
///     GoRouterState state,
///   ) async {
///     final isAuthenticated = await checkAuthentication();
///     if (isAuthenticated) {
///       resolver.next(); // Continue navigation
///     } else {
///       resolver.redirect('/login'); // Redirect to login
///     }
///   }
/// }
/// ```
/// {@endtemplate}
abstract class RouteGuardEnhanced implements RouteGuard {
  /// {@macro enhanced_guard}
  const RouteGuardEnhanced();

  /// Factory constructor for simple callback-based guards
  factory RouteGuardEnhanced.simple(OnGuardNavigation onNavigation) =
      _SimpleGuardEnhanced;

  /// Factory constructor for simple redirect-based guards
  factory RouteGuardEnhanced.redirect(
    FutureOr<String?> Function(BuildContext context, GoRouterState state)
        redirect,
  ) = _RedirectGuardEnhanced;

  /// Factory constructor for conditional redirect guards
  /// Supports both sync and async conditions via FutureOr
  factory RouteGuardEnhanced.redirectIf(
    FutureOr<bool> Function(BuildContext context, GoRouterState state)
        condition,
    String redirectPath,
  ) = _ConditionalRedirectGuard;

  /// Middleware-style navigation method.
  ///
  /// Override this method to implement guard logic using the resolver pattern.
  /// Call [resolver.next()] to allow navigation, [resolver.redirect(path)] to
  /// redirect, or [resolver.block()] to block navigation.
  ///
  /// If this method is overridden, [redirect] will not be called.
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Default implementation uses the legacy redirect method
    final redirectPath = await redirect(context, state);
    if (redirectPath != null) {
      resolver.redirect(redirectPath);
    } else {
      resolver.next();
    }
  }

  /// Legacy redirect method for backward compatibility.
  ///
  /// Override this method for simple redirect-based guards.
  /// Return null to allow access, or a path string to redirect.
  ///
  /// This method is only called if [onNavigation] is not overridden.
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) => null;

  /// Executes the guard using the resolver pattern
  ///
  /// This method creates a resolver and calls [onNavigation], then waits
  /// for the resolver to be completed by the guard implementation.
  Future<GuardResult> executeWithResolver(
    BuildContext context,
    GoRouterState state,
  ) async {
    final resolver = NavigationResolver(context, state);

    // Check if the guard overrides onNavigation by calling it
    await onNavigation(resolver, context, state);

    // Wait for the resolver to complete
    return resolver.future;
  }
}

/// Simple implementation of RouteGuardEnhanced that uses a callback
class _SimpleGuardEnhanced extends RouteGuardEnhanced {
  const _SimpleGuardEnhanced(this._onNavigation);

  final OnGuardNavigation _onNavigation;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    return _onNavigation(resolver, context, state);
  }
}

/// Redirect-based guard implementation
class _RedirectGuardEnhanced extends RouteGuardEnhanced {
  const _RedirectGuardEnhanced(this._redirect);

  final FutureOr<String?> Function(BuildContext context, GoRouterState state)
      _redirect;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return _redirect(context, state);
  }
}

/// Conditional redirect guard
class _ConditionalRedirectGuard extends RouteGuardEnhanced {
  const _ConditionalRedirectGuard(this._condition, this._redirectPath);

  final FutureOr<bool> Function(BuildContext context, GoRouterState state)
      _condition;
  final String _redirectPath;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final shouldRedirect = await _condition(context, state);
    if (shouldRedirect) {
      resolver.redirect(_redirectPath);
    } else {
      resolver.next();
    }
  }
}

/// Adapter that converts legacy RouteGuard to RouteGuardEnhanced
class _LegacyGuardAdapter extends RouteGuardEnhanced {
  const _LegacyGuardAdapter(this._guard);

  final RouteGuard _guard;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return _guard.redirect(context, state);
  }
}

/// Extension to convert legacy guards to enhanced guards
extension RouteGuardExtension on RouteGuard {
  /// Convert this legacy guard to an enhanced guard
  RouteGuardEnhanced toEnhanced() {
    if (this is RouteGuardEnhanced) {
      return this as RouteGuardEnhanced;
    }
    return _LegacyGuardAdapter(this);
  }
}
