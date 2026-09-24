import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/role.dart';
import '../data/services/token_service.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/equipe/equipe_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/perfil/perfil_screen.dart';
import '../features/riscos/riscos_screen.dart';
import '../features/shell/app_shell.dart';

GoRouter buildRouter(TokenService tokenService) {
  return GoRouter(
    initialLocation: '/riscos',
    redirect: (context, state) async {
      final logado = await tokenService.hasToken();
      final indoParaLogin = state.matchedLocation == '/login';
      if (!logado) return indoParaLogin ? null : '/login';
      if (indoParaLogin) return '/riscos';
      final role = (await tokenService.getUsuario())?.role ?? Role.gestor;
      final loc = state.matchedLocation;
      if (loc.startsWith('/admin') && !role.ehAdmin) return '/riscos';
      if (loc.startsWith('/equipe') && !role.podeGerenciarEquipe) {
        return '/riscos';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/riscos',
                builder: (context, state) => const RiscosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/equipe',
                builder: (context, state) => const EquipeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (context, state) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Rota não encontrada: ${state.uri}')),
    ),
  );
}
