import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

void main() {
  testWidgets('block redirects to current or root based on target',
      (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final resolver = NavigationResolver(router)..block();
    final result = await resolver.future;
    expect(result.continueNavigation, isFalse);
    // On initial load, current == target, so redirects to '/'
    expect(result.redirectPath, '/');
  });
}
