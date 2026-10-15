import {
  askGemini,
  depthRule,
  envelopeRule,
  connectedQuestions,
  followupAnswerText,
  isThinAnswer,
} from "../_shared/gemini.ts";
import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

const categoryGuide: Record<string, string> = {
  my_fortune: `내 운세. 고른 기간과 테마에 맞춰 오늘 움직일 템포, 유리한 방향과 장소, 돈·일·마음 중 지금 손댈 일을 구체적으로 적는다.
input.quick이 true면 홈에서 바로 누른 오늘의 운세다. 오늘 하루를 한 장으로 요약하고 sections는 3개만 짧게 쓴다.
today_kst의 요일과 four_pillars의 오늘 기둥을 본문에 반영한다.
recent_readings에 있는 문장, 장소, 방향, 할 일을 반복하지 않고, 어제와 다른 행동 하나를 고른다.
heading은 "지금 템포", "가야 할 쪽", "오늘 할 일"을 그대로 쓰지 않는다.`,
  family: `가족궁합. input.period(오늘, 이번 주, 이번 달, 올해) 동안을 기준으로 적는다.
누가 누구와 어디서 엇갈리는지, 그 기간에 건네면 좋은 말 한 문장, 건드리지 말 화제를 적는다. 서열을 깎거나 탓하지 않는다.
sections 예: "잘 맞는 지점", "건넬 말", "잠시 둘 이야기".`,
  colleague: `동료궁합. input.period(오늘, 이번 주, 이번 달, 올해) 동안을 기준으로 적는다.
같이 일할 때 누가 앞장서면 좋은지, 회의에서 할 말, 거리를 두면 좋은 상황을 적는다.
sections 예: "호흡", "일 나누기", "피할 자리".`,
  date_pick: `날 받기. 목적에 맞는 시기 두서너 개와, 피하면 좋은 때를 날짜나 요일 감각으로 고른다. "좋은 날이 있습니다"로 끝내지 않는다.
input.range가 "연·월·일"이면 해와 달과 날을 모두 고르고, "월·일"이면 input.year(없으면 앞으로 1년) 안에서 달과 날을, "일"이면 input.year와 input.month(없으면 가까운 달) 안에서 날을 고른다.
input.purpose_detail이 있으면 반드시 반영한다.
결혼이면 partner의 사주와 본인 사주를 함께 본다. 출산이면 due_date 앞뒤에서 고르고 baby_name이 있으면 불러 준다.
여행이면 companions와 country, city에 맞춰 떠날 때와 돌아올 때를 고른다. 기타면 other_purpose를 목적으로 삼는다.
sections 예: "고른 때", "그 날에 할 일", "미룰 때".`,
  naming: `사람 이름받기. 이름을 정확히 5개 제안한다. sections도 정확히 5개다.
input.candidates에 후보 이름이 N개 있으면, 앞의 N개 section은 그 후보 이름 그대로 쓰고 어울리는 한자와 사주와의 궁합을 풀어 준다.
나머지 5−N개는 후보와 결이 비슷하면서 새로운 이름을 추천한다. 후보가 없으면 5개 모두 추천한다.
부를 때 소리가 살고, 뜻이 분명한 한글 이름이어야 한다.
각 section의 heading은 이름, body는 소리, 뜻, 한자(뜻과 함께), 어떤 아이에게 맞는지 4문장. 후보 이름이면 body 첫 문장에 "직접 고른 후보"라고 밝힌다.
summary는 이번 다섯 이름의 공통 결만 짧게.`,
  thing_name: `사람 이름이 아니다. 강아지, 고양이, 자동차처럼 불러 주는 애칭을 8개 만든다.
주인 사주는 분위기만 살짝 빌리고, MBTI는 성격 결만 살짝 빌리고, 요즘 말맛은 리듬만 살짝 섞는다. 용어 설명은 하지 않는다.
heading은 부를 이름 그 자체. body는 왜 이 대상에 맞는지, 어떻게 부르면 되는지 두세 문장.
강아지면 멍호, 멍야호, 멍쿠처럼 멍 소리를 살린 이름을 섞는다.
고양이면 야옹, 냥을 살린 짧은 이름을 섞는다.
자동차면 카르, 야르, 발리처럼 차 이름에서 리듬만 따온 두세 음절을 섞는다. 제조사 풀네임을 그대로 쓰지 않는다.
여덟 개 중 최소 다섯 개는 이런 말놀이 이름이다. 초코, 사랑이처럼 어디서나 나오는 이름만 나열하지 않는다.
summary는 이번 이름들의 결을 두 문장으로.`,
  dream: `꿈해몽. input.dream_story(사용자가 고치고 확인한 꿈 이야기)를 가장 먼저 읽고, symbols, action, outcome, mood로 보탠다.
input.reason(해몽이 필요한 이유)에 맞춰 마지막 section을 마무리한다.
상징을 겁주지 않고, 그 장면에서 마음이 원하는 일과 오늘 현실에서 할 행동 하나를 적는다.
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
    const recent = await admin.from("fortunes")
      .select("result_json")
      .eq("user_id", userId)
      .eq("category", category === "thing_name" ? "naming" : category)
      .order("created_at", { ascending: false })
      .limit(3);
    const recentReadings = (recent.data ?? []).flatMap((row) => {
      const stored = row.result_json as { title?: string; summary?: string; menu?: string } | null;
      if (category === "thing_name" && stored?.menu !== "thing_name") return [];
      const title = (stored?.title ?? "").trim();
      const summary = (stored?.summary ?? "").replace(/\s+/g, " ").trim().slice(0, 80);
      const line = [title, summary].filter(Boolean).join(": ");
      return line ? [line] : [];
    });
    const todayKst = new Intl.DateTimeFormat("ko-KR", {
      timeZone: "Asia/Seoul",
      dateStyle: "full",
    }).format(new Date());
    const userPrompt = JSON.stringify({
      category,
      today_kst: todayKst,
      recent_readings: recentReadings,
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
    result.suggested_questions = await connectedQuestions(result, category);
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
