import { createServer } from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';

const PORT = Number(process.env.PORT ?? 3110);
const HOST = process.env.HOST ?? '127.0.0.1';
const ORIGIN = process.env.ALLOWED_ORIGIN ?? 'https://cashly.byescaleira.com';
const TTL_MS = Number(process.env.TTL_MS ?? 24 * 60 * 60 * 1000);
const MAX_BODY = Number(process.env.MAX_BODY ?? 1024 * 1024);
const MAX_SNAPSHOTS = Number(process.env.MAX_SNAPSHOTS ?? 5000);
const PREFIX = '/bridge';

const snapshots = new Map();
const buckets = new Map();
const LIMITS = { read: 120, write: 60 };

const sha256 = (value) => createHash('sha256').update(value).digest();
const isID = (value) => /^[A-Za-z0-9_-]{22}$/.test(value);
const clientIP = (request) =>
  (request.headers['x-forwarded-for'] ?? '').split(',')[0].trim() || request.socket.remoteAddress || 'unknown';

function allow(ip, kind, now) {
  const key = `${kind}:${ip}`;
  const bucket = buckets.get(key);
  if (!bucket || now - bucket.start >= 60_000) {
    buckets.set(key, { start: now, count: 1 });
    return true;
  }
  bucket.count += 1;
  return bucket.count <= LIMITS[kind];
}

function sweep(now) {
  for (const [id, entry] of snapshots) if (entry.expiresAt <= now) snapshots.delete(id);
  for (const [key, bucket] of buckets) if (now - bucket.start >= 60_000) buckets.delete(key);
}

function cors(request, response) {
  if (request.headers.origin === ORIGIN) {
    response.setHeader('Access-Control-Allow-Origin', ORIGIN);
    response.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.setHeader('Access-Control-Allow-Headers', 'If-None-Match');
    response.setHeader('Access-Control-Expose-Headers', 'ETag');
    response.setHeader('Vary', 'Origin');
  }
}

function send(response, status, body, headers = {}) {
  response.writeHead(status, { 'Cache-Control': 'no-store', ...headers, ...(body ? { 'Content-Type': 'application/json' } : {}) });
  response.end(body ? JSON.stringify(body) : undefined);
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    request.on('data', (chunk) => {
      size += chunk.length;
      if (size <= MAX_BODY) chunks.push(chunk);
    });
    request.on('end', () => {
      if (size > MAX_BODY) reject(Object.assign(new Error('too large'), { status: 413 }));
      else resolve(Buffer.concat(chunks).toString('utf8'));
    });
    request.on('error', reject);
  });
}

function validPackage(value) {
  const base64 = (text, min, max) => typeof text === 'string' && /^[A-Za-z0-9+/]+={0,2}$/.test(text) && text.length >= min && text.length <= max;
  return value && value.v === 2 && base64(value.appKey, 88, 88) && base64(value.nonce, 16, 16) && base64(value.ciphertext, 24, MAX_BODY);
}

function owner(request) {
  const header = request.headers.authorization ?? '';
  const match = header.match(/^Bearer ([A-Za-z0-9_-]{32,128})$/);
  return match ? sha256(match[1]) : null;
}

export function handle(request, response, now = Date.now()) {
  sweep(now);
  const url = new URL(request.url, 'http://bridge');
  const path = url.pathname.startsWith(PREFIX) ? url.pathname.slice(PREFIX.length) : url.pathname;
  const ip = clientIP(request);
  cors(request, response);

  if (path === '/health') return send(response, 200, { ok: true });
  if (request.method === 'OPTIONS') return send(response, 204);

  const match = path.match(/^\/v1\/snapshots\/([^/]+)$/);
  if (!match || !isID(match[1])) return send(response, 404, { error: 'not_found' });
  const id = match[1];
  const entry = snapshots.get(id);

  if (request.method === 'GET') {
    if (!allow(ip, 'read', now)) return send(response, 429, { error: 'rate_limited' });
    if (!entry) return send(response, 404, { error: 'not_found' });
    if (request.headers['if-none-match'] === entry.etag) return send(response, 304, null, { ETag: entry.etag });
    return send(response, 200, { ...entry.payload, updatedAt: new Date(entry.updatedAt).toISOString(), expiresAt: new Date(entry.expiresAt).toISOString() }, { ETag: entry.etag });
  }

  if (request.method !== 'PUT' && request.method !== 'DELETE') return send(response, 405, { error: 'method_not_allowed' });
  if (!allow(ip, 'write', now)) return send(response, 429, { error: 'rate_limited' });
  const ownerHash = owner(request);
  if (!ownerHash) return send(response, 401, { error: 'unauthorized' });
  if (entry && !timingSafeEqual(entry.ownerHash, ownerHash)) return send(response, 403, { error: 'forbidden' });

  if (request.method === 'DELETE') {
    snapshots.delete(id);
    return send(response, 204);
  }

  if (Number(request.headers['content-length'] ?? 0) > MAX_BODY) {
    request.resume();
    return send(response, 413, { error: 'too_large' });
  }
  return readBody(request)
    .then((text) => {
      let payload;
      try {
        payload = JSON.parse(text);
      } catch {
        return send(response, 400, { error: 'invalid_json' });
      }
      if (!validPackage(payload)) return send(response, 400, { error: 'invalid_package' });
      if (!entry && snapshots.size >= MAX_SNAPSHOTS) return send(response, 503, { error: 'full' });
      const clean = { v: 2, appKey: payload.appKey, nonce: payload.nonce, ciphertext: payload.ciphertext };
      const etag = `"${sha256(JSON.stringify(clean)).toString('hex').slice(0, 32)}"`;
      const expiresAt = entry ? entry.expiresAt : now + TTL_MS;
      snapshots.set(id, { ownerHash, payload: clean, etag, updatedAt: now, expiresAt });
      console.log(`${new Date(now).toISOString()} ${entry ? 'update' : 'create'} ${id.slice(0, 6)} ${text.length}B`);
      return send(response, entry ? 200 : 201, { expiresAt: new Date(expiresAt).toISOString() }, { ETag: etag });
    })
    .catch((error) => send(response, error.status ?? 400, { error: error.status === 413 ? 'too_large' : 'invalid_body' }));
}

export const store = snapshots;
export const rateBuckets = buckets;

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  createServer((request, response) => handle(request, response)).listen(PORT, HOST, () => {
    console.log(`cashly bridge on ${HOST}:${PORT}`);
  });
}
