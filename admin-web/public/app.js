// 폰거래장 온 관리자 페이지 — 화면·데이터 로직 (index.html 에서 분리: CSP에서 인라인 스크립트 금지)
(() => {
  'use strict';
  const cfg = window.ADMIN_CONFIG;
  // 관리자 페이지는 탭 하나에서 쓰므로 브라우저 탭 간 세션 잠금(navigator.locks)을 쓰지 않는다
  // (일부 환경에서 잠금 대기로 첫 화면이 10초가량 멈추는 문제 방지)
  const sb = supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey, {
    auth: { lock: async (_name, _timeout, fn) => await fn() },
  });
  const app = document.getElementById('app');
  const tip = document.getElementById('tip');

  // ── 공통 ───────────────────────────────────────────────────────────────
  // 사업장명·메모 등은 사용자가 입력한 값 → 화면에 넣을 때 반드시 이스케이프 (관리자 세션 탈취 방지)
  const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const n = (v) => Number(v ?? 0).toLocaleString('ko-KR');
  const won = (v) => `${n(Math.round(Number(v ?? 0)))}원`;
  const usd = (v) => `$${Number(v ?? 0).toFixed(4)}`;
  const kst = (iso, withTime = true) => {
    if (!iso) return '—';
    const d = new Date(iso);
    return d.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul', year: '2-digit', month: '2-digit', day: '2-digit',
      ...(withTime ? { hour: '2-digit', minute: '2-digit', hour12: false } : {}) });
  };
  const ago = (iso) => {
    if (!iso) return '없음';
    const days = Math.floor((Date.now() - new Date(iso)) / 86400000);
    return days <= 0 ? '오늘' : `${days}일 전`;
  };
  const STATUS = {
    active: ['✓ 활동', 'b-active', '7일 안에 거래 입력'],
    caution: ['! 주의', 'b-caution', '7~30일 거래 없음'],
    churned: ['✕ 이탈', 'b-churned', '30일 넘게 거래 없음'],
    unused: ['○ 미사용', 'b-unused', '거래 0건'],
  };
  const badge = (s) => { const [t, c, h] = STATUS[s] || [s, '', '']; return `<span class="badge ${c}" title="${esc(h)}">${esc(t)}</span>`; };

  async function rpc(name, args) {
    const { data, error } = await sb.rpc(name, args);
    if (error) {
      if (error.code === '42501' || /권한/.test(error.message)) throw new Error('관리자 권한이 없습니다.');
      throw new Error(`불러오지 못했습니다 (${error.message})`);
    }
    return data;
  }

  function showError(e) {
    app.innerHTML = `<div class="error">${esc(e.message || e)}</div>`;
  }

  // ── 차트: 단일 시리즈 막대 (한 차트 = 한 단위, 이중 축 없음) ─────────────────
  function barChart({ title, unit, points, format = n }) {
    const W = 560, H = 180, pad = { l: 40, r: 8, t: 8, b: 24 };
    const iw = W - pad.l - pad.r, ih = H - pad.t - pad.b;
    const max = Math.max(1, ...points.map((p) => p.value));
    const nice = niceMax(max);
    const step = iw / points.length;
    const bw = Math.max(2, step - 2); // 막대 사이 2px 간격
    const y = (v) => pad.t + ih - (v / nice) * ih;
    const id = `c${Math.random().toString(36).slice(2, 8)}`;
    const ticks = [0, nice / 2, nice];
    const grid = ticks.map((t) => `<line x1="${pad.l}" x2="${W - pad.r}" y1="${y(t)}" y2="${y(t)}" stroke="var(--line)" stroke-width="1"/>
      <text x="${pad.l - 6}" y="${y(t) + 4}" text-anchor="end" font-size="11" fill="var(--gray)">${esc(format(t))}</text>`).join('');
    const bars = points.map((p, i) => {
      const x = pad.l + i * step + 1;
      const h = Math.max(0, (p.value / nice) * ih);
      const r = Math.min(4, bw / 2, h);
      // 위쪽 모서리만 둥글게, 바닥은 기준선에 붙임
      const top = pad.t + ih - h;
      const path = h <= 0 ? '' : `M${x},${pad.t + ih} V${top + r} Q${x},${top} ${x + r},${top} H${x + bw - r} Q${x + bw},${top} ${x + bw},${top + r} V${pad.t + ih} Z`;
      return `<path d="${path}" fill="var(--chart)"/>
        <rect class="hit" x="${pad.l + i * step}" y="${pad.t}" width="${step}" height="${ih}" fill="transparent"
          data-tip="${esc(`${p.label} · ${format(p.value)}${unit}`)}"/>`;
    }).join('');
    const xl = [0, Math.floor(points.length / 2), points.length - 1].filter((v, i, a) => a.indexOf(v) === i)
      .map((i) => `<text x="${pad.l + i * step + step / 2}" y="${H - 6}" text-anchor="middle" font-size="11" fill="var(--gray)">${esc(points[i]?.short ?? '')}</text>`).join('');
    const total = points.reduce((s, p) => s + p.value, 0);
    const rows = points.map((p) => `<tr><td>${esc(p.label)}</td><td class="r num">${esc(format(p.value))}</td></tr>`).join('');
    return `<div class="card chart">
      <h3>${esc(title)}<span>합계 ${esc(format(total))}${esc(unit)}</span></h3>
      <svg id="${id}" viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(title)} 최근 ${points.length}일">${grid}${bars}${xl}</svg>
      <details><summary>표로 보기</summary><table><tbody>${rows}</tbody></table></details>
    </div>`;
  }
  function niceMax(v) {
    const p = 10 ** Math.floor(Math.log10(v));
    for (const m of [1, 2, 2.5, 5, 10]) if (m * p >= v) return m * p;
    return 10 * p;
  }
  const dayPoints = (daily, key) => daily.map((d) => {
    const [, m, dd] = String(d.date).split('-');
    return { label: `${Number(m)}월 ${Number(dd)}일`, short: `${Number(m)}/${Number(dd)}`, value: Number(d[key] ?? 0) };
  });
  // 차트 툴팁 (막대보다 넓은 히트 영역)
  document.addEventListener('mousemove', (e) => {
    const t = e.target.closest?.('[data-tip]');
    if (!t) { tip.style.display = 'none'; return; }
    tip.textContent = t.getAttribute('data-tip');
    tip.style.display = 'block';
    tip.style.left = `${Math.min(e.clientX + 12, innerWidth - tip.offsetWidth - 8)}px`;
    tip.style.top = `${e.clientY - 36}px`;
  });

  // ── 정렬 가능한 표 ─────────────────────────────────────────────────────
  function sortable(table, rows, render) {
    let key = null, dir = 1;
    table.querySelectorAll('th.sort').forEach((th) => th.addEventListener('click', () => {
      const k = th.dataset.key;
      dir = key === k ? -dir : -1; // 처음 누르면 큰 값부터
      key = k;
      table.querySelectorAll('th.sort').forEach((x) => x.classList.remove('asc', 'desc'));
      th.classList.add(dir === 1 ? 'asc' : 'desc');
      rows.sort((a, b) => {
        const va = a[k], vb = b[k];
        if (va == null && vb == null) return 0;
        if (va == null) return 1;
        if (vb == null) return -1;
        return (typeof va === 'number' ? va - vb : String(va).localeCompare(String(vb), 'ko')) * dir;
      });
      render();
    }));
  }

  // ── 화면: 로그인 ───────────────────────────────────────────────────────
  function renderLogin(message) {
    document.getElementById('top').hidden = true;
    app.innerHTML = `<form class="card login" id="login">
      <div class="brand center" style="justify-content:center">
        <svg width="28" height="28" viewBox="0 0 120 120" aria-hidden="true"><circle cx="60" cy="30" r="18" fill="none" stroke="#C4321E" stroke-width="17"/><path d="M51 56H69V64H104V92H16V64H51Z" fill="#1F2A36"/><rect x="38" y="102" width="44" height="14" fill="#C4321E"/></svg>
        폰거래장 온 <small>관리자</small></div>
      <label for="em">이메일</label><input id="em" type="email" autocomplete="username" required>
      <label for="pw">비밀번호</label><input id="pw" type="password" autocomplete="current-password" required>
      <button class="btn primary" type="submit">로그인</button>
      ${message ? `<div class="error">${esc(message)}</div>` : ''}
    </form>`;
    document.getElementById('login').addEventListener('submit', async (e) => {
      e.preventDefault();
      const btn = e.target.querySelector('button');
      btn.disabled = true; btn.textContent = '확인 중…';
      const { error } = await sb.auth.signInWithPassword({
        email: document.getElementById('em').value.trim(),
        password: document.getElementById('pw').value,
      });
      if (error) { renderLogin('이메일 또는 비밀번호가 맞지 않습니다.'); return; }
      await start();
    });
  }

  // ── 화면: 개요 ─────────────────────────────────────────────────────────
  async function renderOverview() {
    const d = await rpc('admin_overview');
    const t = d.totals;
    const tile = (label, value, sub = '') => `<div class="card tile"><div class="label">${esc(label)}</div><div class="value num">${value}</div>${sub ? `<div class="sub">${sub}</div>` : ''}</div>`;
    const risk = d.at_risk.length
      ? `<ul class="lists">${d.at_risk.map((b) => `<li><a href="#/business/${esc(b.business_id)}">${esc(b.name)}</a> <span class="muted small">마지막 ${esc(kst(b.last_at, false))} · 총 ${n(b.total)}건</span></li>`).join('')}</ul>`
      : '<p class="muted">없음</p>';
    const unused = d.unused.length
      ? `<ul class="lists">${d.unused.map((b) => `<li><a href="#/business/${esc(b.business_id)}">${esc(b.name)}</a> <span class="muted small">${esc(b.email)} · 가입 ${esc(kst(b.created_at, false))}</span></li>`).join('')}</ul>`
      : '<p class="muted">없음</p>';
    app.innerHTML = `<h1>개요</h1>
      <div class="tiles">
        ${tile('전체 계정', n(t.accounts), `7일 신규 ${n(t.new_accounts_7d)}`)}
        ${tile('사업장', n(t.businesses))}
        ${tile('오늘 활동 사업장', n(t.active_today))}
        ${tile('7일 활동 사업장', n(t.active_7d), `30일 ${n(t.active_30d)}곳`)}
        ${tile('7일 거래 등록', n(t.tx_7d), '건')}
        ${tile('30일 AI 예상 비용', usd(t.ai_cost_30d), `호출 ${n(t.ai_calls_30d)}건`)}
      </div>
      <h2>최근 30일</h2>
      <div class="charts">
        ${barChart({ title: '거래 등록', unit: '건', points: dayPoints(d.daily, 'tx') })}
        ${barChart({ title: '활동 사업장', unit: '곳', points: dayPoints(d.daily, 'active') })}
        ${barChart({ title: '신규 가입', unit: '명', points: dayPoints(d.daily, 'signups') })}
      </div>
      <div class="grid2" style="margin-top:12px">
        <div class="card"><h3 style="margin-top:0">! 이탈 위험 <span class="muted small">30일 안에 쓰다가 3일 이상 거래 없음</span></h3>${risk}</div>
        <div class="card"><h3 style="margin-top:0">○ 가입 후 거래 0건</h3>${unused}</div>
      </div>`;
  }

  // ── 화면: 사업장 목록 ──────────────────────────────────────────────────
  async function renderBusinesses() {
    const all = await rpc('admin_businesses');
    const rows = all.map((b) => ({
      ...b,
      tx_7d: Number(b.tx_7d), tx_30d: Number(b.tx_30d), tx_total: Number(b.tx_total),
      customers: Number(b.customers), products: Number(b.products),
      ai_calls_30d: Number(b.ai_calls_30d), ai_cost_30d: Number(b.ai_cost_30d),
    }));
    const counts = Object.fromEntries(Object.keys(STATUS).map((s) => [s, rows.filter((r) => r.status === s).length]));
    app.innerHTML = `<h1>사업장 <span class="muted small">${n(rows.length)}곳</span></h1>
      <div class="toolbar">
        <input id="q" type="search" placeholder="사업장명·이메일·연락처 검색" aria-label="검색">
        <select id="st" aria-label="상태">
          <option value="">전체 상태</option>
          ${Object.entries(STATUS).map(([k, [t]]) => `<option value="${k}">${esc(t)} (${counts[k]})</option>`).join('')}
        </select>
      </div>
      <div class="table-wrap"><table id="tb">
        <thead><tr>
          <th class="sort" data-key="business_name">사업장</th>
          <th class="sort" data-key="status">상태</th>
          <th class="sort" data-key="last_tx_at">마지막 거래</th>
          <th class="sort r" data-key="tx_7d">7일</th>
          <th class="sort r" data-key="tx_30d">30일</th>
          <th class="sort r" data-key="tx_total">전체</th>
          <th class="sort r" data-key="customers">거래처</th>
          <th class="sort r" data-key="products">품목</th>
          <th class="sort r" data-key="ai_calls_30d">AI(30일)</th>
          <th class="sort" data-key="last_sign_in_at">마지막 로그인</th>
          <th class="sort" data-key="signed_up_at">가입</th>
        </tr></thead><tbody></tbody></table></div>`;
    const tbody = app.querySelector('tbody');
    const q = app.querySelector('#q'), st = app.querySelector('#st');
    const render = () => {
      const k = q.value.trim().toLowerCase();
      const list = rows.filter((r) => (!st.value || r.status === st.value)
        && (!k || [r.business_name, r.email, r.phone].some((v) => String(v ?? '').toLowerCase().includes(k))));
      tbody.innerHTML = list.map((r) => `<tr class="click" data-id="${esc(r.business_id)}">
        <td><strong>${esc(r.business_name)}</strong><div class="muted small">${esc(r.email)}${r.phone ? ` · ${esc(r.phone)}` : ''}</div></td>
        <td>${badge(r.status)}</td>
        <td class="num">${esc(kst(r.last_tx_at))}<div class="muted small">${esc(ago(r.last_tx_at))}</div></td>
        <td class="r num">${n(r.tx_7d)}</td><td class="r num">${n(r.tx_30d)}</td><td class="r num">${n(r.tx_total)}</td>
        <td class="r num">${n(r.customers)}</td><td class="r num">${n(r.products)}</td>
        <td class="r num">${n(r.ai_calls_30d)}<div class="muted small">${usd(r.ai_cost_30d)}</div></td>
        <td class="num small">${esc(kst(r.last_sign_in_at))}</td>
        <td class="num small">${esc(kst(r.signed_up_at, false))}</td>
      </tr>`).join('') || '<tr><td colspan="11" class="muted center">조건에 맞는 사업장이 없습니다</td></tr>';
    };
    q.addEventListener('input', render);
    st.addEventListener('change', render);
    tbody.addEventListener('click', (e) => {
      const tr = e.target.closest('tr[data-id]');
      if (tr) location.hash = `#/business/${tr.dataset.id}`;
    });
    sortable(app.querySelector('#tb'), rows, render);
    render();
  }

  // ── 화면: 사업장 상세 (열람 기록 남음) ─────────────────────────────────
  async function renderBusiness(id) {
    const d = await rpc('admin_business_detail', { p_business_id: id });
    const b = d.business, s = d.summary;
    const balance = Number(s.receivable_total) - Number(s.payable_total);
    const custRows = d.customers.map((c) => `<tr>
      <td>${esc(c.name)}${c.is_active ? '' : ' <span class="muted small">(삭제됨)</span>'}<div class="muted small">${esc(c.phone || '')}</div></td>
      <td class="r num ${Number(c.balance) >= 0 ? 'recv' : 'pay'}">${won(Math.abs(c.balance))} <span class="small">${Number(c.balance) >= 0 ? '받을 돈' : '줄 돈'}</span></td>
      <td class="r num">${n(c.tx_count)}</td></tr>`).join('') || '<tr><td colspan="3" class="muted">없음</td></tr>';
    const prodRows = d.products.map((p) => `<tr><td>${esc(p.name)}${p.is_active ? '' : ' <span class="muted small">(삭제됨)</span>'}</td>
      <td>${esc(p.unit)}</td><td class="r num">${p.default_unit_price == null ? '—' : won(p.default_unit_price)}</td></tr>`).join('') || '<tr><td colspan="3" class="muted">없음</td></tr>';
    const aiRows = d.ai.map((a) => `<tr><td>${esc(a.label)}</td><td class="r num">${n(a.calls)}</td><td class="r num">${n(a.failed)}</td><td class="r num">${usd(a.cost)}</td></tr>`).join('')
      || '<tr><td colspan="4" class="muted">최근 30일 사용 없음</td></tr>';

    app.innerHTML = `<p><a href="#/businesses">← 사업장 목록</a></p>
      <h1>${esc(b.name)}</h1>
      <p class="note small">이 화면을 연 기록이 남습니다 (개인정보 열람 기록). 고객 지원·운영 목적으로만 열람하세요.</p>
      <div class="grid2" style="margin-top:12px">
        <div class="card"><dl class="kv">
          <dt>이메일</dt><dd>${esc(b.email)}</dd>
          <dt>연락처</dt><dd>${esc(b.phone || '—')}</dd>
          <dt>가입</dt><dd class="num">${esc(kst(b.created_at))}</dd>
          <dt>마지막 로그인</dt><dd class="num">${esc(kst(b.last_sign_in_at))}</dd>
          <dt>마지막 거래 입력</dt><dd class="num">${esc(kst(s.last_created_at))} <span class="muted small">${esc(ago(s.last_created_at))}</span></dd>
        </dl></div>
        <div class="card"><dl class="kv">
          <dt>거래</dt><dd class="num">${n(s.tx_count)}건 <span class="muted small">${esc(s.first_date || '')} ~ ${esc(s.last_date || '')}</span></dd>
          <dt>받을 돈 합계</dt><dd class="num recv">${won(s.receivable_total)}</dd>
          <dt>줄 돈 합계</dt><dd class="num pay">${won(s.payable_total)}</dd>
          <dt>잔액</dt><dd class="num"><strong>${won(Math.abs(balance))}</strong> ${balance >= 0 ? '받을 돈' : '줄 돈'}</dd>
        </dl></div>
      </div>
      <div class="charts" style="margin-top:12px">${barChart({ title: '거래 등록 (최근 30일)', unit: '건', points: dayPoints(d.daily, 'tx') })}</div>
      <div class="grid2">
        <div><h2>거래처 <span class="muted small">${n(d.customers.length)}곳 · 잔액 큰 순</span></h2>
          <div class="table-wrap" style="max-height:420px;overflow:auto"><table><thead><tr><th>거래처</th><th class="r">잔액</th><th class="r">거래</th></tr></thead><tbody>${custRows}</tbody></table></div></div>
        <div><h2>품목 <span class="muted small">${n(d.products.length)}개</span></h2>
          <div class="table-wrap" style="max-height:420px;overflow:auto"><table><thead><tr><th>품목</th><th>단위</th><th class="r">기본 단가</th></tr></thead><tbody>${prodRows}</tbody></table></div></div>
      </div>
      <h2>AI 사용 <span class="muted small">최근 30일</span></h2>
      <div class="table-wrap"><table><thead><tr><th>기능</th><th class="r">호출</th><th class="r">실패</th><th class="r">예상 비용</th></tr></thead><tbody>${aiRows}</tbody></table></div>
      <h2>거래 내역 <span class="muted small">최신 순</span></h2>
      <div class="table-wrap"><table><thead><tr><th>날짜</th><th>유형</th><th>거래처</th><th>품목</th><th class="r">수량</th><th class="r">단가</th><th class="r">금액</th><th>메모</th></tr></thead><tbody id="txb"></tbody></table></div>
      <p class="center"><button class="btn" id="more">50건 더 보기</button></p>`;

    const txb = app.querySelector('#txb'), more = app.querySelector('#more');
    let offset = 0;
    const loadMore = async () => {
      more.disabled = true; more.textContent = '불러오는 중…';
      try {
        const rows = await rpc('admin_business_transactions', { p_business_id: id, p_limit: 50, p_offset: offset });
        offset += rows.length;
        txb.insertAdjacentHTML('beforeend', rows.map((t) => `<tr>
          <td class="num">${esc(t.date)}</td>
          <td class="${t.type === 'receivable' ? 'recv' : 'pay'}">${t.type === 'receivable' ? '받을 돈' : '줄 돈'}</td>
          <td>${esc(t.customer_name || '—')}</td><td>${esc(t.product_name || '—')}</td>
          <td class="r num">${t.quantity == null ? '—' : `${n(t.quantity)}${esc(t.unit || '')}`}</td>
          <td class="r num">${t.unit_price == null ? '—' : won(t.unit_price)}</td>
          <td class="r num"><strong>${won(t.amount)}</strong></td>
          <td class="small">${esc(t.memo || '')}</td></tr>`).join(''));
        if (offset === 0) txb.innerHTML = '<tr><td colspan="8" class="muted">거래 없음</td></tr>';
        more.hidden = rows.length < 50;
      } catch (e) {
        more.insertAdjacentHTML('afterend', `<div class="error">${esc(e.message)}</div>`);
      } finally {
        more.disabled = false; more.textContent = '50건 더 보기';
      }
    };
    more.addEventListener('click', loadMore);
    await loadMore();
  }

  // ── 화면: AI 사용량 ────────────────────────────────────────────────────
  async function renderAi(days = 30) {
    const d = await rpc('admin_ai_usage', { p_days: days });
    const t = d.totals;
    const tile = (label, value, sub = '') => `<div class="card tile"><div class="label">${esc(label)}</div><div class="value num">${value}</div>${sub ? `<div class="sub">${sub}</div>` : ''}</div>`;
    const taskRows = d.by_task.map((x) => `<tr><td>${esc(x.label)}</td><td class="r num">${n(x.calls)}</td><td class="r num">${n(x.failed)}</td>
      <td class="r num">${x.avg_ms == null ? '—' : `${(x.avg_ms / 1000).toFixed(1)}초`}</td><td class="r num">${usd(x.cost)}</td></tr>`).join('')
      || '<tr><td colspan="5" class="muted">사용 없음</td></tr>';
    const bizRows = d.by_business.map((x) => `<tr class="click" data-id="${esc(x.business_id || '')}"><td>${esc(x.name)}</td><td class="r num">${n(x.calls)}</td>
      <td class="r num">${n(x.failed)}</td><td class="r num">${usd(x.cost)}</td></tr>`).join('')
      || '<tr><td colspan="4" class="muted">사용 없음</td></tr>';
    app.innerHTML = `<h1>AI 사용량</h1>
      <div class="toolbar"><select id="days" aria-label="기간">
        ${[7, 30, 90].map((v) => `<option value="${v}" ${v === d.days ? 'selected' : ''}>최근 ${v}일</option>`).join('')}
      </select></div>
      ${d.unpriced_models.length ? `<p class="note">단가가 등록되지 않은 모델: ${esc(d.unpriced_models.join(', '))} — 비용이 0으로 계산됩니다 (stats.ai_prices)</p>` : ''}
      <div class="tiles">
        ${tile('호출', n(t.calls), `실패 ${n(t.failed)}건`)}
        ${tile('예상 비용', usd(t.cost))}
        ${tile('입력 토큰', n(t.input_tokens))}
        ${tile('출력 토큰', n(t.output_tokens))}
      </div>
      <h2>일별</h2>
      <div class="charts">
        ${barChart({ title: 'AI 호출', unit: '건', points: dayPoints(d.daily, 'calls') })}
        ${barChart({ title: '예상 비용', unit: '', points: dayPoints(d.daily, 'cost'), format: usd })}
      </div>
      <div class="grid2">
        <div><h2>기능별</h2><div class="table-wrap"><table><thead><tr><th>기능</th><th class="r">호출</th><th class="r">실패</th><th class="r">평균 응답</th><th class="r">비용</th></tr></thead><tbody>${taskRows}</tbody></table></div></div>
        <div><h2>사업장별</h2><div class="table-wrap"><table><thead><tr><th>사업장</th><th class="r">호출</th><th class="r">실패</th><th class="r">비용</th></tr></thead><tbody id="bz">${bizRows}</tbody></table></div></div>
      </div>`;
    app.querySelector('#days').addEventListener('change', (e) => route(Number(e.target.value)));
    app.querySelector('#bz').addEventListener('click', (e) => {
      const tr = e.target.closest('tr[data-id]');
      if (tr && tr.dataset.id) location.hash = `#/business/${tr.dataset.id}`;
    });
  }

  // ── 화면: 공지사항 (작성·수정·게시/숨김·삭제) ───────────────────────────
  async function renderNotices() {
    const list = await rpc('admin_announcements');
    const rows = list.map((a) => `<tr class="click" data-id="${esc(a.id)}">
      <td><strong>${esc(a.title)}</strong>
        <div class="muted small">${esc(String(a.body).slice(0, 60))}${String(a.body).length > 60 ? '…' : ''}</div></td>
      <td>${a.is_published ? '<span class="badge b-pub">✓ 게시</span>' : '<span class="badge b-draft">○ 숨김</span>'}
        ${a.is_important ? ' <span class="badge b-imp">! 팝업</span>' : ''}</td>
      <td class="num small">${esc(kst(a.published_at))}</td>
      <td class="r num">${n(a.read_count)}</td>
    </tr>`).join('') || '<tr><td colspan="4" class="muted center">아직 공지가 없습니다</td></tr>';
    app.innerHTML = `<h1>공지사항</h1>
      <p class="muted">게시한 공지는 앱 <strong>설정 → 공지사항</strong>에 바로 보입니다.
        <strong>팝업</strong>을 켜면 아직 안 읽은 사람에게 앱을 열 때 한 번 뜹니다.</p>
      <div class="toolbar"><button class="btn primary" id="new">+ 새 공지</button></div>
      <div class="table-wrap"><table>
        <thead><tr><th>제목</th><th>상태</th><th>게시일</th><th class="r">읽은 사람</th></tr></thead>
        <tbody id="nb">${rows}</tbody></table></div>`;
    app.querySelector('#new').addEventListener('click', () => { location.hash = '#/notice/new'; });
    app.querySelector('#nb').addEventListener('click', (e) => {
      const tr = e.target.closest('tr[data-id]');
      if (tr) location.hash = `#/notice/${tr.dataset.id}`;
    });
  }

  async function renderNoticeForm(id) {
    const isNew = id === 'new';
    let a = { title: '', body: '', link_url: '', link_label: '', is_important: false, is_published: false };
    if (!isNew) {
      const found = (await rpc('admin_announcements')).find((x) => x.id === id);
      if (!found) throw new Error('공지를 찾을 수 없습니다.');
      a = found;
    }
    app.innerHTML = `<p><a href="#/notices">← 공지사항</a></p>
      <h1>${isNew ? '새 공지' : '공지 수정'}</h1>
      <form class="card form" id="nf">
        <label for="f-title">제목 (100자까지)</label>
        <input id="f-title" type="text" maxlength="100" required value="${esc(a.title)}">
        <label for="f-body">본문 (5,000자까지, 줄바꿈 그대로 표시)</label>
        <textarea id="f-body" maxlength="5000" required>${esc(a.body)}</textarea>
        <label for="f-url">링크 주소 (선택, https:// 로 시작)</label>
        <input id="f-url" type="url" placeholder="https://" pattern="https://.+" value="${esc(a.link_url || '')}">
        <label for="f-label">링크 버튼 글자 (선택, 비우면 "자세히 보기")</label>
        <input id="f-label" type="text" maxlength="30" value="${esc(a.link_label || '')}">
        <label class="check"><input id="f-imp" type="checkbox" ${a.is_important ? 'checked' : ''}> 팝업으로 알리기 (앱을 열 때 안 읽은 사람에게 한 번)</label>
        <label class="check"><input id="f-pub" type="checkbox" ${a.is_published ? 'checked' : ''}> 게시하기 (끄면 앱에 보이지 않음)</label>
        ${!isNew && a.published_at ? `<div class="hint">처음 게시: ${esc(kst(a.published_at))} · 읽은 사람 ${n(a.read_count)}명</div>` : ''}
        <div class="actions">
          <button class="btn primary" type="submit">저장</button>
          <a class="btn" href="#/notices" style="text-decoration:none">취소</a>
          ${isNew ? '' : '<button class="btn danger" type="button" id="del" style="margin-left:auto">삭제</button>'}
        </div>
        <div id="ferr"></div>
      </form>`;
    const form = app.querySelector('#nf');
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const btn = form.querySelector('button[type=submit]');
      btn.disabled = true; btn.textContent = '저장 중…';
      try {
        await rpc('admin_save_announcement', {
          p_id: isNew ? null : id,
          p_title: form.querySelector('#f-title').value,
          p_body: form.querySelector('#f-body').value,
          p_link_url: form.querySelector('#f-url').value.trim() || null,
          p_link_label: form.querySelector('#f-label').value.trim() || null,
          p_is_important: form.querySelector('#f-imp').checked,
          p_is_published: form.querySelector('#f-pub').checked,
        });
        location.hash = '#/notices';
      } catch (err) {
        form.querySelector('#ferr').innerHTML = `<div class="error">${esc(err.message)}</div>`;
        btn.disabled = false; btn.textContent = '저장';
      }
    });
    form.querySelector('#del')?.addEventListener('click', async () => {
      if (!confirm(`"${a.title}" 공지를 삭제할까요? 읽음 기록도 함께 지워지고 되돌릴 수 없습니다.`)) return;
      try {
        await rpc('admin_delete_announcement', { p_id: id });
        location.hash = '#/notices';
      } catch (err) {
        form.querySelector('#ferr').innerHTML = `<div class="error">${esc(err.message)}</div>`;
      }
    });
  }

  // ── 라우팅 ─────────────────────────────────────────────────────────────
  async function route(aiDays) {
    const [, page = 'overview', id] = location.hash.split('/');
    document.querySelectorAll('[data-nav]').forEach((a) =>
      a.classList.toggle('on', a.dataset.nav === ({ business: 'businesses', notice: 'notices' }[page] || page)));
    app.innerHTML = '<p class="loading">불러오는 중…</p>';
    tip.style.display = 'none';
    try {
      if (page === 'businesses') await renderBusinesses();
      else if (page === 'business' && id) await renderBusiness(id);
      else if (page === 'ai') await renderAi(typeof aiDays === 'number' ? aiDays : 30);
      else if (page === 'notices') await renderNotices();
      else if (page === 'notice' && id) await renderNoticeForm(id);
      else await renderOverview();
      scrollTo(0, 0);
    } catch (e) {
      showError(e);
    }
  }

  async function start() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) { renderLogin(); return; }
    // 관리자 확인 — 아니면 로그아웃 (데이터는 DB 함수가 따로 한 번 더 막는다)
    const { data: ok, error } = await sb.rpc('is_admin');
    if (error || ok !== true) {
      await sb.auth.signOut();
      renderLogin('관리자 계정이 아닙니다.');
      return;
    }
    document.getElementById('top').hidden = false;
    document.getElementById('who-email').textContent = session.user.email;
    if (!location.hash) location.hash = '#/overview';
    route();
  }

  document.getElementById('logout').addEventListener('click', async () => {
    await sb.auth.signOut();
    location.hash = '';
    renderLogin();
  });
  addEventListener('hashchange', () => route());
  sb.auth.onAuthStateChange((event) => { if (event === 'SIGNED_OUT') renderLogin(); });
  start();
})();
