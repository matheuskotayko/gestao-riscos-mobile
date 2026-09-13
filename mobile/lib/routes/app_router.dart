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
    // cuidado: qualquer excecao nao tratada aqui dentro trava o go_router
    // pra sempre — a tela fica preta e nunca chega nem na tela de login.
    // ja aconteceu de verdade: leitura do secure storage falhando com
    // BadPaddingException (chave do keystore corrompida) travava tudo.
    // por isso TokenService trata erro de leitura e nunca deixa isso
    // vazar ate aqui — se for mexer nesse redirect, mantem essa garantia.
    redirect: (context, state) async {
      final logado = await tokenService.hasToken();
      final indoParaLogin = state.matchedLocation == '/login';

      if (!logado) return indoParaLogin ? null : '/login';
      if (indoParaLogin) return '/riscos';

      // gating por papel pras areas restritas
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
      // StatefulShellRoute (nao o ShellRoute simples) de proposito: cada aba
      // ganha seu proprio Navigator. Com ShellRoute simples, a aba ativa e
      // a UNICA pagina da pilha do router inteiro — e um showDialog aberto
      // nela (ex.: "Adicionar membro" na Equipe) faz o go_router entender
      // que a pilha toda "estourou" quando o dialogo fecha, travando o
      // app numa tela preta sem erro nenhum na hora (só um assert vago no
      // log). com uma pilha por aba isso nao acontece.
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
