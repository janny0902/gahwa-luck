import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = await requireUser(req);
  if (isResponse(auth)) return auth;
  const granted = await auth.admin.rpc("apply_daily_grant", { p_user: auth.userId });
  if (granted.error) return json({ error: granted.error.message }, 500);
  return json(granted.data);
});
