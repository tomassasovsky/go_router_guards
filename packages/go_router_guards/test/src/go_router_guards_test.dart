// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

// Not required for test files

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_guards/go_router_guards.dart';

void main() {
  group('go_router_guards', () {
    test('exports essential classes', () {
      // Test that key classes are exported from both packages
      expect(RouteGuard, isNotNull);
      expect(NavigationResolver, isNotNull);
      expect(GuardResult, isNotNull);
      expect(Guards, isNotNull);
      expect(GoRouterGuard, isNotNull);
      expect(RouteGuardUtils, isNotNull);
    });

    test('can create conditional guard', () {
      expect(
        () => ConditionalGuard(
          guard: _TestGuard(),
          includedPaths: const ['/test'],
        ),
        returnsNormally,
      );
    });
  });
}

class _TestGuard extends RouteGuard<Object, Object> {
  @override
  Future<void> onNavigation(
    NavigationResolver<Object, Object> resolver,
    Object context,
    Object state,
  ) async {
    resolver.next();
  }
}
