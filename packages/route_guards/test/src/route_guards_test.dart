// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

// Not required for test files
// ignore_for_file: prefer_const_constructors
import 'package:route_guards/route_guards.dart';
import 'package:test/test.dart';

void main() {
  group('route_guards', () {
    test('exports essential classes', () {
      // Test that key classes are exported
      expect(RouteGuard, isNotNull);
      expect(NavigationResolver, isNotNull);
      expect(GuardResult, isNotNull);
      expect(Guards, isNotNull);
    });

    test('GuardResult factories work correctly', () {
      final allowResult = GuardResult.allow();
      expect(allowResult.continueNavigation, isTrue);
      expect(allowResult.redirectPath, isNull);

      final redirectResult = GuardResult.redirect('/login');
      expect(redirectResult.continueNavigation, isFalse);
      expect(redirectResult.redirectPath, equals('/login'));
    });
  });
}
