// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:route_guards/route_guards.dart';

/// {@template guard}
/// Route guard that supports middleware-style navigation control.
///
/// Guards use the [onNavigation] method for middleware-style control
/// with the [NavigationResolver] to decide how to handle navigation.
///
/// The generic types [TContext] and [TState] allow for type-safe access to
/// navigation context and state without casting.
///
/// Example:
/// ```dart
/// class AuthGuard extends RouteGuard<BuildContext, RouterState> {
///   @override
///   void onNavigation(
///     NavigationResolver<BuildContext, RouterState> resolver,
///     BuildContext context,
///     RouterState state,
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
abstract class RouteGuard<TContext, TState> {
  /// {@macro guard}
  const RouteGuard();

  /// Middleware-style navigation method.
  ///
  /// Override this method to implement guard logic using the resolver pattern.
  /// Call [resolver.next()] to allow navigation, [resolver.redirect(path)] to
  /// redirect, or [resolver.block()] to block navigation.
  ///
  /// The [context] and [state] parameters are properly typed using generics
  /// for type-safe access without casting.
  FutureOr<void> onNavigation(
    NavigationResolver<TContext, TState> resolver,
    TContext context,
    TState state,
  );

  /// Executes the guard using the resolver pattern
  ///
  /// This method creates a resolver and calls [onNavigation], then waits
  /// for the resolver to be completed by the guard implementation.
  Future<GuardResult> executeWithResolver(
    TContext context,
    TState state,
  ) async {
    final resolver = NavigationResolver<TContext, TState>(context, state);
    await onNavigation(resolver, context, state);
    return resolver.future;
  }
}

/// Legacy route guard base class for backward compatibility.
///
/// This provides backward compatibility for existing code that doesn't use
/// generic types. New code should prefer the generic [RouteGuard] class.
///
/// Example:
/// ```dart
/// class LegacyAuthGuard extends LegacyRouteGuard {
///   @override
///   void onNavigation(
///     NavigationResolver<Object, Object> resolver,
///     Object context,
///     Object state,
///   ) async {
///     final buildContext = context as BuildContext;
///     final goRouterState = state as GoRouterState;
///     // ... implementation
///   }
/// }
/// ```
@Deprecated('Use RouteGuard<TContext, TState> with explicit generic types')
abstract class LegacyRouteGuard extends RouteGuard<Object, Object> {
  /// Creates a legacy route guard for backward compatibility.
  @Deprecated('Use RouteGuard<TContext, TState> with explicit generic types')
  const LegacyRouteGuard();
}
