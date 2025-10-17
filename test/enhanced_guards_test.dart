import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('Enhanced Guards', () {
    group('NavigationResolver', () {
      testWidgets('should resolve with next()', (tester) async {
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final resolver = NavigationResolver(router)..next();
        final result = await resolver.future;
        expect(result.continueNavigation, isTrue);
        expect(result.redirectPath, isNull);
      });

      testWidgets('should resolve with redirect()', (tester) async {
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final resolver = NavigationResolver(router)..redirect('/new-path');
        final result = await resolver.future;
        expect(result.continueNavigation, isFalse);
        expect(result.redirectPath, equals('/new-path'));
      });

      testWidgets('should handle block() correctly', (tester) async {
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final resolver = NavigationResolver(router)..block();
        final result = await resolver.future;
        expect(result.continueNavigation, isFalse);
        expect(result.redirectPath, equals('/'));
      });

      testWidgets('should handle redirect()', (tester) async {
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final resolver = NavigationResolver(router)..redirect('/redirect-path');
        final result = await resolver.future;
        expect(result.continueNavigation, isFalse);
        expect(result.redirectPath, equals('/redirect-path'));
      });

      testWidgets('should prevent multiple resolutions', (tester) async {
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final resolver = NavigationResolver(router)
          ..next()
          ..redirect('/should-be-ignored');
        final result = await resolver.future;
        expect(result.continueNavigation, isTrue);
        expect(result.redirectPath, isNull);
      });
    });

    group('GuardsEnhanced combinations', () {
      testWidgets('all should pass when all guards pass', (tester) async {
        final allowGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final allowGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final guard = guardAll([allowGuard1, allowGuard2]);
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.continueNavigation, isTrue);
      });

      testWidgets('all should fail when any guard fails', (tester) async {
        final allowGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final blockGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        });
        final guard = guardAll([allowGuard, blockGuard]);
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.redirectPath, equals('/blocked'));
      });

      testWidgets('anyOf should pass when any guard passes', (tester) async {
        final blockGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        });
        final allowGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final guard = guardAnyOf([blockGuard, allowGuard]);
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.continueNavigation, isTrue);
      });

      testWidgets('anyOf should use fallback when all fail', (tester) async {
        final blockGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block1');
        });
        final blockGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block2');
        });
        final guard = guardAnyOf([blockGuard1, blockGuard2],
            fallbackRedirect: '/fallback');
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.redirectPath, equals('/fallback'));
      });

      testWidgets('oneOf should pass when exactly one guard passes',
          (tester) async {
        final allowGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final blockGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        });
        final guard = guardOneOf([allowGuard, blockGuard]);
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.continueNavigation, isTrue);
      });

      testWidgets('oneOf should block when more than one guard passes',
          (tester) async {
        final allowGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final allowGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final guard = guardOneOf([allowGuard1, allowGuard2]);
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.redirectPath, equals('/'));
      });

      testWidgets('oneOf should redirect when no guards pass', (tester) async {
        final blockGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block1');
        });
        final blockGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block2');
        });
        final guard = guardOneOf([blockGuard1, blockGuard2],
            fallbackRedirect: '/fallback');
        final router = GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final ctx = tester.element(find.byType(Navigator));
        final state = MockGoRouterState();
        when(() => state.uri).thenReturn(Uri.parse('/test-path'));
        final result = await guard.executeWithResolver(ctx, state);
        expect(result.redirectPath, equals('/fallback'));
      });
    });
  });
}

/// Test implementation of RouteGuardEnhanced for testing
class TestEnhancedGuard extends RouteGuard {
  TestEnhancedGuard(this.onNavigationCallback);

  final FutureOr<void> Function(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) onNavigationCallback;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    return onNavigationCallback(resolver, context, state);
  }
}
