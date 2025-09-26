// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:route_guards/route_guards.dart';

/// Utility class for creating enhanced guard combinations with a fluent API.
///
/// Provides static methods to combine multiple guards with different execution
/// strategies.
abstract class Guards {
  /// Creates a guard that requires all provided guards to pass
  ///
  /// Example:
  /// ```dart
  /// Guards.all([
  ///   authenticationGuard,
  ///   roleGuard,
  /// ])
  /// ```
  static RouteGuard<TContext, TState> all<TContext, TState>(
    List<RouteGuard<TContext, TState>> guards,
  ) {
    return _AllGuard(guards);
  }

  /// Creates a guard that requires any of the provided guards to pass
  ///
  /// Example:
  /// ```dart
  /// Guards.anyOf([
  ///   adminGuard,
  ///   moderatorGuard,
  /// ], fallbackRedirect: '/access-denied')
  /// ```
  static RouteGuard<TContext, TState> anyOf<TContext, TState>(
    List<RouteGuard<TContext, TState>> guards, {
    String? fallbackRedirect,
  }) {
    return _AnyOfGuard(guards, fallbackRedirect);
  }

  /// Creates a guard that requires exactly one of the provided guards to pass
  ///
  /// Example:
  /// ```dart
  /// Guards.oneOf([
  ///   premiumUserGuard,
  ///   trialUserGuard,
  /// ], fallbackRedirect: '/subscription-required')
  /// ```
  static RouteGuard<TContext, TState> oneOf<TContext, TState>(
    List<RouteGuard<TContext, TState>> guards, {
    String? fallbackRedirect,
  }) {
    return _OneOfGuard(guards, fallbackRedirect);
  }
}

/// Implementation of Guards.all()
class _AllGuard<TContext, TState> extends RouteGuard<TContext, TState> {
  const _AllGuard(this.guards);

  final List<RouteGuard<TContext, TState>> guards;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver<TContext, TState> resolver,
    TContext context,
    TState state,
  ) async {
    for (final guard in guards) {
      final result = await guard.executeWithResolver(context, state);
      if (!result.continueNavigation) {
        if (result.redirectPath != null) {
          resolver.redirect(result.redirectPath!);
        } else {
          resolver.block();
        }
        return;
      }
    }
    resolver.next();
  }
}

/// Implementation of Guards.anyOf()
class _AnyOfGuard<TContext, TState> extends RouteGuard<TContext, TState> {
  const _AnyOfGuard(this.guards, this.fallbackRedirect);

  final List<RouteGuard<TContext, TState>> guards;
  final String? fallbackRedirect;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver<TContext, TState> resolver,
    TContext context,
    TState state,
  ) async {
    String? firstRedirectPath;

    for (final guard in guards) {
      final result = await guard.executeWithResolver(context, state);
      if (result.continueNavigation) {
        resolver.next();
        return;
      }
      firstRedirectPath ??= result.redirectPath;
    }

    // All guards failed
    final redirectPath = fallbackRedirect ?? firstRedirectPath;
    if (redirectPath != null) {
      resolver.redirect(redirectPath);
    } else {
      resolver.block();
    }
  }
}

/// Implementation of Guards.oneOf()
class _OneOfGuard<TContext, TState> extends RouteGuard<TContext, TState> {
  const _OneOfGuard(this.guards, this.fallbackRedirect);

  final List<RouteGuard<TContext, TState>> guards;
  final String? fallbackRedirect;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver<TContext, TState> resolver,
    TContext context,
    TState state,
  ) async {
    var passedCount = 0;
    String? firstRedirectPath;

    for (final guard in guards) {
      final result = await guard.executeWithResolver(context, state);
      if (result.continueNavigation) {
        passedCount++;
        if (passedCount > 1) {
          // More than one guard passed, this violates oneOf constraint
          resolver.block();
          return;
        }
      } else {
        firstRedirectPath ??= result.redirectPath;
      }
    }

    if (passedCount == 1) {
      resolver.next();
    } else {
      // Either no guards passed or more than one passed
      final redirectPath = fallbackRedirect ?? firstRedirectPath;
      if (redirectPath != null) {
        resolver.redirect(redirectPath);
      } else {
        resolver.block();
      }
    }
  }
}
