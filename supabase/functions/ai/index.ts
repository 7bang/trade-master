// AI proxy for the 폰거래장 온 app.
// The Claude API key lives only here (secret CLAUDE_API_KEY); the app never sees it.
// Prompts are built server-side so the endpoint can't be used as a free general-purpose LLM.
import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";

const TEXT_MODEL = "claude-haiku-5-5";
const VISION_MODEL = "claude-sonnet-5-5";

const MAX_TEXT_LENGTH = 500;
const MAX_IMAGE_BASE64_LENGTH = 7_000_000; // ~5MB decoded (API limit per image)
const ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];

const anthropic = new Anthropic({
  apiKey: Deno.env.get("CLAUDE_API_KEY"),
  timeout: 60_000,
  maxRetries: 1,
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ── Auth ──────────────────────────────────────────────────────────────────
// verify_jwt also accepts the public anon key, so confirm a real signed-in user.
async function requireUser(req: Request): Promise<string> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new HttpError(401, "로그인이 필요합니다.");

  const res = await fetch(`${Deno.env.get("SUPABASE_URL")}/auth/v1/user`, {
    headers: {
      Authorization: authHeader,
      apikey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    },
  });
  if (!res.ok) throw new HttpError(401, "로그인이 만료되었습니다. 다시 로그인해주세요.");
  const user = await res.json();
  if (!user?.id) throw new HttpError(401, "로그인이 필요합니다.");
  return user.id as string;
}

// ── Input helpers ─────────────────────────────────────────────────────────
function str(value: unknown, field: string, maxLength = MAX_TEXT_LENGTH): string {
  if (typeof value !== "string" || value.trim() === "") {
    throw new HttpError(400, `${field} 값이 비어 있습니다.`);
  }
  if (value.length > maxLength) {
    throw new HttpError(400, `${field}이(가) 너무 깁니다 (최대 ${maxLength}자).`);
  }
  return value.trim();
}

function num(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpError(400, `${field} 값이 올바르지 않습니다.`);
  }
  return value;
}

const won = (n: number) => Math.round(n).toLocaleString("ko-KR");
const today = () =>
  new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Seoul" }); // YYYY-MM-DD

// ── Usage log (ops report: AI 사용량·비용·실패 집계) ──────────────────────
type Meter = { model: string | null; inputTokens: number; outputTokens: number };

async function logUsage(row: {
  user_id: string | null;
  task: string;
  status: number;
  duration_ms: number;
  meter: Meter;
}) {
  try {
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const res = await fetch(`${Deno.env.get("SUPABASE_URL")}/rest/v1/ai_usage_logs`, {
      method: "POST",
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        user_id: row.user_id,
        task: row.task,
        status: row.status,
        duration_ms: row.duration_ms,
        model: row.meter.model,
        input_tokens: row.meter.inputTokens,
        output_tokens: row.meter.outputTokens,
      }),
    });
    if (!res.ok) console.error("ai_usage_logs insert failed:", res.status, await res.text());
  } catch (error) {
    console.error("ai_usage_logs insert error:", error);
  }
}

// ── Claude call ───────────────────────────────────────────────────────────
type Content = string | Array<Record<string, unknown>>;

