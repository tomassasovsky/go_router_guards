// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

/// Create a guard that requires all provided guards to pass.
RouteGuard guardAll(List<RouteGuard> guards) => _AllGuard(guards);

/// Create a guard that requires any of the provided guards to pass.
RouteGuard guardAnyOf(
  List<RouteGuard> guards, {
  String? fallbackRedirect,
}) =>
    _AnyOfGuard(guards, fallbackRedirect);

/// Create a guard that requires exactly one of the provided guards to pass.
RouteGuard guardOneOf(
  List<RouteGuard> guards, {
  String? fallbackRedirect,
}) =>
    _OneOfGuard(guards, fallbackRedirect);

/// Lightweight extension to combine a list of guards ergonomically.
extension GuardsListExtensions on List<RouteGuard> {
  /// Combine guards so all must pass.
  RouteGuard all() => guardAll(this);

  /// Combine guards so any may pass.
  RouteGuard anyOf({String? fallbackRedirect}) =>
      guardAnyOf(this, fallbackRedirect: fallbackRedirect);

  /// Combine guards so exactly one must pass.
  RouteGuard oneOf({String? fallbackRedirect}) =>
      guardOneOf(this, fallbackRedirect: fallbackRedirect);
}

/// Extensions for redirect builders directly from collections of guards.
extension GuardsIterableRedirectExtensions on Iterable<RouteGuard> {
  /// Build a redirect where all guards must pass.
  FutureOr<String?> Function(BuildContext, GoRouterState) redirectAll() =>
      guardAll(toList()).toRedirect();

  /// Build a redirect where any guard may pass.
  FutureOr<String?> Function(BuildContext, GoRouterState) redirectAnyOf({
    String? fallbackRedirect,
  }) =>
      guardAnyOf(toList(), fallbackRedirect: fallbackRedirect).toRedirect();

  /// Build a redirect where exactly one guard must pass.
  FutureOr<String?> Function(BuildContext, GoRouterState) redirectOneOf({
    String? fallbackRedirect,
  }) =>
      guardOneOf(toList(), fallbackRedirect: fallbackRedirect).toRedirect();
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
      switch (result) {
        case AllowResult():
          continue;
        case RedirectResult(:final path):
          resolver.redirect(path);
          return;
      }
    }

    resolver.next();
  }
}

/// Implementation of Guards.anyOf()
class _AnyOfGuard extends RouteGuard {
  const _AnyOfGuard(
    this.guards,
    this.fallbackRedirect,
  );

  final List<RouteGuard> guards;
  final String? fallbackRedirect;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (guards.isEmpty) {
      throw ArgumentError.value(guards, 'guards', 'guards cannot be empty');
    }

    RedirectResult? firstRedirectResult;

    for (final guard in guards) {
      final result = await guard.executeWithResolver(context, state);

      switch (result) {
        case AllowResult():
          resolver.next();
          return;
        case RedirectResult():
          firstRedirectResult ??= result;
      }
    }

    assert(firstRedirectResult != null, 'anyOf: no redirect result');

    final path = fallbackRedirect ?? firstRedirectResult!.path;
    resolver.redirect(path);
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
    if (guards.isEmpty) {
      throw ArgumentError.value(guards, 'guards', 'guards cannot be empty');
    }

    var passed = 0;
    RedirectResult? firstRedirectResult;

    for (final guard in guards) {
      final result = await guard.executeWithResolver(context, state);
      switch (result) {
        case AllowResult():
          passed++;
          if (passed > 1) {
            resolver.block();
            return;
          }
        case RedirectResult():
          firstRedirectResult ??= result;
      }
    }

    if (passed == 1) {
      resolver.next();
      return;
    }

    assert(firstRedirectResult != null, 'oneOf: no redirect result');

    final path = fallbackRedirect ?? firstRedirectResult!.path;
    resolver.redirect(path);
  }
}
