# Reset de senha de funcionário pelo admin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que o admin redefina a senha de funcionários com login por e-mail diretamente no app, sem depender do e-mail de reset do Supabase (inviável no plano Free).

**Architecture:** Edge Function `admin-reset-password` (service_role) valida token + `is_admin()` e chama `auth.admin.updateUserById`. O app expõe um botão na tela de edição do funcionário (apenas login e-mail) que abre um dialog de nova senha, encaminhando via `ProfileService` → `EmployeeNotifier`.

**Tech Stack:** Deno (Supabase Edge Functions), Flutter, Riverpod (StateNotifier), supabase_flutter.

**Nota sobre testes:** o projeto não tem infra de teste para Edge Functions Deno nem para serviços que invocam funções remotas (o `createEmployee` análogo não tem teste). Seguindo o padrão da casa e o spec, a verificação é por `flutter analyze` + teste manual end-to-end. Não há passos de teste automatizado.

**Spec:** `docs/superpowers/specs/2026-06-03-admin-reset-senha-design.md`

---

## File Structure

- Create: `supabase/functions/admin-reset-password/index.ts` — Edge Function de reset (service_role).
- Modify: `petra_erp/lib/services/profile_service.dart` — método `resetEmployeePassword`.
- Modify: `petra_erp/lib/providers/employee_provider.dart` — método `resetEmployeePassword` no notifier.
- Modify: `petra_erp/lib/screens/employees/employee_form_screen.dart` — bloco + dialog na UI.

---

### Task 1: Edge Function `admin-reset-password`

**Files:**
- Create: `supabase/functions/admin-reset-password/index.ts`

- [ ] **Step 1: Criar a função**