async function callClaude(opts: {
  model: string;
  content: Content;
  meter: Meter;
  schema?: Record<string, unknown>;
  maxTokens?: number;
}): Promise<string> {
  opts.meter.model = opts.model;
  const outputConfig: Record<string, unknown> = { effort: "low" };
  if (opts.schema) {
    outputConfig.format = { type: "json_schema", schema: opts.schema };
  }

  const params: Record<string, unknown> = {
    model: opts.model,
    max_tokens: opts.maxTokens ?? 4000,
    output_config: outputConfig,
    messages: [{ role: "user", content: opts.content }],
  };

  // Server-side refusal fallback is available for the Sonnet tier on the Claude API.
  if (opts.model === VISION_MODEL) {
    params.betas = ["server-side-fallback-2026-07-01"];
    params.fallbacks = "default";
  }

  try {
    // deno-lint-ignore no-explicit-any
    const response: any = await anthropic.beta.messages.create(params as any);
    opts.meter.model = response.model ?? opts.model;
    opts.meter.inputTokens += response.usage?.input_tokens ?? 0;
    opts.meter.outputTokens += response.usage?.output_tokens ?? 0;

    if (response.stop_reason === "refusal") {
      throw new HttpError(422, "AI가 이 요청을 처리할 수 없습니다. 내용을 바꿔 다시 시도해주세요.");
    }
    if (response.stop_reason === "max_tokens") {
      throw new HttpError(502, "AI 응답이 너무 길어 중단되었습니다. 다시 시도해주세요.");
    }

    const text = response.content
      .filter((b: { type: string }) => b.type === "text")
      .map((b: { text: string }) => b.text)
      .join("")
      .trim();
    if (!text) throw new HttpError(502, "AI가 빈 응답을 보냈습니다. 다시 시도해주세요.");
    return text;
  } catch (error) {
    if (error instanceof HttpError) throw error;
    if (error instanceof Anthropic.RateLimitError) {
      throw new HttpError(429, "AI 요청이 많습니다. 잠시 후 다시 시도해주세요.");
    }
    if (error instanceof Anthropic.AuthenticationError) {
      console.error("Claude API key rejected");
      throw new HttpError(500, "AI 서버 설정 오류입니다. 관리자에게 문의해주세요.");
    }
    if (error instanceof Anthropic.BadRequestError) {
      console.error("Claude bad request:", error.message);
      throw new HttpError(400, "AI가 입력을 처리하지 못했습니다. 내용을 확인해주세요.");
    }
    if (error instanceof Anthropic.APIConnectionError) {
      throw new HttpError(504, "AI 서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.");
    }
    if (error instanceof Anthropic.APIError) {
      console.error("Claude API error:", error.status, error.message);
      throw new HttpError(502, "AI 서버 오류입니다. 잠시 후 다시 시도해주세요.");
    }
    throw error;
  }
}

// ── Schemas ───────────────────────────────────────────────────────────────
const nullableString = { anyOf: [{ type: "string" }, { type: "null" }] };

const transactionSchema = {
  type: "object",
  properties: {
    customerName: nullableString,
    amount: { type: "number" },
    type: { type: "string", enum: ["receivable", "payable"] },
    memo: nullableString,
    date: { type: "string", format: "date" },
  },
  required: ["customerName", "amount", "type", "memo", "date"],
  additionalProperties: false,
};

const nullableNumber = { anyOf: [{ type: "number" }, { type: "null" }] };

// parse_text (말·글자): 품목·수량·단위·단가를 따로 뽑는다. 못 알아들은 항목은 null.
// 금액·단가 맞추기와 품목 고르기는 앱(TransactionDraft)이 한다.
const spokenSchema = {
  type: "object",
  properties: {
    type: { type: "string", enum: ["receivable", "payable"] },
    date: { type: "string", format: "date" },
    productName: nullableString,
    quantity: nullableNumber,
    unit: nullableString,
    unitPrice: nullableNumber,
    amount: nullableNumber,
    memo: nullableString,
  },
  required: ["type", "date", "productName", "quantity", "unit", "unitPrice", "amount", "memo"],
  additionalProperties: false,
};

const MAX_PRODUCTS = 100;

const insightSchema = {
  type: "object",
  properties: {
    summary: { type: "string" },
    risks: { type: "array", items: { type: "string" } },
    recommendations: { type: "array", items: { type: "string" } },
  },
  required: ["summary", "risks", "recommendations"],
  additionalProperties: false,
};

