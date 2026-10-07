import { askGemini, envelopeRule, followupAnswerText, isThinAnswer, normalizeSuggestedQuestions } from "../_shared/gemini.ts";
import { corsHeaders, isResponse, json, requireUser } from "../_shared/http.ts";

function firstSentence(text: string): string {
  const trimmed = text.replace(/\s+/g, " ").trim();
  const match = trimmed.match(/^.+?[.!?。](?=\s|$)/);
  return (match ? match[0] : trimmed).slice(0, 200);
}

function readingSummary(
  stored: { title?: string; summary?: string } | null,
  fallback: string,
): string {
  const title = (stored?.title ?? "").trim();
  const sentence = firstSentence(stored?.summary ?? fallback);
  return title ? `${title}: ${sentence}` : sentence;
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
    const system = `이전 풀이 요약과 직전 문답에 이어서, 질문의 답을 바로 말한다.
첫 문장은 질문에 대한 결론이다. "알아보겠습니다", "살펴볼게요", "정리해 드릴게요"처럼 답을 미루지 않는다.
summary에 쉬운 말로 6~10문장 적는다. 요약과 직전 문답에 나온 장소, 방향, 사람, 이름이 있으면 이어서 구체적으로 말한다.
sections는 1개. heading은 "이어서", body는 summary와 겹치지 않는 실천 두세 문장.
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
    result.suggested_questions = normalizeSuggestedQuestions(result.suggested_questions, category);
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
