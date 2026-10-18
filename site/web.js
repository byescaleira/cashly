import { strings, locales } from './web-strings.js';
import { renderDashboard, bindDashboard } from './web-dashboard.js';
import { createSessionID, generateKeyPair, pairingLink, openPackage, fetchPackage } from './web-crypto.js';

const WAIT_INTERVAL = 2000;
const WATCH_INTERVAL = 30000;
const PAUSED_INTERVAL = 60000;
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
  document.querySelectorAll('[data-t-placeholder]').forEach((element) => { element.placeholder = t(element.dataset.tPlaceholder); });
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
  document.body.classList.toggle('is-dashboard', view === 'month');
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
    slot('paused').hidden = true;
    state.updatedAt = Date.parse(result.pack.updatedAt) || Date.now();
    if (!session.paired) {
      session.paired = true;
      await saveSession(session);
    }
    renderMonth(state.snapshot);
    show('month');
  } else if (result.status === 'paused') {
    if (session.paired) slot('paused').hidden = false;
    else slot('status').textContent = t('pausedStatus');
    renderUpdated();
    return schedule(PAUSED_INTERVAL);
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

function kit(snapshot) {
  return { t, money: currency(snapshot), locale, element, palette, badge, bar, day };
}

function renderMonth(snapshot) {
  renderDashboard(snapshot, kit(snapshot));
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
  bindDashboard({ t, locale, element, palette, badge, bar, day });
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
