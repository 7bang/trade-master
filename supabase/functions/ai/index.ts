// AI proxy for the TradeClip app.
// The Claude API key lives only here (secret CLAUDE_API_KEY); the app never sees it.
// Prompts are built server-side so the endpoint can't be used as a free general-purpose LLM.
import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";

const TEXT_MODEL = "claude-haiku-5-5";
const VISION_MODEL = "claude-sonnet-5-5";

const MAX_TEXT_LENGTH = 500;
const MAX_IMAGE_BASE64_LENGTH = 7_000_000; // ~5MB decoded (API limit per image)
const MAX_DOC_ITEMS = 50;
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

// ── Claude call ───────────────────────────────────────────────────────────
type Content = string | Array<Record<string, unknown>>;

async function callClaude(opts: {
  model: string;
  content: Content;
  schema?: Record<string, unknown>;
  maxTokens?: number;
}): Promise<string> {
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
async function parseText(input: Record<string, unknown>) {
  const text = str(input.text, "입력 내용");
  const result = await callClaude({
    model: TEXT_MODEL,
    schema: transactionSchema,
    content: `사용자 입력을 거래 정보로 파싱해주세요.

<input>${text}</input>
오늘 날짜: ${today()}

규칙:
- "받을 돈", "매출", "입금", "판매" → receivable
- "줄 돈", "매입", "출금", "구매", "지급" → payable
- 수량×단가 언급 시 amount = 수량×단가
- 금액을 알 수 없으면 amount = 0
- 날짜 언급이 없으면 오늘 날짜 사용
- 거래처명·메모가 없으면 null`,
  });
  return JSON.parse(result);
}

async function parseImage(input: Record<string, unknown>) {
  const mediaType = str(input.mediaType, "이미지 형식", 20);
  if (!ALLOWED_IMAGE_TYPES.includes(mediaType)) {
    throw new HttpError(400, "지원하지 않는 이미지 형식입니다. JPG·PNG·GIF·WEBP 사진을 사용해주세요.");
  }
  const data = str(input.imageBase64, "이미지", MAX_IMAGE_BASE64_LENGTH);

  const result = await callClaude({
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

async function insights(input: Record<string, unknown>) {
  const topCustomers = typeof input.topCustomers === "string"
    ? input.topCustomers.slice(0, 1000)
    : "없음";
  const result = await callClaude({
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

async function collectionMessage(input: Record<string, unknown>) {
  const customerName = str(input.customerName, "거래처명", 100);
  const balance = num(input.balance, "미수금액");
  if (balance <= 0) throw new HttpError(400, "받을 미수금이 없는 거래처입니다.");

  const text = await callClaude({
    model: TEXT_MODEL,
    content: `소상공인이 거래처에게 보낼 미수금 입금 요청 메시지를 작성해주세요.
카카오톡으로 보내기 좋은 짧고 정중한 톤으로, 메시지 본문만 응답하세요.

거래처명: ${customerName}
미수금액: ${won(balance)}원

조건:
- 2-4문장 이내
- 정중하지만 명확하게 입금 요청
- 사업주 서명란은 "[사업장명]"으로 표기`,
  });
  return { text };
}

async function document(input: Record<string, unknown>) {
  const docType = input.documentType === "quote" ? "견적서" : "납품서";
  const businessName = str(input.businessName, "사업장명", 100);
  const customerName = str(input.customerName, "거래처명", 100);
  if (!Array.isArray(input.items) || input.items.length === 0) {
    throw new HttpError(400, "품목을 1개 이상 입력해주세요.");
  }
  if (input.items.length > MAX_DOC_ITEMS) {
    throw new HttpError(400, `품목은 최대 ${MAX_DOC_ITEMS}개까지 입력할 수 있습니다.`);
  }

  let total = 0;
  const lines = input.items.map((raw: Record<string, unknown>) => {
    const name = str(raw.name, "품목명", 100);
    const quantity = num(raw.quantity, "수량");
    const unitPrice = num(raw.unitPrice, "단가");
    const unit = typeof raw.unit === "string" && raw.unit ? raw.unit.slice(0, 10) : "개";
    const subtotal = quantity * unitPrice;
    total += subtotal;
    return `- ${name}: ${quantity}${unit} × ${won(unitPrice)}원 = ${won(subtotal)}원`;
  });

  const issued = new Date().toLocaleDateString("ko-KR", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  const text = await callClaude({
    model: TEXT_MODEL,
    content: `아래 정보로 ${docType} 텍스트를 작성해주세요.
깔끔하고 읽기 좋은 형식으로, 문서 텍스트만 응답하세요.

발행일: ${issued}
공급자(사업장): ${businessName}
수신자(거래처): ${customerName}

품목:
${lines.join("\n")}

합계: ${won(total)}원

형식 요건:
- 제목: "${docType}"
- 발행일·공급자·수신자 표시
- 품목 표 형태 (텍스트)
- 합계 금액 강조
- 하단에 "위와 같이 ${docType} 드립니다." 문구`,
  });
  return { text };
}

const tasks: Record<string, (input: Record<string, unknown>) => Promise<unknown>> = {
  parse_text: parseText,
  parse_image: parseImage,
  insights,
  collection_message: collectionMessage,
  document,
};

// ── Entry ─────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    await requireUser(req);

    const body = await req.json().catch(() => null);
    const handler = tasks[body?.task];
    if (!handler) throw new HttpError(400, "알 수 없는 AI 요청입니다.");

    const result = await handler(body.input ?? {});
    return json({ result });
  } catch (error) {
    if (error instanceof HttpError) return json({ error: error.message }, error.status);
    console.error("Unhandled AI function error:", error);
    return json({ error: "AI 처리 중 오류가 발생했습니다. 다시 시도해주세요." }, 500);
  }
});
