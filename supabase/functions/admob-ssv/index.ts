import { adminClient } from "../_shared/http.ts";

const KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json";
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

let cachedKeys: { at: number; keys: Map<string, CryptoKey> } | null = null;

function base64UrlToBytes(value: string): Uint8Array {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

// AdMob 서명은 DER, WebCrypto ECDSA 검증은 r||s(각 32바이트)를 받는다.
function derToRaw(der: Uint8Array): Uint8Array | null {
  if (der[0] !== 0x30) return null;
  let offset = 2;
  if (der[1] & 0x80) offset = 2 + (der[1] & 0x7f);
  const readInt = (): Uint8Array | null => {
    if (der[offset] !== 0x02) return null;
    const length = der[offset + 1];
    let value = der.slice(offset + 2, offset + 2 + length);
    offset += 2 + length;
    while (value.length > 32 && value[0] === 0) value = value.slice(1);
    if (value.length > 32) return null;
    const out = new Uint8Array(32);
    out.set(value, 32 - value.length);
    return out;
  };
  const r = readInt();
  const s = readInt();
  if (!r || !s) return null;
  const raw = new Uint8Array(64);
  raw.set(r, 0);
  raw.set(s, 32);
  return raw;
}

async function verifierKeys(): Promise<Map<string, CryptoKey>> {
  if (cachedKeys && Date.now() - cachedKeys.at < 6 * 60 * 60 * 1000) return cachedKeys.keys;
  const res = await fetch(KEYS_URL);
  if (!res.ok) throw new Error(`verifier keys ${res.status}`);
  const body = await res.json() as { keys?: { keyId: number | string; base64: string }[] };
  const keys = new Map<string, CryptoKey>();
  for (const item of body.keys ?? []) {
    const key = await crypto.subtle.importKey(
      "spki",
      base64UrlToBytes(item.base64),
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["verify"],
    );
    keys.set(String(item.keyId), key);
  }
  cachedKeys = { at: Date.now(), keys };
  return keys;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const query = url.search.startsWith("?") ? url.search.slice(1) : url.search;
  const signatureAt = query.indexOf("&signature=");
  // AdMob 콘솔의 URL 확인 요청은 서명 없이 올 수 있다.
  if (signatureAt < 0) return new Response("ok");

  const signedContent = query.slice(0, signatureAt);
  const params = url.searchParams;
  const signature = params.get("signature") ?? "";
  const keyId = params.get("key_id") ?? "";
  const userId = params.get("user_id") ?? "";
  const kind = params.get("custom_data") ?? "";
  const transactionId = params.get("transaction_id") ?? "";

  try {
    const keys = await verifierKeys();
    const key = keys.get(keyId);
    const raw = derToRaw(base64UrlToBytes(signature));
    if (!key || !raw) return new Response("bad signature", { status: 400 });
    const valid = await crypto.subtle.verify(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      raw,
      new TextEncoder().encode(signedContent),
    );
    if (!valid) return new Response("bad signature", { status: 400 });
  } catch (error) {
    console.error("admob-ssv verify failed", String(error));
    return new Response("verify failed", { status: 500 });
  }

  if (!UUID_RE.test(userId) || (kind !== "amulet" && kind !== "rice") || !transactionId) {
    return new Response("ignored");
  }

  const claimed = await adminClient().rpc("claim_ad_reward_ssv", {
    p_user: userId,
    p_kind: kind,
    p_txn: transactionId,
  });
  if (claimed.error) {
    console.error("admob-ssv grant failed", claimed.error.message);
    return new Response("grant failed", { status: 500 });
  }
  return new Response("ok");
});
