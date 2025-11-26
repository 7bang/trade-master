import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/business_setup_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/customer/customer_detail_screen.dart';
import 'screens/customer/customer_form_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_form_screen.dart';
import 'screens/transaction/transaction_form_screen.dart';
import 'screens/transaction/transaction_detail_screen.dart';

void main() async {
  // Flutter 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 앱 실행
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '거래의장인',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// 라우터 설정
final _router = GoRouter(
  routes: [
    // ========== 인증 관련 ==========
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/business-setup',
      builder: (context, state) => const BusinessSetupScreen(),
    ),

    // ========== 거래처 관련 ==========
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomerListScreen(),
    ),
    GoRoute(
      path: '/customers/new',
      builder: (context, state) => const CustomerFormScreen(),
    ),
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomerDetailScreen(customerId: id);
      },
    ),
    GoRoute(
      path: '/customers/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomerFormScreen(customerId: id);
      },
    ),

    // ========== 품목 관련 ==========
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/products/new',
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: '/products/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductFormScreen(productId: id);
      },
    ),

    // ========== 거래 관련 ==========
    GoRoute(
      path: '/customers/:customerId/transactions/new',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return TransactionFormScreen(customerId: customerId);
      },
    ),
    GoRoute(
      path: '/customers/:customerId/transactions/:id/edit',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        final id = state.pathParameters['id']!;
        return TransactionFormScreen(
          customerId: customerId,
          transactionId: id,
        );
      },
    ),
    GoRoute(
      path: '/transactions/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionDetailScreen(transactionId: id);
      },
    ),
  ],
  initialLocation: '/',
);
