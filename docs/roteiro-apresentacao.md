# Roteiro de apresentação — app mobile

Fala guiada sobre as partes do app que sustentam a demonstração. Os trechos em
citação são para ler/adaptar; o resto é contexto para responder perguntas.

---

## Motor de sincronização (~2 min)

A parte com mais decisão de engenharia. Se for dominar só um assunto, é este.

**Abertura**

> A parte que dá mais trabalho num app de campo não é a tela, é o que acontece
> quando não tem internet. O nosso funciona offline por inteiro, e isso exige
> quatro mecanismos.

**1. Fila de mutações**

> Tudo que o usuário cria ou edita sem rede não se perde: vira uma linha numa
> fila no banco local, com a operação e os dados. Quando a conexão volta, a
> fila é enviada na ordem.

**2. Colapso da fila**

> Se o gestor editar o mesmo risco três vezes offline, não mandamos três
> requisições — a fila colapsa numa só. E se ele criar um risco e depois
> excluir, ainda offline, as duas operações se anulam: o servidor nunca fica
> sabendo.

**3. Pull incremental**

> Para baixar, não puxamos tudo toda vez. O app guarda a data da última
> alteração que já tem e pede só o que mudou depois disso. Economiza dado e
> bateria.

**4. Conflito por versão**

> O caso difícil: duas pessoas editam o mesmo risco. Quando o app envia, manda
> junto a versão que tinha como base. Se o servidor viu que mudou nesse meio
> tempo, responde 409 com a versão atual — e o app adota a do servidor.
> Escolhemos servidor vence, porque é a fonte de verdade da auditoria.

**Fechamento**

> Um risco criado offline precisa de identificador antes de existir no
> servidor. Ele nasce com um UUID temporário marcado como local, e quando
> finalmente sobe, o app troca pela chave real sem que a tela aberta quebre.

Onde está no código: `lib/data/sync/motor_sync.dart` (envio, pull, conflito) e
`lib/data/local/dao_sync.dart` (fila, colapso, cursor, remapeamento de UUID).

---

## Perguntas prováveis

**"Por que não usaram Provider / Bloc / Riverpod?"**

> O estado compartilhado do app é o banco local, não memória. Cada tela lê do
> banco e tem seu estado próprio com setState. Um container global resolveria
> pouco e adicionaria camada.

**"Como funciona a autenticação?"**

> JWT de acesso único, de vida longa, sem refresh — é o que o backend emite.
> Fica no armazenamento seguro do Android. Logout limpa a sessão do aparelho;
> o servidor não revoga token.

Tem também login offline: no primeiro login com rede o app guarda um hash
PBKDF2 da senha e valida localmente quando a API não responde. A senha em si
nunca é gravada.

**"E as permissões, ficam só no app?"**

> Não — o backend é a fonte de verdade e checa tudo de novo. O app espelha as
> regras só para não oferecer ao usuário um botão que vai falhar.

Detalhe que rende pergunta: nem o admin escapa da regra de setor. O backend não
dá bypass para superusuário na escrita de risco, então a interface também não
dá. Está comentado no código porque parece bug e não é.

**"Como o nível de risco é calculado?"**

> Probabilidade vezes impacto, escalas de 1 a 5, calculado no backend e nunca
> enviado pelo app. Cada risco tem o nível inerente, antes dos controles, e o
> residual, depois deles — é o "inerente 12 → residual 6" que aparece nos cards.

Faixas: extremo ≥ 20, alto ≥ 12, moderado ≥ 4, baixo < 4.

---

## Antes de apresentar

- Toda tela que for mostrar offline precisa ter sido aberta **uma vez com
  conexão** — o cache enche por demanda. Vale para Equipe, Dashboard e os
  detalhes de risco.
- Subir tudo: `./run.sh` na raiz (backend + emulador + app).
- Credenciais do seed em [INSTALACAO.md](../INSTALACAO.md).
