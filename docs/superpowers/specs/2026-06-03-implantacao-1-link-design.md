# Implantação do Petra — Página de 1 Link (PWA + Windows + Android)

**Data:** 2026-06-03
**Status:** Aprovado para planejamento

## Contexto

O dono da empresa cliente precisa começar a usar o Petra de vez. O objetivo é entregar **um único link** que, ao ser aberto, vira uma página inteligente que:

1. Detecta o dispositivo do dono (Windows PC, iPhone, Android, navegador desktop);
2. Destaca o caminho de instalação certo para aquele aparelho, com instrução visual do último passo;
3. Lista sempre os 3 acessos (Web/PWA, instalador Windows, APK Android), explicando cada um.

Todo o acesso aponta para o mesmo backend Supabase de produção (`prxkfifwuygtlynozdqx`) e para a conta de admin que o desenvolvedor cria antecipadamente para o dono. Não há onboarding self-service: o dono apenas faz login.

### Limite técnico assumido (decisão de produto)
Instalação 100% silenciosa **não existe** em nenhum navegador/OS. O download pode iniciar sozinho; o passo final de instalar (abrir o `.exe` no Windows; "Adicionar à Tela de Início" no iPhone; tocar "Instalar" no Android/Chrome) **sempre exige 1 ação do dono**. A entrega busca o caminho mais curto: detectar o aparelho, mostrar o botão certo e guiar o último passo visualmente.

## Decisões tomadas

| Tema | Decisão |
|---|---|
| Plataformas | PWA (cobre iPhone+Android+PC) + instalador Windows + APK Android |
| iPhone | PWA via Safari "Adicionar à Tela de Início" (sem App Store, sem Apple Developer) |
| Hospedagem | Vercel grátis — landing, app web, `.exe` e APK no **mesmo** projeto Vercel |
| Conta do dono | Desenvolvedor cria a conta admin (email + senha provisória) antes de entregar |
| Windows | Instalador profissional via **Inno Setup** (atalho menu Iniciar + desktop) |
| Android | APK assinado (keystore já existe) disponível para download |
| Estrutura do link | 1 link → landing com detecção de dispositivo → 3 acessos listados |

## Arquitetura da entrega

```
https://petra-<empresa>.vercel.app/
├── /                → landing inteligente (detecção de dispositivo)
├── /app/            → PWA Flutter (build web) — o sistema em si
├── /download/petra-setup.exe   → instalador Windows
└── /download/petra.apk         → APK Android assinado
```

A landing (`index.html` estático) é servida na raiz. O app PWA fica sob `/app/` (build Flutter com `--base-href=/app/`). Os binários ficam em `/download/`.

## Componentes

### 1. Página de landing (`web_landing/index.html`)
- HTML/CSS/JS estático, único arquivo, sem dependências.
- Detecta `navigator.userAgent` / `navigator.platform` → classifica em: iPhone (Safari), Android (Chrome), Windows PC, outro/desktop.
- Renderiza o card de destaque do dispositivo detectado:
  - **Windows:** botão "Baixar e instalar no PC" que inicia download do `.exe`; instrução "abra o arquivo → Avançar".
  - **iPhone:** botão "Abrir o app agora" (link para `/app/`); instrução com seta para Compartilhar → "Adicionar à Tela de Início".
  - **Android:** botão "Abrir o app" + link "baixar APK"; menção ao banner Instalar do Chrome.
  - **Desktop genérico:** botão "Abrir o app" + dica do botão Instalar no Chrome/Edge.
- Abaixo do destaque: seção fixa com os 3 acessos (Web, Windows, Android) e descrição curta de cada.
- Identidade visual do app (laranja `#FF8C42`, fundo escuro, fontes Syne/Jakarta).

### 2. PWA (ajuste do já existente)
- Corrigir `web/manifest.json`: `name`/`short_name` para "Petra ERP" e "Petra"; `description` real; `background_color`/`theme_color` para a identidade do app (`#0B0F19` / `#FF8C42` a decidir no plano); confirmar ícones maskable.
- Build com `--base-href=/app/` e os `--dart-define` de `SUPABASE_URL`/`SUPABASE_ANON_KEY` (obrigatórios — ver memória de build).
- Verificar "installable" via Lighthouse/DevTools.

### 3. Instalador Windows (Inno Setup)
- Script `.iss` empacotando a saída de `flutter build windows --release` (pasta `build/windows/x64/runner/Release/`).
- Cria atalho no menu Iniciar e na área de trabalho; ícone do app; nome "Petra ERP".
- Saída: `petra-setup.exe`.
- **Não assinado** nesta versão → SmartScreen avisa na 1ª execução (documentar no checklist do dono).

### 4. APK Android
- `flutter build apk --release` com `--dart-define` de Supabase.
- Assinado pela keystore existente (`android/key.properties` + `upload-keystore.jks`).
- Confirmar permissão INTERNET no manifest (ver memória).
- Saída: `petra.apk`.

### 5. Deploy Vercel
- Projeto Vercel servindo o diretório com a landing na raiz, `/app/` (PWA) e `/download/` (binários).
- `vercel.json` para roteamento/headers se necessário.
- Pré-requisito: instalar Vercel CLI (`npm i -g vercel`) ou usar dashboard.

## Pré-requisitos a instalar (máquina de build)
- **Inno Setup** (`iscc`) — não instalado.
- **Vercel CLI** — não instalado (ou usar dashboard web).
- Flutter e Node já presentes.

## Verificação (como provar que funciona)

Testável pelo desenvolvedor:
1. **Web boot:** servir o build e abrir — sem tela branca; login do dono funciona contra o Supabase de produção.
2. **PWA installable:** DevTools/Lighthouse aponta o app como instalável; manifest com nome/ícones corretos.
3. **Detecção da landing:** abrir a landing com User-Agent simulado de iPhone, Android e Windows (DevTools device toolbar) → o card correto aparece em cada caso; os 3 links resolvem.
4. **Instalador Windows:** rodar `petra-setup.exe` numa pasta limpa → instala, cria atalhos, o app abre e conecta no Supabase.
5. **APK:** instalar `petra.apk` num Android (ou emulador) → abre e conecta.
6. **Links de download:** no Vercel publicado, `/download/petra-setup.exe` e `/download/petra.apk` baixam corretamente.

Dependente dos aparelhos do dono (checklist a entregar, não testável daqui):
- iPhone: "Adicionar à Tela de Início" no Safari real do dono.
- Android: tocar "Instalar"/abrir APK no aparelho do dono.

Pré-entrega (responsabilidade do desenvolvedor):
- Conta admin do dono criada (email + senha provisória).
- Link Vercel publicado e testado num celular real antes de enviar.

## Fora de escopo (YAGNI)
- App nativo iOS / App Store.
- Onboarding self-service / cadastro de empresa.
- Auto-update do app Windows.
- Assinatura de código do `.exe` (certificado pago).
- CI/CD automatizado.
