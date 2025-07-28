import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router_guards/go_router_guards.dart';

/// Immutable chainable guard system that executes multiple guards in sequence.
///
/// This class provides backward compatibility with the original GuardChain API.
/// For new code, consider using the expression-based system with Guards
/// utility.
///
/// Example:
/// ```dart
/// GuardChain()
///   .add(AuthenticationGuard())
///   .add(RoleGuard(['admin']))
///   .add(SubscriptionGuard())
/// ```
class GuardChain {
  /// Creates an empty guard chain.
  const GuardChain([this._guards = const []]);

  /// The guards in the chain.
  final List<RouteGuard> _guards;

  /// Adds a guard to the chain.
  ///
  /// Returns a new chain with the guard added.
  GuardChain add(RouteGuard guard) {
    final newGuards = List<RouteGuard>.from(_guards)..add(guard);
    return GuardChain(newGuards);
  }

  /// Adds multiple guards to the chain.
  ///
  /// Returns a new chain with the guards added.
  GuardChain addAll(Iterable<RouteGuard> guards) {
    final newGuards = List<RouteGuard>.from(_guards)..addAll(guards);
    return GuardChain(newGuards);
  }

  /// Clears all guards from the chain.
  ///
  /// Returns a new empty chain.
  GuardChain clear() => const GuardChain();

  /// Returns the number of guards in the chain.
  int get length => _guards.length;

  /// Returns true if the chain is empty.
  bool get isEmpty => _guards.isEmpty;

  /// Returns true if the chain is not empty.
  bool get isNotEmpty => _guards.isNotEmpty;

  /// Executes all guards in the chain.
  ///
  /// Returns the first redirect path encountered, or null if all guards pass.
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    for (final guard in _guards) {
      final result = await guard.redirect(context, state);
      if (result != null) return result;
      if (!context.mounted) return null;
    }
    return null;
  }

  /// Converts the chain to a guard expression.
  ///
  /// This allows the chain to be used with the expression-based system.
  GuardExpression toExpression() {
    if (_guards.isEmpty) return const _AllowGuard();
    if (_guards.length == 1) return Guard(_guards.first);

    // Convert to AndAll for multiple guards
    final expressions = _guards.map(Guard.new).toList();
    return AndAll(expressions);
  }
}

/// Guard that always allows access.
/// Used internally by GuardChain.
class _AllowGuard extends GuardExpression {
  const _AllowGuard();

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) => null;
}
