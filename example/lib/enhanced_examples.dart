// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:go_router_guards/go_router_guards.dart';

// import 'screens.dart';

// part 'enhanced_examples.g.dart'; // Uncomment after running build_runner

// // Example of an enhanced authentication guard using the resolver pattern
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

// // Example of an enhanced role guard with more sophisticated logic
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

// // Example showing how to use factory constructors
// @TypedGoRoute<EnhancedProtectedRoute>(path: '/enhanced-protected')
// class EnhancedProtectedRoute extends GoRouteData
//     with _$EnhancedProtectedRoute, GuardedRoute {
//   const EnhancedProtectedRoute();

//   @override
//   RouteGuardEnhanced get guards => GuardsEnhanced.all([
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

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return const ProtectedScreen();
//   }
// }

// // Example showing conditional guards
// @TypedGoRoute<ConditionalRoute>(path: '/conditional/:section')
// class ConditionalRoute extends GoRouteData
//     with _$ConditionalRoute, GuardedRoute {
//   const ConditionalRoute(this.section);

//   final String section;

//   @override
//   RouteGuardEnhanced get guards => GuardsEnhanced.conditional(
//     // Different guards based on the section
//     condition: (context, state) => section == 'admin',
//     whenTrue: GuardsEnhanced.all([
//       GuardsEnhanced.authenticated(
//         check: (context) => context.read<AuthCubit>().state.isAuthenticated,
//         redirectTo: '/login',
//       ),
//       GuardsEnhanced.hasRole(
//         roles: ['admin'],
//         getCurrentRoles: (context) => context.read<UserCubit>().state.roles,
//         redirectTo: '/unauthorized',
//       ),
//     ]),
//     whenFalse: GuardsEnhanced.authenticated(
//       check: (context) => context.read<AuthCubit>().state.isAuthenticated,
//       redirectTo: '/login',
//     ),
//   );

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Section: $section')),
//       body: Center(child: Text('Content for $section section')),
//     );
//   }
// }

// // Example using simple callback with custom logic
// @TypedGoRoute<CustomLogicRoute>(path: '/custom-logic')
// class CustomLogicRoute extends GoRouteData
//     with _$CustomLogicRoute, GuardedRoute {
//   const CustomLogicRoute();

//   @override
//   RouteGuardEnhanced get guards =>
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

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return const Scaffold(
//       body: Center(child: Text('Custom Logic Protected Content')),
//     );
//   }
// }

// // Example showing async authentication with external service
// @TypedGoRoute<AsyncProtectedRoute>(path: '/async-protected')
// class AsyncProtectedRoute extends GoRouteData
//     with _$AsyncProtectedRoute, GuardedRoute {
//   const AsyncProtectedRoute();

//   @override
//   RouteGuardEnhanced get guards => GuardsEnhanced.simple((
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

//       if (!context.mounted) return;

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

//   // Simulate checking subscription status
//   Future<bool> _checkSubscription(BuildContext context) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     // In a real app, this would check with your subscription service
//     return true; // Assume user has valid subscription for demo
//   }

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return const Scaffold(body: Center(child: Text('Async Protected Content')));
//   }
// }

// // Example showing anyOf guard logic
// @TypedGoRoute<FlexibleAccessRoute>(path: '/flexible-access')
// class FlexibleAccessRoute extends GoRouteData
//     with _$FlexibleAccessRoute, GuardedRoute {
//   const FlexibleAccessRoute();

//   @override
//   RouteGuardEnhanced get guards => GuardsEnhanced.anyOf([
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
//         resolver.block(); // No redirect, just block
//       }
//     }),
//   ], fallbackRedirect: '/access-denied');

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return const Scaffold(body: Center(child: Text('Flexible Access Content')));
//   }
// }

// // Routes that maintain backward compatibility with legacy guards
// @TypedGoRoute<BackwardCompatibleRoute>(path: '/backward-compatible')
// class BackwardCompatibleRoute extends GoRouteData
//     with _$BackwardCompatibleRoute, GuardedRoute {
//   const BackwardCompatibleRoute();

//   @override
//   RouteGuard get guards => Guards.all([
//     // Legacy guard still works
//     AuthenticationGuard(),
//     RoleGuard(['user']),
//   ]);

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return const Scaffold(
//       body: Center(child: Text('Backward Compatible Content')),
//     );
//   }
// }

// // Example showing mixed legacy and enhanced guards
// @TypedGoRoute<MixedGuardsRoute>(path: '/mixed-guards')
// class MixedGuardsRoute extends GoRouteData
//     with _$MixedGuardsRoute, GuardedRoute {
//   const MixedGuardsRoute();

//   @override
//   RouteGuard get guards => Guards.all([
//     // Legacy guard
//     AuthenticationGuard(),
//     // Enhanced guard converted to legacy using toEnhanced().redirect()
//     GuardsEnhanced.hasRole(
//       roles: ['admin'],
//       getCurrentRoles: (context) => context.read<UserCubit>().state.roles,
//       redirectTo: '/unauthorized',
//     ),
//   ]);

//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     return const Scaffold(body: Center(child: Text('Mixed Guards Content')));
//   }
// }

// // Legacy guards for reference (from the original example)
// class AuthenticationGuard implements RouteGuard {
//   @override
//   FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
//     final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
//     if (!isAuthenticated) {
//       return '/login';
//     }
//     return null;
//   }
// }

// class RoleGuard implements RouteGuard {
//   const RoleGuard(this.requiredRoles);
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
