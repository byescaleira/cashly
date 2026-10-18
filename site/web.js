import { strings, locales } from './web-strings.js';
import { createSessionID, generateKeyPair, pairingLink, openPackage, fetchPackage } from './web-crypto.js';

const WAIT_INTERVAL = 2000;
const WATCH_INTERVAL = 30000;
const CODE_LIFETIME = 10 * 60 * 1000;
const DATABASE = 'cashly-web';
const STORE = 'session';

function resolveLocale() {
  const codes = Object.keys(locales);
  const match = (value) => {
    if (!value) return null;
    const wanted = String(value).replace(/_/g, '-').toLowerCase();
    return codes.find((code) => code.toLowerCase() === wanted || locales[code].toLowerCase() === wanted)
      ?? codes.find((code) => code.split('-')[0] === wanted.split('-')[0])
      ?? null;
  };
  const explicit = match(new URLSearchParams(location.search).get('locale'));
  if (explicit) return explicit;
  for (const language of navigator.languages ?? [navigator.language]) {
    const code = match(language);
    if (code) return code;
  }
  return 'en-US';
}

const locale = resolveLocale();
const text = strings[locales[locale]];
const t = (key, values = {}) => (text[key] ?? strings.en[key]).replace(/\{(\w+)\}/g, (_, name) => values[name] ?? '');
const slot = (name) => document.querySelector(`[data-slot="${name}"]`);

function translatePage() {
  document.documentElement.lang = locale;
  document.querySelectorAll('[data-t]').forEach((element) => { element.textContent = t(element.dataset.t); });
  if (document.body.dataset.page === 'app') document.title = t('pageTitle');
  if (document.body.dataset.page === 'link') document.title = t('linkTitle');
}

function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DATABASE, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(STORE);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function storage(mode, action) {
  try {
    const database = await openDatabase();
    return await new Promise((resolve, reject) => {
      const request = action(database.transaction(STORE, mode).objectStore(STORE));
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  } catch {
    return undefined;
  }
}

const loadSession = () => storage('readonly', (store) => store.get('current'));
const saveSession = (session) => storage('readwrite', (store) => store.put(session, 'current'));
const clearSession = () => storage('readwrite', (store) => store.delete('current'));

const state = { session: null, etag: null, timer: null, snapshot: null, updatedAt: null };

function show(view) {
  document.querySelectorAll('[data-view]').forEach((element) => { element.hidden = element.dataset.view !== view; });
  document.querySelector('[data-action="sign-out"]').hidden = view !== 'month';
  slot('updated').hidden = view !== 'month';
}

function message(title, body) {
  stop();
  slot('message-title').textContent = t(title);
  slot('message-text').textContent = t(body);
  show('message');
}

function stop() {
  clearTimeout(state.timer);
  state.timer = null;
}

function schedule(delay) {
  stop();
  state.timer = setTimeout(poll, delay);
}

function drawCode(link) {
  const code = qrcode(0, 'M');
  code.addData(link);
  code.make();
  slot('qr').innerHTML = code.createSvgTag({ cellSize: 4, margin: 0, scalable: true });
}

async function newSession() {
  stop();
  await clearSession();
  const keys = await generateKeyPair();
  const id = createSessionID();
  const session = { id, link: await pairingLink(id, keys.publicKey), privateKey: keys.privateKey, createdAt: Date.now(), paired: false };
  state.session = session;
  state.etag = null;
  state.snapshot = null;
  drawCode(session.link);
  await saveSession(session);
  slot('status').textContent = t('waiting');
  show('pair');
  schedule(WAIT_INTERVAL);
}

async function poll() {
  const session = state.session;
  if (!session) return;
  if (document.hidden) return schedule(WAIT_INTERVAL);
  if (!session.paired && Date.now() - session.createdAt > CODE_LIFETIME) {
    await clearSession();
    return message('expiredTitle', 'expiredText');
  }
  let result;
  try {
    result = await fetchPackage(session.id, state.etag);
  } catch {
    result = { status: 'error' };
  }
  if (result.status === 'ok') {
    try {
      state.snapshot = await openPackage(session.privateKey, session.id, result.pack);
    } catch {
      await clearSession();
      return message('brokenTitle', 'brokenText');
    }
    state.etag = result.etag;
    state.updatedAt = Date.parse(result.pack.updatedAt) || Date.now();
    if (!session.paired) {
      session.paired = true;
      await saveSession(session);
    }
    renderMonth(state.snapshot);
    show('month');
  } else if (result.status === 'missing' && session.paired) {
    await clearSession();
    return message('endedTitle', 'endedText');
  } else if (result.status === 'error' || result.status === 'limited') {
    if (!session.paired) slot('status').textContent = t('retrying');
  } else if (!session.paired) {
    slot('status').textContent = t('waiting');
  }
  renderUpdated();
  schedule(session.paired ? WATCH_INTERVAL : result.status === 'limited' ? WATCH_INTERVAL : WAIT_INTERVAL);
}

function currency(snapshot) {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: snapshot.currency || 'USD' });
}

