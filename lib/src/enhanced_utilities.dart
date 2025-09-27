// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

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
  static RouteGuard all(List<RouteGuard> guards) {
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
  static RouteGuard anyOf(
    List<RouteGuard> guards, {
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
  static RouteGuard oneOf(
    List<RouteGuard> guards, {
    String? fallbackRedirect,
  }) {
    return _OneOfGuard(guards, fallbackRedirect);
  }
}

/// Implementation of Guards.all()
class _AllGuard extends RouteGuard {
  const _AllGuard(this.guards);

  final List<RouteGuard> guards;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
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
class _AnyOfGuard extends RouteGuard {
  const _AnyOfGuard(this.guards, this.fallbackRedirect);

  final List<RouteGuard> guards;
  final String? fallbackRedirect;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
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
class _OneOfGuard extends RouteGuard {
  const _OneOfGuard(this.guards, this.fallbackRedirect);

  final List<RouteGuard> guards;
  final String? fallbackRedirect;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
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
