import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockBuildContext extends Mock implements BuildContext {}

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('Enhanced Guards', () {
    late MockBuildContext mockContext;
    late MockGoRouterState mockState;

    setUp(() {
      mockContext = MockBuildContext();
      mockState = MockGoRouterState();

      // Setup default mocks
      when(() => mockContext.mounted).thenReturn(true);
      when(() => mockState.fullPath).thenReturn('/test-path');
      when(() => mockState.uri).thenReturn(Uri.parse('/test-path'));
    });

    group('NavigationResolver', () {
      test('should resolve with next()', () async {
        final resolver = NavigationResolver(mockContext, mockState)..next();

        final result = await resolver.future;
        expect(result.continueNavigation, isTrue);
        expect(result.redirectPath, isNull);
      });

      test('should resolve with redirect()', () async {
        final resolver = NavigationResolver(mockContext, mockState)
          ..redirect('/new-path');

        final result = await resolver.future;
        expect(result.continueNavigation, isFalse);
        expect(result.redirectPath, equals('/new-path'));
      });

      test('should handle block() correctly', () async {
        final resolver = NavigationResolver(mockContext, mockState)..block();

        final result = await resolver.future;
        expect(result.continueNavigation, isFalse);
        expect(result.redirectPath,
            equals('/test-path')); // blocked to current path
      });

      test('should handle redirect()', () async {
        final resolver = NavigationResolver(mockContext, mockState)
          ..redirect('/redirect-path');

        final result = await resolver.future;
        expect(result.continueNavigation, isFalse);
        expect(result.redirectPath, equals('/redirect-path'));
      });

      test('should prevent multiple resolutions', () async {
        final resolver = NavigationResolver(mockContext, mockState)
          ..next()
          ..redirect('/should-be-ignored'); // This should be ignored

        final result = await resolver.future;
        expect(result.continueNavigation, isTrue);
        expect(result.redirectPath, isNull);
      });
    });

    group('GuardsEnhanced combinations', () {
      test('all should pass when all guards pass', () async {
        final allowGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final allowGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });

        final guard = Guards.all([allowGuard1, allowGuard2]);

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.continueNavigation, isTrue);
      });

      test('all should fail when any guard fails', () async {
        final allowGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final blockGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        });

        final guard = Guards.all([allowGuard, blockGuard]);

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.redirectPath, equals('/blocked'));
      });

      test('anyOf should pass when any guard passes', () async {
        final blockGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        });
        final allowGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });

        final guard = Guards.anyOf([blockGuard, allowGuard]);

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.continueNavigation, isTrue);
      });

      test('anyOf should use fallback when all fail', () async {
        final blockGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block1');
        });
        final blockGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block2');
        });

        final guard = Guards.anyOf([
          blockGuard1,
          blockGuard2,
        ], fallbackRedirect: '/fallback');

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.redirectPath, equals('/fallback'));
      });

      test('oneOf should pass when exactly one guard passes', () async {
        final allowGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final blockGuard = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        });

        final guard = Guards.oneOf([allowGuard, blockGuard]);

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.continueNavigation, isTrue);
      });

      test('oneOf should block when more than one guard passes', () async {
        final allowGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });
        final allowGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });

        final guard = Guards.oneOf([allowGuard1, allowGuard2]);

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.redirectPath,
            equals('/test-path')); // blocked to current path
      });

      test('oneOf should redirect when no guards pass', () async {
        final blockGuard1 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block1');
        });
        final blockGuard2 = TestEnhancedGuard((resolver, context, state) {
          resolver.redirect('/block2');
        });

        final guard = Guards.oneOf([
          blockGuard1,
          blockGuard2,
        ], fallbackRedirect: '/fallback');

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.redirectPath, equals('/fallback'));
      });
    });

    group('GuardedRoute integration', () {
      test('should work with enhanced guards via executeWithResolver',
          () async {
        final guard = TestEnhancedGuard((resolver, context, state) {
          resolver.next();
        });

        final result = await guard.executeWithResolver(mockContext, mockState);
        expect(result.continueNavigation, isTrue);
      });

      test(
        'should work with enhanced guards that redirect '
        'via executeWithResolver',
        () async {
          final guard = TestEnhancedGuard((resolver, context, state) {
            resolver.redirect('/redirect-target');
          });

          final result =
              await guard.executeWithResolver(mockContext, mockState);
          expect(result.redirectPath, equals('/redirect-target'));
        },
      );
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
