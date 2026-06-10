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

    // NOTE: NÃO usamos supabase.rpc("is_admin") porque o client foi criado com
    // SERVICE_ROLE_KEY. Em contexto service_role, auth.uid() retorna NULL e
    // is_admin() SEMPRE retorna false. Em vez disso, consultamos a tabela profiles
    // diretamente (service_role bypassa RLS) usando o user.id já verificado acima.
    const { data: profile } = await supabase
      .from("profiles")
      .select("roles")
      .eq("id", user.id)
      .eq("active", true)
      .maybeSingle();

    const isAdmin = profile?.roles?.includes("admin") ?? false;

    if (!isAdmin) {
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
    console.error("admin-reset-password error:", error);
    return new Response(
      JSON.stringify({ error: "Erro interno do servidor" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
