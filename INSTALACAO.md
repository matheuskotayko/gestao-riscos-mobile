# Instalação — Gestão de Risco UFSM

Guia passo a passo pra clonar o repositório e rodar o projeto do zero. Complementa o [README.md](README.md) (que já traz uma versão resumida) com mais detalhe — em especial as duas formas de rodar o app: **emulador Android** e **celular físico**.

---

## Pré-requisitos

- **Docker** e **Docker Compose** (pra subir a API + banco + object storage).
- **Git**.
- Pra rodar o app a partir do código-fonte: **Flutter SDK** (canal stable, 3.x) com o Android toolchain configurado (`flutter doctor` sem erros).
- Um dispositivo Android pra testar: **emulador** (Android Studio) ou **celular físico** com Depuração USB.

> Se o objetivo é só ver o app funcionando sem instalar o Flutter, pule direto para [Opção rápida: instalar o APK pronto](#opção-rápida-instalar-o-apk-pronto) — só precisa de um emulador ou celular, nada de SDK.

---

## 1. Clonar o repositório

```bash
git clone git@github.com:matheuskotayko/gestao-riscos-mobile.git
cd gestao-riscos-mobile
```

(Se não tiver chave SSH configurada no GitHub, use a URL HTTPS: `https://github.com/matheuskotayko/gestao-riscos-mobile.git`.)

---

## 2. Subir o backend

Um único comando, na raiz do repositório:

```bash
docker compose up --build
```

Isso sobe três serviços:

- **`backend`** — API Django em `http://localhost:8000`.
- **`db`** — PostgreSQL.
- **`minio`** — object storage das fotos de evidência, console em `http://localhost:9001` (`minioadmin` / `minioadmin`).

Na primeira subida, o container do backend roda `migrate` e `seed_apresentacao` automaticamente — não precisa criar usuário nem popular dado nenhum na mão. Espera aparecer uma linha do tipo `Starting development server at http://0.0.0.0:8000/` no log antes de seguir pro próximo passo.

Pra derrubar tudo depois: `docker compose down` (ou `Ctrl+C` e depois `docker compose down`).

> Não precisa criar nenhum arquivo `.env` pra esse passo — todas as variáveis têm valor padrão no `docker-compose.yml`. Só é necessário mexer nisso se for testar em celular físico (ver [Passo 3B](#3b---celular-físico-via-usb)).

### Verificando que a API subiu

```bash
curl http://localhost:8000/api/usuarios/setores/
```

Deve devolver um JSON com a lista de unidades (não erro de conexão).

---

## 3. Rodar o app mobile

### Opção rápida: instalar o APK pronto

O repositório publica um APK já compilado nas [Releases](https://github.com/matheuskotayko/gestao-riscos-mobile/releases) do GitHub — não precisa instalar Flutter nem Android SDK, só um emulador ou celular com o backend do Passo 2 rodando.

1. Baixa o `.apk` da [última release](https://github.com/matheuskotayko/gestao-riscos-mobile/releases/latest).
2. Instala num **emulador Android já aberto** (arrasta o arquivo `.apk` pra dentro da janela do emulador) ou num **celular físico** (copia o arquivo pro aparelho e abre, com "instalar de fontes desconhecidas" permitido).
3. Abre o app e faz login (credenciais em [Acesso de teste](#acesso-de-teste)).

**Atenção:** esse APK vem fixo em `API_BASE_URL=http://10.0.2.2:8000`, que só funciona em **emulador** (é o endereço fixo que o Android usa pra apontar pro `localhost` da máquina host). Num celular físico ele não vai achar o backend — pra celular físico, siga a [Opção B](#3b---celular-físico-via-usb) abaixo, que exige compilar com o `.env` ajustado.

Se quiser rodar a partir do código-fonte (pra poder mudar o `.env`, testar as duas formas, ou simplesmente porque é o fluxo mais confiável), siga as opções A e B a seguir.

### Preparo comum (emulador ou celular)

```bash
cd mobile
cp .env.example .env
flutter pub get
```

O `.env.example` já vem com `API_BASE_URL=http://10.0.2.2:8000`, que é o valor certo pra **emulador**. Pra celular físico esse valor muda — ver Opção B.

### 3A — Emulador Android

1. Abre o **Android Studio** → **Device Manager** → **Create Device** → escolhe qualquer Pixel recente com imagem de sistema API 34 ou 35 → finaliza a criação.
2. Inicia o emulador criado (▶ no Device Manager).
3. Confirma que o Flutter enxerga o dispositivo:
   ```bash
   flutter devices
   ```
   Deve listar algo como `sdk gphone64 x86 64 (emulator-5554)`.
4. Roda o app:
   ```bash
   flutter run
   ```
   Se houver mais de um dispositivo conectado, especifica com `-d emulator-5554` (ou o id que apareceu no passo anterior).

Não precisa mudar mais nada — `10.0.2.2` já é o endereço que o emulador usa pra alcançar o backend rodando na máquina host, e o `docker-compose.yml` já serve as fotos em `10.0.2.2:9000` por padrão.

**Sem Android Studio (só linha de comando):** dá pra criar e abrir o emulador sem instalar a IDE, usando o [`cmdline-tools`](https://developer.android.com/studio#command-tools) do Android SDK:

```bash
sdkmanager "platform-tools" "emulator" "platforms;android-35" "system-images;android-35;google_apis;x86_64"
avdmanager create avd -n gestao -k "system-images;android-35;google_apis;x86_64" -d "pixel_6"
emulator -avd gestao -no-snapshot &
adb wait-for-device
flutter run -d emulator-5554
```

### 3B - Celular físico via USB

1. No celular: **Ajustes → Sobre o telefone** → toca 7 vezes em "Número da versão" pra habilitar as **Opções do desenvolvedor**. Depois **Ajustes → Sistema → Opções do desenvolvedor** → liga **Depuração USB**.
2. Conecta o celular no computador por cabo USB e aceita o prompt "Permitir depuração USB?" que aparece na tela do aparelho.
3. Confirma que o adb enxerga o aparelho:
   ```bash
   adb devices
   ```
   Deve listar o dispositivo como `device` (não `unauthorized` — se aparecer isso, olha a tela do celular e aceita o prompt).
4. Encaminha as portas do backend e do MinIO do celular pro `localhost` do computador:
   ```bash
   adb reverse tcp:8000 tcp:8000
   adb reverse tcp:9000 tcp:9000
   ```
   Isso faz o celular enxergar `localhost:8000` e `localhost:9000` como se fossem portas locais dele — funciona por cabo USB independente de Wi-Fi, rede local ou firewall.
5. Ajusta `mobile/.env`:
   ```
   API_BASE_URL=http://localhost:8000
   ```
6. Ajusta o `.env` da **raiz do repositório** (cria a partir do exemplo se ainda não existir) pra apontar as fotos de evidência pro mesmo esquema:
   ```bash
   cp .env.example .env    # na raiz, se ainda não tiver
   ```
   E edita a linha:
   ```
   MINIO_PUBLIC_DOMAIN=localhost:9000
   ```
   Depois recria o backend pra pegar a variável nova (sem precisar rebuildar a imagem):
   ```bash
   docker compose up -d
   ```
7. Roda o app:
   ```bash
   cd mobile
   flutter run
   ```
   Se tiver o emulador aberto também, especifica o celular com `-d <id-do-aparelho>` (aparece em `flutter devices`).

> **Atenção:** o `.env` do app é lido só na inicialização (é um asset embutido no APK). Se mudar `API_BASE_URL` com o app já rodando, um hot reload (`r`) não é suficiente — precisa de hot restart (`R`) ou rodar `flutter run` de novo.

> Esse encaminhamento via `adb reverse` precisa do cabo conectado. Se o cabo cair, refaz os dois comandos do passo 4 antes de tentar de novo.

---

## Acesso de teste

```
SIAPE: 202512603
Senha: 12345678
```

Esse é o administrador criado pelo seed. Os demais gestores de demonstração (perfis `gestor` e `gestor_adm`, pra testar as permissões por setor) usam a mesma senha `12345678` — a lista completa de SIAPEs está em `backend/usuarios/management/commands/seed_apresentacao.py`.

---

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| App trava numa tela preta ou de carregamento | Backend não está de pé | Confere com `docker compose ps` — todos os serviços devem estar `Up`/`healthy` |
| Erro de conexão só no emulador | `.env` apontando pra `localhost` em vez de `10.0.2.2` | `10.0.2.2` é o endereço fixo que o emulador usa pro host, `localhost` dentro do emulador é o próprio emulador |
| Erro de conexão só no celular físico | Portas não encaminhadas ou `.env` errado | Refaz `adb reverse tcp:8000 tcp:8000` e `adb reverse tcp:9000 tcp:9000`, confirma `API_BASE_URL=http://localhost:8000` e reinicia o app (hot restart) |
| Login funciona mas fotos de monitoramento não carregam | `MINIO_PUBLIC_DOMAIN` não bate com o dispositivo usado | Emulador: `10.0.2.2:9000` (padrão). Celular físico: `localhost:9000` com `adb reverse` ativo |
| `adb devices` mostra `unauthorized` | Prompt de confiança não foi aceito no celular | Olha a tela do aparelho e aceita "Permitir depuração USB?" |
| Mudou o `.env` mas o app continua com o valor antigo | `.env` é lido só na inicialização | Hot restart (`R`) ou `flutter run` de novo — hot reload (`r`) não recarrega assets |

---

## Rodando os testes automatizados

```bash
# Backend (214 testes)
cd backend && pytest

# Mobile (82 testes, não precisa de emulador)
cd mobile && flutter test
```
