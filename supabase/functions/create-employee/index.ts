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
        JSON.stringify({ error: "Apenas administradores podem criar funcionários" }),
        { status: 403, headers: { "Content-Type": "application/json" } },
      );
    }

    const body = await req.json();
    const { email, password, name, roles, phone, login_mode } = body;

    if (!email || !password || !name || !roles) {
      return new Response(
        JSON.stringify({ error: "Campos obrigatórios: email, password, name, roles" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const validRoles = ["admin", "vendedor", "cortador", "montador", "entregador"];
    if (!Array.isArray(roles) || roles.length === 0) {
      return new Response(
        JSON.stringify({ error: "roles deve ser um array não vazio" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    for (const role of roles) {
      if (!validRoles.includes(role)) {
        return new Response(
          JSON.stringify({ error: `Role inválido: ${role}` }),
          { status: 400, headers: { "Content-Type": "application/json" } },
        );
      }
    }

    const user_metadata: Record<string, unknown> = { name, roles, phone };
    if (login_mode && (login_mode === "email" || login_mode === "pin")) {
      user_metadata.login_mode = login_mode;
    }

    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata,
    });

    if (createError || !newUser.user) {
      return new Response(
        JSON.stringify({ error: createError?.message ?? "Falha ao criar usuário" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({
        id: newUser.user.id,
        email: newUser.user.email,
        name,
        roles,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("create-employee error:", error);
    return new Response(
      JSON.stringify({ error: "Erro interno do servidor" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
