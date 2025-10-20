// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:go_router_guards/src/internal/shared_guards.dart';
import 'package:meta/meta.dart';

/// {@template guard}
/// Route guard that supports middleware-style navigation control.
///
/// Guards use the [onNavigation] method for middleware-style control
/// with the [NavigationResolver] to decide how to handle navigation.
///
/// Example:
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   FutureOr<void> onNavigation(
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
abstract class RouteGuard {
  /// {@macro guard}
  const RouteGuard();

  /// Creates a guard from a navigation callback.
  factory RouteGuard.from(OnGuardNavigation onNavigation) =>
      CallbackGuard(onNavigation);

  /// A guard that always allows navigation.
  factory RouteGuard.allow() => const AllowGuard();

  /// A guard that always redirects to the provided [path].
  factory RouteGuard.redirectTo(String path) => RedirectGuard(path);

  /// Middleware-style navigation method.
  ///
  /// Override this method to implement guard logic using the resolver pattern.
  ///
  /// Call [NavigationResolver.next] to allow navigation,
  /// [NavigationResolver.redirect] to redirect to a different path, or
  /// [NavigationResolver.block] to block navigation entirely.
  @mustBeOverridden
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  );

  /// Executes the guard using the resolver pattern
  ///
  /// This method creates a resolver and calls [onNavigation], then waits
  /// for the resolver to be completed by the guard implementation.
  @internal
  Future<GuardResult> executeWithResolver(
    BuildContext context,
    GoRouterState state,
  ) async {
    GoRouter router;

    try {
      router = GoRouter.of(context);
      // this method can throw a FlutterError if the router is not mounted
      // ignore: avoid_catching_errors
    } on FlutterError {
      throw const RouterNotMountedException();
    }

    final resolver = NavigationResolver(router);
    await onNavigation(resolver, context, state);
    return resolver.future;
  }

  /// Returns a redirect callback suitable for GoRouter's `redirect`.
  ///
  /// Example:
  /// ```dart
  /// final router = GoRouter(
  ///   routes: [...],
  ///   redirect: AuthGuard().toRedirect(),
  /// );
  /// ```
  GoRouterRedirect toRedirect() {
    return (context, state) async {
      final result = await executeWithResolver(context, state);

      return switch (result) {
        AllowResult() => null,
        RedirectResult(:final path) => path,
      };
    };
  }
}