// ── Tasks ─────────────────────────────────────────────────────────────────
async function parseText(input: Record<string, unknown>, meter: Meter) {
  const text = str(input.text, "입력 내용");
  const products = Array.isArray(input.products)
    ? input.products
      .filter((p): p is string => typeof p === "string" && p.trim() !== "")
      .map((p) => p.trim().slice(0, 50))
      .slice(0, MAX_PRODUCTS)
    : [];
  const catalog = products.length
    ? products.map((p) => `- ${p}`).join("\n")
    : "(등록된 품목 없음)";

  const result = await callClaude({
    meter,
    model: TEXT_MODEL,
    schema: spokenSchema,
    content: `시장 상인이 말하거나 적은 거래 한 건을 항목별로 정리해주세요.
음성 인식 결과일 수 있어 띄어쓰기·맞춤법이 틀릴 수 있습니다.

<input>${text}</input>
오늘 날짜: ${today()}

<등록된_품목>
${catalog}
</등록된_품목>

규칙:
- type: 사장님이 돈을 받는 거래면 receivable, 돈을 내는 거래면 payable
  - receivable: "받을 돈", "매출", "판매", "팔았어", "물건을 외상으로 줬어", "입금 받을"
  - payable: "줄 돈", "매입", "구매", "샀어", "돈 줬어", "돈 냈어", "지급", "값 치렀어"
  - "~원 줬어/냈어"처럼 돈을 준 경우는 payable. 언급이 없으면 receivable
- date: "어제", "그저께", "지난 월요일" 등은 오늘 기준으로 계산. 언급 없으면 오늘
- productName: 거래한 물건 이름. 등록된 품목 중 같은 물건이 있으면 그 이름을 글자 그대로 쓰고, 없으면 말한 이름. 물건이 없으면 null
- quantity: 수량 숫자만. 언급 없으면 null
- unit: 말한 단위. "키로·킬로·키로그램" → "kg", 그 외(개, 마리, 박스, 단, 근)는 그대로. 언급 없으면 null
- unitPrice: 한 단위당 가격을 말했을 때만 ("키로에 2만원", "개당 500원"). 아니면 null
- amount: 전체 금액을 말했을 때만. 아니면 null. 계산해서 채우지 말 것
- memo: 위 항목에 들어가지 않는 내용(배송, 결제 방법 등). 없으면 null
- 금액·수량을 짐작해서 만들지 말 것. 들리지 않았으면 null

말로 한 숫자 예:
- "사만 오천원" → 45000, "만 이천" → 12000, "삼십만" → 300000, "오천 오백원" → 5500
- "삼 키로" → quantity 3, unit "kg" / "반 키로" → 0.5 / "두 박스" → 2, "박스"
- "6만원" "육만원" → 60000

예:
"광어 3키로 6만원 받을 돈" → productName "광어", quantity 3, unit "kg", unitPrice null, amount 60000
"우럭 키로에 만오천원 두 키로 샀어" → payable, productName "우럭", quantity 2, unit "kg", unitPrice 15000, amount null
"포장 비닐 세 묶음 육천원 냈어" → payable, productName "포장 비닐", quantity 3, unit "묶음", amount 6000`,
  });
  return JSON.parse(result);
}

async function parseImage(input: Record<string, unknown>, meter: Meter) {
  const mediaType = str(input.mediaType, "이미지 형식", 20);
  if (!ALLOWED_IMAGE_TYPES.includes(mediaType)) {
    throw new HttpError(400, "지원하지 않는 이미지 형식입니다. JPG·PNG·GIF·WEBP 사진을 사용해주세요.");
  }
  const data = str(input.imageBase64, "이미지", MAX_IMAGE_BASE64_LENGTH);

  const result = await callClaude({
    meter,
    model: VISION_MODEL,
    schema: transactionSchema,
    content: [
      { type: "image", source: { type: "base64", media_type: mediaType, data } },
      {
        type: "text",
        text: `이 이미지에서 거래 정보를 추출해주세요.
오늘 날짜: ${today()}

규칙:
- 영수증이면 보통 payable (구매)
- 납품서·청구서면 receivable (판매)
- amount는 최종 합계 금액
- 금액을 읽을 수 없으면 amount = 0
- 날짜가 없으면 오늘 날짜
- memo에는 품목 요약, 없으면 null`,
      },
    ],
  });
  return JSON.parse(result);
}