Espelha `supabase/functions/create-employee/index.ts` (mesmo fluxo de auth + is_admin).

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false } },
    );

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");

    if (!token) {
      return new Response(JSON.stringify({ error: "Token não fornecido" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Usuário não autenticado" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: isAdmin, error: roleError } = await supabase.rpc("is_admin");

    if (roleError || !isAdmin) {
      return new Response(
        JSON.stringify({ error: "Apenas administradores podem redefinir senhas" }),
        { status: 403, headers: { "Content-Type": "application/json" } },
      );
    }

    const body = await req.json();
    const { user_id, password } = body;

    if (!user_id || !password) {
      return new Response(
        JSON.stringify({ error: "Campos obrigatórios: user_id, password" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    if (typeof password !== "string" || password.length < 6) {
      return new Response(
        JSON.stringify({ error: "A senha deve conter no mínimo 6 caracteres" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const { error: updateError } = await supabase.auth.admin.updateUserById(
      user_id,
      { password },
    );

    if (updateError) {
      return new Response(
        JSON.stringify({ error: updateError.message ?? "Falha ao redefinir senha" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: `Erro interno: ${error}` }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
```

- [ ] **Step 2: Deploy via MCP**

Usar `mcp__supabase__deploy_edge_function` com `project_id: prxkfifwuygtlynozdqx`, `name: admin-reset-password`, `files` contendo o conteúdo acima. A função herda `verify_jwt: true` (default) e usa as env vars `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` já presentes no projeto.

Expected: `{ "...": "ACTIVE" }` / sucesso no deploy.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/admin-reset-password/
git commit -m "feat: Edge Function admin-reset-password (reset de senha pelo admin)"
```

---

### Task 2: `ProfileService.resetEmployeePassword`

**Files:**
- Modify: `petra_erp/lib/services/profile_service.dart`

- [ ] **Step 1: Adicionar o método**

Inserir após `createEmployee` (antes de `unblockWorker`, ~linha 100). Espelha o tratamento de erro de `createEmployee`.

```dart
  Future<void> resetEmployeePassword({
    required String userId,
    required String password,
  }) async {
    final res = await _client.functions.invoke(
      'admin-reset-password',
      body: {'user_id': userId, 'password': password},
    );
    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map ? data['error'] as String? : null;
      throw Exception(msg ?? 'Falha ao redefinir senha');
    }
  }
```

- [ ] **Step 2: Analyze**

Run: `cd petra_erp && rtk flutter analyze lib/services/profile_service.dart`
Expected: No issues found.

---

### Task 3: `EmployeeNotifier.resetEmployeePassword`

**Files:**
- Modify: `petra_erp/lib/providers/employee_provider.dart`

- [ ] **Step 1: Adicionar o método**

Inserir após `resetWorkerPin` (~linha 79). Não chama `loadEmployees()` — a lista de funcionários não muda.

```dart
  Future<void> resetEmployeePassword(String userId, String password) async {
    await _service.resetEmployeePassword(userId: userId, password: password);
  }
```

- [ ] **Step 2: Analyze**

Run: `cd petra_erp && rtk flutter analyze lib/providers/employee_provider.dart`
Expected: No issues found.

---

### Task 4: UI — bloco e dialog na tela de edição

**Files:**
- Modify: `petra_erp/lib/screens/employees/employee_form_screen.dart`

- [ ] **Step 1: Adicionar o handler do dialog**

Inserir o método após `_resetPin` (~linha 192), antes de `_toggleActive`. Usa um `GlobalKey<FormState>` e dois controllers locais ao dialog.

```dart
  Future<void> _resetPassword() async {
    final formKey = GlobalKey<FormState>();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha *',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha *',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) => val != passCtrl.text
                    ? 'As senhas não coincidem'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );

    if (ok == true && widget.id != null) {
      try {
        await ref
            .read(employeeProvider.notifier)
            .resetEmployeePassword(widget.id!, passCtrl.text.trim());
        if (mounted) AppSnackbar.success(context, 'Senha redefinida.');
      } catch (e) {
        if (mounted) AppSnackbar.error(context, friendlyError(e));
      }
    }

    passCtrl.dispose();
    confirmCtrl.dispose();
  }
```

- [ ] **Step 2: Adicionar o bloco na UI**

No `build`, logo após o bloco PIN (que termina na linha 307, depois do `const SizedBox(height: 16.0)` que fecha o `if (_isEditing && _isPinAccess)`), inserir o bloco análogo para login e-mail:

```dart
                    if (_isEditing && !_isPinAccess) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Acesso por e-mail',
                            style: AppTheme.jakarta(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          AppButton(
                            label: 'Redefinir senha',
                            icon: LucideIcons.keyRound,
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.sm,
                            onPressed: _resetPassword,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                    ],
```

- [ ] **Step 3: Analyze**

Run: `cd petra_erp && rtk flutter analyze`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add petra_erp/lib/services/profile_service.dart petra_erp/lib/providers/employee_provider.dart petra_erp/lib/screens/employees/employee_form_screen.dart
git commit -m "feat: botao de redefinir senha do funcionario (login e-mail) pelo admin"
```

---

## Verificação final (manual, end-to-end)

1. `cd petra_erp && rtk flutter analyze` → No issues found.
2. Rodar o app logado como **admin**.
3. Abrir um funcionário com login **e-mail** → conferir que o bloco "Acesso por e-mail" + botão "Redefinir senha" aparece (e NÃO aparece para funcionário PIN).
4. Clicar "Redefinir senha" → digitar nova senha + confirmação divergente → ver erro "As senhas não coincidem".
5. Digitar senha < 6 caracteres → ver erro de validação.
6. Digitar senha válida e igual → snackbar "Senha redefinida.".
7. Deslogar e logar com o funcionário usando a **nova** senha → sucesso.

---

## Self-Review

- **Cobertura do spec:** Edge Function (Task 1), `ProfileService` (Task 2), `EmployeeNotifier` (Task 3), UI bloco+dialog (Task 4), deploy + analyze + manual (Verificação). Todos os itens do spec têm task.
- **Placeholders:** nenhum — todo código é literal.
- **Consistência de tipos:** `resetEmployeePassword(userId, password)` no serviço usa parâmetros nomeados; o notifier usa posicionais `(String userId, String password)` e chama o serviço com nomeados — consistente. A UI chama `resetEmployeePassword(widget.id!, passCtrl.text.trim())` (posicional) → bate com o notifier. Body da função `{user_id, password}` bate com o que o serviço envia.
- **Fora de escopo respeitado:** sem geração de senha, sem troca forçada, sem reset para PIN, sem auditoria.
