// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:go_router_guards/go_router_guards.dart';

// import 'screens.dart';

// /// Example of an enhanced authentication guard using the resolver pattern
// class EnhancedAuthGuard extends RouteGuardEnhanced {
//   @override
//   FutureOr<void> onNavigation(
//     NavigationResolver resolver,
//     BuildContext context,
//     GoRouterState state,
//   ) async {
//     final authState = context.read<AuthCubit>().state;

//     if (authState.isAuthenticated) {
//       resolver.next(); // Continue navigation
//     } else {
//       // Redirect to login with the current path as a query parameter
//       final currentPath = state.uri.toString();
//       resolver.redirect('/login?redirect=${Uri.encodeComponent(currentPath)}');
//     }
//   }
// }

// /// Example of an enhanced role guard with more sophisticated logic
// class EnhancedRoleGuard extends RouteGuardEnhanced {
//   const EnhancedRoleGuard(this.requiredRoles, {this.requireAll = false});

//   final List<String> requiredRoles;
//   final bool requireAll;

//   @override
//   FutureOr<void> onNavigation(
//     NavigationResolver resolver,
//     BuildContext context,
//     GoRouterState state,
//   ) async {
//     final userState = context.read<UserCubit>().state;
//     final userRoles = userState.roles;

//     bool hasAccess;
//     if (requireAll) {
//       // User must have ALL required roles
//       hasAccess = requiredRoles.every(userRoles.contains);
//     } else {
//       // User must have at least ONE required role
//       hasAccess = requiredRoles.any(userRoles.contains);
//     }

//     if (hasAccess) {
//       resolver.next();
//     } else {
//       // Different redirects based on authentication status
//       final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
//       if (!isAuthenticated) {
//         resolver.redirect('/login');
//       } else {
//         resolver.redirect('/unauthorized');
//       }
//     }
//   }
// }

// /// Example usage of enhanced guards in a route
// /// This demonstrates how you can use the enhanced guard system
// class EnhancedExampleRoute {
//   /// Example showing how to use factory constructors
//   static RouteGuardEnhanced get enhancedProtectedGuards => GuardsEnhanced.all([
//     // Using factory constructor for authentication
//     GuardsEnhanced.authenticated(
//       check: (context) => context.read<AuthCubit>().state.isAuthenticated,
//       redirectTo: '/login',
//     ),
//     // Using factory constructor for role checking
//     GuardsEnhanced.hasRole(
//       roles: ['admin', 'moderator'],
//       getCurrentRoles: (context) => context.read<UserCubit>().state.roles,
//       redirectTo: '/unauthorized',
//     ),
//   ]);

//   /// Example showing conditional guards
//   static RouteGuardEnhanced conditionalGuards(String section) =>
//       GuardsEnhanced.conditional(
//         // Different guards based on the section
//         condition: (context, state) => section == 'admin',
//         whenTrue: GuardsEnhanced.all([
//           GuardsEnhanced.authenticated(
//             check: (context) => context.read<AuthCubit>().state.isAuthenticated,
//             redirectTo: '/login',
//           ),
//           GuardsEnhanced.hasRole(
//             roles: ['admin'],
//             getCurrentRoles: (context) => context.read<UserCubit>().state.roles,
//             redirectTo: '/unauthorized',
//           ),
//         ]),
//         whenFalse: GuardsEnhanced.authenticated(
//           check: (context) => context.read<AuthCubit>().state.isAuthenticated,
//           redirectTo: '/login',
//         ),
//       );

//   /// Example using simple callback with custom logic
//   static RouteGuardEnhanced get customLogicGuards =>
//       GuardsEnhanced.simple((resolver, context, state) async {
//         // Custom business logic
//         final authState = context.read<AuthCubit>().state;
//         final userState = context.read<UserCubit>().state;

//         // Check if it's business hours (example)
//         final now = DateTime.now();
//         final isBusinessHours = now.hour >= 9 && now.hour <= 17;

//         if (!authState.isAuthenticated) {
//           resolver.redirect('/login');
//           return;
//         }

//         if (!isBusinessHours && !userState.roles.contains('admin')) {
//           // Only admins can access outside business hours
//           resolver.redirect('/after-hours-notice');
//           return;
//         }

//         // All checks passed
//         resolver.next();
//       });

