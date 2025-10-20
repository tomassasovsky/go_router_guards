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
    // On initial load, current == target, so redirects to '/'
    expect(result, isA<RedirectResult>());
    expect((result as RedirectResult).path, '/');
  });

  testWidgets('context getter throws when navigator not mounted',
      (tester) async {
    // No router mounted, resolver.context should throw
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
    );
    final resolver = NavigationResolver(router);
    expect(() => resolver.context, throwsA(isA<RouterNotMountedException>()));
  });

  // Removed brittle test that depended on internal router transient state
}
