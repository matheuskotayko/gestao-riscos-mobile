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

bool podeEscreverNoSetor(int setorId, List<int> setoresDoUsuario) {
  return setoresDoUsuario.contains(setorId);
}