//   /// Example showing async authentication with external service
//   static RouteGuardEnhanced get asyncProtectedGuards => GuardsEnhanced.simple((
//     resolver,
//     context,
//     state,
//   ) async {
//     // Simulate async authentication check with external service
//     try {
//       // This could be a call to your authentication service
//       await Future.delayed(
//         const Duration(milliseconds: 500),
//       ); // Simulate network call

//       final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
//       if (isAuthenticated) {
//         // Additional async validation could go here
//         final hasValidSubscription = await _checkSubscription(context);
//         if (hasValidSubscription) {
//           resolver.next();
//         } else {
//           resolver.redirect('/subscription-required');
//         }
//       } else {
//         resolver.redirect('/login');
//       }
//     } catch (e) {
//       // Handle authentication service errors
//       resolver.redirect(
//         '/error?message=${Uri.encodeComponent('Authentication service unavailable')}',
//       );
//     }
//   });

//   /// Example showing anyOf guard logic
//   static RouteGuardEnhanced get flexibleAccessGuards => GuardsEnhanced.anyOf([
//     // Access granted if user is admin
//     GuardsEnhanced.hasRole(
//       roles: ['admin'],
//       getCurrentRoles: (context) => context.read<UserCubit>().state.roles,
//       redirectTo: '/unauthorized',
//     ),
//     // OR if user has premium role (simulating premium subscription)
//     GuardsEnhanced.simple((resolver, context, state) async {
//       final userState = context.read<UserCubit>().state;
//       if (userState.roles.contains('premium')) {
//         resolver.next();
//       } else {
//         resolver.redirect('/upgrade-required');
//       }
//     }),
//     // OR if it's a special promotional period
//     GuardsEnhanced.simple((resolver, context, state) {
//       final now = DateTime.now();
//       final isPromotionalPeriod = now.month == 12; // December promotion
//       if (isPromotionalPeriod) {
//         resolver.next();
//       } else {
//         resolver.block(); // Block by redirecting to current location
//       }
//     }),
//   ], fallbackRedirect: '/access-denied');

//   /// Simulate checking subscription status
//   static Future<bool> _checkSubscription(BuildContext context) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     // In a real app, this would check with your subscription service
//     return true; // Assume user has valid subscription for demo
//   }
// }

// /// Demonstration of how to integrate enhanced guards with go_router
// /// This shows the pattern without relying on generated code
// void demonstrateEnhancedGuards() {
//   // Example of using enhanced guards in go_router configuration
//   final router = GoRouter(
//     routes: [
//       GoRoute(
//         path: '/enhanced-protected',
//         builder: (context, state) => const ProtectedScreen(),
//         redirect: (context, state) async {
//           // Use enhanced guard
//           final guard = EnhancedExampleRoute.enhancedProtectedGuards;
//           final result = await guard.executeWithResolver(context, state);
//           return result.redirectPath;
//         },
//       ),
//       GoRoute(
//         path: '/custom-logic',
//         builder: (context, state) => const Scaffold(
//           body: Center(child: Text('Custom Logic Protected Content')),
//         ),
//         redirect: (context, state) async {
//           final guard = EnhancedExampleRoute.customLogicGuards;
//           final result = await guard.executeWithResolver(context, state);
//           return result.redirectPath;
//         },
//       ),
//       GoRoute(
//         path: '/flexible-access',
//         builder: (context, state) => const Scaffold(
//           body: Center(child: Text('Flexible Access Content')),
//         ),
//         redirect: (context, state) async {
//           final guard = EnhancedExampleRoute.flexibleAccessGuards;
//           final result = await guard.executeWithResolver(context, state);
//           return result.redirectPath;
//         },
//       ),
//     ],
//   );
// }

// /// Legacy guards for reference (from the original example)
// class LegacyAuthenticationGuard implements RouteGuard {
//   @override
//   FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
//     final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
//     if (!isAuthenticated) {
//       return '/login';
//     }
//     return null;
//   }
// }

// class LegacyRoleGuard implements RouteGuard {
//   const LegacyRoleGuard(this.requiredRoles);
//   final List<String> requiredRoles;

//   @override
//   FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
//     final userRoles = context.read<UserCubit>().state.roles;
//     final hasRequiredRole = requiredRoles.any(userRoles.contains);
//     if (!hasRequiredRole) {
//       return '/unauthorized';
//     }
//     return null;
//   }
// }
