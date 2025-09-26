// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
/// This is a framework-agnostic resolver that can be adapted for different
/// routing systems. The generic types [TContext] and [TState] provide
/// type-safe access to context and state without casting.
/// {@endtemplate}
class NavigationResolver<TContext, TState> {
  /// {@macro navigation_resolver}
  NavigationResolver(this._context, this._state);

  final TContext _context;
  final TState _state;
  final Completer<GuardResult> _completer = Completer<GuardResult>();

  /// The current route being navigated to.
  TState get state => _state;

  /// The context for the navigation.
  TContext get context => _context;

  /// Whether this resolver has been resolved.
  bool get isResolved => _completer.isCompleted;

  /// The future that completes when the guard resolves.
  Future<GuardResult> get future => _completer.future;

  /// Continue navigation (allow access)
  void next({bool continueNavigation = true}) {
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
    _completer.complete(
      GuardResult.redirect(
        path,
        reevaluateOnChange: reevaluateOnChange,
      ),
    );
  }

  /// Block navigation to the current route.
  ///
  /// This is a framework-agnostic block method. The specific implementation
  /// of what "blocking" means depends on the router integration.
  void block({bool reevaluateOnChange = false}) {
    if (isResolved) return;
    _completer.complete(
      GuardResult.redirect(
        '#blocked', // Placeholder - will be handled by router integration
        reevaluateOnChange: reevaluateOnChange,
      ),
    );
  }

  /// Complete with a custom result.
  void resolve(GuardResult result) {
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
typedef OnGuardNavigation<TContext, TState> = FutureOr<void> Function(
  NavigationResolver<TContext, TState> resolver,
  TContext context,
  TState state,
);

/// Legacy typedef for backward compatibility.
/// Use [OnGuardNavigation] with explicit generic types instead.
@Deprecated('Use OnGuardNavigation<TContext, TState> with explicit types')
typedef LegacyOnGuardNavigation = FutureOr<void> Function(
  NavigationResolver<Object, Object> resolver,
  Object context,
  Object state,
);
