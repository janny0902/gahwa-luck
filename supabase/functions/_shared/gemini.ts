const MODEL = "gemini-3.5-flash-lite";

export async function askGemini(system: string, user: string): Promise<Record<string, unknown>> {
  const key = Deno.env.get("GEMINI_API_KEY") ?? Deno.env.get("GEMINI_API_KEY_FREE") ?? "";
  if (!key) {
    throw new Error("GEMINI_API_KEY 시크릿이 없습니다");
  }
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${key}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: "user", parts: [{ text: user }] }],
        generationConfig: {
          temperature: 0.75,
          maxOutputTokens: 4096,
          responseMimeType: "application/json",
        },
      }),
    },
  );
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Gemini 오류 ${response.status}: ${detail.slice(0, 300)}`);
  }
  const payload = await response.json();
  const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== "string" || text.trim() === "") {
    throw new Error("Gemini 응답이 비어 있습니다");
  }
  const parsed = JSON.parse(text) as Record<string, unknown>;
  if (!Array.isArray(parsed.sections)) parsed.sections = [];
  if (!Array.isArray(parsed.suggested_questions)) parsed.suggested_questions = [];
  if (typeof parsed.title !== "string") parsed.title = "운세";
  if (typeof parsed.summary !== "string") parsed.summary = "";
  return parsed;
}

const HARD_TERMS =
  /오행|십신|용신|희신|편재|식신|상관|정재|비겁|편관|정관|인성|비견|겁재|원진|도화|역마|괴강|천을|신살|대운|월건|세운|일간|간지|충합|형충|자원오행|납음|합충|살\(/;

export const easyFollowups: Record<string, string[]> = {
  my_fortune: ["오늘 조심할 일은?", "돈 흐름은 어때요?", "쉬는 게 나을까요?"],
  family: ["누구랑 조심할까요?", "오늘은 무슨 말을 할까요?", "집안 분위기는?"],
  colleague: ["누구랑 잘 맞아요?", "회식은 어때요?", "일 얘기 팁은?"],
  date_pick: ["다른 날도 있어요?", "피하면 좋은 때는?", "몇 시가 좋아요?"],
  naming: ["다른 이름은요?", "부르기 쉬운가요?", "한자 뜻은 어때요?"],
  thing_name: ["더 웃긴 이름은?", "더 짧은 이름은?", "부르기 쉬운 건?"],
  dream: ["좋은 꿈인가요?", "오늘 어떻게 하면 돼요?", "또 무슨 뜻일까요?"],
};

const STALL =
  /알아보겠|살펴보겠|정리해\s*드리|확인해\s*보겠|곧\s*알려|생각해\s*보겠|고민해\s*보겠|말씀드리겠|도움이\s*되|분석해\s*보겠|검토해\s*보|알아볼게요|살펴볼게요/;

export function isThinAnswer(text: string, minChars: number): boolean {
  const compact = text.replace(/\s/g, "");
  if (STALL.test(compact.slice(0, 40))) return true;
  return compact.length < minChars;
}

function questionText(item: unknown): string {
  if (typeof item === "string") return item.trim();
  if (item && typeof item === "object") {
    const rec = item as Record<string, unknown>;
    for (const key of ["question", "q", "text"]) {
      if (typeof rec[key] === "string") return String(rec[key]).trim();
    }
  }
  return "";
}

export function normalizeSuggestedQuestions(raw: unknown, category = "my_fortune"): string[] {
  const fallback = easyFollowups[category] ?? easyFollowups.my_fortune;
  const kept: string[] = [];
  if (Array.isArray(raw)) {
    for (const item of raw) {
      const q = questionText(item).replace(/^\d+[.)]\s*/, "");
      if (!q || q.length > 28 || HARD_TERMS.test(q)) continue;
      if (!kept.includes(q)) kept.push(q);
      if (kept.length >= 3) break;
    }
  }
  for (const q of fallback) {
    if (kept.length >= 3) break;
    if (!kept.includes(q)) kept.push(q);
  }
  return kept.slice(0, 3);
}

export function followupAnswerText(parsed: Record<string, unknown>): string {
  const parts: string[] = [];
  const summary = typeof parsed.summary === "string" ? parsed.summary.trim() : "";
  if (summary) parts.push(summary);
  if (Array.isArray(parsed.sections)) {
    for (const item of parsed.sections) {
      if (!item || typeof item !== "object") continue;
      const rec = item as Record<string, unknown>;
      const heading = typeof rec.heading === "string" ? rec.heading.trim() : "";
      const body = typeof rec.body === "string" ? rec.body.trim() : "";
      if (!body) continue;
      parts.push(heading ? `${heading}\n${body}` : body);
    }
  }
  const text = parts.join("\n\n").trim();
  if (text) return text;
  return typeof parsed.title === "string" ? parsed.title.trim() : "";
}

export const envelopeRule = `
반드시 JSON만 출력한다. 마크다운을 쓰지 않는다.
공통 필드:
- title: 짧은 제목
- summary: 결론 자체. 3~5문장. 예고나 인사로 시작하지 않는다.
- sections: [{ "heading": "소제목", "body": "본문" }]
- suggested_questions: 누구나 바로 눌러볼 수 있는 아주 쉬운 한 줄 질문 3개.
  18자 안팎, 일상 말투. 전문 용어(오행, 십신, 용신, 편재, 충, 합, 간지 등) 금지.
  좋은 예: "오늘 조심할 일은?", "돈 흐름은 어때요?", "쉬는 게 나을까요?"
  나쁜 예: "편재와 식신의 합이 재물 흐름에 미치는 영향은?"
어조는 담백한 설명체(~해요). 의료 진단, 범죄, 성생활, 사상 고백을 요구하거나 단정하지 않는다.
건강은 휴식과 생활 리듬 수준만 말한다.
첫 문장은 결론이다. "알아보겠습니다", "살펴볼게요", "정리해 드릴게요", "확인해 보겠습니다", "도움이 되길 바랍니다" 같은 빈말은 쓰지 않는다.
사주 용어를 늘어놓지 말고, 그 뜻을 시간·장소·할 말·피할 일로 풀어 쓴다.
`;

export const depthRule = `
summary는 오늘 바로 써먹는 결론 3~5문장이다.
카테고리 안내가 section 개수를 정하면 그 개수를 따른다. 정하지 않았으면 3개다.
heading은 결론이 드러나는 짧은 말.
각 body는 운세면 5~8문장, 이름 후보면 2~4문장이다. 언제, 어디서, 무슨 말을 하고, 무엇을 미루면 좋은지 운세에 적는다.
막연한 "좋은 흐름입니다"만 반복하지 않는다.
`;