async function insights(input: Record<string, unknown>, meter: Meter) {
  const topCustomers = typeof input.topCustomers === "string"
    ? input.topCustomers.slice(0, 1000)
    : "없음";
  const result = await callClaude({
    meter,
    model: TEXT_MODEL,
    schema: insightSchema,
    content: `소상공인 거래 데이터를 분석해서 경영 인사이트를 제공해주세요.

데이터:
- 거래처 수: ${num(input.customerCount, "거래처 수")}명
- 이번 달 매출(receivable): ${won(num(input.monthlyReceivable, "이번 달 매출"))}원
- 이번 달 매입(payable): ${won(num(input.monthlyPayable, "이번 달 매입"))}원
- 미수금 합계: ${won(num(input.totalReceivable, "미수금 합계"))}원
- 미지급 합계: ${won(num(input.totalPayable, "미지급 합계"))}원
- 상위 거래처 (잔액 기준): ${topCustomers}

summary는 전체 경영 상황 요약 2-3문장, risks는 위험 요소 2개 내외, recommendations는 권고사항 3개 내외로 작성하세요.`,
  });
  return JSON.parse(result);
}

async function collectionMessage(input: Record<string, unknown>, meter: Meter) {
  const customerName = str(input.customerName, "거래처명", 100);
  const balance = num(input.balance, "미수금액");
  if (balance <= 0) throw new HttpError(400, "받을 미수금이 없는 거래처입니다.");
  const businessName = str(input.businessName, "사업장명", 100);
  const businessPhone = typeof input.businessPhone === "string"
    ? input.businessPhone.trim().slice(0, 30)
    : "";
  const signature = businessPhone ? `${businessName} (${businessPhone})` : businessName;

  const text = await callClaude({
    meter,
    model: TEXT_MODEL,
    content: `소상공인이 거래처에게 보낼 미수금 입금 요청 메시지를 작성해주세요.
카카오톡으로 보내기 좋은 짧고 정중한 톤으로, 메시지 본문만 응답하세요.

보내는 사업장: ${businessName}
거래처명: ${customerName}
미수금액: ${won(balance)}원

조건:
- 2-4문장 이내
- 정중하지만 명확하게 입금 요청
- 마지막 줄 서명은 정확히 "${signature} 드림"
- [사업장명] 같은 대괄호 자리표시자는 쓰지 말 것`,
  });
  return { text };
}

const tasks: Record<
  string,
  (input: Record<string, unknown>, meter: Meter) => Promise<unknown>
> = {
  parse_text: parseText,
  parse_image: parseImage,
  insights,
  collection_message: collectionMessage,
};

// ── Entry ─────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const startedAt = Date.now();
  const meter: Meter = { model: null, inputTokens: 0, outputTokens: 0 };
  let userId: string | null = null;
  let task: string | null = null;
  let status = 200;

  try {
    userId = await requireUser(req);

    const body = await req.json().catch(() => null);
    const handler = tasks[body?.task];
    if (!handler) throw new HttpError(400, "알 수 없는 AI 요청입니다.");
    task = body.task as string;

    const result = await handler(body.input ?? {}, meter);
    return json({ result });
  } catch (error) {
    if (error instanceof HttpError) {
      status = error.status;
      return json({ error: error.message }, error.status);
    }
    status = 500;
    console.error("Unhandled AI function error:", error);
    return json({ error: "AI 처리 중 오류가 발생했습니다. 다시 시도해주세요." }, 500);
  } finally {
    // 로그인 사용자의 유효한 작업만 기록 (응답은 기다리지 않음)
    if (userId && task) {
      const pending = logUsage({
        user_id: userId,
        task,
        status,
        duration_ms: Date.now() - startedAt,
        meter,
      });
      // deno-lint-ignore no-explicit-any
      (globalThis as any).EdgeRuntime?.waitUntil?.(pending);
    }
  }
});
