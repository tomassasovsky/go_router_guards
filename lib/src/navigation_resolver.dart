import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// {@template guard_result}
/// Result of a guard navigation resolution
/// {@endtemplate}
class GuardResult {
  /// {@macro guard_result}
  const GuardResult({
    required this.continueNavigation,
    this.redirectPath,
    this.reevaluateOnChange = false,
  });

  /// Factory for allowing navigation to continue
  const GuardResult.allow({this.reevaluateOnChange = false})
      : continueNavigation = true,
        redirectPath = null;

  /// Factory for blocking navigation with redirect
  const GuardResult.redirect(String path, {this.reevaluateOnChange = false})
      : continueNavigation = false,
        redirectPath = path;

  /// Factory for blocking navigation by redirecting to current location
  ///
  /// Note: In practice, use [NavigationResolver.block()] which will
  /// automatically redirect to the current location to achieve blocking.
  @Deprecated('Use NavigationResolver.block() instead')
  const GuardResult.block({this.reevaluateOnChange = false})
      : continueNavigation = false,
        redirectPath = null;

  /// Whether to continue with the navigation
  final bool continueNavigation;

  /// Optional redirect path if navigation should be redirected
  final String? redirectPath;

  /// Whether this guard should be reevaluated on state changes
  final bool reevaluateOnChange;
}

/// {@template navigation_resolver}
/// Navigation resolver that provides control over the navigation flow
/// Similar to auto_route's NavigationResolver but adapted for go_router
/// {@endtemplate}
class NavigationResolver {
  /// {@macro navigation_resolver}
  NavigationResolver(this._context, this._state);

  final BuildContext _context;
  final GoRouterState _state;
  final Completer<GuardResult> _completer = Completer<GuardResult>();

  /// The current route being navigated to
  GoRouterState get state => _state;

  /// The context for the navigation
  BuildContext get context => _context;

  /// Whether this resolver has been resolved
  bool get isResolved => _completer.isCompleted;

  /// The future that completes when the guard resolves
  Future<GuardResult> get future => _completer.future;

  /// Continue navigation (allow access)
  void next([bool continueNavigation = true]) {
    if (isResolved) return;
    _completer.complete(
      GuardResult(
        continueNavigation: continueNavigation,
      ),
    );
  }

  /// Redirect to a different path
  void redirect(String path, {bool reevaluateOnChange = false}) {
    if (isResolved) return;
    _completer.complete(GuardResult.redirect(
      path,
      reevaluateOnChange: reevaluateOnChange,
    ));
  }

  /// Block navigation by redirecting to current location
  void block({bool reevaluateOnChange = false}) {
    if (isResolved) return;
    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    // Block by redirecting to current location
    _completer.complete(GuardResult.redirect(
      currentLocation,
      reevaluateOnChange: reevaluateOnChange,
    ));
  }

  /// Complete with a custom result
  void resolve(GuardResult result) {
    if (isResolved) return;
    _completer.complete(result);
  }

  /// Navigate back if the guard fails
  void nextOrBack([bool continueNavigation = true]) {
    if (continueNavigation) {
      next();
    } else {
      block();
      // Note: In go_router, we can't automatically go back here
      // The calling code would need to handle this
    }
  }
}

/// Signature for the enhanced guard navigation callback
typedef OnGuardNavigation = FutureOr<void> Function(
  NavigationResolver resolver,
  BuildContext context,
  GoRouterState state,
);
