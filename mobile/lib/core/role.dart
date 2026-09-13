/// tres niveis de acesso do backend, checados nas views:
/// - [admin]      = is_superuser (cadastro de gestores, unidades, inativos)
/// - [gestorAdm]  = cargo == 'gestor_adm' (gerencia membros de equipe)
/// - [gestor]     = cargo == 'gestor' (crud de riscos so nos proprios setores)
enum Role {
  gestor,
  gestorAdm,
  admin;

  static Role from({required String? cargo, required bool isSuperuser}) {
    if (isSuperuser) return Role.admin;
    if (cargo == 'gestor_adm') return Role.gestorAdm;
    return Role.gestor;
  }

  bool get podeGerenciarEquipe => this == Role.gestorAdm || this == Role.admin;
  bool get ehAdmin => this == Role.admin;
}

/// espelha a permissao PertenceAoSetorDoRisco do backend: escrita num risco
/// so e permitida se o setor do risco estiver entre os setores do usuario.
/// o backend continua sendo a fonte de verdade, isso aqui so controla a ui.
///
/// atencao: nem admin (is_superuser) passa direto aqui de proposito — o
/// backend nao da bypass pra superusuario nessa regra, entao a ui tambem
/// nao deve dar. se um admin precisar editar risco de outro setor, o jeito
/// e ele se vincular ao setor primeiro.
bool podeEscreverNoSetor(int setorId, List<int> setoresDoUsuario) {
  return setoresDoUsuario.contains(setorId);
}
