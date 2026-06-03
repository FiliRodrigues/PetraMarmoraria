# Implantação do Petra — Página de 1 Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar um único link que abre uma landing inteligente (detecta o dispositivo do dono) oferecendo o sistema Petra como PWA, instalador Windows e APK Android — tudo hospedado no mesmo projeto Vercel.

**Architecture:** Build estático servido pelo Vercel. A raiz (`/`) é uma landing HTML/JS que detecta o User-Agent e destaca o caminho de instalação certo. O sistema Flutter compilado para web fica sob `/app/`. Os binários (`.exe` do Windows e `.apk` do Android) ficam em `/download/`. Todo acesso aponta para o mesmo Supabase de produção.

**Tech Stack:** Flutter (web/windows/apk), HTML/CSS/JS estático para a landing, Inno Setup para o instalador Windows, Vercel para hospedagem, Supabase (produção `prxkfifwuygtlynozdqx`).

**Pré-requisitos a instalar antes de começar:**
- **Inno Setup** (fornece `iscc.exe`): baixar de https://jrsoftware.org/isdl.php e instalar. Confirmar com `& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /?`.
- **Vercel CLI**: `npm i -g vercel` (já há Node em `C:\Program Files\nodejs\node.exe`).
- Flutter já está em `C:\flutter\bin\flutter.bat`.

**Credenciais de build (do `.env`, obrigatórias — sem elas o app quebra no boot):**
- `SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co`
- `SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeGtmaWZ3dXlndGx5bm96ZHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzU0OTcsImV4cCI6MjA5NTQxMTQ5N30.eOjvkz6-ZR_dNMqRko-tnYrxKHbf-9dEf9guM2eOwrg`

---

## File Structure

```
Petra/
├── deploy/                          # NOVO — pasta de tudo que vai pro Vercel
│   ├── index.html                   # landing inteligente (raiz do link)
│   ├── vercel.json                  # roteamento/headers
│   ├── app/                         # build web do Flutter (gerado, --base-href=/app/)
│   └── download/
│       ├── petra-setup.exe          # instalador Windows (gerado pelo Inno)
│       └── petra.apk                # APK assinado (gerado pelo Flutter)
├── installer/
│   └── petra.iss                    # script Inno Setup
└── petra_erp/
    └── web/manifest.json            # MODIFICAR — nome/cores do PWA
```

A landing é um único arquivo estático sem dependências. O `vercel.json` garante que `/app/` faça fallback para o `index.html` do Flutter (SPA) e que os downloads tenham o header certo.

---

### Task 1: Corrigir o manifest do PWA

O `web/manifest.json` está genérico ("petra_erp", "A new Flutter project.", cor azul `#0175C2`). Sem isso o PWA instala com nome e cor errados no iPhone/Android.

**Files:**
- Modify: `petra_erp/web/manifest.json`

- [ ] **Step 1: Substituir nome, descrição e cores**

Substituir o conteúdo de `petra_erp/web/manifest.json` por:

```json
{
    "name": "Petra ERP",
    "short_name": "Petra",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#0B0F19",
    "theme_color": "#0B0F19",
    "description": "Petra ERP - Sistema de Gestão para Marmoraria",
    "orientation": "portrait-primary",
    "prefer_related_applications": false,
    "icons": [
        {
            "src": "icons/Icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-512.png",
            "sizes": "512x512",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-maskable-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icons/Icon-maskable-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "maskable"
        }
    ]
}
```

- [ ] **Step 2: Verificar JSON válido**

Run: `node -e "JSON.parse(require('fs').readFileSync('petra_erp/web/manifest.json','utf8')); console.log('JSON ok')"`
Expected: `JSON ok`

- [ ] **Step 3: Commit**

```bash
git add petra_erp/web/manifest.json
git commit -m "fix: manifest PWA com nome e cores do Petra"
```

---

### Task 2: Build web do Flutter para /app/

