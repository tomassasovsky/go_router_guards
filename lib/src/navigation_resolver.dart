// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// {@template guard_result}
/// Result of a guard navigation resolution.
/// {@endtemplate}
class GuardResult {
  /// {@macro guard_result}
  const GuardResult({
    required this.continueNavigation,
    this.redirectPath,
    this.reevaluateOnChange = false,
  });

  /// Factory for allowing navigation to continue.
  const GuardResult.allow({this.reevaluateOnChange = false})
      : continueNavigation = true,
        redirectPath = null;

  /// Factory for blocking navigation with redirect.
  const GuardResult.redirect(String path, {this.reevaluateOnChange = false})
      : continueNavigation = false,
        redirectPath = path;

  /// Whether to continue with the navigation.
  final bool continueNavigation;

  /// Optional redirect path if navigation should be redirected.
  final String? redirectPath;

  /// Whether this guard should be reevaluated on state changes.
  final bool reevaluateOnChange;
}

/// {@template navigation_resolver}
/// Navigation resolver that provides control over the navigation flow.
///
/// Similar to auto_route's NavigationResolver but adapted for go_router.
/// {@endtemplate}
class NavigationResolver {
  /// {@macro navigation_resolver}
  NavigationResolver(this._context);

  final BuildContext _context;
  final Completer<GuardResult> _completer = Completer<GuardResult>();

  /// Whether this resolver has been resolved.
  bool get isResolved => _completer.isCompleted;

  /// The future that completes when the guard resolves.
  Future<GuardResult> get future => _completer.future;

  /// Continue navigation (allow access)
  void next({bool continueNavigation = true}) {
    if (isResolved) return;
    _resolve(
      GuardResult(
        continueNavigation: continueNavigation,
      ),
    );
  }

  /// Redirect to a different path
  void redirect(String path, {bool reevaluateOnChange = false}) {
    if (isResolved) return;
    _resolve(GuardResult.redirect(
      path,
      reevaluateOnChange: reevaluateOnChange,
    ));
  }

  /// If you don't want to redirect to a specific path, but rather
  /// keep the current location, you can use this method.
  ///
  /// This is useful when you want to block navigation to a specific route
  /// and keep the current location.
  ///
  /// For example, if you want to block navigation to a protected route and
  /// keep the current location, you can use this method.
  void block({bool reevaluateOnChange = false}) {
    if (isResolved) return;

    final router = GoRouter.of(_context);
    final currentLocation = router.routerDelegate.currentConfiguration.fullPath;
    final targetLocation = router.routeInformationProvider.value.uri.toString();

    // There's an edge case where the current location is the one the user
    // is going to (e.g. deep linking). In this case, we should not 
    // block-redirect to the current location, but rather redirect
    // to the default location ("/").
    if (currentLocation == targetLocation) {
      _resolve(
          GuardResult.redirect('/', reevaluateOnChange: reevaluateOnChange));
    } else {
      _resolve(GuardResult.redirect(currentLocation,
          reevaluateOnChange: reevaluateOnChange));
    }
  }

  /// Complete with a custom result.
  void _resolve(GuardResult result) {
    if (isResolved) return;
    _completer.complete(result);
  }

  /// Navigate back if the guard fails.
  void nextOrBack({bool continueNavigation = true}) {
    if (continueNavigation) {
      next();
    } else {
      block();
    }
  }
}

/// Signature for the enhanced guard navigation callback.
typedef OnGuardNavigation = FutureOr<void> Function(
  NavigationResolver resolver,
  BuildContext context,
  GoRouterState state,
);
