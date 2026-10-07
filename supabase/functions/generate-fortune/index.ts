import {
  askGemini,
  depthRule,
  envelopeRule,
  followupAnswerText,
  isThinAnswer,
  normalizeSuggestedQuestions,
} from "../_shared/gemini.ts";
import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

const categoryGuide: Record<string, string> = {
  my_fortune: `내 운세. 고른 기간과 테마에 맞춰 오늘 움직일 템포, 유리한 방향과 장소, 돈·일·마음 중 지금 손댈 일을 구체적으로 적는다.
sections 예: "지금 템포", "가야 할 쪽", "오늘 할 일".`,
  family: `가족궁합. 누가 누구와 어디서 엇갈리는지, 오늘 건네면 좋은 말 한 문장, 건드리지 말 화제를 적는다. 서열을 깎거나 탓하지 않는다.
sections 예: "잘 맞는 지점", "오늘 건넬 말", "잠시 둘 이야기".`,
  colleague: `동료궁합. 같이 일할 때 누가 앞장서면 좋은지, 회의에서 할 말, 거리를 두면 좋은 상황을 적는다.
sections 예: "호흡", "일 나누기", "피할 자리".`,
  date_pick: `날 받기. 목적에 맞는 시기 두서너 개와, 피하면 좋은 때를 날짜나 요일 감각으로 고른다. "좋은 날이 있습니다"로 끝내지 않는다.
sections 예: "고른 때", "그 날에 할 일", "미룰 때".`,
  naming: `사람 이름받기. 부를 때 소리가 살고, 뜻이 분명한 한글 이름 6개를 제안한다.
각 section의 heading은 이름, body는 소리, 뜻, 한자(뜻과 함께), 어떤 아이에게 맞는지 4문장.
summary는 이번 후보의 공통 결만 짧게.`,
  thing_name: `사람 이름이 아니다. 강아지, 고양이, 자동차처럼 불러 주는 애칭을 8개 만든다.
주인 사주는 분위기만 살짝 빌리고, MBTI는 성격 결만 살짝 빌리고, 요즘 말맛은 리듬만 살짝 섞는다. 용어 설명은 하지 않는다.
heading은 부를 이름 그 자체. body는 왜 이 대상에 맞는지, 어떻게 부르면 되는지 두세 문장.
강아지면 멍호, 멍야호, 멍쿠처럼 멍 소리를 살린 이름을 섞는다.
고양이면 야옹, 냥을 살린 짧은 이름을 섞는다.
자동차면 카르, 야르, 발리처럼 차 이름에서 리듬만 따온 두세 음절을 섞는다. 제조사 풀네임을 그대로 쓰지 않는다.
여덟 개 중 최소 다섯 개는 이런 말놀이 이름이다. 초코, 사랑이처럼 어디서나 나오는 이름만 나열하지 않는다.
summary는 이번 이름들의 결을 두 문장으로.`,
  dream: `꿈해몽. 상징을 겁주지 않고, 그 장면에서 마음이 원하는 일과 오늘 현실에서 할 행동 하나를 적는다.
sections 예: "이 장면", "마음", "오늘 할 일".`,
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = await requireUser(req);
  if (isResponse(auth)) return auth;
  const { admin, userId } = auth;

  let body: { category?: string; input?: unknown; four_pillars?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: "요청 형식이 잘못되었습니다" }, 400);
  }
  const category = body.category ?? "";
  const guide = categoryGuide[category];
  if (!guide) return json({ error: "알 수 없는 운세 종류입니다" }, 400);

  const spent = await admin.rpc("spend_amulet", { p_user: userId, p_reason: "fortune" });
  if (spent.error) return json({ error: spent.error.message }, 500);
  const spend = spent.data as { ok?: boolean; error?: string };
  if (!spend?.ok) return json({ error: spend?.error ?? "부적을 쓰지 못했습니다" }, 402);

  try {
    const userPrompt = JSON.stringify({
      category,
      input: body.input ?? {},
      four_pillars: body.four_pillars ?? {},
    });
    const system = `너는 가화만사성 운세 안내자다. ${guide}\n${depthRule}\n${envelopeRule}`;
    let result = await askGemini(system, userPrompt);
    if (isThinAnswer(followupAnswerText(result), category === "thing_name" ? 280 : 360)) {
      result = await askGemini(
        `${system}\n직전 답은 너무 짧거나 빈말이었다. 결론을 첫 문장에 쓰고, 본문을 빠짐없이 채워라.`,
        userPrompt,
      );
    }
    result.suggested_questions = normalizeSuggestedQuestions(result.suggested_questions, category);
    result.menu = category;
    const title = String(result.title ?? "운세");
    const summary = String(result.summary ?? "");
    const sectionText = Array.isArray(result.sections)
      ? result.sections.map((item) => {
        if (!item || typeof item !== "object") return "";
        const rec = item as Record<string, unknown>;
        const heading = typeof rec.heading === "string" ? rec.heading.trim() : "";
        const sectionBody = typeof rec.body === "string" ? rec.body.trim() : "";
        return [heading, sectionBody].filter(Boolean).join("\n");
      }).filter(Boolean).join("\n\n")
      : "";
    const inserted = await admin.from("fortunes").insert({
      user_id: userId,
      category: category === "thing_name" ? "naming" : category,
      input_summary: body.input ?? {},
      four_pillars: body.four_pillars ?? {},
      result_json: result,
      result_text: [title, summary, sectionText].filter(Boolean).join("\n\n"),
      remaining_rice_turns: 5,
    }).select("id, category, result_json, result_text, four_pillars, remaining_rice_turns, created_at").single();
    if (inserted.error) throw new Error(inserted.error.message);
    return json({ fortune: inserted.data });
  } catch (error) {
    await admin.rpc("refund_amulet", { p_user: userId, p_reason: "fortune_refund" });
    const message = error instanceof Error ? error.message : "운세를 만들지 못했습니다";
    return json({ error: message }, 502);
  }
});
