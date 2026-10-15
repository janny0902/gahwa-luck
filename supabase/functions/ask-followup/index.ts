import { askGemini, connectedQuestions, envelopeRule, followupAnswerText, isThinAnswer } from "../_shared/gemini.ts";
import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

function readingSummary(
  stored: { title?: string; summary?: string; sections?: unknown } | null,
  fallback: string,
): string {
  const title = (stored?.title ?? "").trim();
  const summary = (stored?.summary ?? fallback).replace(/\s+/g, " ").trim().slice(0, 500);
  const headings = Array.isArray(stored?.sections)
    ? stored.sections.flatMap((item) => {
      if (!item || typeof item !== "object") return [];
      const heading = (item as { heading?: string }).heading?.trim() ?? "";
      return heading ? [heading] : [];
    })
    : [];
  return [title, summary, headings.join(", ")].filter(Boolean).join("\n");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = await requireUser(req);
  if (isResponse(auth)) return auth;
  const { admin, userId } = auth;

  let body: { fortune_id?: string; question?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "요청 형식이 잘못되었습니다" }, 400);
  }
  const fortuneId = body.fortune_id ?? "";
  const question = (body.question ?? "").trim();
  if (!fortuneId || question.length < 2) {
    return json({ error: "질문을 입력해 주세요" }, 400);
  }

  const fortune = await admin.from("fortunes")
    .select("id, user_id, category, result_text, result_json")
    .eq("id", fortuneId)
    .maybeSingle();
  if (fortune.error || !fortune.data || fortune.data.user_id !== userId) {
    return json({ error: "운세 기록을 찾지 못했습니다" }, 404);
  }

  const spent = await admin.rpc("spend_rice", { p_user: userId, p_fortune: fortuneId });
  if (spent.error) return json({ error: spent.error.message }, 500);
  const spend = spent.data as { ok?: boolean; error?: string; remaining_rice_turns?: number };
  if (!spend?.ok) return json({ error: spend?.error ?? "쌀알을 쓰지 못했습니다" }, 402);

  const previous = await admin.from("fortune_chats")
    .select("turn_index, user_question, ai_answer")
    .eq("fortune_id", fortuneId)
    .order("turn_index", { ascending: true });
  const turns = previous.data ?? [];
  const nextTurn = turns.length + 1;

  try {
    const stored = fortune.data.result_json as { menu?: string } | null;
    const category = stored?.menu === "thing_name"
      ? "thing_name"
      : String(fortune.data.category ?? "my_fortune");
    const last = turns.at(-1);
    const userPrompt = JSON.stringify({
      reading_summary: readingSummary(
        fortune.data.result_json as { title?: string; summary?: string } | null,
        String(fortune.data.result_text ?? ""),
      ),
      last_turn: last ? { question: last.user_question, answer: last.ai_answer } : null,
      question,
    });
    const system = `이전 풀이와 직전 문답에 이어서, 이번 질문의 답을 바로 말한다.
첫 문장은 이 질문에만 해당하는 결론이다. "알아보겠습니다", "살펴볼게요", "정리해 드릴게요"처럼 답을 미루지 않는다.
summary에 쉬운 말로 6~10문장 적는다. 풀이에 나온 장소, 방향, 사람, 시간, 물건을 답 안에 다시 쓴다.
"천천히 하세요", "무리하지 마세요", "마음을 편하게"처럼 어떤 질문에도 붙는 말로 끝내지 않는다.
직전 답과 첫 문장, 권하는 행동을 다르게 쓴다.
sections는 1개. heading은 질문의 핵심 단어, body는 summary와 겹치지 않는 실천 두세 문장.
전문 용어는 쓰지 않는다.
${envelopeRule}`;
    let result = await askGemini(system, userPrompt);
    let answer = followupAnswerText(result);
    if (isThinAnswer(answer, 140)) {
      result = await askGemini(
        `${system}\n직전 답은 거절되었다. 질문 "${question}"의 답을 첫 문장에 쓰고, 이유와 오늘 할 일을 이어서 적어라.`,
        userPrompt,
      );
      answer = followupAnswerText(result);
    }
    result.suggested_questions = await connectedQuestions(result, category);
    const saved = await admin.from("fortune_chats").insert({
      fortune_id: fortuneId,
      turn_index: nextTurn,
      user_question: question,
      ai_answer: answer,
    }).select("turn_index, user_question, ai_answer").single();
    if (saved.error) throw new Error(saved.error.message);
    return json({
      chat: saved.data,
      result,
      remaining_rice_turns: spend.remaining_rice_turns ?? 0,
    });
  } catch (error) {
    await admin.rpc("refund_rice", { p_user: userId, p_fortune: fortuneId });
    const message = error instanceof Error ? error.message : "답을 만들지 못했습니다";
    return json({ error: message }, 502);
  }
});
