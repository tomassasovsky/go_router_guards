// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/src/exceptions.dart';

/// Signature for the enhanced guard navigation callback.
typedef OnGuardNavigation = FutureOr<void> Function(
  NavigationResolver resolver,
  BuildContext context,
  GoRouterState state,
);

/// {@template guard_result}
/// Result of a guard navigation resolution.
/// {@endtemplate}
sealed class GuardResult {
  const GuardResult();

  /// Factory for allowing navigation to continue.
  const factory GuardResult.allow() = AllowResult;

  /// Factory for blocking navigation with redirect to a specific path.
  const factory GuardResult.redirect(String path) = RedirectResult;
}

/// {@template allow_result}
/// Result of a guard navigation resolution that allows navigation.
/// {@endtemplate}
class AllowResult extends GuardResult {
  /// {@macro allow_result}
  const AllowResult() : super();
}

/// {@template redirect_result}
/// Result of a guard navigation resolution that redirects to a specific path.
/// {@endtemplate}
class RedirectResult extends GuardResult {
  /// {@macro redirect_result}
  const RedirectResult(this.path) : super();

  /// The path to redirect to.
  final String path;
}

/// {@template navigation_resolver}
/// Navigation resolver that provides control over the navigation flow.
/// {@endtemplate}
class NavigationResolver {
  /// {@macro navigation_resolver}
  NavigationResolver(this._router);

  final GoRouter _router;
  final Completer<GuardResult> _completer = Completer<GuardResult>();

  /// Returns the current [BuildContext].
  ///
  /// Be-aware build context can be null if the navigator is not yet mounted
  /// this happens if you're guarding the first route in the app
  BuildContext get context {
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context == null) {
      throw const RouterNotMountedException();
    }
    return context;
  }

  /// Whether this resolver has been resolved.
  bool get isResolved => _completer.isCompleted;

  /// The future that completes when the guard resolves.
  Future<GuardResult> get future => _completer.future;

  /// Continue navigation (allow access)
  void next() {
    if (isResolved) return;
    _completer.complete(const GuardResult.allow());
  }

  /// Redirect to a different path
  void redirect(String path) {
    if (isResolved) return;
    _completer.complete(GuardResult.redirect(path));
  }

  /// Block navigation entirely.
  ///
  /// If you don't want to redirect to a specific path, but rather
  /// keep the current location, you can use this method.
  ///
  /// If the current location is the one the user is going to
  /// (e.g. deep linking), this method will redirect to the default location ("/").
  void block() {
    if (isResolved) return;

    final currentLocation =
        _router.routerDelegate.currentConfiguration.fullPath;
    final targetLocation =
        _router.routeInformationProvider.value.uri.toString();

    final redirectPath =
        currentLocation == targetLocation ? '/' : currentLocation;
    _completer.complete(GuardResult.redirect(redirectPath));
  }
}
