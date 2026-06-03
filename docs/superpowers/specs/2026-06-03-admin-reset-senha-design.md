# Reset de senha de funcionário pelo admin — Design

**Data:** 2026-06-03
**Projeto:** Petra ERP (Flutter + Supabase, project `prxkfifwuygtlynozdqx`)

## Contexto

No plano Free do Supabase, o e-mail de "esqueci a senha" usa o SMTP compartilhado (limite baixo, cai em spam) — não dá para confiar nele em produção. Decisão de produto: o **admin redefine a senha** dos funcionários com login por e-mail diretamente pelo app. Funcionários de chão usam login por PIN, que já tem "Redefinir PIN" e "Desbloquear" na tela de edição — fora deste escopo.

Resetar a senha de outro usuário exige a Admin API do Supabase Auth (`auth.admin.updateUserById`), que só roda com `service_role` no servidor. Logo, precisa de uma Edge Function, espelhando a `create-employee` já existente.

## Arquitetura

```
EmployeeFormScreen (dialog nova senha)
  → EmployeeNotifier.resetEmployeePassword
    → ProfileService.resetEmployeePassword
      → Edge Function admin-reset-password (service_role)
        → auth.admin.updateUserById(user_id, { password })
```

### 1. Edge Function `admin-reset-password`
Arquivo: `supabase/functions/admin-reset-password/index.ts`. Espelha `create-employee`:
- `verify_jwt: true`; lê `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` de `Deno.env`.
- Valida token do chamador via `auth.getUser(token)` → 401 se ausente/inválido.
- Checa `is_admin()` via `supabase.rpc("is_admin")` → 403 se não-admin.
- Body `{ user_id: string, password: string }`. Validações → 400:
  - `user_id` presente;
  - `password` com pelo menos 6 caracteres.
- `auth.admin.updateUserById(user_id, { password })` → 500 em erro.
- Sucesso: `{ success: true }`, status 200.
- Sem segredos hardcoded.

### 2. Camada de serviço/estado (app)
- `ProfileService.resetEmployeePassword({ required String userId, required String password })`
  ([profile_service.dart](../../../petra_erp/lib/services/profile_service.dart)) — `_client.functions.invoke('admin-reset-password', body: {...})`; se `res.status != 200`, lança com a mensagem de `data['error']` (mesmo padrão de `createEmployee`).
- `EmployeeNotifier.resetEmployeePassword(...)`
  ([employee_provider.dart](../../../petra_erp/lib/providers/employee_provider.dart)) — repassa ao serviço; **não** chama `loadEmployees()` (a lista não muda).

### 3. UI
Em [employee_form_screen.dart](../../../petra_erp/lib/screens/employees/employee_form_screen.dart):
- Bloco visível só quando `_isEditing && !_isPinAccess` (espelha o bloco PIN, linhas 272–307), rótulo "Acesso por e-mail" + botão "Redefinir senha" (`AppButton`, variant outline).
- Dialog com dois campos obscurecidos: **Nova senha** (`Validators.validatePassword`) e **Confirmar senha** (deve ser igual). Botões Cancelar / Redefinir.
- Ao confirmar: `resetEmployeePassword(userId: widget.id!, password: ...)`, fecha dialog, `AppSnackbar.success(context, 'Senha redefinida.')`. Erro → `friendlyError(e)` em `AppSnackbar.error`.

## Erros / segurança
- Autorização inteira no servidor (token + `is_admin`); o app nunca usa `service_role`.
- Não altera RLS, sessão, nem o fluxo de PIN.
- Mensagens amigáveis via `friendlyError` existente.

## Fora de escopo (YAGNI)
- Geração automática de senha aleatória.
- Troca forçada no primeiro login.
- Reset para contas PIN.
- Histórico/auditoria de resets.

## Verificação
1. Deploy via `mcp__supabase__deploy_edge_function` (projeto `prxkfifwuygtlynozdqx`).
2. `cd petra_erp && rtk flutter analyze` limpo.
3. Manual: logado como admin → editar funcionário e-mail → redefinir senha → deslogar → logar com a nova senha.
4. Versionar `supabase/functions/admin-reset-password/` + alterações do app no git.
