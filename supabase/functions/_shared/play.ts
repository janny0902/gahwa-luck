const TOKEN_URL = "https://oauth2.googleapis.com/token";
const PUBLISHER = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

type ServiceAccount = { client_email: string; private_key: string };

let cachedToken = "";
let cachedUntil = 0;

function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function textToBase64Url(value: string): string {
  return bytesToBase64Url(new TextEncoder().encode(value));
}

function pemToPkcs8(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN [^-]+-----/g, "").replace(/-----END [^-]+-----/g, "").replace(/\s+/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function serviceAccount(): ServiceAccount {
  const raw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON") ?? "";
  if (!raw.trim()) {
    throw new Error("Play 결제 검증 시크릿이 없습니다");
  }
  let parsed: ServiceAccount;
  try {
    parsed = JSON.parse(raw) as ServiceAccount;
  } catch {
    throw new Error("Play 결제 검증 시크릿 형식이 잘못되었습니다");
  }
  if (!parsed.client_email || !parsed.private_key) {
    throw new Error("Play 결제 검증 시크릿 형식이 잘못되었습니다");
  }
  return parsed;
}

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedUntil > now + 60) return cachedToken;
  const account = serviceAccount();
  const header = textToBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = textToBase64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const assertion = `${header}.${claim}.${bytesToBase64Url(new Uint8Array(signature))}`;
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error("Play 결제 권한을 받지 못했습니다");
  }
  const payload = await response.json();
  const token = payload?.access_token;
  if (typeof token !== "string" || token.length === 0) {
    throw new Error("Play 결제 권한을 받지 못했습니다");
  }
  cachedToken = token;
  cachedUntil = now + Number(payload.expires_in ?? 3600);
  return token;
}

export type PlayPurchase = { purchaseState: number; orderId: string };

function productUrl(packageName: string, productId: string, token: string): string {
  return `${PUBLISHER}/${packageName}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
}

export async function readPlayPurchase(
  packageName: string,
  productId: string,
  token: string,
): Promise<PlayPurchase> {
  const bearer = await accessToken();
  const response = await fetch(productUrl(packageName, productId, token), {
    headers: { Authorization: `Bearer ${bearer}` },
  });
  if (response.status === 404) {
    throw new Error("플레이에서 이 결제를 찾지 못했습니다");
  }
  if (!response.ok) {
    throw new Error("플레이 결제 확인에 실패했습니다");
  }
  const payload = await response.json();
  return {
    purchaseState: Number(payload?.purchaseState ?? -1),
    orderId: typeof payload?.orderId === "string" ? payload.orderId : "",
  };
}

export async function consumePlayPurchase(
  packageName: string,
  productId: string,
  token: string,
): Promise<void> {
  const bearer = await accessToken();
  const response = await fetch(`${productUrl(packageName, productId, token)}:consume`, {
    method: "POST",
    headers: { Authorization: `Bearer ${bearer}` },
  });
  if (response.ok || response.status === 404) return;
}