function day(value, options) {
  const [year, month, date] = value.split('-').map(Number);
  return new Intl.DateTimeFormat(locale, options).format(new Date(year, month - 1, date));
}

function palette(color) {
  return ['olive', 'rust', 'mustard', 'teal', 'denim', 'plum', 'brown', 'orange'].includes(color) ? `var(--${color})` : 'var(--tint)';
}

function element(tag, className, content) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (content !== undefined) node.textContent = content;
  return node;
}

function badge(name, color) {
  const node = element('span', 'badge', (name || '·').trim().charAt(0).toLocaleUpperCase(locale));
  node.style.setProperty('--badge', palette(color));
  return node;
}

function bar(color, ratio) {
  const node = element('div', 'bar filled');
  node.style.setProperty('--bar', color);
  node.style.setProperty('--value', `${Math.min(Math.max(ratio, 0), 1) * 100}%`);
  node.append(element('i'));
  return node;
}

function emptyRow(key) {
  const row = element('div', 'row');
  row.append(element('p', 'web-empty', t(key)));
  return row;
}

function renderMonth(snapshot) {
  const money = currency(snapshot);
  const month = snapshot.month;
  const paceColor = { onTrack: 'var(--positive)', ahead: 'var(--warning)', over: 'var(--negative)' }[month.pace] ?? 'var(--positive)';

  slot('month-range').textContent = day(month.start, { month: 'long', year: 'numeric' });
  slot('available').textContent = money.format(month.available);
  slot('available').style.color = month.available < 0 ? 'var(--negative)' : '';
  slot('per-day').textContent = t('perDay', { amount: money.format(month.perDay) });
  slot('per-day').hidden = !(month.perDay > 0);
  slot('used').textContent = t('used', { percent: new Intl.NumberFormat(locale, { style: 'percent' }).format(month.usedRatio) });
  slot('pace').textContent = t(month.pace in { onTrack: 1, ahead: 1, over: 1 } ? month.pace : 'onTrack');
  slot('pace').style.color = paceColor;
  const paceBar = slot('pace-bar');
  paceBar.style.setProperty('--bar', paceColor);
  paceBar.style.setProperty('--value', `${Math.min(Math.max(month.usedRatio, 0), 1) * 100}%`);
  paceBar.style.setProperty('--elapsed', `${Math.min(Math.max(month.elapsedRatio, 0), 1) * 100}%`);
  slot('planned').textContent = money.format(month.planned);
  slot('spent').textContent = money.format(month.spent);
  slot('income').textContent = money.format(month.income);

  const budgets = slot('budgets');
  budgets.replaceChildren(...(snapshot.budgets?.length ? snapshot.budgets.map((budget) => {
    const row = element('div', 'row budget');
    const body = element('div');
    const top = element('div', 'budget-top');
    top.append(element('span', '', budget.name), element('span', '', t('budgetOf', { spent: money.format(budget.spent), planned: money.format(budget.planned) })));
    const ratio = budget.planned > 0 ? budget.spent / budget.planned : 0;
    body.append(top, bar(ratio > 1 ? 'var(--negative)' : palette(budget.color), ratio));
    row.append(badge(budget.name, budget.color), body);
    return row;
  }) : [emptyRow('noBudgets')]));

  const upcoming = slot('upcoming');
  upcoming.replaceChildren(...(snapshot.upcoming?.length ? snapshot.upcoming.map((item) => {
    const row = element('div', 'row web-item');
    const body = element('div');
    body.append(element('div', 'web-item-title', item.description), element('div', 'web-item-detail', t('due', { date: day(item.dueDate, { day: 'numeric', month: 'short' }) })));
    row.append(badge(item.description, 'denim'), body, element('span', 'web-item-amount', money.format(item.amount)));
    return row;
  }) : [emptyRow('noUpcoming')]));

  const history = slot('history');
  const days = new Map();
  for (const transaction of snapshot.transactions ?? []) {
    if (!days.has(transaction.date)) days.set(transaction.date, []);
    days.get(transaction.date).push(transaction);
  }
  if (!days.size) {
    const group = element('div', 'group');
    group.append(emptyRow('noHistory'));
    history.replaceChildren(group);
    return;
  }
  history.replaceChildren(...[...days.entries()].sort(([a], [b]) => b.localeCompare(a)).flatMap(([date, items]) => {
    const group = element('div', 'group');
    group.append(...items.map((transaction) => {
      const row = element('div', 'row web-item');
      const body = element('div');
      const detail = element('div', 'web-item-detail');
      if (transaction.category?.name) detail.append(element('span', '', transaction.category.name));
      const status = { toPay: ['toPay', 'var(--warning)'], toReceive: ['toReceive', 'var(--teal)'], canceled: ['canceled', 'var(--secondary)'] }[transaction.status];
      if (status) {
        const chip = element('span', 'chip', t(status[0]));
        chip.style.setProperty('--chip', status[1]);
        detail.append(chip);
      }
      if (transaction.status === 'canceled') row.classList.add('canceled');
      for (const tag of transaction.tags ?? []) {
        const chip = element('span', 'chip', tag);
        chip.style.setProperty('--chip', 'var(--secondary)');
        detail.append(chip);
      }
      body.append(element('div', 'web-item-title', transaction.description), detail);
      const income = transaction.kind === 'income';
      const amount = element('span', `web-item-amount${income ? ' positive' : ''}`, (income ? '+' : '−') + money.format(Math.abs(transaction.amount)));
      row.append(badge(transaction.category?.name || transaction.description, transaction.category?.color), body, amount);
      return row;
    }));
    return [element('h3', 'web-day', day(date, { weekday: 'long', day: 'numeric', month: 'long' })), group];
  }));
}

function renderUpdated() {
  if (!state.updatedAt) return;
  const minutes = Math.round((state.updatedAt - Date.now()) / 60000);
  const relative = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
  const time = Math.abs(minutes) < 60 ? relative.format(minutes, 'minute') : relative.format(Math.round(minutes / 60), 'hour');
  slot('updated').textContent = t('updated', { time });
}

async function start() {
  translatePage();
  if (document.body.dataset.page !== 'app') return;
  document.querySelector('[data-action="new-code"]').addEventListener('click', newSession);
  document.querySelector('[data-action="sign-out"]').addEventListener('click', newSession);
  document.addEventListener('visibilitychange', () => { if (!document.hidden && state.session) schedule(0); });
  if (!window.crypto?.subtle || !window.indexedDB || typeof qrcode !== 'function') {
    return message('unsupportedTitle', 'unsupportedText');
  }
  const saved = await loadSession();
  if (saved?.privateKey && saved.paired) {
    state.session = saved;
    show(null);
    return schedule(0);
  }
  await newSession();
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
else start();
