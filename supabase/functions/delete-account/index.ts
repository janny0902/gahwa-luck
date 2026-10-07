import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = await requireUser(req);
  if (isResponse(auth)) return auth;

  let body: { confirm?: boolean };
  try {
    body = await req.json();
  } catch {
    return json({ error: "요청 형식이 잘못되었습니다" }, 400);
  }
  if (body.confirm !== true) return json({ error: "탈퇴 확인이 필요합니다" }, 400);

  const removed = await auth.admin.auth.admin.deleteUser(auth.userId);
  if (removed.error) return json({ error: "계정을 삭제하지 못했습니다" }, 500);
  return json({ ok: true });
});
