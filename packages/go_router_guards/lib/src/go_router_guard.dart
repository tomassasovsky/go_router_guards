// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';
import 'package:route_guards/route_guards.dart';

/// A route guard that is specifically designed to work with Go Router.
///
/// This extends the base [RouteGuard] and provides Go Router specific
/// functionality with proper typing for BuildContext and GoRouterState.
abstract class GoRouterGuard extends RouteGuard<BuildContext, GoRouterState> {
  /// Creates a Go Router specific guard.
  const GoRouterGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver<BuildContext, GoRouterState> resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final goRouterResolver = resolver is GoRouterNavigationResolver
        ? resolver
        : GoRouterNavigationResolver(context, state);
    return onGoRouterNavigation(goRouterResolver, context, state);
  }

  @override
  Future<GuardResult> executeWithResolver(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Use GoRouterNavigationResolver for enhanced Go Router functionality
    final resolver = GoRouterNavigationResolver(context, state);
    await onNavigation(resolver, context, state);
    return resolver.future;
  }

  /// Go Router specific navigation method with properly typed parameters.
  ///
  /// Override this method to implement guard logic using the resolver pattern.
  /// Call [resolver.next()] to allow navigation, [resolver.redirect(path)] to
  /// redirect, or [resolver.block()] to block navigation.
  ///
  /// The resolver parameter is a [GoRouterNavigationResolver] which provides
  /// Go Router-specific functionality like improved blocking behavior.
  @mustBeOverridden
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    // Default implementation - allows navigation
    // Override this method in your guard implementation
    resolver.next();
  }
}

/// Enhanced navigation resolver that provides Go Router specific functionality.
class GoRouterNavigationResolver
    extends NavigationResolver<BuildContext, GoRouterState> {
  /// Creates a Go Router specific navigation resolver.
  GoRouterNavigationResolver(
    super._context,
    super._state,
  );

  /// Block navigation by staying at the current location.
  ///
  /// This uses Go Router's current location to implement blocking behavior.
  ///
  /// If there's no valid current location (e.g., direct navigation),
  /// it will use the global fallback configured via
  /// [RouteGuardConfig.instance].
  @override
  void block({bool reevaluateOnChange = false}) {
    if (isResolved) return;
    final router = GoRouter.of(context);
    var currentLocation = router.routerDelegate.currentConfiguration.fullPath;

    // Handle case where there's no valid current location (direct navigation)
    if (currentLocation.isEmpty ||
        currentLocation == state.uri.path ||
        !router.canPop()) {
      currentLocation = RouteGuardConfig.instance.fallbackPath;
    }

    redirect(currentLocation, reevaluateOnChange: reevaluateOnChange);
  }
}