Gera o sistema compilado com base href `/app/` e as credenciais Supabase, e copia para `deploy/app/`.

**Files:**
- Create: `deploy/app/` (saída do build)

- [ ] **Step 1: Build web release com base-href e dart-defines**

Run (PowerShell, a partir da raiz `Petra/`):

```powershell
& C:\flutter\bin\flutter.bat build web --release `
  --base-href=/app/ `
  --dart-define=SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeGtmaWZ3dXlndGx5bm96ZHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzU0OTcsImV4cCI6MjA5NTQxMTQ5N30.eOjvkz6-ZR_dNMqRko-tnYrxKHbf-9dEf9guM2eOwrg
```

Working directory para o flutter é `petra_erp/`. Se o terminal estiver na raiz, rode `cd petra_erp` antes, ou use `& C:\flutter\bin\flutter.bat build web ...` dentro de `petra_erp/`.
Expected: termina com `√ Built build\web` (sem erros).

- [ ] **Step 2: Copiar o build para deploy/app/**

Run (PowerShell):

```powershell
New-Item -ItemType Directory -Force "deploy\app" | Out-Null
Copy-Item -Recurse -Force "petra_erp\build\web\*" "deploy\app\"
```

- [ ] **Step 3: Verificar que index.html do app existe e tem base href /app/**

Run: `node -e "const s=require('fs').readFileSync('deploy/app/index.html','utf8'); console.log(s.includes('href=\"/app/\"')?'base href OK':'BASE HREF FALTANDO')"`
Expected: `base href OK`

- [ ] **Step 4: Servir e validar boot local (sem tela branca)**

Run (PowerShell, em background não necessário — testar rápido):

```powershell
cd deploy; npx --yes serve -l 7799 app
```

Abrir `http://localhost:7799/app/` no Chrome. Expected: a tela de login do Petra aparece (não fica branca). Parar o serve depois (Ctrl+C no terminal correspondente).

> Nota: `deploy/app/` será regerado no fim (Task 8) com o manifest já corrigido. Não comitar `deploy/app/` ainda — é artefato; será tratado no .gitignore na Task 7.

---

### Task 3: Build do APK Android assinado

Gera o `petra.apk` assinado pela keystore existente.

**Files:**
- Create: `deploy/download/petra.apk` (saída do build)

- [ ] **Step 1: Confirmar permissão INTERNET no manifest**

Run: `node -e "const s=require('fs').readFileSync('petra_erp/android/app/src/main/AndroidManifest.xml','utf8'); console.log(s.includes('android.permission.INTERNET')?'INTERNET OK':'FALTA INTERNET')"`
Expected: `INTERNET OK`
Se faltar: adicionar `<uses-permission android:name="android.permission.INTERNET"/>` dentro de `<manifest>` antes de `<application>`.

- [ ] **Step 2: Build APK release**

Run (PowerShell, dentro de `petra_erp/`):

```powershell
& C:\flutter\bin\flutter.bat build apk --release `
  --dart-define=SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeGtmaWZ3dXlndGx5bm96ZHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzU0OTcsImV4cCI6MjA5NTQxMTQ5N30.eOjvkz6-ZR_dNMqRko-tnYrxKHbf-9dEf9guM2eOwrg
```

Expected: termina com `√ Built build\app\outputs\flutter-apk\app-release.apk`.

- [ ] **Step 3: Copiar APK para deploy/download/**

Run (PowerShell, a partir da raiz `Petra/`):

```powershell
New-Item -ItemType Directory -Force "deploy\download" | Out-Null
Copy-Item -Force "petra_erp\build\app\outputs\flutter-apk\app-release.apk" "deploy\download\petra.apk"
```

- [ ] **Step 4: Verificar que o APK foi copiado e tem tamanho razoável**

Run: `node -e "const sz=require('fs').statSync('deploy/download/petra.apk').size; console.log(sz>5000000?'APK OK ('+(sz/1048576).toFixed(1)+' MB)':'APK SUSPEITO: '+sz+' bytes')"`
Expected: `APK OK (XX.X MB)` (tipicamente 20-40 MB).

---

### Task 4: Build Windows + instalador Inno Setup

Gera o `petra-setup.exe` que empacota a saída do `flutter build windows`.

**Files:**
- Create: `installer/petra.iss`
- Create: `deploy/download/petra-setup.exe` (saída do Inno)

- [ ] **Step 1: Build Windows release**

Run (PowerShell, dentro de `petra_erp/`):

```powershell
& C:\flutter\bin\flutter.bat build windows --release `
  --dart-define=SUPABASE_URL=https://prxkfifwuygtlynozdqx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeGtmaWZ3dXlndGx5bm96ZHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzU0OTcsImV4cCI6MjA5NTQxMTQ5N30.eOjvkz6-ZR_dNMqRko-tnYrxKHbf-9dEf9guM2eOwrg
```

Expected: termina com `√ Built build\windows\x64\runner\Release\petra_erp.exe`.

- [ ] **Step 2: Criar o script Inno Setup**

Create `installer/petra.iss` com este conteúdo exato:

```iss
; Instalador do Petra ERP — gerado para distribuicao ao dono
#define MyAppName "Petra ERP"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Petra"
#define MyAppExeName "petra_erp.exe"
#define BuildDir "..\petra_erp\build\windows\x64\runner\Release"
#define IconFile "..\petra_erp\windows\runner\resources\app_icon.ico"
#define OutDir "..\deploy\download"

[Setup]
AppId={{8F3A1C20-7E4B-4D9A-9C1E-PETRAERP0001}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Petra ERP
DefaultGroupName=Petra ERP
DisableProgramGroupPage=yes
OutputDir={#OutDir}
OutputBaseFilename=petra-setup
SetupIconFile={#IconFile}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na area de trabalho"; GroupDescription: "Atalhos:"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir o Petra ERP"; Flags: nowait postinstall skipifsilent
```

> Nota: `PrivilegesRequired=lowest` instala em `%LocalAppData%\Programs` sem precisar de admin. Se o idioma `BrazilianPortuguese.isl` não existir na instalação do Inno, trocar a seção `[Languages]` por `Name: "english"; MessagesFile: "compiler:Default.isl"`.

- [ ] **Step 3: Compilar o instalador**

Run (PowerShell, a partir da raiz `Petra/`; ajustar caminho do ISCC se necessário):

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\petra.iss
```

Expected: termina com `Successful compile` e gera `deploy\download\petra-setup.exe`.

- [ ] **Step 4: Verificar que o instalador foi gerado**

Run: `node -e "const sz=require('fs').statSync('deploy/download/petra-setup.exe').size; console.log(sz>20000000?'SETUP OK ('+(sz/1048576).toFixed(1)+' MB)':'SETUP SUSPEITO: '+sz+' bytes')"`
Expected: `SETUP OK (XX.X MB)` (deve incluir as DLLs grandes — flutter_windows.dll ~20MB, pdfium ~4.5MB).

- [ ] **Step 5: Teste de instalação real**

Rodar `deploy\download\petra-setup.exe` manualmente. Expected: instala, cria atalho no menu Iniciar e (se marcado) na área de trabalho; ao abrir, a tela de login do Petra aparece e conecta no Supabase. Desinstalar depois pelo Painel de Controle.

- [ ] **Step 6: Commit do script (binários ficam fora do git — ver Task 7)**

```bash
git add installer/petra.iss
git commit -m "feat: script Inno Setup do instalador Windows"
```

---

### Task 5: Landing inteligente (página de 1 link)

A página estática que detecta o dispositivo e destaca o caminho certo. É o coração da entrega.

**Files:**
- Create: `deploy/index.html`

- [ ] **Step 1: Criar a landing**

Create `deploy/index.html` com este conteúdo exato:

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Petra ERP — Instalar</title>
<link rel="icon" href="/app/icons/Icon-192.png">
<link rel="apple-touch-icon" href="/app/icons/Icon-192.png">
<style>
  :root{--bg:#0B0F19;--surface:#131825;--elev:#1A2035;--orange:#FF8C42;--success:#34D399;--txt:#F1F5F9;--txt2:#8B9CC0;--muted:#64748B}
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:var(--bg);color:var(--txt);font-family:-apple-system,Segoe UI,Roboto,sans-serif;line-height:1.5;padding:28px 18px 60px;max-width:560px;margin:0 auto}
  .logo{width:64px;height:64px;border-radius:16px;background:linear-gradient(135deg,var(--orange),#ff6b1a);display:flex;align-items:center;justify-content:center;font-weight:800;font-size:30px;color:#1a0f06;margin:0 auto 16px}
  h1{font-size:24px;font-weight:800;text-align:center;letter-spacing:-.5px}
  .tag{text-align:center;color:var(--muted);font-size:13px;margin-top:4px;margin-bottom:24px}
  .hero{background:var(--surface);border:1px solid #232a3d;border-radius:18px;padding:22px;margin-bottom:22px}
  .hero h2{font-size:18px;margin-bottom:6px}
  .hero p{color:var(--txt2);font-size:14px;margin-bottom:16px}
  .btn{display:block;text-align:center;background:var(--orange);color:#1a0f06;font-weight:700;padding:14px;border-radius:12px;font-size:15px;text-decoration:none;margin-bottom:10px}
  .btn.ghost{background:transparent;border:1px solid #2a3247;color:var(--txt)}
  .steps{background:#0a0e17;border:1px solid #1f2638;border-radius:12px;padding:14px 16px;font-size:13.5px;color:var(--txt2);margin-top:6px}
  .steps b{color:var(--txt)}
  .steps ol{margin-left:18px;margin-top:6px}
  .steps li{padding:3px 0}
  .all{margin-top:8px}
  .all h3{font-size:12px;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);margin-bottom:12px}
  .opt{display:flex;align-items:center;gap:14px;background:var(--surface);border:1px solid #232a3d;border-radius:14px;padding:14px 16px;margin-bottom:10px;text-decoration:none;color:inherit}
  .opt .ic{font-size:24px;flex-shrink:0}
  .opt .t{font-weight:700;font-size:15px}
  .opt .d{font-size:12.5px;color:var(--txt2)}
  .opt .arrow{margin-left:auto;color:var(--muted)}
  .hidden{display:none}
</style>
</head>
<body>
  <div class="logo">P</div>
  <h1>Petra ERP</h1>
  <p class="tag" id="detected">Carregando…</p>

  <div class="hero" id="hero"></div>

  <div class="all">
    <h3>Todas as formas de acessar</h3>
    <a class="opt" href="/app/" id="opt-web">
      <span class="ic">🌐</span>
      <span><span class="t">Abrir no navegador</span><br><span class="d">Funciona em qualquer aparelho. Dá pra instalar como app.</span></span>
      <span class="arrow">›</span>
    </a>
    <a class="opt" href="/download/petra-setup.exe">
      <span class="ic">🖥️</span>
      <span><span class="t">Instalar no PC (Windows)</span><br><span class="d">Baixa o instalador e o Petra fica no menu Iniciar.</span></span>
      <span class="arrow">›</span>
    </a>
    <a class="opt" href="/download/petra.apk">
      <span class="ic">🤖</span>
      <span><span class="t">Baixar APK (Android)</span><br><span class="d">Instala como app nativo no celular Android.</span></span>
      <span class="arrow">›</span>
    </a>
  </div>

<script>
(function(){
  var ua = navigator.userAgent || "";
  var isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var isAndroid = /Android/.test(ua);
  var isWindows = /Windows NT/.test(ua);
  var hero = document.getElementById('hero');
  var det = document.getElementById('detected');

  function heroWindows(){
    det.textContent = 'Detectamos: Windows PC';
    hero.innerHTML =
      '<h2>Instalar no seu PC</h2>'+
      '<p>Clique abaixo. O instalador vai baixar — depois é só abrir e clicar em Avançar.</p>'+
      '<a class="btn" href="/download/petra-setup.exe">⬇️ Baixar e instalar no PC</a>'+
      '<a class="btn ghost" href="/app/">Ou abrir no navegador</a>'+
      '<div class="steps"><b>Depois de baixar:</b><ol>'+
      '<li>Abra o arquivo <b>petra-setup.exe</b> (na pasta Downloads).</li>'+
      '<li>Se o Windows avisar, clique em <b>"Mais informações" → "Executar assim mesmo"</b>.</li>'+
      '<li>Clique em <b>Avançar</b> até concluir. Pronto!</li></ol></div>';
  }
  function heroIOS(){
    det.textContent = 'Detectamos: iPhone';
    hero.innerHTML =
      '<h2>Instalar no seu iPhone</h2>'+
      '<p>Abra o app e adicione à tela inicial — fica com ícone igual a um aplicativo.</p>'+
      '<a class="btn" href="/app/">📲 Abrir o app agora</a>'+
      '<div class="steps"><b>Para virar ícone na tela inicial:</b><ol>'+
      '<li>Toque no botão <b>Compartilhar</b> (quadrado com seta ↑) na barra do Safari.</li>'+
      '<li>Escolha <b>"Adicionar à Tela de Início"</b>.</li>'+
      '<li>Toque em <b>Adicionar</b>. O ícone do Petra aparece na tela!</li></ol></div>';
  }
  function heroAndroid(){
    det.textContent = 'Detectamos: Android';
    hero.innerHTML =
      '<h2>Instalar no seu Android</h2>'+
      '<p>Você pode abrir como app no navegador (recomendado) ou baixar o APK.</p>'+
      '<a class="btn" href="/app/">📲 Abrir o app agora</a>'+
      '<a class="btn ghost" href="/download/petra.apk">Ou baixar o APK</a>'+
      '<div class="steps"><b>Pelo navegador:</b> ao abrir, o Chrome mostra <b>"Instalar app"</b> — toque para virar ícone na tela. '+
      '<br><b>Pelo APK:</b> abra o arquivo baixado e permita "instalar de fontes desconhecidas".</div>';
  }
  function heroDesktop(){
    det.textContent = 'Detectamos: navegador';
    hero.innerHTML =
      '<h2>Abrir o Petra</h2>'+
      '<p>Use direto no navegador. No Chrome ou Edge dá pra instalar como app (ícone no desktop).</p>'+
      '<a class="btn" href="/app/">🌐 Abrir o app agora</a>'+
      '<div class="steps">Para instalar: abra o app e clique no ícone de <b>instalar</b> na barra de endereço do Chrome/Edge.</div>';
  }

  if(isWindows) heroWindows();
  else if(isIOS) heroIOS();
  else if(isAndroid) heroAndroid();
  else heroDesktop();
})();
</script>
</body>
</html>
```

- [ ] **Step 2: Verificar HTML válido (sem erro de parse)**

Run: `node -e "const s=require('fs').readFileSync('deploy/index.html','utf8'); if(!s.includes('heroWindows')||!s.includes('/download/petra-setup.exe')||!s.includes('/download/petra.apk')||!s.includes('/app/')) throw new Error('faltam refs'); console.log('landing refs OK')"`
Expected: `landing refs OK`

- [ ] **Step 3: Teste de detecção por dispositivo**

Servir e testar com o DevTools (device toolbar) simulando cada User-Agent.

Run (PowerShell, na pasta `deploy/`):
```powershell
cd deploy; npx --yes serve -l 7799
```
Abrir `http://localhost:7799/` no Chrome. Com DevTools → Toggle device toolbar:
- iPhone selecionado → texto "Detectamos: iPhone" + instrução "Adicionar à Tela de Início".
- (No modo responsivo, editar o UA para conter "Android") → "Detectamos: Android".
- Desktop normal (Windows) → "Detectamos: Windows PC" + botão de baixar instalador.
Expected: o card correto aparece em cada caso; os 3 links na seção "Todas as formas" apontam para `/app/`, `/download/petra-setup.exe`, `/download/petra.apk`.

- [ ] **Step 4: Commit**

```bash
git add deploy/index.html
git commit -m "feat: landing inteligente de 1 link com deteccao de dispositivo"
```

---

### Task 6: Configuração do Vercel (vercel.json)

Garante o roteamento SPA do `/app/` e os headers corretos para download dos binários.

**Files:**
- Create: `deploy/vercel.json`

- [ ] **Step 1: Criar vercel.json**

Create `deploy/vercel.json` com este conteúdo exato:

```json
{
  "cleanUrls": false,
  "rewrites": [
    { "source": "/app/(.*)", "destination": "/app/index.html" }
  ],
  "headers": [
    {
      "source": "/download/petra-setup.exe",
      "headers": [
        { "key": "Content-Type", "value": "application/octet-stream" },
        { "key": "Content-Disposition", "value": "attachment; filename=\"petra-setup.exe\"" }
      ]
    },
    {
      "source": "/download/petra.apk",
      "headers": [
        { "key": "Content-Type", "value": "application/vnd.android.package-archive" },
        { "key": "Content-Disposition", "value": "attachment; filename=\"petra.apk\"" }
      ]
    }
  ]
}
```

> Nota: o rewrite de `/app/(.*)` para o `index.html` do Flutter só deve afetar rotas de navegação. Como o Flutter web usa hash/path routing dentro do próprio `index.html`, e os assets têm extensão, o Vercel serve arquivos estáticos existentes antes de aplicar o rewrite. Se algum asset 404, validar na Task 8.

- [ ] **Step 2: Verificar JSON válido**

Run: `node -e "JSON.parse(require('fs').readFileSync('deploy/vercel.json','utf8')); console.log('vercel.json ok')"`
Expected: `vercel.json ok`

- [ ] **Step 3: Commit**

```bash
git add deploy/vercel.json
git commit -m "feat: config Vercel (rewrites SPA + headers de download)"
```

---

### Task 7: Ignorar artefatos de build no git

Os builds (`deploy/app/`, binários) não devem ir pro git — são gerados. Só código-fonte (landing, vercel.json, .iss) é versionado.

**Files:**
- Modify ou Create: `.gitignore` (raiz)

- [ ] **Step 1: Adicionar entradas ao .gitignore**

Acrescentar ao final do `.gitignore` da raiz (criar o arquivo se não existir):

```gitignore
# Artefatos de deploy (gerados — nao versionar)
deploy/app/
deploy/download/
```

- [ ] **Step 2: Verificar que os artefatos estão ignorados**

Run: `cd "c:/Users/filip/Desktop/Petra" && git check-ignore deploy/app/index.html deploy/download/petra.apk`
Expected: as duas linhas são impressas (significa que estão ignoradas).

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: ignorar artefatos de deploy"
```

---

### Task 8: Rebuild final + deploy no Vercel

Regenera tudo com o manifest já corrigido e publica. Esta é a task que produz o link final.

**Files:**
- Nenhum novo arquivo de código — apenas regeração de artefatos e deploy.

- [ ] **Step 1: Garantir artefatos atualizados em deploy/**

Confirmar que `deploy/app/` (Task 2 — já com o manifest da Task 1), `deploy/download/petra-setup.exe` (Task 4) e `deploy/download/petra.apk` (Task 3) existem.

Run: `node -e "const fs=require('fs'); ['deploy/app/index.html','deploy/app/manifest.json','deploy/download/petra-setup.exe','deploy/download/petra.apk'].forEach(f=>{if(!fs.existsSync(f))throw new Error('FALTA '+f)}); console.log('todos os artefatos presentes')"`
Expected: `todos os artefatos presentes`

- [ ] **Step 2: Confirmar que o manifest no build de deploy está correto**

Run: `node -e "const m=JSON.parse(require('fs').readFileSync('deploy/app/manifest.json','utf8')); console.log(m.name==='Petra ERP'?'manifest correto no deploy':'MANIFEST ANTIGO — refazer Task 2')"`
Expected: `manifest correto no deploy`
Se falhar: o `deploy/app/` foi copiado antes da correção do manifest — refazer os steps da Task 2.

- [ ] **Step 3: Deploy de produção no Vercel**

Run (PowerShell, na pasta `deploy/`). Primeira vez pede login e nome do projeto:

```powershell
cd deploy; vercel --prod
```

Seguir os prompts: login (browser), "Set up and deploy" → yes, escopo da conta, nome do projeto (ex.: `petra-empresa`), diretório `./`, sem override de settings.
Expected: ao final imprime a URL de produção, ex.: `https://petra-empresa.vercel.app`.

- [ ] **Step 4: Validar a URL publicada — landing**

Abrir `https://<projeto>.vercel.app/` no navegador. Expected: a landing carrega, detecta o dispositivo, mostra os 3 acessos.

- [ ] **Step 5: Validar a URL publicada — app PWA**

Abrir `https://<projeto>.vercel.app/app/`. Expected: tela de login do Petra (sem tela branca). No Chrome desktop, DevTools → Application → Manifest mostra "Petra ERP" e "installable" sem erros.

- [ ] **Step 6: Validar downloads**

Abrir `https://<projeto>.vercel.app/download/petra-setup.exe` e `.../download/petra.apk`. Expected: os dois baixam (não abrem como página de erro).

- [ ] **Step 7: Teste num celular real (crítico)**

No iPhone do dono (ou um iPhone qualquer): abrir a URL no Safari → seguir a instrução "Adicionar à Tela de Início" → confirmar que o ícone aparece e abre o app conectando no Supabase.
No Android: abrir no Chrome → "Instalar app" → confirmar ícone e login.

---

## Pós-implementação — checklist de entrega ao dono (responsabilidade do desenvolvedor)

Estes itens não são código, mas o "100% funcionando" depende deles:

- [ ] **Criar a conta admin do dono** no Supabase: Authentication → Add user (email + senha provisória) e setar `roles = ARRAY['admin']` no profile (ver memória [[petra-cadastro-funcionario]] — preferir a Edge Function `create-employee` se aplicável a admin).
- [ ] **Testar o login do dono** com as credenciais antes de enviar.
- [ ] **Enviar ao dono:** o link único (`https://<projeto>.vercel.app`), o email e a senha provisória, e uma instrução de 1 linha ("abra o link no celular/PC e siga a tela").
- [ ] Confirmar com o dono que ele conseguiu instalar e logar.

---

## Self-Review (preenchido pelo autor do plano)

**Cobertura do spec:**
- Landing com detecção de dispositivo → Task 5 ✓
- PWA ajustado (manifest) → Task 1 ✓
- Build web /app/ → Task 2 ✓
- Instalador Windows (Inno) → Task 4 ✓
- APK Android assinado → Task 3 ✓
- Deploy Vercel (tudo junto) → Task 6 + Task 8 ✓
- Conta do dono criada pelo dev → checklist pós-implementação ✓
- Verificação testável (web boot, installable, detecção, instalador, APK, downloads) → steps de teste em cada task + Task 8 ✓
- Fora de escopo (iOS nativo, self-service, auto-update, assinatura .exe) → não há tasks para eles ✓

**Placeholders:** nenhum — todo código/comando está completo.

**Consistência de tipos/caminhos:** caminhos de `deploy/`, `/app/`, `/download/petra-setup.exe`, `/download/petra.apk` usados de forma idêntica na landing, no vercel.json e nos builds. Credenciais Supabase idênticas em todos os builds.
