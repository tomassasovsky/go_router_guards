// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/src/navigation_resolver.dart';
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
abstract class RouteGuard {
  /// {@macro guard}
  const RouteGuard();

  /// Middleware-style navigation method.
  ///
  /// Override this method to implement guard logic using the resolver pattern.
  /// Call [resolver.next()] to allow navigation, [resolver.redirect(path)] to
  /// redirect, or [resolver.block()] to block navigation.
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
    final resolver = NavigationResolver(context);
    await onNavigation(resolver, context, state);
    return resolver.future;
  }
}
