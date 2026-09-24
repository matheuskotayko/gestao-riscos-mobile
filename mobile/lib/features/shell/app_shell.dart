import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/role.dart';
import '../../data/services/token_service.dart';

const _ordemBranches = [
  '/riscos',
  '/dashboard',
  '/equipe',
  '/admin',
  '/perfil',
];
List<AbaShell> tabsPara(Role role) => [
  const AbaShell(
    '/riscos',
    Icons.warning_amber_outlined,
    Icons.warning_amber,
    'Riscos',
  ),
  const AbaShell(
    '/dashboard',
    Icons.insights_outlined,
    Icons.insights,
    'Dashboard',
  ),
  if (role.podeGerenciarEquipe)
    const AbaShell('/equipe', Icons.groups_outlined, Icons.groups, 'Equipe'),
  if (role.ehAdmin)
    const AbaShell(
      '/admin',
      Icons.admin_panel_settings_outlined,
      Icons.admin_panel_settings,
      'Admin',
    ),
  const AbaShell('/perfil', Icons.person_outline, Icons.person, 'Perfil'),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell, this.tokens});
  final StatefulNavigationShell navigationShell;
  final TokenService? tokens;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final TokenService _tokens = widget.tokens ?? TokenService();
  List<AbaShell> _tabs = tabsPara(Role.gestor);
  @override
  void initState() {
    super.initState();
    _carregarPapel();
  }

  Future<void> _carregarPapel() async {
    final role = (await _tokens.getUsuario())?.role ?? Role.gestor;
    if (!mounted) return;
    setState(() => _tabs = tabsPara(role));
  }

  int _indexAtual() {
    final path = _ordemBranches[widget.navigationShell.currentIndex];
    final i = _tabs.indexWhere((t) => t.path == path);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexAtual(),
        onDestinationSelected: (i) => widget.navigationShell.goBranch(
          _ordemBranches.indexOf(_tabs[i].path),
        ),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class AbaShell {
  const AbaShell(this.path, this.icon, this.activeIcon, this.label);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
