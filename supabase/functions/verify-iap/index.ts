import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";
import { consumePlayPurchase, readPlayPurchase } from "../_shared/play.ts";

const PACKAGE = "com.janny.gahwa_luck";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = await requireUser(req);
  if (isResponse(auth)) return auth;

  let body: { product_id?: string; purchase_token?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "요청 형식이 잘못되었습니다" }, 400);
  }
  const productId = body.product_id ?? "";
  const token = body.purchase_token ?? "";
  if (!productId || !token) return json({ error: "상품 정보가 없습니다" }, 400);

  let purchase;
  try {
    purchase = await readPlayPurchase(PACKAGE, productId, token);
  } catch (error) {
    const message = error instanceof Error ? error.message : "결제 확인에 실패했습니다";
    const status = message.includes("시크릿") ? 500 : 502;
    return json({ error: message }, status);
  }
  if (purchase.purchaseState === 2) {
    return json({ error: "결제가 아직 처리 중입니다" }, 409);
  }
  if (purchase.purchaseState !== 0) {
    return json({ error: "완료된 결제가 아닙니다" }, 402);
  }

  const granted = await auth.admin.rpc("grant_iap", {
    p_user: auth.userId,
    p_product: productId,
    p_token: token,
    p_order: purchase.orderId,
  });
  if (granted.error) return json({ error: granted.error.message }, 500);
  const data = granted.data as { ok?: boolean; error?: string };
  if (!data?.ok) return json({ error: data?.error ?? "상품을 넣지 못했습니다" }, 400);

  try {
    await consumePlayPurchase(PACKAGE, productId, token);
  } catch {
    // 지급은 끝났고, 소비는 다음 구매 전에 다시 시도할 수 있다.
  }
  return json(data);
});
