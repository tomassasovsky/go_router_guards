import 'package:go_router_guards/go_router_guards.dart';

/// Utility class for creating enhanced guard combinations with a fluent API.
///
/// Similar to [Guards] but for enhanced guards that use the resolver pattern.
/// Provides static methods to combine multiple guards with different execution
/// strategies.
abstract class GuardsEnhanced {
  /// Creates a guard that requires all provided guards to pass
  ///
  /// Example:
  /// ```dart
  /// GuardsEnhanced.all([
  ///   authenticationGuard,
  ///   roleGuard,
  /// ])
  /// ```
  static RouteGuardEnhanced all(List<RouteGuardEnhanced> guards) {
    return RouteGuardEnhanced.simple((resolver, context, state) async {
      for (final guard in guards) {
        final result = await guard.executeWithResolver(context, state);
        if (!result.continueNavigation) {
          if (result.redirectPath != null) {
            resolver.redirect(result.redirectPath!);
          } else {
            resolver.block();
          }
          return;
        }
      }
      resolver.next();
    });
  }

  /// Creates a guard that requires any of the provided guards to pass
  ///
  /// Example:
  /// ```dart
  /// GuardsEnhanced.anyOf([
  ///   adminGuard,
  ///   moderatorGuard,
  /// ], fallbackRedirect: '/access-denied')
  /// ```
  static RouteGuardEnhanced anyOf(
    List<RouteGuardEnhanced> guards, {
    String? fallbackRedirect,
  }) {
    return RouteGuardEnhanced.simple((resolver, context, state) async {
      String? firstRedirectPath;

      for (final guard in guards) {
        final result = await guard.executeWithResolver(context, state);
        if (result.continueNavigation) {
          resolver.next();
          return;
        }
        firstRedirectPath ??= result.redirectPath;
      }

      // All guards failed
      final redirectPath = fallbackRedirect ?? firstRedirectPath;
      if (redirectPath != null) {
        resolver.redirect(redirectPath);
      } else {
        resolver.block();
      }
    });
  }

  /// Creates a guard that requires exactly one of the provided guards to pass
  ///
  /// Example:
  /// ```dart
  /// GuardsEnhanced.oneOf([
  ///   premiumUserGuard,
  ///   trialUserGuard,
  /// ], fallbackRedirect: '/subscription-required')
  /// ```
  static RouteGuardEnhanced oneOf(
    List<RouteGuardEnhanced> guards, {
    String? fallbackRedirect,
  }) {
    return RouteGuardEnhanced.simple((resolver, context, state) async {
      var passedCount = 0;
      String? firstRedirectPath;

      for (final guard in guards) {
        final result = await guard.executeWithResolver(context, state);
        if (result.continueNavigation) {
          passedCount++;
          if (passedCount > 1) {
            // More than one guard passed, this violates oneOf constraint
            resolver.block();
            return;
          }
        } else {
          firstRedirectPath ??= result.redirectPath;
        }
      }

      if (passedCount == 1) {
        resolver.next();
      } else {
        // Either no guards passed or more than one passed
        final redirectPath = fallbackRedirect ?? firstRedirectPath;
        if (redirectPath != null) {
          resolver.redirect(redirectPath);
        } else {
          resolver.block();
        }
      }
    });
  }
}
