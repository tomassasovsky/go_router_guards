import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:mocktail/mocktail.dart';

class MockBuildContext extends Mock implements BuildContext {}

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('go_router_guards', () {
    test('exports RouteGuard interface', () {
      expect(RouteGuard, isNotNull);
    });

    test('exports GuardChain class', () {
      expect(GuardChain, isNotNull);
    });

    test('exports GuardedRoute mixin', () {
      expect(GuardedRoute, isNotNull);
    });

    group('RouteGuard', () {
      test('can be implemented', () {
        final guard = TestGuard();
        expect(guard, isA<RouteGuard>());
      });

      test('can return null to allow access', () async {
        final guard = TestGuard(() => null);
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await guard.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('can return redirect path to deny access', () async {
        final guard = TestGuard(() => '/login');
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await guard.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });
    });

    group('GuardChain', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('creates empty chain', () {
        final chain = GuardChain();
        expect(chain.length, equals(0));
        expect(chain.isEmpty, isTrue);
        expect(chain.isNotEmpty, isFalse);
      });

      test('adds guard to chain', () {
        final chain = GuardChain();
        final guard = TestGuard();

        chain.add(guard);

        expect(chain.length, equals(1));
        expect(chain.isEmpty, isFalse);
        expect(chain.isNotEmpty, isTrue);
      });

      test('supports method chaining', () {
        final chain = GuardChain();
        final guard1 = TestGuard();
        final guard2 = TestGuard();

        chain
          ..add(guard1)
          ..add(guard2);

        expect(chain.length, equals(2));
      });

      test('adds all guards at once', () {
        final chain = GuardChain();
        final guards = [TestGuard(), TestGuard(), TestGuard()];

        chain.addAll(guards);

        expect(chain.length, equals(3));
      });

      test('clears all guards', () {
        final chain = GuardChain()
          ..add(TestGuard())
          ..add(TestGuard());

        expect(chain.length, equals(2));

        chain.clear();

        expect(chain.length, equals(0));
        expect(chain.isEmpty, isTrue);
      });

      test('executes guards in order', () async {
        final chain = GuardChain();
        final results = <String>[];

        final guard1 = TestGuard(() {
          results.add('guard1');
          return null;
        });
        final guard2 = TestGuard(() {
          results.add('guard2');
          return null;
        });

        chain
          ..add(guard1)
          ..add(guard2);

        final result = await chain.execute(mockContext, mockState);

        expect(result, isNull);
        expect(results, equals(['guard1', 'guard2']));
      });

      test('stops execution on first redirect', () async {
        final chain = GuardChain();

        final guard1 = TestGuard(() => '/redirect1');
        final guard2 = TestGuard(() => '/redirect2');

        chain
          ..add(guard1)
          ..add(guard2);

        final result = await chain.execute(mockContext, mockState);

        expect(result, equals('/redirect1'));
      });

      test('returns null when all guards pass', () async {
        final chain = GuardChain();

        final guard1 = TestGuard(() => null);
        final guard2 = TestGuard(() => null);

        chain
          ..add(guard1)
          ..add(guard2);

        final result = await chain.execute(mockContext, mockState);

        expect(result, isNull);
      });

      test('handles empty chain', () async {
        final chain = GuardChain();

        final result = await chain.execute(mockContext, mockState);

        expect(result, isNull);
      });
    });

    group('GuardedRoute', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('provides default empty guards', () {
        const route = TestGuardedRoute();
        expect(route.guards.length, equals(0));
      });

      test('executes guards on redirect', () async {
        const route = TestGuardedRoute();
        final result = await route.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('can override guards', () {
        const route = TestGuardedRouteWithGuards();
        expect(route.guards.length, equals(1));
      });

      test('executes custom guards', () async {
        const route = TestGuardedRouteWithGuards();
        final result = await route.redirect(mockContext, mockState);
        expect(result, equals('/custom-redirect'));
      });
    });
  });
}

// Test implementations
class TestGuard implements RouteGuard {
  TestGuard([this._redirectCallback]);

  final FutureOr<String?> Function()? _redirectCallback;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return _redirectCallback?.call();
  }
}

class TestGuardedRoute extends GoRouteData with GuardedRoute {
  const TestGuardedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(
      body: Center(child: Text('Test Route')),
    );
  }
}

class TestGuardedRouteWithGuards extends GoRouteData with GuardedRoute {
  const TestGuardedRouteWithGuards();

  @override
  GuardChain get guards =>
      GuardChain()..add(TestGuard(() => '/custom-redirect'));

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(
      body: Center(child: Text('Test Route with Guards')),
    );
  }
}
