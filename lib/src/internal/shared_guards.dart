// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/src/core.dart';
import 'package:go_router_guards/src/navigation_resolver.dart';
import 'package:meta/meta.dart';

/// {@template callback_guard}
/// Guard that executes a callback function.
/// {@endtemplate}
@internal
class CallbackGuard extends RouteGuard {
  /// {@macro callback_guard}
  const CallbackGuard(this.onGuardNavigation);

  final OnGuardNavigation onGuardNavigation;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    return onGuardNavigation(resolver, context, state);
  }
}

/// {@template allow_guard}
/// Guard that allows navigation.
/// {@endtemplate}
@internal
class AllowGuard extends RouteGuard {
  /// {@macro allow_guard}
  const AllowGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.next();
  }
}

/// {@template redirect_guard}
/// Guard that redirects to a different path.
/// {@endtemplate}
@internal
class RedirectGuard extends RouteGuard {
  const RedirectGuard(this.path);

  final String path;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.redirect(path);
  }
}
