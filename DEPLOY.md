# Petra ERP — Guia de Distribuição e Atualização

> Fonte da verdade para publicar o Petra e subir atualizações. Toda nova versão deve atualizar **os 3 alvos de uma vez**: Web (PWA), Windows (instalador) e Android (APK).

## Visão geral

O dono usa **1 link único** que abre uma landing inteligente (detecta o aparelho) com 3 formas de instalar. Tudo hospedado no mesmo projeto Vercel.

**Link de produção (público):** https://deploy-ochre-rho.vercel.app

| URL | O que é |
|---|---|
| `/` | Landing inteligente (detecta Windows/iPhone/Android) |
| `/app/` | O sistema (PWA Flutter) — instalável no iPhone, Android e PC |
| `/download/petra-setup.exe` | Instalador Windows (Inno Setup) |
| `/download/petra.apk` | APK Android assinado |

**Backend:** Supabase de produção `prxkfifwuygtlynozdqx`. Todos os 3 alvos apontam para o mesmo banco e a mesma conta do dono.

## Estrutura no repositório

```
deploy/                       # tudo que vai pro Vercel
├── index.html                # landing (versionado)
├── vercel.json               # roteamento + headers de download (versionado)
├── app/                      # build web (GERADO — git-ignored)
└── download/
    ├── petra-setup.exe       # GERADO — git-ignored
    └── petra.apk             # GERADO — git-ignored
installer/petra.iss           # script do instalador Windows (versionado)
petra_erp/web/manifest.json   # nome/cores do PWA (versionado)
```

Apenas código-fonte vai pro git. Os binários e o build são regenerados a cada release (ver `.gitignore`).

## Pré-requisitos (instalados na máquina de build)

- **Flutter** — `C:\flutter\bin\flutter.bat`
- **Inno Setup** — `%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe` (instalado via `winget install JRSoftware.InnoSetup`)
- **Vercel CLI** — `npm i -g vercel` (login já feito: conta `filirodrigues`, org `atrlocacoes`)
- **Android SDK** — para `apksigner` (verificação de assinatura)

## Credenciais de build (OBRIGATÓRIAS)

Sem os dois `--dart-define` o app quebra no boot (tela branca / config error). Valores em `.env` na raiz:

```
SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co
SUPABASE_ANON_KEY=<ver .env — chave anon/publishable>
```

---

## RELEASE — subir uma atualização para TODOS os sistemas

Execute na ordem. Cada passo de build leva 1-2 min. Comandos em PowerShell.

### 0. Antes de tudo
- Suba a versão em `petra_erp/pubspec.yaml` (`version: 1.0.0+1` → `1.0.1+2`).
- Se mexeu no PWA (nome/cor/ícone), confirme `petra_erp/web/manifest.json`.

### 1. Build Web → deploy/app/
```powershell
cd petra_erp
& C:\flutter\bin\flutter.bat build web --release `
  --base-href=/app/ `
  --dart-define=SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY do .env>
cd ..
New-Item -ItemType Directory -Force "deploy\app" | Out-Null
Copy-Item -Recurse -Force "petra_erp\build\web\*" "deploy\app\"
```

### 2. Build APK → deploy/download/petra.apk
```powershell
cd petra_erp
& C:\flutter\bin\flutter.bat build apk --release `
  --dart-define=SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY do .env>
cd ..
New-Item -ItemType Directory -Force "deploy\download" | Out-Null
Copy-Item -Force "petra_erp\build\app\outputs\flutter-apk\app-release.apk" "deploy\download\petra.apk"
```

### 3. Build Windows + Instalador → deploy/download/petra-setup.exe
```powershell
cd petra_erp
& C:\flutter\bin\flutter.bat build windows --release `
  --dart-define=SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY do .env>
cd ..
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" installer\petra.iss
```

### 4. Deploy no Vercel (sobe os 3 de uma vez)
```powershell
cd deploy
vercel --prod --yes
cd ..
```
O Vercel publica a landing, o `/app/` e os dois downloads juntos. A URL `deploy-ochre-rho.vercel.app` aponta automaticamente para o novo deploy.

### 5. Verificação pós-deploy (sempre)
```powershell
# todos devem retornar 200
"https://deploy-ochre-rho.vercel.app/",
"https://deploy-ochre-rho.vercel.app/app/",
"https://deploy-ochre-rho.vercel.app/download/petra-setup.exe",
"https://deploy-ochre-rho.vercel.app/download/petra.apk" | ForEach-Object {
  try { "$([int](Invoke-WebRequest $_ -Method Head -UseBasicParsing).StatusCode)  $_" }
  catch { "FALHA $_" }
}
```
- Abrir `/app/` no navegador → tela de login aparece (sem tela branca).
- Confirmar que `petra.apk` e `petra-setup.exe` **baixam** (não abrem como página).

---

## Como o dono recebe atualizações (importante)

| Alvo | Atualiza sozinho? | O que o dono faz |
|---|---|---|
| **Web / PWA** (iPhone, Android, PC pelo link) | ✅ **Sim** — basta fechar e reabrir o app | Nada |
| **APK Android** | ❌ Não | Baixar o novo APK pelo link e reinstalar por cima |
| **Instalador Windows** | ❌ Não | Baixar o novo `.exe` pelo link e instalar por cima |

**Consequência prática:** o PWA é o canal de atualização sem atrito. Quem instalou o app Windows nativo ou o APK precisa rebaixar manualmente. Para mudanças frequentes, incentive o dono a usar a versão web/PWA.

---

## Notas e limitações conhecidas

- **Instalador `.exe` não é assinado** (sem certificado de código). O Windows mostra aviso SmartScreen na 1ª execução. A landing já instrui: *"Mais informações → Executar assim mesmo"*. Para remover o aviso seria preciso comprar um certificado de assinatura de código.
- **iPhone é sempre PWA** (Safari → "Adicionar à Tela de Início"). Não há app nativo iOS — exigiria conta Apple Developer ($99/ano) + Mac.
- **Vercel Deployment Protection (SSO) está ativa** no projeto `petra-erp`: aliases com nome bonito (ex: `petra-sistema.vercel.app`) ficam **bloqueados (401)**. Só a URL auto-gerada `deploy-ochre-rho.vercel.app` é pública. Para liberar um nome melhor: dashboard Vercel → projeto petra-erp → Settings → Deployment Protection → desligar Vercel Authentication.
- **Conta do dono é provisionada manualmente** (não há onboarding self-service): criar no Supabase (Authentication → Add user, `roles = ARRAY['admin']`) e testar o login antes de entregar.

## Projeto Vercel — dados

- Projeto: `petra-erp` (renomeado de `deploy`)
- Org/team: `atrlocacoes` (`team_tnJrsMMN7cUbeAHGNM7BxpEk`)
- projectId: `prj_1k7HSev4zVmwr2pPSwWCJRuOzp3b`
- Conta: `filirodrigues`

## Referências internas

- Spec: `docs/superpowers/specs/2026-06-03-implantacao-1-link-design.md`
- Plano de implementação: `docs/superpowers/plans/2026-06-03-implantacao-1-link.md`
