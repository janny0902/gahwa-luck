import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = await requireUser(req);
  if (isResponse(auth)) return auth;
  if ((Deno.env.get("REWARD_CLIENT_CLAIM") ?? "").toLowerCase() === "off") {
    return json({ error: "광고 보상은 광고 서버 확인 후 지급됩니다" }, 410);
  }
  let body: { kind?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "요청 형식이 잘못되었습니다" }, 400);
  }
  const kind = body.kind === "rice" ? "rice" : body.kind === "amulet" ? "amulet" : "";
  if (!kind) return json({ error: "부적 또는 쌀알을 선택해 주세요" }, 400);
  const claimed = await auth.admin.rpc("claim_ad_reward", {
    p_user: auth.userId,
    p_kind: kind,
  });
  if (claimed.error) return json({ error: claimed.error.message }, 500);
  const data = claimed.data as { ok?: boolean; error?: string };
  if (!data?.ok) return json({ error: data?.error ?? "보상을 받지 못했습니다" }, 400);
  return json(data);
});
